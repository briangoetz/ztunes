require "PathUtils"
require "DropHandler"
require "Transcoders"

BASE = "."

# Drop folder(s)
DROP = "#{BASE}/drop"

# Media folders
AUDIO = "#{BASE}/music"
VIDEO = "#{BASE}/video"

# View folders
MP3 = "#{BASE}/mp3"
IPOD = "#{BASE}/ipod"
SQUEEZEBOX = "#{BASE}/squeezebox"

# The staging directory is a temporary folder for use by zTunes
STAGE = "#{BASE}/stage"

# How long to wait after a files last modification time to declare it "dropped"
THRESHOLD = 120

# How many threads to create; this should equal how many cores you have
MAX_THREADS = 4

DROP_FOLDERS = {
        DROP => {
                "wav"  => { :handler => WavToFlacDropHandler.new,  :toDir => AUDIO },
                "mp3"  => { :handler => SimpleDropHandler.new("mp3"),  :toDir => AUDIO },
                "wma"  => { :handler => WmaDropHandler.new,  :toDir => AUDIO },
                "flac" => { :handler => SimpleDropHandler.new("flac"), :toDir => AUDIO },
                "m4a"  => { :handler => SimpleDropHandler.new("m4a"),  :toDir => AUDIO }
        }
}

VIEW_FOLDERS = {
        MP3 => { :target => :mp3,
                 :fromDirs => [ AUDIO ],
                 :supportedTypes => [ "mp3" ],
                 :transcode => { "flac" => FlacToMp3.new,
                                 "wma" => WmaToMp3.new,
                                 "m4a" => M4aToMp3.new }
        },
        IPOD => { :target => :ipod,
                  :fromDirs => [ AUDIO, MP3 ],
                  :supportedTypes => [ "m4a", "mp3" ],
                  :transcode => { "mp4" => Mp4ForIpod.new }
        },
        SQUEEZEBOX => { :target => :squeezebox,
                        :fromDirs => [ AUDIO, MP3 ],
                        :supportedTypes => [ "flac", "wma", "mp3" ]
        }
}

ADDITIONAL_SOURCES = [ "/home/media/music" ]

