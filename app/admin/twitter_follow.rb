ActiveAdmin.register TwitterFollow do
  belongs_to :user

  index do
    selectable_column
    id_column
    column :username do |tf|
      link_to "@#{tf.username}", "https://twitter.com/#{tf.username}"
    end
    column :followed_at
    column :unfollowed_at
    column :following_count
    column :followers_count
    column :favourites_count
    column :hashtag
    column :was_following
    column :lang
    column :description
    column :source_tweet_text
    column :source_tweet_uri

    actions
  end
end
