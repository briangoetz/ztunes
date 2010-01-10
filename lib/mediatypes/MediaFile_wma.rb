require "rubygems"
require "wmainfo"
require "MediaFile"

class MediaFile_wma < MediaFile
    def initialize(file)
        super("wma")
        @info = WmaInfo.new(file, { :encoding => "LATIN1" } )
    end

    MethodToTags = { 
        :album => "AlbumTitle",
        :title => "Title", 
        :genre => "Genre",
        :tracknumber => "TrackNumber"
    }

    MethodToTags.each do |k,v|
        define_method(k) do
            tagFromHash(@info.tags, v)
        end
    end

    def artist
        result = tagFromHash(@info.tags, "Author")
        result = tagFromHash(@info.tags, "AlbumArtist") if !result
        result
    end

    def tags
        @info.tags
    end

    def drm?
        @info.hasdrm?
    end
end

