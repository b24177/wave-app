class PostsController < ApplicationController
  SUPPORTED_SOURCES = ['Youtube', 'Facebook', 'Twitter', 'Instagram', 'Ticketmaster'].freeze

  def index
    @posts = Post.where(artist_id: followed_artist_ids)
                 .where(source: SUPPORTED_SOURCES)
                 .order(created_at: 'desc')
    current_user.notifications.unread.update_all(read_at: Time.now)
    # User.first.notifications.update_all(read_at: nil)
  end

  def show
    @post = Post.find(params[:id])
  end

  private

  def followed_artist_ids
    current_user.user_artists.where(status: 'follow').select(:artist_id)
  end
end
