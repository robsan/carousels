# Carousels v0.0.1
# "Simple, Ruby-powered radio automation software"
# Mattt Thompson, 2008

require 'rubygems'

gem 'twitter'
gem 'ruby-mp3info'
gem 'activesupport'

['mp3info', 'twitter', 'activesupport', 'pp'].each{|lib| require lib}
Dir.chdir(File.join(File.expand_path(File.dirname(__FILE__))))

MPG321 = "/opt/local/bin/mpg321"
Leeway = 3.minutes

def setup
  @genres  = Dir.entries('genres').reject{|e| e =~ /\./ }
  t = (Time.now + 1.hour);
  @available_time = (Time.now - Time.utc(2008, t.month, t.day, t.hour)) + Leeway
  @id = Dir["ids/*.{mp3}"]
  @twitter = Twitter::Base.new('your email', 'your password')
  @queue   = []
end

setup and loop do  
  @genres.sort_by{rand}.each do |genre|
    genre = "Silence" # Testing purposes
    stock = Dir["genres/#{genre}/*.{mp3}"].index_by{|song| Mp3Info.open(song).length.seconds}
    while @available_time > Leeway
      stock.delete_if{|duration, song| duration > @available_time}
      song = stock.delete(duration = stock.keys.rand)
      break if song.nil?
      @queue << song
      @available_time -= duration
    end

    while(system("%s %s" % [MPG321, "\"#{song = @queue.shift}\""]) && ! @queue.empty?)
      Mp3Info.open(song) do |track|
        title, artist, album = track.tag.title || song.basename, track.tag.artist, track.tag.album
        message = "\"#{title}\""
        message << " - #{artist}" if artist
        message << " (#{album})"  if album
        pp message
        # @twitter.update(message)
      end
    end
    
    system("%s %s" % [MPG321, "\"#{@id}\""])
    pp "88.3 WRCT Station Identification"
    
    setup
  end
end