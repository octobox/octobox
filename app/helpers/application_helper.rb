module ApplicationHelper
  include Pagy::Frontend
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
    return unless flash.any?
    concat(content_tag(:div, class: "flex-header header-flash-messages") do
      flash.each do |msg_type, message|
        concat(content_tag(:div, message, class: "alert #{bootstrap_class_for(msg_type)} fade show") do
          concat content_tag(:button, octicon('x'), class: 'close', data: { dismiss: 'alert' })
          concat message.html_safe
        end)
      end
    end)
    nil
  end

  def repo_scope_modal
    content_tag :span, octicon('shield'), class: 'btn btn-sm btn-link repo-scope d-inline-block', title: 'Requires repo scope', data: {toggle:'modal', target:'#repo-scope'} unless Octobox.fetch_subject? || Octobox.personal_access_tokens_enabled?
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

  def used_by_orgs
    %w(kubernetes facebook nodejs angular Microsoft google
       elastic src-d alphagov vuejs rails algolia
       shopify WordPress golang opencollective travis-ci github Financial-Times rust-lang)
  end

  def current_theme
    current_user.try(:theme) || 'light'
  end

  def avatar_url(github_login, size: 30)
    github_login = github_login.gsub('[bot]', '') if Comment::BOT_AUTHOR_REGEX.match?(github_login)
    "#{Octobox.config.github_domain}/#{github_login}.png?s=#{size}"
  end

  def show_confirmations_class
    return unless logged_in?
    return 'disable_confirmations' if current_user.disable_confirmations?
  end

  def confirmation(message, notification)
    notification.user.disable_confirmations? ? nil : message
  end
end
