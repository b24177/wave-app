# frozen_string_literal: true

class SpotifyArtistEnrichmentJob < ApplicationJob
  queue_as :spotify_enrichment

  def perform(artist_id, image_url = nil)
    artist = Artist.find_by(id: artist_id)
    return if artist.nil?

    summary = SpotifyArtistEnrichmentService.new(artist: artist, image_url: image_url).call
    Rails.logger.info("Spotify enrichment summary for artist #{artist.id}: #{summary}")
  rescue StandardError => e
    Rails.logger.warn("Spotify enrichment failed for artist #{artist_id}: #{e.class} #{e.message}")
  end
end
