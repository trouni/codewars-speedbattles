class SessionsController < Devise::SessionsController

  def create
    cookies.signed[:user_id] = current_user&.id
    super
  end

  # def edit
  #   if params[:id]
  #     @user = User.find(params[:id])
  #   else
  #     @user = current_user
  #   end
  # end

  # def update
  #   @user = User.find(params[:id])
  #   @user.update(user_params)
  # end

  def destroy
    cookies.signed[:user_id] = nil
    super
  end

  protected

  # def user_params
  #   params.require(:user).permit(:id, :username, :name)
  # end

  def update_resource(resource, params)
    resource.update_without_password(params)
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || rooms_path
  end
end

