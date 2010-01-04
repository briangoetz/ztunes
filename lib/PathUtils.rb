module PathUtils

    def self.splitPath(file)
        file.split(File::SEPARATOR)
    end

    def self.relativePath(file, base) 
        filePaths = splitPath(File.expand_path(file))
        basePaths = splitPath(File.expand_path(base))
        if (filePaths.first(basePaths.length) == basePaths)
            File.join(filePaths.last(filePaths.length-basePaths.length))
        else
            ""
        end
    end

    def self.replaceExtension(file, fromExtn, toExtn) 
        file.gsub(/\.#{fromExtn}$/, ".#{toExtn}");
    end

    def self.computeRelative(file, fromBase, toBase, 
                                  fromExtn = "", toExtn = "")
        f = relativePath(file, fromBase)
        f = File.join(toBase, f) if f != ""
        f = replaceExtension(f, fromExtn, toExtn) if (fromExtn != "")
        f
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

    def self.extension(file) 
        File.extname(file).sub(/^\./, "")
    end

    def self.escape(s) 
        # How many backslashes?  Keep adding more until it works.
        s.gsub(/([()`'"&;, ])/, '\\\\\\1') 
    end

    def self.isDeadLink(f)
        return false if !File.symlink?(f)
        target = File.readlink(f)
        return !File.exist?(target) || isDeadLink(target)
    end
end

#puts PathUtils.computeRelative("/a/b/c/d.e", "/a/b", "/x/y", "e", "f")
#puts PathUtils.computeRelative("/a/b/c/d.e", "/a/b", "/x/y")
