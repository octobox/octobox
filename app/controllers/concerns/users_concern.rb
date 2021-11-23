module UsersConcern
  extend ActiveSupport::Concern

  def ensure_correct_user
    return unless params[:id]
    head :unauthorized unless current_user.id.to_s == params[:id]
  end

  def update_user_params
    if params[:user].has_key? :refresh_interval_minutes
      params[:user][:refresh_interval] = params[:user][:refresh_interval_minutes].to_i * 60_000
    end

    # If the user changes nothing in the form, personal_access_token will be blank.  In that case we don't want to update it.
    if params[:user][:personal_access_token].blank?
      params[:user][:personal_access_token] = current_user.personal_access_token if params[:user][:personal_access_token].blank?
    end

    # No matter what is in the personal_access_token field, we want it cleared if the checkbox is checked
    if params.has_key?('clear_personal_access_token')
      params[:user][:personal_access_token] = nil
    end

    params.require(:user).permit(:personal_access_token, :refresh_interval, :theme, :display_comments, :disable_confirmations)
  end
end
