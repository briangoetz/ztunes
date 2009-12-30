require "MediaFile"

ARGV.each do |f|
    th = MediaFile.handlerFor(f)
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
