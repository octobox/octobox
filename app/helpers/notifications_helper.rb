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
      starred: params[:starred]
    }
  end

  def any_active_filters?
    filters[:reason].present? || filters[:status].present? || filters[:repo].present? || filters[:type].present?
  end
end
