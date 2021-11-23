# frozen_string_literal: true
class Api::UsersController < Api::ApplicationController
include UsersConcern

  before_action :ensure_correct_user

  # Return a user profile. Only shows the current user
  #
  # ==== Example
  #
  # <code>GET api/users/profile.json</code>
  #   {
  #     "user" : {
  #         "id" : 1,
  #         "github_id" : 3074765,
  #         "github_login" : "jules2689",
  #         "last_synced_at" : "2017-02-22T15:49:32.104Z",
  #         "created_at" : "2017-02-22T15:49:32.099Z",
  #         "updated_at" : "2017-02-22T15:49:32.099Z"
  #     }
  #   }
  def profile

  end

  # Update a user profile. Only updates the current user
  #
  # * +:personal_access_token+ - The user's personal access token
  # * +:refresh_interval+ - The refresh interval on which a sync should be initiated (while viewing the app). In milliseconds.
  #
  # ==== Example
  #
  # <code>PATCH api/users/:id.json</code>
  #   { "user" : { "refresh_interval" : 60000 } }
  #
  #   HEAD OK
  #
  def update
    if current_user.update(update_user_params)
      if params[:user][:regenerate_api_token]
        current_user.regenerate_api_token
      end
      head :ok
    else
      render json: { errors: current_user.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  # Delete your user profile. Can only delete the current user
  #
  # ==== Example
  #
  # <code>DELETE api/users/:id.json</code>
  #   HEAD OK
  #
  def destroy
    user = User.find(current_user.id)
    github_login = user.github_login
    user.destroy
    head :ok
  end
end
