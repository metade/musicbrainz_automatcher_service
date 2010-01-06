require 'rubygems'
require 'sinatra'
require 'musicbrainz_automatcher'
require 'erb'

AUTOMATCHER = MusicbrainzAutomatcher.new

get '/' do
  erb :index
end

get '/artists/automatch' do
  artists = params.keys.
              select { |k| k =~ /artist\d*/ }.sort.
              map { |k| params[k] }
  artists.delete_if { |a| a.blank? }
  track = params['track']
  
  match = AUTOMATCHER.match_artist(artists, track)
  raise Sinatra::NotFound.new('Unable to match artist') unless match
  match
end
