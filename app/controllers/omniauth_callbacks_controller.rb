# frozen_string_literal: true
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
    @user = User.from_omniauth(request.env["omniauth.auth"])

    unless @user.persisted?
      @user.save!
    end

    follow_seed_artists(@user)
    enqueue_spotify_import(@user, request.env['omniauth.auth'])

    flash[:notice] = 'Spotify import started. Your followed artists will continue syncing in the background.'

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

  def enqueue_spotify_import(user, auth)
    SpotifyFollowedArtistsImportJob.perform_later(user.id, auth.to_h)
  end
end
