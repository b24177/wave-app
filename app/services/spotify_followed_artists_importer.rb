# frozen_string_literal: true

class SpotifyFollowedArtistsImporter
  DEFAULT_LIMIT = 50

  def initialize(user:, spotify_user:)
    @user = user
    @spotify_user = spotify_user
  end

  def import_page(after: nil, limit: DEFAULT_LIMIT)
    artists_processed = 0
    artists_followed = 0

    batch = spotify_followed_artists(after: after, limit: limit)
    return { artists_processed: 0, artists_followed: 0, fetched: 0, next_after: nil } if batch.blank?

    batch.each do |artist|
      artist_record = Artist.find_or_initialize_by(spotify_id: artist.id)

      if artist_record.new_record?
        artists_processed += 1
        artist_record.name = artist.name
        artist_record.followers = artist.followers['total']
        artist_record.save!

        image_url = artist.images&.last&.[]('url')
        SpotifyArtistEnrichmentJob.perform_later(artist_record.id, image_url)
      end

      user_artist = UserArtist.find_or_create_by!(artist: artist_record, user: @user)
      if user_artist.status != 'follow'
        user_artist.update!(status: 'follow')
      end
      artists_followed += 1
    rescue StandardError => e
      Rails.logger.warn("Spotify import skipped artist #{artist.id}: #{e.class} #{e.message}")
    end

    {
      artists_processed: artists_processed,
      artists_followed: artists_followed,
      fetched: batch.size,
      next_after: cursor_after_for(batch)
    }
  end

  private

  def spotify_followed_artists(after:, limit:)
    options = { type: 'artist', limit: limit }
    options[:after] = after if after.present?
    @spotify_user.following(**options)
  end

  def cursor_after_for(batch)
    return nil unless batch.respond_to?(:cursors)

    batch.cursors&.[]('after')
  end
end
