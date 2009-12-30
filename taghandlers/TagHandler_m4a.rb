require "rubygems"
require "mp4info"

class TagHandler_m4a
    def initialize(file)
        @info = MP4Info.open(file)
    end

    @@methodToTags = { 
        :artist => :ART, 
        :album => :ALB, 
        :title => :NAM, 
        :genre => :GNRE
    }

    @@methodToTags.each { |k,v|
        TagHandler_m4a.send :define_method, k do
            @info.send v
        end
    }

    def tracknumber 
        @info.TRKN[0]
    end
end

