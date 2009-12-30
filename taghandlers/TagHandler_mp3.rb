require "rubygems"
require "mp3info"

class TagHandler_mp3
    def initialize(file)
        @info = Mp3Info.new(file)
    end

    @@methodToTags = { 
        :artist => :artist, 
        :album => :album, 
        :title => :title, 
        :genre => :genre_s,
        :tracknumber => :tracknum
    }

    @@methodToTags.each { |k,v|
        TagHandler_mp3.send :define_method, k do
            @info.tag.send v
        end
    }
end

