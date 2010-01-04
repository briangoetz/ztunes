require "rubygems"
require "mp4info"

class MediaFile_m4a < MediaFile
    def initialize(file)
        super("m4a")
        @info = MP4Info.open(file)
    end

    MethodToTags = { 
        :artist => :ART, 
        :album => :ALB, 
        :title => :NAM, 
        :genre => :GNRE
    }

    MethodToTags.each do |k,v|
        define_method(k) do
            @info.send v
        end
    end

    def tracknumber 
        @info.TRKN[0]
    end
end

