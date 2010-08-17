require 'rubygems'
require 'sinatra'
require 'musicbrainz_automatcher'
require 'erb'
require 'open-uri'

AUTOMATCHER = MusicbrainzAutomatcher.new

def twitter_data(links)
  twitter = links.map { |u| $1 if u =~ %r[twitter\.com/(\w+)] }.compact.first
  if twitter
    url = "http://api.twitter.com/1/users/show.json?screen_name=#{twitter}"
    data = JSON.parse(open(url).read)
    { :username => twitter,
      :followers => data['followers_count']
    }
  end
end

def facebook_data(links)
  facebook = links.map { |u| $1 if u =~ %r[facebook\.com/(\w+)$] }.compact.first
  if facebook
    url = "http://graph.facebook.com/#{facebook}"
    data = JSON.parse(open(url).read)
    { :page => facebook,
      :fans => data['fan_count']
    }
  end
end

def artist_data(gid)
  query = MusicBrainz::Webservice::Query.new
  artist = query.get_artist_by_id(gid, :url_rels => true)
  links = artist.get_relations.map { |u| u.target }
  { :gid => gid,
    :name => artist.name,
    :links => links,
    :twitter => twitter_data(links),
    :facebook => facebook_data(links),
  }
end

get '/' do
  erb :index
end

get '/artists/automatch.:format' do |format|
  artists = params.keys.
              select { |k| k =~ /artist\d*/ }.sort.
              map { |k| params[k] }
  artists.delete_if { |a| a.blank? }
  track = params['track']
  
  gid = AUTOMATCHER.match_artist(artists, track)
  raise Sinatra::NotFound.new('Unable to match artist') unless gid
  
  artist_data(gid).to_json
end
