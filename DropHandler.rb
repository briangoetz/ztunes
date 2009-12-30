require "MediaFile"
require "PathUtils"

class DropHandler
    attr_accessor :typeMap
    attr_reader   :isTransform

    @isTransform = false

    def outputType(file)
        @typeMap[PathUtils.extension(file)]
    end

    def handles?(file)
        outputType(file) != nil
    end

    def getOutputFile(file, inputBase) 
        th = MediaFile.for(file)
        return nil if !th
        wasExtn = PathUtils.extension(file)
        newExtn = outputType(file)

        f = th.fileName()
        f = PathUtils.replaceExtension(f, wasExtn, newExtn) if (wasExtn != newExtn)
        f
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
        tags = { :artist => artist, :album => album, :title => title, 
                 :tracknumber => trackNo, :genre => genre }
        MediaFile.makeFileName(tags, :audio, "flac")
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
        @typeMap = { "wma" => "wma" }
    end

    def handles?(file)
        super(file) && !MediaFile.for(file).drm?
    end
end


class Mp3DropHandler < DropHandler
    def initialize
        @typeMap = { "mp3" => "mp3" }
    end
end


class AacDropHandler < DropHandler
    def initialize
        @typeMap = { "m4a" => "m4a" }
    end
end


class FlacDropHandler < DropHandler
    def initialize
        @typeMap = { "flac" => "flac" }
    end
end


class TivoDropHandler < DropHandler
    def initialize
        @typeMap = { "TiVo" => "mp4" }
        @isTransform = true
    end

    def getOutputFile(file, inputBase)
        MediaFile.makeFileName({ :title => file.pathmap("%n") }, :video, "mp4")
    end

    # getCommand
    # deal with media key
end
