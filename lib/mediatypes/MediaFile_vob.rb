require "rubygems"
require "MediaFile"

class MediaFile_vob < MediaFile
    def initialize(file)
        super("vob")
    end

    Methods = [ :artist, :album, :title, :genre, :tracknumber ]

    Methods.each do |k|
        define_method(k) do
            nil
        end
    end
end

