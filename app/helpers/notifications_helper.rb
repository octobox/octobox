module NotificationsHelper
  def menu_separator(custom_class=nil)
    "<li class='divider #{custom_class}'></li>".html_safe
  end

  def filters
    {
      reason:  params[:reason],
      status:  params[:status],
      repo:    params[:repo],
      type:    params[:type],
      archive: params[:archive],
      starred: params[:starred],
      owner: params[:owner]
    }
  end

  def any_active_filters?
    [:status, :reason, :type, :repo, :owner].any?{|param| filters[param].present? }
  end

  def filtered_params(override = {})
    filters.merge(override)
  end
end
