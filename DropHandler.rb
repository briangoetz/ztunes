class DropHandler
    attr_reader :fileType
    @THRESHOLD = 120

    def handles?(file)
        file =~ /#{fileType}$/
    end

    def handle(file, stagingDir, threadPool) 
        age = Time.now - File.stat(file).mtime
        if (age < $THRESHOLD)
            # rename to staging
            # enqueue doHandle(f)
        end
    end

    # protected doHandle
end

class WavDropHandler < DropHandler
    def initialize
        @fileType = "wav"
    end

    def doHandle(file) 
    end
end
