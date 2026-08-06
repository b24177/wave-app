# frozen_string_literal: true
class OmniauthCallbacksController < Devise::OmniauthCallbacksController
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
    auth = request.env['omniauth.auth']
    @user = User.from_omniauth(auth)

    unless @user.persisted?
      @user.save!
    end

    follow_seed_artists(@user)
    import_state = bootstrap_spotify_import(@user, auth)

    flash[:notice] = spotify_import_notice(import_state)

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

  def bootstrap_spotify_import(user, auth)
    auth_hash = auth.to_h
    import_state = { imported_now: false, queued: false }

    summary = import_first_spotify_page(user, auth_hash)
    import_state[:imported_now] = summary.present?

    next_after = summary&.fetch(:next_after, nil)
    if next_after.present?
      import_state[:queued] = enqueue_spotify_import(user, auth_hash, next_after)
    elsif summary.nil?
      import_state[:queued] = enqueue_spotify_import(user, auth_hash)
    end

    import_state
  rescue StandardError => e
    Rails.logger.warn("Spotify login import bootstrap failed for user #{user.id}: #{e.class} #{e.message}")
    { imported_now: false, queued: enqueue_spotify_import(user, auth.to_h) }
  end

  def import_first_spotify_page(user, auth_hash)
    access_token = extract_access_token(auth_hash)
    return nil if access_token.blank?

    spotify_client = SpotifyClient.new(user_access_token: access_token)
    SpotifyFollowedArtistsImporter.new(user: user, spotify_client: spotify_client).import_page
  rescue StandardError => e
    Rails.logger.warn("Spotify immediate import failed for user #{user.id}: #{e.class} #{e.message}")
    nil
  end

  def enqueue_spotify_import(user, auth_hash, after = nil)
    SpotifyFollowedArtistsImportJob.perform_later(user.id, auth_hash, after)
    true
  rescue StandardError => e
    Rails.logger.warn("Spotify background enqueue failed for user #{user.id}: #{e.class} #{e.message}")
    false
  end

  def extract_access_token(auth_hash)
    auth_hash&.dig('credentials', 'token') || auth_hash&.dig(:credentials, :token)
  end

  def spotify_import_notice(import_state)
    imported_now = import_state.fetch(:imported_now, false)
    queued = import_state.fetch(:queued, false)

    if imported_now && queued
      'Imported your first Spotify artists. We will keep syncing the rest in the background.'
    elsif imported_now
      'Imported your Spotify artists now. Background sync is currently unavailable, but your artists are ready.'
    elsif queued
      'Spotify import started. Your followed artists will continue syncing in the background.'
    else
      'We could not start Spotify import right now. Please try reconnecting Spotify in a moment.'
    end
  end
end
