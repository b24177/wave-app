class ArtistsController < ApplicationController

  def index
    @artists = current_user.artists.select do |artist|
      UserArtist.where(artist_id: artist.id).first.status == 'follow'
    end
  end

  def show
    @artist = Artist.find(params[:id])
    @posts = Post.where(artist: @artist)
  end

  def follow
    @artist = Artist.find(params[:id])
    if current_user.follow(@artist.id)
      respond_to do |format|
        format.html { redirect_to artists_path }
        format.js
      end
    end
  end

  def unfollow
    @artist = Artist.find(params[:id])
    if current_user.unfollow(@artist.id)
      respond_to do |format|
        format.html { redirect_to artists_path }
        format.js { render action: :follow }
      end
    end
  end

  def discover
    last_user_artist = current_user.user_artists.last
    unless last_user_artist&.artist&.spotify_id.present?
      redirect_to artists_path, alert: "Follow at least one artist before using Discover."
      return
    end

    related_artists = RSpotify::Artist.find(last_user_artist.artist.spotify_id).related_artists
    @artists = related_artists.map do |artist|
      existing_artist = Artist.find_by(spotify_id: artist.id)
      next existing_artist if existing_artist.present?

      related_artist = Artist.create!(
        name: artist.name,
        spotify_id: artist.id,
        followers: artist.followers["total"]
      )

      image_url = artist.images&.last&.[]("url")
      if image_url.present?
        related_artist.photo.attach(io: URI.open(image_url), filename: "avatar", content_type: "image/jpg")
      end

      related_artist
    end
  rescue StandardError => e
    Rails.logger.warn("Artists#discover failed: #{e.class} #{e.message}")
    redirect_to artists_path, alert: "Discover is temporarily unavailable."
  end
end
