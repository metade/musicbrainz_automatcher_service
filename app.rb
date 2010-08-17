require 'rubygems'
require 'sinatra'
require 'sinatra/respond_to'
require 'builder'

require 'musicbrainz_automatcher'
require 'erb'
require 'open-uri'

Sinatra::Application.register Sinatra::RespondTo


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
  twitter = twitter_data(links) || {}
  facebook = facebook_data(links) || {}
  { :gid => gid,
    :name => artist.name,
    :twitter => twitter[:username],
    :twitter_followers => twitter[:followers],
    :facebook => facebook[:page],
    :facebook_fans => facebook[:fans]
  }
end

get '/' do
  erb :index
end

get '/artists/automatch' do |format|
  artists = params.keys.
              select { |k| k =~ /artist\d*/ }.sort.
              map { |k| params[k] }
  artists.delete_if { |a| a.blank? }
  track = params['track']
  
  gid = AUTOMATCHER.match_artist(artists, track)
  raise Sinatra::NotFound.new('Unable to match artist') unless gid
  @data = artist_data(gid)
  respond_to do |wants|
    wants.xml { builder :artists_automatch }
    wants.json { @data.to_json }
  end
end
