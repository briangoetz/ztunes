require "rubygems"
require "calibre/semaphore"
require "rake"

#
# Encapsulate conditional execution, printing to console, and thread management
#
class ZTunesExec
    attr_accessor :dryRun

    def initialize(maxThreads)
        @dryRun = false
        @counter = 0
        @semaphore = Semaphore.new maxThreads
        @pendingThreads = [ 0 ]
        @pendingThreads.extend(MonitorMixin)
        @condition = @pendingThreads.new_cond
    end

    def doFileCmd(cmd, *args)
        begin
            args.each { |s| s = PathUtils.escape(s) };
            if (@dryRun)
                puts "#{cmd} #{args.join(' ')}"
            else
                self.send cmd, *args if !@dryRun
            end
        rescue
            puts "Exception: " + $!
            puts "  executing #{cmd} #{args.join(' ')}"
        end
    end

    def doCmd(cmd)
        begin
            puts "#{cmd}"
            if !@dryRun
                Kernel.system cmd
                $?
            else
                0
            end
        rescue
            puts "...execution error: " + $!
            $?
        end
    end

    def tempFile(f)
        @pendingThreads.synchronize do
            @counter += 1
            File.join(STAGE, "#{f.pathmap("%f")}-#{$$}-#{@counter}")
        end
    end

    def defer(&proc)
        begin
            @pendingThreads.synchronize do
                @pendingThreads[0] += 1
                Thread.new(self) do |exec|
                    begin
                        @semaphore.wait
                        proc.call(exec)
                    ensure
                        @semaphore.signal
                        @pendingThreads.synchronize do
                            @pendingThreads[0] -= 1
                            @condition.signal
                        end
                    end
                end
            end
        end
    end

    def join
        @pendingThreads.synchronize do
            @condition.wait_while { @pendingThreads[0] > 0 }
        end
    end
end

