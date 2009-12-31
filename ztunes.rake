require "PathUtils"
require "DropHandler"

##
## Configuration 
##

BASE = "."
DROP = "#{BASE}/drop"
STAGE = "#{BASE}/stage"
SRC = [ "#{BASE}/music", "/home/media/music"  ]
AUDIO = "#{BASE}/music" 
VIDEO = "#{BASE}/video" 
MP3 = "#{BASE}/mp3"
THRESHOLD = 120

DROP_FOLDERS = {
        DROP => {
                "wav"  => { :handler => WavDropHandler.new,  :toDir => AUDIO },
                "mp3"  => { :handler => Mp3DropHandler.new,  :toDir => AUDIO },
                "wma"  => { :handler => WmaDropHandler.new,  :toDir => AUDIO },
                "flac" => { :handler => FlacDropHandler.new, :toDir => AUDIO },
                "m4a"  => { :handler => AacDropHandler.new,  :toDir => AUDIO }
        }
}

#SHADOW_FOLDERS = {
#        MP3 => { :fromDirs => [ AUDIO ],
#                 :supportedTypes => [ "mp3" ],
#                 :transcode => { "flac" => FlacToMp3.new }
#        },
#        IPOD => { },
#        SQUEEZEBOX => { }
#        }

@sourceDirs = {
        "wav" => AUDIO,
        "mp3" => AUDIO,
        "wma" => AUDIO,
        "m4a" => AUDIO,
        "flac" => AUDIO,
        "TiVo" => VIDEO }


## 
## End Configuration
##

@dryRun = false
@dropFolders = [ ]
@dropCounter = 0

#
# Task :drop scans the DROP folder, and looks for any files of a type
# for which it has a handler, which has not been modified for at least 
# THRESHOLD seconds.  It files them into the AUDIO or VIDEO directory, 
# based on the file type.
#

DROP_FOLDERS.each do |dir, types|
    @dropFolders << dir
    counter = ++@dropCounter
    types.each do |type, config|
        handler = config[:handler]
        taskName = "drop_#{type}_#{counter}"
        task :drop => [ taskName ]
        task taskName do
            FileList["#{dir}/*.#{type}"].each do |f|
                if ((Time.now - File.stat(f).mtime > THRESHOLD) &&
                        handler.handles?(f))
                    stageFile = PathUtils.computeRelative(f, DROP, STAGE)
                    outputBase = config[:toDir]
                    outputFile = File.join(outputBase,
                                           handler.getOutputFile(f, DROP))
                    outputDir = outputFile.pathmap("%d")
                    doFileCmd(:mv, f, stageFile)
                    doFileCmd(:mkdir_p, outputDir) if !File.exist?(outputDir)
                    if handler.is_transform
                        # TODO thread these
                        # catch exceptions?
                        # TODO write to temporary output file, then rename
                        # TODO turn doCmd into doProc
                        doCmd(handler.getCommand(stageFile, outputFile))
                        doFileCmd(:rm, stageFile)
                    else
                        doFileCmd(:mv, stageFile, outputFile)
                    end
                end
            end
        end
    end
end

#
# Task :preview is like the -n switch for make; when put at the beginning
# of the task list, it makes later tasks only print out their actions, but
# not execute them.
#

task :preview do
    @dryRun = true
end


# 
# Task :rename will crawl the source directories, and rename any files whose
# file names do not match their tags.
#

task :rename do
    SRC.each do |d|
        FileList["#{d}/**/*"].each do |f|
            next if File.directory?(f)
            th = MediaFile.for(f)
            next if !th
            relPath = PathUtils.relativePath(f, d)
            shouldBe = th.fileName
            if (relPath != shouldBe)
                doFileCmd(:mv, f, File.join(d, shouldBe))
            end
        end
    end
end


#
# Task :checktags crawls through the source directories, and warns if any 
# files have missing tags
#

task :checktags do
    SRC.each do |d|
        FileList["#{d}/**/*"].each do |f|
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


task :mp3 do
    SRC.each do |d|
        FileList["#{d}/**/*"].each do |f| 
            next if File.directory?(f)
            extn = PathUtils.extension(f)
            # next if not audio
            if (extn == "mp3")
                # doFileCmd :ln_s
            else
                # transcode
            end
        end
    end
end


#
# Task :prune will scan the source directories, and will delete any empty
# directories (which might have been created by renaming).
#

task :prune_src do
    SRC.each { |d| pruneEmptyDirs(d) }
end

task :prune_mp3 do
    pruneEmptyDirs(MP3)
end

task :prune_drop do
    DROP_FOLDERS.each_key {|k| pruneEmptyDirs(k) }
end

task :prune => [ :prune_src, :prune_mp3, :prune_drop ]


def pruneDeadLinks(dir)
    FileList["#{dir}/**/*"].each do |f|
        if (File.symlink?(f) && File.readlink(f) != nil)
            doFileCmd :rm, f
        end
    end
end

def pruneEmptyDirs(dir, depth = 0)
    PathUtils.dirEntries(dir) \
        .map    { |f| File.join(dir, f) } \
        .select { |f| File.directory? f } \
        .each   { |s| pruneEmptyDirs(s, depth+1) }

    if depth > 0 && PathUtils.dirEntries(dir).empty? 
        doFileCmd :rmdir, dir
    end
end 

def doFileCmd(cmd, *args)
    begin
        args = args.each { |s| s = PathUtils.escape(s) };
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
        Kernel.system cmd if !@dryRun
    rescue
        puts "...execution error: " + $!
    end 
end

task :default do
end
