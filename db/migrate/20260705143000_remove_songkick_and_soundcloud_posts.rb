class RemoveSongkickAndSoundcloudPosts < ActiveRecord::Migration[7.0]
  SOURCES_TO_REMOVE = ['Songkick', 'SoundCloud'].freeze

  def up
    post_scope = Post.where(source: SOURCES_TO_REMOVE)
    post_ids = post_scope.pluck(:id)
    return if post_ids.empty?

    Content.where(post_id: post_ids).delete_all
    Notification.where(post_id: post_ids).delete_all
    Post.where(id: post_ids).delete_all
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'Removed SoundCloud/Songkick posts cannot be restored automatically.'
  end

  class Post < ActiveRecord::Base
    self.table_name = 'posts'
  end

  class Content < ActiveRecord::Base
    self.table_name = 'contents'
  end

  class Notification < ActiveRecord::Base
    self.table_name = 'notifications'
  end
end
