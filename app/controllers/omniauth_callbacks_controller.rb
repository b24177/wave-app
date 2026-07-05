# frozen_string_literal: true
require 'open-uri'
require 'nokogiri'

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

    unless @user.persisted?
      @user.save!
    end

    import_summary = get_followed_artists(spotify_user)
    follow_seed_artists(@user)

    if ENV['TICKETMASTER_DEBUG_MATCHING'] == '1'
      flash[:tm_summary] = "Ticketmaster matched #{import_summary[:ticketmaster_matched]}/#{import_summary[:artists_processed]} imported artists"
    end

    sign_in_and_redirect @user, event: :authentication #this will throw if @user is not activated

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
    artists_processed = 0
    ticketmaster_matched = 0

    if @user.artists.empty?
      user.following(type: 'artist', limit: 10).each do |artist|
        artist_record = Artist.find_or_initialize_by(spotify_id: artist.id)

        if artist_record.new_record?
          artists_processed += 1
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

          ticketmaster_event = ticketmaster_concert(artist_record.name)
          if ticketmaster_event.present?
            ticketmaster_matched += 1
            post = Post.create!(artist: artist_record, source: 'Ticketmaster')
            post.contents.create!(format: 'event_name', data: ticketmaster_event[:name]) if ticketmaster_event[:name].present?
            post.contents.create!(format: 'starts_at', data: ticketmaster_event[:starts_at]) if ticketmaster_event[:starts_at].present?
            post.contents.create!(format: 'venue', data: ticketmaster_event[:venue]) if ticketmaster_event[:venue].present?
            post.contents.create!(format: 'city', data: ticketmaster_event[:city]) if ticketmaster_event[:city].present?
            post.contents.create!(format: 'ticket_url', data: ticketmaster_event[:ticket_url]) if ticketmaster_event[:ticket_url].present?
            post.contents.create!(format: 'image_url', data: ticketmaster_event[:image_url]) if ticketmaster_event[:image_url].present?
          end
        end

        UserArtist.find_or_create_by!(artist: artist_record, user: @user) { |ua| ua.status = 'follow' }
      rescue StandardError => e
        Rails.logger.warn("Spotify import skipped artist #{artist.id}: #{e.class} #{e.message}")
      end
    end

    { artists_processed: artists_processed, ticketmaster_matched: ticketmaster_matched }
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

  def ticketmaster_concert(query)
    return unless TicketmasterConfig.configured?

    @ticketmaster_client ||= TicketmasterClient.new
    @ticketmaster_client.first_music_event_for(query)
  rescue StandardError => e
    Rails.logger.warn("Ticketmaster enrichment failed for #{query}: #{e.class} #{e.message}")
    nil
  end
end
