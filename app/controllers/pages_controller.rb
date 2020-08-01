class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
    render layout: 'vue_application'
  end

  def webhook_help
  end
end
