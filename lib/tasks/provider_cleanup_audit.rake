namespace :data_cleanup do
  desc 'Audit (and optionally clean) legacy Songkick/SoundCloud rows with before/after counts'
  task legacy_provider_audit: :environment do
    sources = ['Songkick', 'SoundCloud']
    apply_cleanup = ENV['APPLY'] == '1'

    before_post_scope = Post.where(source: sources)
    before_post_ids = before_post_scope.pluck(:id)

    before_posts = before_post_ids.size
    before_contents = Content.where(post_id: before_post_ids).count
    before_notifications = Notification.where(post_id: before_post_ids).count

    if apply_cleanup && before_post_ids.any?
      Content.where(post_id: before_post_ids).delete_all
      Notification.where(post_id: before_post_ids).delete_all
      Post.where(id: before_post_ids).delete_all
    end

    after_post_scope = Post.where(source: sources)
    after_post_ids = after_post_scope.pluck(:id)

    after_posts = after_post_ids.size
    after_contents = Content.where(post_id: after_post_ids).count
    after_notifications = Notification.where(post_id: after_post_ids).count

    puts 'Legacy Provider Cleanup Audit'
    puts "Sources: #{sources.join(', ')}"
    puts "Apply cleanup: #{apply_cleanup}"
    puts
    puts "Before posts: #{before_posts}"
    puts "Before contents: #{before_contents}"
    puts "Before notifications: #{before_notifications}"
    puts
    puts "After posts: #{after_posts}"
    puts "After contents: #{after_contents}"
    puts "After notifications: #{after_notifications}"
    puts
    puts "Removed posts: #{before_posts - after_posts}"
    puts "Removed contents: #{before_contents - after_contents}"
    puts "Removed notifications: #{before_notifications - after_notifications}"
  end
end
