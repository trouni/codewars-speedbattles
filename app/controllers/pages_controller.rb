class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
  end

  def webhook_help
  end

  def sign_out_all
    User.all.each { |user| sign_out user}
    redirect_to root_path
  end
end
