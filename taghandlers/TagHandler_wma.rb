require "rubygems"
require "wmainfo"
require "TagHandler"

class TagHandler_wma
    def initialize(file)
        @info = WmaInfo.new(file)
    end

    MethodToTags = { 
        :artist => "AlbumArtist", 
        :album => "AlbumTitle", 
        :title => "Title", 
        :genre => "Genre",
        :tracknumber => "TrackNumber"
    }

    MethodToTags.each do |k,v|
        define_method(k) do
            TagHandler.tag(@info.tags, v)
        end
    end

    def drm?
        @info.hasdrm?
    end
end

