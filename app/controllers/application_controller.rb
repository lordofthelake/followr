class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  helper_method :current_user, :new_user?, :expire_session

  def current_user
    user = nil
    user = User.find_by_id(session[:user_id]) if session[:user_id]

    unless user
      user = Credential.find_by_twitter_oauth_token(params[:auth_token]).user rescue nil if params[:auth_token]
    end

    if user
      session[:user_id] = user.id
      return user
    else
      expire_session
    end
  end

  def expire_session
    session[:user_id] = nil
  end

  def new_user?
    return unless current_user
    twitter_follow_preference = current_user.twitter_follow_preference
    !(current_user.created_at < 4.hours.ago) && twitter_follow_preference.present? && twitter_follow_preference.hashtags.blank?
  end
end
