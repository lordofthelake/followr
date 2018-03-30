class TwitterUnfollowWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence {
    daily.hour_of_day(0, 6, 7, 8, 22, 23)
   }

  def perform
    unless ENV['WORKERS_DRY_RUN'].blank?
      puts "TwitterUnfollowWorker run but returning due to WORKERS_DRY_RUN env variable"
      return
    end

    User.wants_twitter_unfollow.find_in_batches do |group|
      group.each do |user|
        follow_prefs = user.twitter_follow_preference
        unfollow_days = follow_prefs.unfollow_after
        users_to_unfollow = user.twitter_follows.where('followed_at <= ? AND UNFOLLOWED IS NOT TRUE', unfollow_days.to_i.days.ago)

        client = user.credential.twitter_client rescue nil
        client_muted_ids = client.muted_ids.to_a rescue []

        next if client.nil? || users_to_unfollow.empty?
        next unless user.can_twitter_unfollow?

        users_to_unfollow.each do |followed_user|
          begin
            twitter_user_id = followed_user.twitter_user_id.to_i

            # don't unfollow people who the user has manually unmuted
            next unless client_muted_ids.include?(twitter_user_id)

            if client.unfollow(twitter_user_id)
              followed_user.update_attributes({ unfollowed: true, unfollowed_at: DateTime.now })
              client.unmute(twitter_user_id)
              retweets_on = client.friendship_update(twitter_user_id, { :wants_retweets => true })
            end

          rescue Twitter::Error::Forbidden => e
          rescue Twitter::Error::NotFound => e
            followed_user.update_attributes({ unfollowed: true, unfollowed_at: DateTime.now })

          end
        end
      end
    end
  end
end