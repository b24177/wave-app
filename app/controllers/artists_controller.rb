class ArtistsController < ApplicationController
  PER_PAGE = 24
  SUPPORTED_SOURCES = ['Youtube', 'Facebook', 'Twitter', 'Instagram', 'Ticketmaster'].freeze

  def index
    @query = params[:query].to_s.strip
    @current_page = [params.fetch(:page, 1).to_i, 1].max

    followed_artists = Artist.joins(:user_artists)
                            .where(user_artists: { user_id: current_user.id, status: 'follow' })
                            .distinct
                            .order(:name)

    if @query.present?
      followed_artists = followed_artists.where('artists.name ILIKE ?', "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%")
    end

    total_count = followed_artists.count(:id)
    @total_pages = [((total_count.to_f) / PER_PAGE).ceil, 1].max

    @artists = followed_artists.limit(PER_PAGE).offset((@current_page - 1) * PER_PAGE)
    @has_previous_page = @current_page > 1
    @has_next_page = @current_page < @total_pages
  end

  def show
    @artist = Artist.find(params[:id])
    @posts = Post.where(artist: @artist, source: SUPPORTED_SOURCES)
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

    related_artists = SpotifyClient.new.related_artists(last_user_artist.artist.spotify_id)
    @artists = related_artists.map do |artist|
      existing_artist = Artist.find_by(spotify_id: artist['id'])
      next existing_artist if existing_artist.present?

      related_artist = Artist.create!(
        name: artist['name'],
        spotify_id: artist['id'],
        followers: artist.dig('followers', 'total')
      )

      image_url = Array(artist['images']).last&.[]('url')
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
