require "rubygems"
require "wmainfo"
require "TagHandler"

class TagHandler_wma
    def initialize(file)
        @info = WmaInfo.new(file)
    end

    @@methodToTags = { 
        :artist => "AlbumArtist", 
        :album => "AlbumTitle", 
        :title => "Title", 
        :genre => "Genre",
        :tracknumber => "TrackNumber"
    }

    @@methodToTags.each { |k,v|
        TagHandler_wma.send :define_method, k do
            TagHandler.tag(@info.tags, v)
        end
    }

    def drm?
        @info.hasdrm?
    end
end

