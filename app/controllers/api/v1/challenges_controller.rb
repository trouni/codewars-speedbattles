class Api::V1::ChallengesController < Api::V1::BaseController
  include CodewarsHelper

  def show
    skip_authorization
    @challenge = fetch_kata_info(params[:id])
  end
end
