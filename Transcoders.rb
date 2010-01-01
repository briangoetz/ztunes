class TranscodeHandler < FileHandler
    def initialize(typeMap)
        super(typeMap, true)
    end

    def handle(exec, inputFile, outputFile)
        tmpFile = inputFile + "_"
        # TODO support threading
        success = transform(exec, inputFile, tmpFile)
        if (success)
            exec.doFileCmd(:mv, tmpFile, outputFile)
        else
            exec.doFileCmd(:rm, tmpFile) if File.exist?(tmpFile)
        end
        success
    end
end

class FlacToMp3 < TranscodeHandler
    def initialize(opts = {})
        super({ "flac" => "mp3" })
    end

    def transform(exec, inputFile, outputFile)
        cmd = ""
        exec.doCmd(cmd)
    end
end

class WmaToMp3 < TranscodeHandler
    def initialize(opts = {})
        super({ "wma" => "mp3" })
    end

    def transform(exec, inputFile, outputFile)
        cmd = ""
        exec.doCmd(cmd)
    end
end

class M4aToMp3 < TranscodeHandler
    def initialize(opts = {})
        super({ "m4a" => "mp3" })
    end

    def transform(exec, inputFile, outputFile)
        cmd = ""
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