require "rubygems"
require "flacinfo"
require "MediaFile"

class MediaFile_flac < MediaFile
    def initialize(file)
        super("flac")
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
            tagFromHash(@info.tags, v)
        end
    end
end

