class TranscodeHandler < FileHandler
end

class FlacToMp3 < TranscodeHandler
    def initialize(opts = {})
        super({ "flac" => "mp3" }, true)
    end
end

class WmaToMp3 < TranscodeHandler
    def initialize(opts = {})
        super({ "wma" => "mp3" }, true)
    end
end

class M4aToMp3 < TranscodeHandler
    def initialize(opts = {})
        super({ "m4a" => "mp3" }, true)
    end
end

class Mp4ForIpod < TranscodeHandler
    def initialize(opts = {})
        super({ "mp4" => "mp4" }, true)
    end

end