require "rubygems"
require "flacinfo"
require "MediaFile"

class MediaFile_flac
    def initialize(file)
        @info = FlacInfo.new(file)
    end

    MethodToTags = { 
        :artist => "ARTIST", 
        :album => "ALBUM", 
        :title => "TITLE", 
        :genre => "GENRE",
        :tracknumber => "TRACKNUMBER"
    }

    MethodToTags.each do |k,v|
        define_method(k) do
            MediaFile.tag(@info.tags, v)
        end
    end
end

#x = MediaFile_flac.new "hold/Roundabout.flac"
#puts x.artist, x.album, x.genre, x.title, x.tracknumber
