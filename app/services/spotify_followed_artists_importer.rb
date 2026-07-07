# frozen_string_literal: true

class SpotifyFollowedArtistsImporter
  DEFAULT_LIMIT = 50

  def initialize(user:, spotify_client:)
    @user = user
    @spotify_client = spotify_client
  end

  def import_page(after: nil, limit: DEFAULT_LIMIT)
    artists_processed = 0
    artists_followed = 0

    batch = spotify_followed_artists(after: after, limit: limit)
    items = batch.fetch(:items, [])
    return { artists_processed: 0, artists_followed: 0, fetched: 0, next_after: nil } if items.blank?

    items.each do |artist|
      artist_id = artist['id']
      next if artist_id.blank?

      artist_record = Artist.find_or_initialize_by(spotify_id: artist_id)

      if artist_record.new_record?
        artists_processed += 1
        artist_record.name = artist['name']
        artist_record.followers = artist.dig('followers', 'total')
        artist_record.save!

        image_url = Array(artist['images']).last&.[]('url')
        SpotifyArtistEnrichmentJob.perform_later(artist_record.id, image_url)
      end

      user_artist = UserArtist.find_or_create_by!(artist: artist_record, user: @user)
      if user_artist.status != 'follow'
        user_artist.update!(status: 'follow')
      end
      artists_followed += 1
    rescue StandardError => e
      Rails.logger.warn("Spotify import skipped artist #{artist_id}: #{e.class} #{e.message}")
    end

    {
      artists_processed: artists_processed,
      artists_followed: artists_followed,
      fetched: items.size,
      next_after: cursor_after_for(batch)
    }
  end

  private

  def spotify_followed_artists(after:, limit:)
    @spotify_client.followed_artists(after: after, limit: limit)
  end

  def cursor_after_for(batch)
    batch.fetch(:cursors, {})['after']
  end
end
