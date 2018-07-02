namespace :twitter do
  task follow: :environment do
    total_tweets_per_tick = 500

    User.wants_twitter_follow.find_each do |user|
      begin
        next if !user.twitter_check? || user.rate_limited? || !user.can_twitter_follow? # usernames = []

        follow_prefs = user.twitter_follow_preference
        hashtags = follow_prefs.hashtags.delete('#').delete(' ').split(',').shuffle

        client = begin
                    user.credential.twitter_client
                  rescue
                    nil
                  end
        next if client.nil?

        # Keep track of # of followers user has hourly
        Follower.compose(user) if Follower.can_compose_for?(user)

        follower_ids = client.follower_ids.to_a
        user.twitter_follows.where(twitter_user_id: follower_ids).update_all(was_following: true)

        tweets_per_hashtag = total_tweets_per_tick / hashtags.count

        hashtags
          .flat_map do |hashtag|
            client.search("##{hashtag} exclude:replies exclude:retweets filter:safe",
                          result_type: 'recent', lang: 'en', count: tweets_per_hashtag)
                  .collect
                  .take(tweets_per_hashtag)
                  .map { |tweet| SearchResult.new(hashtag, tweet, tweet.user) }
          end
          .uniq { |search_result| search_result.user.screen_name.to_s }
          .delete_if do |search_result|
            user_to_follow = search_result.user
            username = user_to_follow.screen_name.to_s

            # Skip users without bio
            user_to_follow.default_profile? ||
              user_to_follow.default_profile? ||
              user_to_follow.protected? ||
              user_to_follow.friends_count.zero? ||
              TwitterFollow.where(user: user, username: username).any?
          end
          .sort_by do |search_result|
            twitter_user = search_result.user
            (1 - (twitter_user.followers_count / twitter_user.friends_count.to_f)).abs
          end
          .take(6)
          .each do |search_result|
            username = search_result.user.screen_name.to_s
            tweet = search_result.tweet

            client.favorite(tweet) if tweet.favorite_count.positive? || tweet.retweet_count.positive?
            client.friendship_update(username, wants_retweets: false)
            client.mute(username) # don't show their tweets in our feed
            followed = client.follow(username)

            TwitterFollow.follow!(user, search_result) if followed
          end
      rescue Twitter::Error::TooManyRequests => e
        # rate limited - set rate_limit_until timestamp
        sleep_time =
          begin
            (e.rate_limit.reset_in + 1.minute) / 60
          rescue
            16
          end
        follow_prefs.update_attributes(rate_limit_until: DateTime.now + sleep_time.minutes)
      rescue Twitter::Error::Forbidden => e
        # if e.message.index('Application cannot perform write actions')
        #   user.credential.update_attributes(is_valid: false)
        # end
        raise e
      rescue Twitter::Error::Unauthorized => e
        # follow_prefs.update_attributes(mass_follow: false, mass_unfollow: false)
        # user.credential.update_attributes(is_valid: false)
        raise e
      end
    end
  end
end
