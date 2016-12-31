module NotificationsHelper
  def menu_separator(custom_class=nil)
    "<li class='divider #{custom_class}'></li>".html_safe
  end

  def filters
    {
      reason:   params[:reason],
      status:   params[:status],
      repo:     params[:repo],
      type:     params[:type],
      archive:  params[:archive],
      starred:  params[:starred],
      owner:    params[:owner],
      per_page: params[:per_page]
    }
  end

  def notification_param_keys
    filters.keys - [:per_page]
  end

  def bucket_param_keys
    [:archived, :starred]
  end

  def filter_param_keys
    notification_param_keys - bucket_param_keys
  end

  def any_active_filters?
    filter_param_keys.any?{|param| filters[param].present? }
  end

  def filtered_params(override = {})
    filters.merge(override)
  end

  def archive_selected_button(custom_class=nil)
    action = params[:archive] ? 'unarchive' : 'archive'
    button_tag(type: "button",
               class: "archive_toggle #{action}_selected #{custom_class}") do
      "#{action} selected".capitalize
    end
  end
end
