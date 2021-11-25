# frozen_string_literal: true
class UsersController < ApplicationController
  include UsersConcern

  before_action :ensure_correct_user

  def profile
    render 'api/users/profile'
  end

  def extension
    @return_to = params[:return_to].presence || Octobox.config.github_domain
  end

  def edit
    repo_counts = current_user.notifications.group(:repository_full_name).count
    @total = repo_counts.sum(&:last)
    @most_active_repos = repo_counts.sort_by(&:last).reverse.first(10)
    @most_active_orgs = current_user.notifications.group(:repository_owner_name).count.sort_by(&:last).reverse.first(10)
    @pinned_search = PinnedSearch.new(query: params[:q])
  end

  def update
    if current_user.update(update_user_params)
      if params[:user][:regenerate_api_token]
        current_user.regenerate_api_token
      end

      respond_to do |format|
        format.html { redirect_back(fallback_location: root_path, notice: 'Settings updated') }
        format.json { head :ok }
      end
    else
      respond_to do |format|
        format.html do
          flash[:error] = 'Could not update your account'
          flash[:alert] = current_user.errors.full_messages.to_sentence
          redirect_to :settings
        end
        format.json { render json: { errors: current_user.errors.full_messages.to_sentence }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    user = User.find(current_user.id)
    github_login = user.github_login
    user.destroy

    respond_to do |format|
      format.html do
        flash[:success] = "User deleted: #{github_login}"
        redirect_to root_path
      end
      format.json { head :ok }
    end
  end

  def export
    send_data current_user.notifications.to_json, :type => 'application/json; header=present', :disposition => "attachment; filename=octobox.json"
  end

  def import
    data = JSON.parse(params[:file].read)
    current_user.import_notifications(data)
    flash[:success] = "Import complete"
    redirect_to root_path
  end
end
