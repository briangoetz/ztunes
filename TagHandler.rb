require "PathUtils"

class TagHandler
    @@handlers = { }

    def self.handlerFor(file)
        extn = PathUtils.extension(file)
        k = @@handlers[extn]
        if !k
            begin
                require "taghandlers/TagHandler_#{extn}"
                k = eval("TagHandler_#{extn}")
                @@handlers[extn]
            rescue LoadError
            rescue
            end
        end
        k ? k.new(file) : nil
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

#puts TagHandler.handlerFor("foo.mp3")
#puts TagHandler.handlerFor("foo.mp4")
