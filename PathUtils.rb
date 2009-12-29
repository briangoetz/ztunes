class PathUtils

    def self.splitPath(dir)
        dir.split(File::SEPARATOR)
    end

    def self.computeRelative(file, fromBase, toBase, \
                             fromExtn = "", toExtn = "") 
        dirs = splitPath(File.dirname(file))
        fromDirs = splitPath(fromBase)
        while (!fromDirs.empty? && fromDirs.first == dirs.first)
            dirs.shift 
            fromDirs.shift 
        end
        toDirs = splitPath(toBase)
        return File.join(toDirs.concat(dirs).concat([ File.basename(file, fromExtn) + toExtn ]))
    end

    def self.searchList(dirs, file) 
        dirs.each do |d|
            f = File.join(d, file)
            if File.exist?(f)
                return f
            end
        end
        return ""
    end

    def self.dirEntries(dir)
        (!File.exist? dir) \
            ? [ ] \
            : Dir.entries(dir) - [".", ".."] 
    end 

end


