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

    # If the user changes nothing in the form, personal_access_token will be blank.  In that case we don't want to update it.
    if params[:user][:personal_access_token].blank?
      params[:user][:personal_access_token] = current_user.personal_access_token if params[:user][:personal_access_token].blank?
    end

    # No matter what is in the personal_access_token field, we want it cleared if the checkbox is checked
    if params.has_key?('clear_personal_access_token')
      params[:user][:personal_access_token] = nil
    end

    params.require(:user).permit(:personal_access_token)
  end
end
