require "PathUtils.rb"
require "DropHandler.rb"

##
## Configuration 
##

BASE = "."
DROP = "#{BASE}/drop"
STAGE = "#{BASE}/stage"
SRC = [ "#{BASE}/music" ]
MP3 = "#{BASE}/mp3"
THRESHOLD = 120

@handlers = { "wav" => WavDropHandler.new }

## 
## End Configuration
##


def installDropHandler(handler) 
    @handlers[handler.fileType] = handler
    taskName = "drop_#{handler.fileType}"
    task :drop => [ taskName ]
    task taskName do
    end
end

@handlers.each { |k,v| installDropHandler(v) }

task :default do
    puts PathUtils.computeRelative("/foo/yada/bar.baz", "/foo", "/moo", "baz", "max")
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
        self.send cmd, args
        puts "#{cmd} #{args}"
    rescue
        puts "Exception: " + $!
        puts "  executing #{cmd} #{args}"
    end 
end

