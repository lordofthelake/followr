class RenameEncryptedAttribute < ActiveRecord::Migration
  def change
    rename_column :credentials, :encrypted_twitter_oauth_token, :twitter_oauth_token
    rename_column :credentials, :encrypted_twitter_oauth_token_secret, :twitter_oauth_token_secret
  end
end
