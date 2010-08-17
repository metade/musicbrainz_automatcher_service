xml.instruct!
xml.artist do |artist|
  artist.gid @data[:gid]
  artist.name @data[:name]
  artist.link "http://www.bbc.co.uk/music/artists/#{@data[:gid]}"
  artist.facebook @data[:facebook]
  artist.facebook_fans @data[:facebook_fans]
  artist.twitter @data[:twitter]
  artist.twitter_followers @data[:twitter_followers]
end
