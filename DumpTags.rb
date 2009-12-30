require "TagHandler"

ARGV.each do |f|
    th = TagHandler.handlerFor(f)
    puts "File: #{f}"
    if !th
        puts "No handler for #{f}"
        next
    end
    puts "  Artist: #{th.artist}"
    puts "  Genre: #{th.genre}"
    puts "  Album: #{th.album}"
    puts "  Title: #{th.title}"
    puts "  Track: #{th.tracknumber}"
end
