require "rubygems"
require "PathUtils"
require "DropHandler"
require "Transcoders"
require "calibre/semaphore"

##
## Configuration 
##

BASE = "."
DROP = "#{BASE}/drop"
STAGE = "#{BASE}/stage"
AUDIO = "#{BASE}/music"
IPOD = "#{BASE}/ipod" 
SQUEEZEBOX = "#{BASE}/squeezebox"
VIDEO = "#{BASE}/video"
MP3 = "#{BASE}/mp3"
THRESHOLD = 120
MAX_THREADS = 4

DROP_FOLDERS = {
        DROP => {
                "wav"  => { :handler => WavToFlacDropHandler.new,  :toDir => AUDIO },
                "mp3"  => { :handler => SimpleDropHandler.new("mp3"),  :toDir => AUDIO },
                "wma"  => { :handler => WmaDropHandler.new,  :toDir => AUDIO },
                "flac" => { :handler => SimpleDropHandler.new("flac"), :toDir => AUDIO },
                "m4a"  => { :handler => SimpleDropHandler.new("m4a"),  :toDir => AUDIO }
        }
}

VIEW_FOLDERS = {
        MP3 => { :target => :mp3,
                 :fromDirs => [ AUDIO ],
                 :supportedTypes => [ "mp3" ],
                 :transcode => { "flac" => FlacToMp3.new,
                                 "wma" => WmaToMp3.new,
                                 "m4a" => M4aToMp3.new }
        },
        IPOD => { :target => :ipod,
                  :fromDirs => [ AUDIO, MP3 ],
                  :supportedTypes => [ "m4a", "mp3" ],
                  :transcode => { "mp4" => Mp4ForIpod.new }
        },
        SQUEEZEBOX => { :target => :squeezebox,
                        :fromDirs => [ AUDIO, MP3 ],
                        :supportedTypes => [ "flac", "wma", "mp3" ]
        }
}

ADDITIONAL_SOURCES = [ "/home/media/music" ]

##
## End Configuration
##

@dropFolders = [ ]
@viewFolders = [ ]
@folderCounter = 0
@sourceFolders = [ ]
@viewTargets = { }
ALL_FILES = File.join("**", "*")

#
# Encapsulate conditional execution, printing to console, and thread management
# Unfortunately we have to define this inside the rakefile to pick up all the rake goodies, and define it first...
#
class ZTunesExec
    attr_accessor :dryRun

    def initialize()
        @dryRun = false
        @counter = 0
        @semaphore = Semaphore.new MAX_THREADS
        @pendingThreads = [ 0 ]
        @pendingThreads.extend(MonitorMixin)
        @condition = @pendingThreads.new_cond
    end

    def doFileCmd(cmd, *args)
        begin
            args.each { |s| s = PathUtils.escape(s) };
            if (@dryRun)
                puts "#{cmd} #{args.join(' ')}"
            else
                self.send cmd, *args if !@dryRun
            end
        rescue
            puts "Exception: " + $!
            puts "  executing #{cmd} #{args.join(' ')}"
        end
    end

    def doCmd(cmd)
        begin
            puts "#{cmd}"
            if !@dryRun
                Kernel.system cmd
                $?
            else
                0
            end
        rescue
            puts "...execution error: " + $!
            $?
        end
    end

    def tempFile(f)
        @pendingThreads.synchronize do
            @counter += 1
            File.join(STAGE, "#{f.pathmap("%f")}-#{$$}-#{@counter}")
        end
    end

    def defer(&proc)
        begin
            @pendingThreads.synchronize do
                t = Thread.new(self) do |exec|
                    begin
                        Thread.stop
                        @semaphore.wait
                        proc.call(exec)
                    ensure
                        @semaphore.signal
                        @pendingThreads.synchronize do
                            @pendingThreads[0] -= 1
                            @condition.signal
                        end
                    end
                end
                @pendingThreads[0] += 1
                t.run 
            end
        end
    end

    def join
        @pendingThreads.synchronize do
            @condition.wait_while { @pendingThreads[0] > 0 }
        end
    end
end

EXEC = ZTunesExec.new

DROP_FOLDERS.each_value { |types| types.each_value { |config| @sourceFolders << config[:toDir] } }
VIEW_FOLDERS.each_value { |config| @sourceFolders = @sourceFolders | config[:fromDirs].to_a }
@sourceFolders = @sourceFolders | ADDITIONAL_SOURCES.to_a
@sourceFolders.uniq!

#
# Task :drop scans the DROP folder, and looks for any files of a type
# for which it has a handler, which has not been modified for at least 
# THRESHOLD seconds.  It files them into the AUDIO or VIDEO directory, 
# based on the file type.
#

DROP_FOLDERS.each do |dir, types|
    @dropFolders << dir
    @folderCounter += 1
    counter = @folderCounter
    types.each do |type, config|
        handler = config[:handler]
        taskName = "drop_#{type}_#{counter}"
        task :drop => [ taskName ]
        task taskName do
            FileList[File.join(dir, "*.#{type}")].each do |f|
                if ((Time.now - File.stat(f).mtime > THRESHOLD) &&
                        handler.handles?(f))
                    stageFile = PathUtils.computeRelative(f, dir, STAGE)
                    outputBase = config[:toDir]
                    outputFile = File.join(outputBase, handler.getOutputFile(f, dir))
                    outputDir = outputFile.pathmap("%d")
                    EXEC.doFileCmd(:mv, f, stageFile)
                    EXEC.doFileCmd(:mkdir_p, outputDir) if !File.exist?(outputDir)
                    handler.handle(EXEC, stageFile, outputFile)
                end
            end
            EXEC.join
        end
    end
end


#
# Task :views
#

VIEW_FOLDERS.each do |viewDir, config|
    @viewFolders << viewDir
    @folderCounter += 1
    counter = @folderCounter
    target = config[:target]
    taskName = target ? target : "view_#{counter}"
    @viewTargets[viewDir] = taskName
    task :views => [ taskName ]
    task taskName do
        supportedTypes = config[:supportedTypes].to_a
        transcodeTypes = config[:transcode] ? config[:transcode].keys : []
        targetsDone = {}
        tracksDone = {}
        sourceFiles = []

        config[:fromDirs].to_a.each do |d|
            FileList[File.join(d, ALL_FILES)].each do |f|
                sourceFiles << [d, f]
            end
        end

        def iter(sourceFiles, types)
            if !types.empty?
                sourceFiles.each do |p|
                    d, f = p
                    next if File.directory?(f)
                    extn = PathUtils.extension(f)
                    next if !types.include?(extn)
                    yield d, f, extn
                end
            end
        end

        # Do the supported types first, then the transcodes
        # Filter out duplicate types; if we've already grabbed a Foo.flac, don't also grab the Foo.mp3
        iter(sourceFiles, supportedTypes) do |d, f, extn|
            target = PathUtils.computeRelative(f, d, viewDir)
            next if targetsDone[target]
            targetsDone[target] = f
            trackKey = PathUtils.relativePath(f, d).pathmap("%X")
            next if tracksDone[trackKey]
            tracksDone[trackKey] = true
            unless uptodate?(target, f)
                next if (File.exist?(target) && File.symlink?(target) && File.expand_path(File.readlink(target)) == File.expand_path(f))
                outputDir = target.pathmap("%d")
                EXEC.doFileCmd(:mkdir_p, outputDir) if !File.exist?(outputDir)
                target = File.expand_path(target)
                EXEC.doFileCmd(:rm, target) if File.exist?(target)
                EXEC.doFileCmd(:ln_s, File.expand_path(f), target)
            end
        end
        iter(sourceFiles, transcodeTypes) do |d, f, extn|
            handler = config[:transcode][extn]
            target = File.join(viewDir, handler.getOutputFile(f, d))
            next if targetsDone[target]
            targetsDone[target] = f
            trackKey = PathUtils.relativePath(f, d).pathmap("%X")
            next if tracksDone[trackKey]
            tracksDone[trackKey] = true
            unless uptodate?(target, f)
                outputDir = target.pathmap("%d")
                EXEC.doFileCmd(:mkdir_p, outputDir) if !File.exist?(outputDir)
                handler.handle(EXEC, f, target)
            end
        end
        EXEC.join
    end
end

# If a view points to another view, then create the appropriate dependency
VIEW_FOLDERS.each do |viewDir, config|
    config[:fromDirs].to_a.each do |d|
        if (@viewTargets[d])
            task @viewTargets[viewDir] => [ @viewTargets[d] ]
        end
    end
end

#
# Task :preview is like the -n switch for make; when put at the beginning
# of the task list, it makes later tasks only print out their actions, but
# not execute them.
#

task :preview do
    EXEC.dryRun = true
end


# 
# Task :rename will crawl the source directories, and rename any files whose
# file names do not match their tags.
#

task :rename do
    @sourceFolders.each do |d|
        FileList[File.join(d, ALL_FILES)].each do |f|
            next if File.directory?(f)
            th = MediaFile.for(f)
            next if !th
            relPath = PathUtils.relativePath(f, d)
            shouldBe = th.fileName
            if (relPath != shouldBe)
                EXEC.doFileCmd(:mv, f, File.join(d, shouldBe))
            end
        end
    end
end


#
# Task :checktags crawls through the source directories, and warns if any 
# files have missing tags
#

task :checktags do
    @sourceFolders.each do |d|
        FileList[File.join(d, ALL_FILES)].each do |f|
            next if File.directory?(f)
            th = MediaFile.for(f)
            next if !th

            puts "Missing ARTIST: #{f}" if !th.artist
            puts "Missing ALBUM: #{f}" if !th.album
            puts "Missing TITLE: #{f}" if !th.title
            puts "Missing TRACK NUMBER: #{f}" if !th.tracknumber
            puts "Missing GENRE: #{f}" if !th.genre
        end
    end
end


#
# Task :prune will scan the source directories, and will delete any empty
# directories (which might have been created by renaming).
#

task :prune_src do
    @sourceFolders.each { |d| pruneEmptyDirs(d) }
end

task :prune_drop do
    DROP_FOLDERS.each_key {|k| pruneEmptyDirs(k) }
end

task :prune_views do
    VIEW_FOLDERS.each_key {|k| pruneEmptyDirs(k) }
end

task :prune_dead_links do
    VIEW_FOLDERS.each_key {|k| pruneDeadLinks(k) }
end

task :prune_dead_transcodes do
    # TODO for each non-link file in the view folder, try to find a source, or prune it
end

task :prune => [ :prune_src, :prune_drop, :prune_views, :prune_dead_links, :prune_dead_transcodes ]


def pruneDeadLinks(dir)
    FileList[File.join(dir, ALL_FILES)].each do |f|
        if (PathUtils.isDeadLink(f))
            EXEC.doFileCmd :rm, f
        end
    end
end

def pruneEmptyDirs(dir, depth = 0)
    PathUtils.dirEntries(dir) \
        .map    { |f| File.join(dir, f) } \
        .select { |f| File.directory? f } \
        .each   { |s| pruneEmptyDirs(s, depth+1) }

    if depth > 0 && PathUtils.dirEntries(dir).empty? 
        EXEC.doFileCmd :rmdir, dir
    end
end 

task :default do
end

