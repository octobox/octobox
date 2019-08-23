class PinnedSearchesController < ApplicationController
  def new
    @pinned_search = current_user.pinned_searches.build
  end

  def create
    @pinned_search = current_user.pinned_searches.build(pinned_search_params)
    if @pinned_search.save
      redirect_to settings_path, notice: 'Search saved'
    else
      render :new
    end
  end

  def edit
    @pinned_search = current_user.pinned_searches.find(params[:id])
  end

  def update
    @pinned_search = current_user.pinned_searches.find(params[:id])
    if @pinned_search.update(pinned_search_params)
      redirect_to settings_path, notice: 'Search updated'
    else
      render :new
    end
  end

  def destroy
    @pinned_search = current_user.pinned_searches.find(params[:id])
    @pinned_search.destroy
    redirect_to settings_path, notice: 'Search deleted'
  end

  def index
    redirect_to settings_path
  end

  def show
    respond_to do |format|
      format.html { redirect_to settings_path }
      format.json do
        @pinned_search = current_user.pinned_searches.find(params[:id])
        @search = Search.initialize_for_saved_search(query: @pinned_search.query, user: current_user)
      end
    end
  end

  private

  def pinned_search_params
    params.require(:pinned_search).permit(:query, :name)
  end
end
