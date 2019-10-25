class RegistrationsController < Devise::RegistrationsController

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

  protected

  # def user_params
  #   params.require(:user).permit(:id, :username, :name)
  # end

  def update_resource(resource, params)
    resource.update_without_password(params)
  end

  def after_update_path_for(_resource)
    current_room_id = params[:current_room][:id].to_i
    if current_room_id.zero?
      root_path
    else
      room_path(Room.find(current_room_id))
    end
  end
end
