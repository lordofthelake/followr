class TwitterUnfollowWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence do
    daily.hour_of_day(0, 6, 7, 8, 22, 23)
  end

  def perform
    unless ENV['WORKERS_DRY_RUN'].blank?
      puts 'TwitterUnfollowWorker run but returning due to WORKERS_DRY_RUN env variable'
      return
    end

    User.wants_twitter_unfollow.find_each do |user|
      follow_prefs = user.twitter_follow_preference
      unfollow_days = follow_prefs.unfollow_after
      users_to_unfollow = user.twitter_follows
                              .where('followed_at <= ? AND UNFOLLOWED IS NOT TRUE', unfollow_days.to_i.days.ago)

      client = begin
                  user.credential.twitter_client
                rescue
                  nil
                end
      client_muted_ids =
        begin
          client.muted_ids.to_a
        rescue
          []
        end

      next if client.nil? || users_to_unfollow.empty?
      next unless user.can_twitter_unfollow?

      follower_ids = client.follower_ids.to_a
      user.twitter_follows.where(twitter_user_id: follower_ids).update_all(was_following: true)

      users_to_unfollow.each do |followed_user|
        begin
          twitter_user_id = followed_user.twitter_user_id.to_i

          # don't unfollow people who the user has manually unmuted
          next unless client_muted_ids.include?(twitter_user_id)

          if client.unfollow(twitter_user_id)
            followed_user.update_attributes(unfollowed: true, unfollowed_at: DateTime.now)
            client.unmute(twitter_user_id)
            client.friendship_update(twitter_user_id, wants_retweets: true)
          end
        rescue Twitter::Error::NotFound
          followed_user.update_attributes(unfollowed: true, unfollowed_at: DateTime.now)
        end
      end
    end
  end
end
