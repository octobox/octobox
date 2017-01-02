# frozen_string_literal: true
class UsersController < ApplicationController
  before_action :ensure_correct_user

  def edit; end

  def update
    if current_user.update_attributes(update_user_params)
      redirect_to root_path
    else
      flash[:error] = 'Could not update your account'
      flash[:alert] = current_user.errors.full_messages.to_sentence
      redirect_to :settings
    end
  end

  def destroy
    user = User.find(current_user.id)
    github_login = user.github_login
    user.destroy
    flash[:success] = "User deleted: #{github_login}"
    redirect_to root_path
  end

  private

  def ensure_correct_user
    return unless params[:id]
    head :unauthorized unless current_user.id.to_s == params[:id]
  end

  def update_user_params

    # If the user changes nothing in the form, personal_access_token will be blank.  In that case we don't want to update it.
    if params[:user][:personal_access_token].blank?
      params[:user][:personal_access_token] = current_user.personal_access_token if params[:user][:personal_access_token].blank?
    end

    # No matter what is in the personal_access_token field, we want it cleared if the checkbox is checked
    if params.has_key?('clear_personal_access_token')
      params[:user][:personal_access_token] = nil
    end

    params.require(:user).permit(:personal_access_token, :sync_on_load)
  end
end
