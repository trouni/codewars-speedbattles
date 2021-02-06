require 'open-uri'

class CodewarsController < ApplicationController
  include CodewarsHelper
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token
  skip_after_action :verify_authorized, only: :webhook

  def webhook
    secret = request.headers[:HTTP_X_WEBHOOK_SECRET]
    render json: { ok: false, message: "Missing secret" } and return if secret.nil?

    payload = JSON.parse(Base64.decode64(secret)).with_indifferent_access

    user = User.find(payload.fetch(:id))
    user&.update_settings(connected_webhook: true, last_webhook_at: Time.now) if user&.authentication_token == payload.fetch(:t)
    update_user_from_webhook(params[:user]) if params[:user]
    
    render json: { ok: true }
    rescue JSON::ParserError, ActiveRecord::RecordNotFound
      render json: { ok: false, message: "Invalid secret" }
  end

  private

  def update_user_from_webhook(user)
    codewars_id = user[:id]
    user = User.find_by(codewars_id: codewars_id) || fetch_user(id: codewars_id)
    if user
      user.assign_attributes(codewars_id: codewars_id)
      codewars_honor = user[:honor]
      user.assign_attributes(codewars_honor: codewars_honor) if codewars_honor
      codewars_rank = user[:rank]
      user.assign_attributes(codewars_overall_rank: codewars_rank) if codewars_rank
      user.save
      FetchCompletedChallengesJob.perform_later(user_id: user.id, all_pages: false)
    end
  end
end
