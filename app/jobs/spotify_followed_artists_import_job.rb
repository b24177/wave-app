# frozen_string_literal: true

class SpotifyFollowedArtistsImportJob < ApplicationJob
  queue_as :spotify_import

  def perform(user_id, auth_hash, after = nil)
    user = User.find_by(id: user_id)
    return if user.nil?

    auth = begin
      OmniAuth::AuthHash.new(auth_hash)
    rescue StandardError
      auth_hash
    end

    spotify_user = RSpotify::User.new(auth)
    summary = SpotifyFollowedArtistsImporter.new(user: user, spotify_user: spotify_user).import_page(after: after)

    if summary[:next_after].present?
      self.class.perform_later(user.id, auth_hash, summary[:next_after])
    end

    Rails.logger.info("Spotify import summary for user #{user.id}: #{summary}")
  rescue StandardError => e
    Rails.logger.warn("Spotify background import failed for user #{user_id}: #{e.class} #{e.message}")
  end
end
