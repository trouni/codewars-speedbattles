require 'open-uri'

class CodewarsController < ApplicationController
  include CodewarsHelper
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  def webhook
    payload = JSON.parse(Base64.decode64(request.headers[:HTTP_X_WEBHOOK_SECRET])).with_indifferent_access
    user = User.find(payload.fetch(:id))
    user&.update(connected_webhook: true) if user&.authentication_token == payload.fetch(:t)
    update_user_from_webhook(params[:user]) if params[:user]

    skip_authorization
    render json: { ok: true }
  end

  private

  def update_user_from_webhook(user)
    codewars_id = user[:id]
    user = User.find_by(codewars_id: codewars_id) || fetch_user(id: codewars_id)
    if user
      user.update(codewars_id: codewars_id)
      codewars_honor = user[:honor]
      user.update(codewars_honor: codewars_honor) if codewars_honor
      codewars_rank = user[:rank]
      user.update(codewars_rank: codewars_rank) if codewars_rank
      FetchCompletedChallengesJob.perform_later(user_id: user.id, all_pages: false)
    end
  end
end
