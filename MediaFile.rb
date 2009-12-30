require "PathUtils"

class MediaFile
    @@handlers = { }

    def initialize(extension = "", kind = :audio)
        @extension = extension
        @kind = kind
    end

    def self.types()
        @@handlers.keys
    end

    def self.for(file)
        extn = PathUtils.extension(file).downcase
        k = @@handlers[extn]
        if !k
            begin
                require "mediatypes/MediaFile_#{extn}"
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

    def tagFromHash(tags, key)
        t = tags[key]
        return t if t 
        t = tags[key.upcase]
        return t if t 
        t = tags[key.downcase]
        return t if t 
        t = tags[key.downcase.capitalize]
        return t
    end

    def fileName()
        tags = { :artist => artist, :album => album, :title => title,
                 :tracknumber => tracknumber }
        MediaFile.makeFileName(tags, @kind, @extension)
    end

    def self.makeFileName(tags, kind, extension)
        extn = extension ? ".#{extension}" : ""
        if (kind == :audio) 
            File.join(normalize(:artist, tags[:artist]),
                      normalize(:album, tags[:album]),
                      normalize(:title, tags[:title]) + extn)
        else 
            normalize(:title, tags[:title]) + extn
        end
    end

    DefaultValues = {
        :artist => "Unknown Artist",
        :album => "Unknown Album",
        :title => "Unknown Title"
    }

    def self.normalize(fieldName, value) 
        # Windows can't deal with trailing spaces or dots
        # Also can't deal with: \ / : * ? " < > |

        t = value
        t = DefaultValues[field] if !t
        t = "Unknown" if !t
        t.sub!(/[\. ]+$/, "")
        t.gsub!(/\: ?/, ' - ')
        t.tr!('*?', '  ')
        t.tr!('<>', '()')
        t.tr!('"', '\'')
        t.tr!('/\\', ',')
        t
    end
end

