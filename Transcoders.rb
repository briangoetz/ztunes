class TranscodeHandler < FileHandler
    def initialize(typeMap)
        super(typeMap, true)
    end

    def getOutputFile(file, inputBase)
        wasExtn = PathUtils.extension(file)
        newExtn = outputType(file)

        file = PathUtils.relativePath(file, inputBase)
        file = PathUtils.replaceExtension(file, wasExtn, newExtn) if (wasExtn != newExtn)
        file
    end

    def handle(exec, inputFile, outputFile)
        exec.defer do |exec|
            tmpFile = exec.tempFile(inputFile)
            success = transform(exec, inputFile, tmpFile)
            if (success)
                MediaFile.copyTagsFrom(inputFile, tmpFile, PathUtils.extension(outputFile))
                exec.doFileCmd(:mv, tmpFile, outputFile)
            else
                exec.doFileCmd(:rm, tmpFile) if File.exist?(tmpFile)
            end
        end
    end
end

class FlacToMp3 < TranscodeHandler
    def initialize(opts = {})
        super({ "flac" => "mp3" })
    end

    def transform(exec, inputFile, outputFile)
        cmd = "flac --decode --stdout --silent #{PathUtils.escape(inputFile)} | lame --preset standard --silent - #{PathUtils.escape(outputFile)}"
        exec.doCmd(cmd)
    end
end

class WmaToMp3 < TranscodeHandler
    def initialize(opts = {})
        super({ "wma" => "mp3" })
    end

    def transform(exec, inputFile, outputFile)
        cmd = "ffmpeg -i #{PathUtils.escape(inputFile)} -f wav - | lame --preset standard --silent - #{PathUtils.escape(outputFile)}"
        exec.doCmd(cmd)
    end
end

class M4aToMp3 < TranscodeHandler
    def initialize(opts = {})
        super({ "m4a" => "mp3" })
    end

    def transform(exec, inputFile, outputFile)
        cmd = "ffmpeg -i #{PathUtils.escape(inputFile)} -f wav - | lame --preset standard --silent - #{PathUtils.escape(outputFile)}"
        exec.doCmd(cmd)
    end
end

class Mp4ForIpod < TranscodeHandler
    def initialize(opts = {})
        super({ "mp4" => "mp4" })
    end

    def transform(exec, inputFile, outputFile)
        cmd = ""
        exec.doCmd(cmd)
    end
end