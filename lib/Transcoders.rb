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
                MediaFile.copyTagsFrom(inputFile, tmpFile, PathUtils.extension(outputFile)) if !exec.dryRun
                outputDir = outputFile.pathmap("%d")
                EXEC.doFileCmd(:mkdir_p, outputDir) if !File.exist?(outputDir)
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
        title = inputFile.pathmap("%n")
        cmd = "ffmpeg -y -i #{PathUtils.escape(inputFile)} -f mp4 -metadata title='#{title}' -vcodec libx264 -level 21 -s 480x320 -b 768k -bt 768k -bufsize 4M -maxrate 4M -g 250 -coder 0 -flags +loop -cmp +chroma -partitions +parti4x4+partp8x8+partb8x8 -flags2 +mixed_refs -me_method umh -subq 6 -trellis 1 -refs 3 -me_range 16 -keyint_min 25 -sc_threshold 40 -i_qfactor 0.71 -qmin 10 -qmax 51 -qdiff 4 -threads 0 -acodec libfaac -ac 2 -ab 128k #{PathUtils.escape(outputFile)}"
        exec.doCmd(cmd)
    end
end