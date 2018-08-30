module ApplicationHelper
  ALERT_TYPES = {
    success: 'alert-success',
    error: 'alert-danger',
    alert: 'alert-warning',
    notice: 'alert-info'
  }.freeze

  def bootstrap_class_for(flash_type)
    ALERT_TYPES[flash_type.to_sym] || flash_type.to_s
  end

  def flash_messages
    flash.each do |msg_type, message|
      concat(content_tag(:div, message, class: "alert #{bootstrap_class_for(msg_type)} fade in") do
        concat content_tag(:button, 'x', class: 'close', data: { dismiss: 'alert' })
        concat message
      end)
    end
    nil
  end

  def repo_scope_modal
    content_tag :span, octicon('shield'), class: 'btn btn-sm btn-link repo-scope d-inline-block', title: 'Requires repo scope', data: {toggle:'modal', target:'#repo-scope'} unless Octobox.config.fetch_subject || Octobox.personal_access_tokens_enabled?
  end

  def octobox_icon(height=16)
    image_tag('infinitacle.svg', alt: "Octobox", height: height)
  end

  def octobox_reverse_icon(height=16)
    image_tag('infinitacle-reverse.svg', alt: "Octobox", height: height)
  end

  def octobox_round(height=80)
    image_tag('infinitacle-round.svg', alt: "Logo", height: height)
  end

  def menu_separator(custom_class=nil)
    "<li class='divider #{custom_class}'></li>".html_safe
  end

  def current_theme
    current_user.try(:theme)
  end
end
