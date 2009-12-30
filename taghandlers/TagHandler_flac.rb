require "rubygems"
require "flacinfo"
require "TagHandler"

class TagHandler_flac
    def initialize(file)
        @info = FlacInfo.new(file)
    end

    @@methodToTags = { 
        :artist => "ARTIST", 
        :album => "ALBUM", 
        :title => "TITLE", 
        :genre => "GENRE",
        :tracknumber => "TRACKNUMBER"
    }

    @@methodToTags.each { |k,v|
        TagHandler_flac.send :define_method, k do
            TagHandler.tag(@info.tags, v)
        end
    }
end

