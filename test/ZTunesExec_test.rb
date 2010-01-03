require "test/unit"
require "ZTunesExec"

class ZTunesExec_test < Test::Unit::TestCase
    def setup
        @strings = []
        @exec = ZTunesExec.new 2
    end

    def teardown
    end

    def test_preview
        @exec.dryRun = true
    end
end