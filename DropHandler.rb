require "FileHandler"
require "MediaFile"
require "PathUtils"

class DropHandler < FileHandler
end

class WavDropHandler < DropHandler
    def initialize
        super({ "wav" => "flac" }, true)
    end

    def handles?(file)
        pieces = file.pathmap("%n").split("#")
        super(file) && pieces.size == 5
    end

    def getOutputFile(file, inputBase)
        genre, artist, album, trackNo, title = file.pathmap("%n").split("#")
        tags = { :artist => artist, :album => album, :title => title, 
                 :tracknumber => trackNo, :genre => genre }
        MediaFile.nameFromTags(tags, :audio, "flac")
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


class WmaDropHandler < DropHandler
    def initialize
        super({ "wma" => "wma" })
    end

    def handles?(file)
        super(file) && !MediaFile.for(file).drm?
    end
end


class Mp3DropHandler < DropHandler
    def initialize(opts = {})
        super({ "mp3" => "mp3" })
    end
end


class AacDropHandler < DropHandler
    def initialize(opts = {})
        super({ "m4a" => "m4a" })
    end
end


class FlacDropHandler < DropHandler
    def initialize(opts = {})
        super({ "flac" => "flac" })
    end
end


class TivoDropHandler < DropHandler
    def initialize(opts = {})
        super({ "TiVo" => "mp4" }, true)
        @mediaKey = opts[:mak]
    end

    def getOutputFile(file, inputBase)
        MediaFile.nameFromTags({ :title => file.pathmap("%n") }, :video, "mp4")
    end

    # getCommand
end
