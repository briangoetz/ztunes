require "rubygems"
require "mp3info"

class DropHandler
    attr_accessor :typeMap
    attr_reader   :isTransform

    @isTransform = false

    def outputType(file)
        @typeMap[file.pathmap("%x")]
    end

    def handles?(file)
        outputType(file) != nil
    end

    def getOutputFile(file, inputBase, outputBase)
        ext = file.pathmap("%x")
        f = PathUtils.computeRelative(file, inputBase, outputBase, ext, @typeMap[ext])
    end
end

class WavDropHandler < DropHandler
    def initialize
        @typeMap = { "wav" => "flac" }
        @isTransform = true
    end

    def handles?(file)
        pieces = file.pathmap("%n").split("#")
        super.handles?(file) && pieces.size == 5
    end

    def getOutputFile(file, inputBase, outputBase)
        genre, artist, album, trackNo, title = file.pathmap("%n").split("#")
        File.join(outputBase, artist, album, "#{title}.flac")
    end

    def getCommand(file, outputFile) 
        genre, artist, album, trackNo, title = file.pathmap("%n").split("#")
        return "flac --best --replay-gain --silent " \
                + "-T \"artist=#{artist}\" -T \"title=#{title}\" " \
                + "-T \"album=#{album}\" -T \"tracknumber=#{trackNo}\" " \
                + "-T \"genre=#{genre}\" " \
                + " #{file} --output-name=#{outputFile}"
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

    # getOutputFile using wma tags
end


class Mp3DropHandler < DropHandler
    def initialize
        @typeMap = { "mp3" => "mp3" }
    end

    def getOutputFile(file, inputBase, outputBase)
        mp3 = Mp3Info.new(file)
        File.join(outputBase, mp3.tag.artist, mp3.tag.album, "#{mp3.tag.title}.mp3")
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
