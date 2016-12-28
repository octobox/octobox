# frozen_string_literal: true
class UsersController < ApplicationController
  def edit; end

  def update
    if current_user.update_attributes(update_user_params)
      redirect_to root_path
    else
      flash[:error] = 'Could not update your account'
      redirect_to :user_preferences
    end
  end

  private

  def update_user_params
    params.require(:user).permit(:personal_access_token)
  end
end
