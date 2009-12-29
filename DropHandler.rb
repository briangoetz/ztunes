# fileType => fileTypes?

class DropHandler
    attr_reader :fileType
    attr_reader :outputFileType

    def handles?(file)
        file =~ /#{fileType}$/
    end

    def getOutputFile(file, inputBase, outputBase)
        return PathUtils.computeRelative(file, inputBase, outputBase, @fileType, @outputFileType)
    end
end

class WavDropHandler < DropHandler
    def initialize
        @fileType = "wav"
        @outputFileType = "flac"
    end

    def handles?(file)
        filePart = file.pathmap("%n")
        pieces = filePart.split("#")
        super.handles?(file) && pieces.size == 5
    end

    def getOutputFile(file, inputBase, outputBase)
        genre, artist, album, trackNo, title = file.pathmap("%n").split("#")
        File.join(outputBase, artist, album, "#{title}.flac")
    end

    def getCommand(file, outputFile) 
        genre, artist, album, trackNo, title = file.pathmap("%n").split("#")
        return "flac --best --replay-gain --delete-input-file --silent " \
                + "-T \"artist=#{artist}\" -T \"title=#{title}\" " \
                + "-T \"album=#{album}\" -T \"tracknumber=#{trackNo}\" " \
                + "-T \"genre=#{genre}\" " \
                + " #{file} --output-name=#{outputFile}"
    end
end


class AacDropHandler < DropHandler
    def initialize
        @fileType = "mp4"
        @outputFileType = "mp4"
    end
end


class WmaDropHandler < DropHandler
end


class Mp3DropHandler < DropHandler
end


class TivoDropHandler < DropHandler
end


class FlacDropHandler < DropHandler
end
