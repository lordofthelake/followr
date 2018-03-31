class AddStatsToTwitterFollows < ActiveRecord::Migration[5.1]
  def change
    add_column :twitter_follows, :followers_count, :integer
    add_column :twitter_follows, :following_count, :integer
    add_column :twitter_follows, :statuses_count, :integer
    add_column :twitter_follows, :favourites_count, :integer
    add_column :twitter_follows, :lang, :string
    add_column :twitter_follows, :description, :text
  end
end
