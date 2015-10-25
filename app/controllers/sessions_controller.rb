class SessionsController < ApplicationController

  protect_from_forgery except: :create

  def create

  end

  def destroy
    session[:user_id] = nil
    redirect_to root_url
  end
end
