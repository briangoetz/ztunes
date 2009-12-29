require "PathUtils"
require "DropHandler"

##
## Configuration 
##

BASE = "."
DROP = "#{BASE}/drop"
STAGE = "#{BASE}/stage"
SRC = [ "#{BASE}/music" ]
AUDIO = "#{BASE}/music" 
VIDEO = "#{BASE}/video" 
MP3 = "#{BASE}/mp3"
THRESHOLD = 120

@sourceDirs = { "wav" => AUDIO, 
                "mp3" => AUDIO,
                "TiVo" => VIDEO
              }

@handlers = { "wav" => WavDropHandler.new, 
              "mp3" => Mp3DropHandler.new }

## 
## End Configuration
##

@dryRun = false

def installDropHandler(type, handler) 
    @handlers[type] = handler
    taskName = "drop_#{type}"
    task :drop => [ taskName ]
    task taskName do
        FileList["#{DROP}/*.#{type}"].each do |f|
            if (Time.now - File.stat(f).mtime > THRESHOLD)
                stageFile = PathUtils.computeRelative(f, DROP, STAGE)
                outputBase = @sourceDirs[type]
                outputFile = handler.getOutputFile(f, DROP, outputBase)
                outputDir = outputFile.pathmap("%d")
                doFileCmd(:mv, [ f, stageFile ])
                doFileCmd(:mkdir_p, outputDir) if !File.exist?(outputDir)
                if handler.isTransform
                    # TODO thread these
                    # catch exceptions?
                    doCmd(handler.getCommand(stageFile, outputFile))
                    doFileCmd(:rm, stageFile)
                else
                    doFileCmd(:mv, [ stageFile, outputFile ])
                end
            end
        end
    end
end

@handlers.each { |k,v| installDropHandler(k, v) }

task :preview do
    @dryRun = true
end


task :prune_src do
    SRC.each { |d| pruneEmptyDirs(d) }
end

task :prune_mp3 do
    pruneEmptyDirs(MP3)
end

task :prune => [ :prune_src, :prune_mp3 ]


def pruneEmptyDirs(dir, depth = 0) 
    PathUtils.dirEntries(dir) \
        .map    { |f| File.join(dir, f) } \
        .select { |f| File.directory? f } \
        .each   { |s| pruneEmptyDirs(s, depth+1) }

    if depth > 0 && PathUtils.dirEntries(dir).empty? 
        doFileCmd :rmdir, dir
    end
end 

def doFileCmd(cmd, args)
    begin
        self.send cmd, args if !@dryRun
        puts "#{cmd} #{args.join(' ')}"
    rescue
        puts "Exception: " + $!
        puts "  executing #{cmd} #{args}"
    end 
end

def doCmd(cmd)
    begin
        puts "#{cmd}"
        kernel cmd if !@dryRun
    rescue
        puts "...execution error: " + $!
    end 
end


task :default do
end
