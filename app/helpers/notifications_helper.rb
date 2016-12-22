module NotificationsHelper
  def menu_separator(custom_class=nil)
    "<li class='divider #{custom_class}'></li>".html_safe
  end
end
