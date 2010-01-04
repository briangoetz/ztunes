require "PathUtils"

class MediaFile
    @@handlers = { }

    def initialize(extension, kind = :audio)
        @extension = extension
        @kind = kind
    end

    def self.types()
        @@handlers.keys
    end

    def self.tryLoad(extn)
        begin
            require "mediatypes/MediaFile_#{extn}"
            k = eval("MediaFile_#{extn}")
            @@handlers[extn] = k
        rescue LoadError
            @@handlers[extn] = false
            # fail silently
        rescue
            @@handlers[extn] = false
            puts "Error loading tag handler for #{extn}: #{$!}"
        end
        return k
    end

    def self.supported(file)
        extn = PathUtils.extension(file).downcase
        k = @@handlers[extn]
        k = tryLoad(extn) if k == nil
        return (k != nil)
    end

    def self.for(file, extn = nil)
        if (extn)
            extn = extn.downcase
        else
            extn = PathUtils.extension(file).downcase
        end
        k = @@handlers[extn]
        k = tryLoad(extn) if k == nil
        begin
            k ? k.new(file) : nil
        rescue
            puts "Error instantiating tag handler for #{file}: #{$!}"
            nil
        end
    end

    def self.copyTagsFrom(inFile, outFile, outFileExtn = nil)
        inH = MediaFile.for(inFile)
        outH = MediaFile.for(outFile, outFileExtn)
        return if !inH || !outH
        [ :artist, :album, :title, :genre ].each do |t|
            tag = inH.send t
            outH.send "#{t}=", tag if tag != nil
        end
        outH.tracknumber = inH.tracknumber.to_i
        outH.save
    end

    def tags
        { :artist => artist, :album => album, :title => title,
          :tracknumber => tracknumber, :genre => genre }
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
                 :tracknumber => tracknumber, :genre => genre }
        MediaFile.nameFromTags(tags, @kind, @extension)
    end

    def self.nameFromTags (tags, kind, extension)
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
        t = DefaultValues[fieldName] if !t
        t = "Unknown" if !t
        if (fieldName == :artist && t =~ /;/)
           t = t.split(";")[0]
        end
        if (t =~ /^([A-Z]\.)+$/)
            t.gsub!(/\./, '')
        end
        t.sub!(/[\. ]+$/, '')
        t.gsub!(/\: ?/, ' - ')
        t.gsub!(/[\/\\] ?/, ', ')
        t.gsub!(/ ,/, ',')
        t.tr!('*?', '  ')
        t.tr!('<>', '()')
        t.tr!('"', '\'')
        t
    end
end

