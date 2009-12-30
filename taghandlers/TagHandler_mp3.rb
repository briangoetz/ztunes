require "rubygems"
require "mp3info"

class TagHandler_mp3
    def initialize(file)
        @info = Mp3Info.new(file)
    end

    MethodToTags = { 
        :artist => :artist, 
        :album => :album, 
        :title => :title, 
        :genre => :genre_s,
        :tracknumber => :tracknum
    }

    MethodToTags.each do |k,v|
        define_method(k) do
            @info.tag.send v
        end
    end
end

