require "rubygems"
require "mp3info"

class MediaFile_mp3 < MediaFile
    def initialize(file)
        super("mp3")
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

        define_method("#{k}=") do |val|
            @info.tag.send "#{v}=", val
        end
    end

    def tags
        @info.tag2
    end

    def save
        @info.flush
    end
end

