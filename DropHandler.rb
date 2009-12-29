require "rubygems"
require "mp3info"
require "wmainfo"

class DropHandler
    attr_accessor :typeMap
    attr_reader   :isTransform

    @isTransform = false

    def outputType(file)
        ext = file.pathmap("%x").sub!(/^\./, "")
        @typeMap[ext]
    end

    def handles?(file)
        outputType(file) != nil
    end

end

class WavDropHandler < DropHandler
    def initialize
        @typeMap = { "wav" => "flac" }
        @isTransform = true
    end

    def handles?(file)
        pieces = file.pathmap("%n").split("#")
        super(file) && pieces.size == 5
    end

    def getOutputFile(file, inputBase)
        genre, artist, album, trackNo, title = file.pathmap("%n").split("#")
        File.join(artist, album, "#{title}.flac")
    end

    def getCommand(file, outputFile) 
        genre, artist, album, trackNo, title = file.pathmap("%n").split("#")
        return "flac --best --replay-gain --silent " \
                + "-T \"artist=#{artist}\" -T \"title=#{title}\" " \
                + "-T \"album=#{album}\" -T \"tracknumber=#{trackNo}\" " \
                + "-T \"genre=#{genre}\" " \
                + " #{PathUtils.escape(file)} " \
                + "--output-name=#{PathUtils.escape(outputFile)}"
    end
end


class AacDropHandler < DropHandler
    def initialize
        @typeMap = { "m4a" => "m4a" }
    end

    # getOutputFile using m4a tags
end


class WmaDropHandler < DropHandler
    def initialize
        @typeMap = { "wma" => "wma" }
    end

    def handles?(file)
        wma = WmaInfo.new(file)
        super(file) && !wma.hasdrm?
    end

    def getOutputFile(file, inputBase)
        wma = WmaInfo.new(file)
        artist = wma.tags["AlbumArtist"]
        artist = "Unknown Artist" if artist == nil
        album = wma.tags["AlbumTitle"]
        album = "Unknown Album" if album == nil
        title = wma.tags["Title"]
        title = "Unknown Title" if title == nil
        File.join(artist, album, "#{title}.flac")
    end
end


class Mp3DropHandler < DropHandler
    def initialize
        @typeMap = { "mp3" => "mp3" }
    end

    def getOutputFile(file, inputBase)
        mp3 = Mp3Info.new(file)
        File.join(mp3.tag.artist, mp3.tag.album, "#{mp3.tag.title}.mp3")
    end
end


class TivoDropHandler < DropHandler
    def initialize
        @typeMap = { "TiVo" => "mp4" }
        @isTransform = true
    end

    # getOutputFile using mp3 tags
end


class FlacDropHandler < DropHandler
    def initialize
        @typeMap = { "flac" => "flac" }
    end

    # getOutputFile using flac tags
    # deal with media key
end
