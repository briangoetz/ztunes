require "FileHandler"
require "MediaFile"
require "PathUtils"

class DropHandler < FileHandler
    def handle(exec, inputFile, outputFile)
        if is_transform
            tmpFile = inputFile + "_"
            # TODO support threading
            success = transform(exec, inputFile, tmpFile)
            if (success)
                exec.doFileCmd(:mv, tmpFile, outputFile)
                exec.doFileCmd(:rm, inputFile)
            else
                exec.doFileCmd(:rm, tmpFile) if File.exist?(tmpFile)
            end
            success
        else
            exec.doFileCmd(:mv, inputFile, outputFile)
            true
        end
    end
end

class WavToFlacDropHandler < DropHandler
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

    def transform(exec, inputFile, outputFile)
        genre, artist, album, trackNo, title = inputFile.pathmap("%n").split("#")
        cmd = "flac --best --replay-gain --silent " \
                + "-T \"artist=#{artist}\" -T \"title=#{title}\" " \
                + "-T \"album=#{album}\" -T \"tracknumber=#{trackNo}\" " \
                + "-T \"genre=#{genre}\" " \
                + " #{PathUtils.escape(inputFile)} " \
                + "--output-name=#{PathUtils.escape(outputFile)}"
        exec.doCmd(cmd)
    end
end


class SimpleDropHandler < DropHandler
    def initialize(extn, opts = {})
        typeMap = {}
        extn.to_a.each { |e| typeMap[e] = e }
        super(typeMap)
    end
end


class WmaDropHandler < SimpleDropHandler
    def initialize
        super("wma")
    end

    def handles?(file)
        super(file) && !MediaFile.for(file).drm?
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

    def transform(exec, inputFile, outputFile)
        cmd = "tivodecode -m #{@mediaKey} #{PathUtils.escape(inputFile)} > #{outputFile}"
        exec.doCmd(cmd)
    end
end
