class CredentialsController < ApplicationController

  protect_from_forgery except: :create
  
  def create
    twitter_consumer_key = params[:twitter_consumer_key]
    twitter_consumer_secret = params[:twitter_consumer_secret]
    twitter_oauth_token = params[:twitter_oauth_token]
    twitter_oauth_token_secret = params[:twitter_oauth_token_secret]
    user = User.find_by_twitter_uid(params[:auth]["uid"])
    
    unless user
      user = User.create_with_omniauth(params[:auth])
    end

    credential = Credential.create_with_omniauth(user, params)
      # credentials = user.credential
      # credentials_with_these_tokens = credentials.select {|c| c.twitter_oauth_token == twitter_oauth_token && c.encrypted_twitter_oauth_token_secret = twitter_oauth_token_secret }
      # if (credentials_with_these_tokens.empty? || !credentials_with_these_tokens.first.is_valid) && credentials.valid.length < Credential::MAX_TWITTER_APPS
      #   invalid_credentials = credentials.not_valid.present? ? credentials.not_valid : [Credential.new]
      #   c = invalid_credentials.first
      #   c.user_id ||= user.id
      #   c.twitter_consumer_key = twitter_consumer_key
      #   c.twitter_consumer_secret = twitter_consumer_secret
      #   c.twitter_oauth_token = twitter_oauth_token
      #   c.twitter_oauth_token_secret = twitter_oauth_token_secret
      #   c.is_valid = true
      #   c.save!
      # end
    render :ok, json: { auth_token: credential.twitter_oauth_token } and return
    # else
    #   user = User.create_with_omniauth(params[:auth])
    #   if user
    #     credential = Credential.create_with_omniauth(user, params)
    #     render :ok, json: { auth_token: credential.twitter_oauth_token } and return
    #   end
    # end
    # render status: 400, json: nil
  end

end