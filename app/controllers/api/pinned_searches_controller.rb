class Api::PinnedSearchesController < Api::ApplicationController
  # Create a pinned search
  #
  # * +:query+ - The search query string
  # * +:name+ - The display name of the search
  #
  # ==== Example
  #
  # <code>POST api/pinned_searchesjson</code>
  #   { "pinned_search" : { "query" : "owner:octobox inbox:true", "name" : "Work" } }
  #
  #   {
  #     "id" : 35778,
  #     "user_id" : 11741,
  #     "query" : "owner:octobox inbox:true",
  #     "name" : "Work",
  #     "count" : 0,
  #     "created_at" : "2021-11-23T19:48:39.953Z",
  #     "updated_at" : "2021-11-23T19:48:39.953Z"
  #   }
  #
  def create
    @pinned_search = current_user.pinned_searches.build(pinned_search_params)
    if @pinned_search.save
      render 'show'
    else
      render json: { errors: @pinned_search.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  # Update a pinned search
  #
  # * +:query+ - The search query string
  # * +:name+ - The display name of the search
  #
  # ==== Example
  #
  # <code>PATCH api/pinned_searches/:id.json</code>
  #   { "pinned_search" : { "query" : "owner:octobox inbox:true", "name" : "Work" } }
  #
  #   {
  #     "id" : 35778,
  #     "user_id" : 11741,
  #     "query" : "owner:octobox inbox:true",
  #     "name" : "Work",
  #     "count" : 0,
  #     "created_at" : "2021-11-23T19:48:39.953Z",
  #     "updated_at" : "2021-11-23T19:48:39.953Z"
  #   }
  #
  def update
    @pinned_search = current_user.pinned_searches.find(params[:id])
    if @pinned_search.update(pinned_search_params)
      render 'show'
    else
      render json: { errors: @pinned_search.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  # Delete a pinned search
  #
  # ==== Example
  #
  # <code>DELETE api/pinned_searches/:id.json</code>
  #   HEAD OK
  #
  def destroy
    @pinned_search = current_user.pinned_searches.find(params[:id])
    @pinned_search.destroy
    head :ok
  end

  # List users pinned searches
  #
  # ==== Example
  #
  # <code>GET api/pinned_searches.json</code>
  #
  # {
  #   "pinned_searches":[
  #     {
  #       "id":35794,
  #       "user_id":11746,
  #       "query":"state:closed,merged archived:false",
  #       "name":"Archivable",
  #       "count":0,
  #       "created_at":"2021-11-23T19:52:19.097Z",
  #       "updated_at":"2021-11-23T19:52:19.097Z"
  #     }
  #   ]
  # }
  #
  def index
    @pinned_searches = current_user.pinned_searches
  end

  # Get a single pinned search
  #
  # ==== Example
  #
  # <code>GET api/pinned_searches/:id.json</code>
  #
  #   {
  #     "id" : 35778,
  #     "user_id" : 11741,
  #     "query" : "owner:octobox inbox:true",
  #     "name" : "Work",
  #     "count" : 0,
  #     "created_at" : "2021-11-23T19:48:39.953Z",
  #     "updated_at" : "2021-11-23T19:48:39.953Z"
  #   }
  #
  def show
    @pinned_search = current_user.pinned_searches.find(params[:id])
  end

  private

  def pinned_search_params
    params.require(:pinned_search).permit(:query, :name)
  end
end
