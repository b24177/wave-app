# frozen_string_literal: true
require 'open-uri'
require 'nokogiri'

begin
  require 'soundcloud'
rescue LoadError
  # SoundCloud support is optional for local development.
end

class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token
  # You should configure your model like this:
  # devise :omniauthable, omniauth_providers: [:twitter]

  # You should also create an action method in this controller like this:
  # def twitter
  # end

  # More info at:
  # https://github.com/heartcombo/devise#omniauth

  # GET|POST /resource/auth/twitter
  # def passthru
  #   super
  # end

  # GET|POST /users/auth/twitter/callback
  # def failure
  #   super
  # end

  # protected

  # The path used when OmniAuth fails
  # def after_omniauth_failure_path_for(scope)
  #   super(scope)
  # end

  def spotify
    spotify_user = RSpotify::User.new(request.env['omniauth.auth'])
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication #this will throw if @user is not activated
      #set_flash_message(:notice, :success, kind: "Spotify") if is_navigational_format?
    else
      @user.save!
      # session["devise.spotify_data"] = request.env["omniauth.auth"].except(:extra) # Removing extra as it can overflow some session stores
      # redirect_to new_user_registration_url
    end
    get_followed_artists(spotify_user)
    follow_seed_artists(@user)

  end

  def failure
    redirect_to root_path
  end

  private

  def follow_seed_artists(user)
    Artist.first(3).each do |artist|
      unless user.user_artists.exists?(artist_id: artist.id)
        UserArtist.create!(artist_id: artist.id, user: user, status: 'follow')
      end
    end
  end

  def get_followed_artists(user)
    if @user.artists.empty?
      user.following(type: 'artist', limit: 10).each do |artist|
        artist_record = Artist.find_or_initialize_by(spotify_id: artist.id)

        if artist_record.new_record?
          artist_record.name = artist.name
          artist_record.followers = artist.followers['total']
          artist_record.save!

          image_url = artist.images&.last&.[]('url')
          if image_url.present?
            begin
              artist_record.photo.attach(io: URI.open(image_url), filename: 'avatar', content_type: 'image/jpeg')
            rescue StandardError => e
              Rails.logger.warn("Spotify artist image attach failed for #{artist.id}: #{e.class} #{e.message}")
            end
          end

          youtube_embed = youtube_url(artist_record.name)
          if youtube_embed.present?
            post = Post.create!(artist: artist_record, source: 'Youtube')
            post.contents.create!(format: 'video', data: youtube_embed)
          end

          soundcloud_track = soundcloud_track_id(artist_record.name)
          if soundcloud_track.present?
            post = Post.create!(artist: artist_record, source: 'SoundCloud')
            post.contents.create!(format: 'audio', data: soundcloud_track)
          end
        end

        UserArtist.find_or_create_by!(artist: artist_record, user: @user) { |ua| ua.status = 'follow' }
      rescue StandardError => e
        Rails.logger.warn("Spotify import skipped artist #{artist.id}: #{e.class} #{e.message}")
      end
    end
  end

  def youtube_url(query)
    a = MusicBrainz::Artist.find_by_name(query)
    return if a.nil?

    url = Array(a.urls[:youtube]).compact.find { |u| u.include?('/channel/') }
    return if url.nil?

    channel = Yt::Channel.new(id: url.split('/').last)
    video = channel.videos.first
    return if video.nil?

    iframe = Nokogiri::HTML(video.embed_html).xpath('//iframe').first
    iframe&.[]('src')&.split('//')&.last
  rescue StandardError => e
    Rails.logger.warn("YouTube enrichment failed for #{query}: #{e.class} #{e.message}")
    nil
  end

  def soundcloud_track_id(query)
    return unless defined?(SoundCloud)

    a = MusicBrainz::Artist.find_by_name(query)
    return if a.nil?

    url = Array(a.urls[:soundcloud]).compact.first
    return if url.nil?

    client = SoundCloud.new(client_id: ENV['SC_CLIENT_ID'])
    tracks = if url.include?('/tracks')
               client.get('/resolve', url: url)
             else
               client.get('/resolve', url: "#{url}/tracks")
             end

    return if tracks.empty?

    tracks.first.uri.split('/').last
  rescue StandardError => e
    Rails.logger.warn("SoundCloud enrichment failed for #{query}: #{e.class} #{e.message}")
    nil
  end
end
