require "PathUtils.rb"
require "DropHandler.rb"

##
## Configuration 
##

BASE = "."
DROP = "#{BASE}/drop"
STAGE = "#{BASE}/stage"
SRC = [ "#{BASE}/music" ]
OUT = "#{BASE}/music" 
MP3 = "#{BASE}/mp3"
THRESHOLD = 120

@handlers = { "wav" => WavDropHandler.new }

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
                outputFile = handler.getOutputFile(stageFile, STAGE, OUT)
                outputDir = outputFile.pathmap("%d")
                doFileCmd(:mv, [ f, stageFile ])
                doFileCmd(:mkdir_p, outputDir) if !File.exist?(outputDir)
                # TODO thread these
                doCmd(handler.getCommand(stageFile, outputFile))
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
        puts "#{cmd} #{args}"
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
