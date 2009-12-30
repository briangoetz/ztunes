require "rubygems"
require "wmainfo"
require "MediaFile"

class MediaFile_wma
    def initialize(file)
        @info = WmaInfo.new(file, { :encoding => "LATIN1" } )
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
            MediaFile.tag(@info.tags, v)
        end
    end

    def drm?
        @info.hasdrm?
    end
end

