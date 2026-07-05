# frozen_string_literal: true

require 'open-uri'
require 'nokogiri'

class SpotifyArtistEnrichmentService
  def initialize(artist:, image_url: nil)
    @artist = artist
    @image_url = image_url
  end

  def call
    attached_image = attach_artist_image
    youtube_created = create_youtube_post
    ticketmaster_created = create_ticketmaster_post

    {
      attached_image: attached_image,
      youtube_created: youtube_created,
      ticketmaster_created: ticketmaster_created
    }
  end

  private

  def attach_artist_image
    return false if @image_url.blank? || @artist.photo.attached?

    @artist.photo.attach(io: URI.open(@image_url), filename: 'avatar', content_type: 'image/jpeg')
    true
  rescue StandardError => e
    Rails.logger.warn("Spotify artist image attach failed for #{@artist.spotify_id}: #{e.class} #{e.message}")
    false
  end

  def create_youtube_post
    return false if Post.exists?(artist: @artist, source: 'Youtube')

    youtube_embed = youtube_url(@artist.name)
    return false if youtube_embed.blank?

    post = Post.create!(artist: @artist, source: 'Youtube')
    post.contents.create!(format: 'video', data: youtube_embed)
    true
  rescue StandardError => e
    Rails.logger.warn("YouTube enrichment failed for #{@artist.name}: #{e.class} #{e.message}")
    false
  end

  def create_ticketmaster_post
    return false if Post.exists?(artist: @artist, source: 'Ticketmaster')

    ticketmaster_event = ticketmaster_concert(@artist.name)
    return false if ticketmaster_event.blank?

    post = Post.create!(artist: @artist, source: 'Ticketmaster')
    post.contents.create!(format: 'event_name', data: ticketmaster_event[:name]) if ticketmaster_event[:name].present?
    post.contents.create!(format: 'starts_at', data: ticketmaster_event[:starts_at]) if ticketmaster_event[:starts_at].present?
    post.contents.create!(format: 'venue', data: ticketmaster_event[:venue]) if ticketmaster_event[:venue].present?
    post.contents.create!(format: 'city', data: ticketmaster_event[:city]) if ticketmaster_event[:city].present?
    post.contents.create!(format: 'ticket_url', data: ticketmaster_event[:ticket_url]) if ticketmaster_event[:ticket_url].present?
    post.contents.create!(format: 'image_url', data: ticketmaster_event[:image_url]) if ticketmaster_event[:image_url].present?
    true
  rescue StandardError => e
    Rails.logger.warn("Ticketmaster enrichment failed for #{@artist.name}: #{e.class} #{e.message}")
    false
  end

  def youtube_url(query)
    artist = MusicBrainz::Artist.find_by_name(query)
    return if artist.nil?

    url = Array(artist.urls[:youtube]).compact.find { |entry| entry.include?('/channel/') }
    return if url.nil?

    channel = Yt::Channel.new(id: url.split('/').last)
    video = channel.videos.first
    return if video.nil?

    iframe = Nokogiri::HTML(video.embed_html).xpath('//iframe').first
    iframe&.[]('src')&.split('//')&.last
  end

  def ticketmaster_concert(query)
    return unless TicketmasterConfig.configured?

    @ticketmaster_client ||= TicketmasterClient.new
    @ticketmaster_client.first_music_event_for(query)
  end
end
