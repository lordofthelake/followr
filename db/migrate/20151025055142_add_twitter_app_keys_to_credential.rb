class AddTwitterAppKeysToCredential < ActiveRecord::Migration
  def change
    add_column :credentials,  :encrypted_twitter_consumer_key, :string
    add_column :credentials,  :encrypted_twitter_consumer_secret, :string
  end
end
