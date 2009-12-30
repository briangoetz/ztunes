require "PathUtils"

class MediaFile
    @@handlers = { }

    def self.handlerFor(file)
        extn = PathUtils.extension(file).downcase
        k = @@handlers[extn]
        if !k
            begin
                require "taghandlers/MediaFile_#{extn}"
                k = eval("MediaFile_#{extn}")
                @@handlers[extn] = k
            rescue LoadError
                puts "Error loading tag handler for #{extn}: #{$!}"
            rescue
                puts "Error loading tag handler for #{extn}: #{$!}"
            end
        end
        begin
            k ? k.new(file) : nil
        rescue
            puts "Error instantating tag handler for #{file}: #{$!}"
            nil
        end
    end

    def self.tag(tags, key)
        t = tags[key]
        return t if t 
        t = tags[key.upcase]
        return t if t 
        t = tags[key.downcase]
        return t if t 
        t = tags[key.downcase.capitalize]
        return t
    end
end

