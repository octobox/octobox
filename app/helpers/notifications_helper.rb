module NotificationsHelper
  REASON_LABELS = {
    'comment'        => 'primary',
    'author'         => 'success',
    'state_change'   => 'info',
    'mention'        => 'warning',
    'assign'         => 'danger',
    'subscribed'     => 'subscribed',
    'team_mention'   => 'team_mention',
    'security_alert' => 'security_alert'
  }.freeze

  STATE_LABELS = {
    'open'   => 'success',
    'closed' => 'danger',
    'merged' => 'subscribed'
  }

  SUBJECT_TYPES = {
    'RepositoryInvitation'         => 'mail',
    'Issue'                        => 'issue-opened',
    'PullRequest'                  => 'git-pull-request',
    'Commit'                       => 'git-commit',
    'Release'                      => 'tag',
    'RepositoryVulnerabilityAlert' => 'alert'
  }.freeze

  SUBJECT_STATUS = {
    success: "success",
    failure: "failure",
    error: "error",
    pending: "pending"
  }

  NOTIFICATION_STATUS_OCTICON = {
    'success' => 'check',
    'failure' => 'x',
    'error' => 'alert',
    'pending' => 'dot-fill'
  }

  COMMENT_STATUS = {
    'APPROVED' => 'success',
    'CHANGES_REQUESTED' => 'error',
    'COMMENTED' => 'pending'
  }

  COMMENT_STATUS_OCTICON = {
    'APPROVED' => 'check',
    'CHANGES_REQUESTED' => 'x',
    'COMMENTED' => 'dot-fill'
  }

  def filters
    {
      reason:          params[:reason],
      unread:          params[:unread],
      repo:            params[:repo],
      number:          params[:number],
      type:            params[:type],
      archive:         params[:archive],
      starred:         params[:starred],
      owner:           params[:owner],
      per_page:        params[:per_page],
      q:               params[:q],
      state:           params[:state],
      label:           params[:label],
      author:          params[:author],
      bot:             params[:bot],
      unlabelled:      params[:unlabelled],
      assigned:        params[:assigned],
      is_private:      params[:is_private],
      status:          params[:status],
    }
  end

  def inbox_selected?
    !archive_selected? && !starred_selected? && !showing_search_results?
  end

  def archive_selected?
    filters[:archive].present?
  end

  def starred_selected?
    filters[:starred].present?
  end

  def showing_search_results?
    filters[:q].present?
  end

  def show_archive_icon?
    starred_selected? || showing_search_results?
  end

  def notification_param_keys
    filters.keys - [:per_page]
  end

  def bucket_param_keys
    [:archive, :starred]
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

  def mute_button
    function_button('Mute', 'mute', "mute", 'Mute notification', false)
  end

  def delete_button
    function_button("Delete", 'trash', "delete", 'Delete notification', false)
  end

  def archive_button
    function_button("Archive", 'checklist', "archive_toggle archive", 'Archive', false)
  end

  def unarchive_button
    function_button("Unarchive", 'inbox', "archive_toggle unarchive", 'Unarchive notification', false)
  end

  def mute_selected_button
    function_button('Mute selected', 'mute', 'mute_selected', 'Mute selected items')
  end

  def mark_read_selected_button
    function_button('Mark as read', 'eye', 'mark_read_selected', 'Mark items as read')
  end

  def archive_selected_button
    function_button("Archive selected", 'checklist', "archive_toggle archive_selected", 'Archive selected items')
  end

  def unarchive_selected_button
    function_button("Unarchive selected", 'inbox', "archive_toggle unarchive_selected", 'Unarchive selected items')
  end

  def delete_selected_button
    function_button("Delete selected", 'trash', "delete_selected", 'Delete selected items')
  end

  def select_all_button(cur_selected, total)
    button_tag(type: 'button', class: "select_all btn btn-sm btn-outline-dark hidden-button", 'data-toggle': "tooltip", 'data-placement': "bottom", 'title': "Number of items selected") do
      octicon('check', height: 16) +
        content_tag(:span, " #{cur_selected}", class: 'bold d-none d-md-inline-block ml-1') +
        " | " +
        content_tag(:span, " #{total}", class: 'd-none d-md-inline-block')
    end if cur_selected < total
  end

  def function_button(title, octicon, css_class, tooltip, hidden=true)
    button_tag(type: 'button', class: "#{css_class} btn btn-sm btn-outline-dark #{'hidden-button' if hidden}", 'data-toggle': "tooltip", 'data-placement': "bottom", 'title': tooltip ) do
      octicon(octicon, height: 16) + content_tag(:span, "#{title}", class: 'd-none d-xl-inline-block ml-1')
    end
  end

  def no_url_filter_parameters_present
    notification_param_keys.all?{|param| params[param].blank? }
  end

  def notification_icon(notification)
    subject_type = notification.subject_type
    state = notification.user.try(:github_app_authorized?) ? notification.state : nil
    return 'issue-closed' if subject_type == 'Issue' && state == 'closed'
    return 'git-merge' if subject_type == 'PullRequest' && state == 'merged'
    subject_type_icon(subject_type)
  end

  def subject_type_icon(subject_type)
    SUBJECT_TYPES[subject_type]
  end

  def notification_icon_title(notification)
    return "Draft #{notification.subject_type.underscore.humanize.downcase}" if notification.draft?
    return notification.subject_type.underscore.humanize if notification.state.blank?
    "#{notification.state.underscore.humanize} #{notification.subject_type.underscore.humanize.downcase}"
  end

  def notification_icon_color(notification)
    return unless notification.display_subject?
    return 'text-draft' if notification.draft?
    return 'text-subscribed' if notification.state == 'closed' && notification.subject_type == 'Issue'
    {
      'open' => 'text-success',
      'closed' => 'text-danger',
      'merged' => 'text-subscribed'
    }[notification.state]
  end

  def reason_label(reason)
    REASON_LABELS.fetch(reason, 'secondary')
  end

  def state_label(state)
    STATE_LABELS.fetch(state, 'secondary')
  end

  def filter_option(param)
    if filters[param].present?
      link_to root_path(filters.except(param)), class: "btn btn-sm btn-outline-dark" do
        concat octicon('x', :height => 16)
        concat ' '
        concat yield
      end
    end
  end

  def reason_filter_option(reason)
    if filters[:reason].present? && reason.present?
      reasons = filters[:reason].split(',').reject(&:empty?)
      index = reasons.index(reason.underscore.downcase)
      reasons.delete_at(index) if index
      link_to root_path(filters.merge(:reason => reasons.join(','))), class: "btn btn-sm btn-outline-dark" do
        concat octicon('x', :height => 16)
        concat ' '
        concat yield
      end
    end
  end

  def filter_link(param, value, count)
    sidebar_filter_link(active: params[param] == value.to_s, param: param, value: value, count: count) do
      yield
    end
  end

  def org_filter_link(param, value)
    sidebar_filter_link(active: params[param] == value.to_s, param: param, value: value, except: :repo, link_class: 'owner-label') do
      yield
    end
  end

  def repo_filter_link(param, repo_name, count)
    active = params[param] == repo_name || params[:owner] == repo_name.split('/')[0]
    sidebar_filter_link(active: active, param: param, value: repo_name, count: count, except: :owner, link_class: 'repo-label', title: repo_name) do
      yield
    end
  end

  def sidebar_filter_link(active:, param:, value:, count: nil, except: nil, link_class: nil, path_params: nil, title: nil)
    css_class = 'nav-item'
    css_class += ' active' if active
    css_class += " #{param}-#{value}"

    content_tag :li, class: css_class, title: title do
      active = (active && not_repo_in_active_org(param))
      path_params ||= filtered_params(param => (active ? nil : value)).except(except)
      link_to root_path(path_params), class: (active ? "nav-link active filter #{link_class}" : "nav-link filter #{link_class}") do
        yield
        if active && not_repo_in_active_org(param)
          concat content_tag(:span, octicon('x', :height => 16), class: 'badge badge-light')
        elsif count.present?
          concat content_tag(:span, count, class: 'badge badge-light')
        end
      end
    end
  end

  def reason_filter_link(value, count)
    active = params[:reason].present? && params[:reason].split(',').include?(value.to_s)
    link_value = reason_link_param_value(params[:reason], value, active)
    path_params = filtered_params(:reason => link_value)

    sidebar_filter_link(active: active, param: :reason, value: link_value, count: count, path_params: path_params) do
      yield
    end
  end

  def reason_link_param_value(param, value, active)
    reasons = param.try(:split, ',') || []
    active ? reasons.delete(value) : reasons.push(value)
    reasons.try(:join, ',')
  end

  def not_repo_in_active_org(param)
    return true unless param == :repo
    params[:owner].blank?
  end

  def search_query_matches?(query, other_query)
    query = Search.new(query: query, scope: {}).to_query
    other_query = Search.new(query: other_query, scope: {}).to_query
    query.split(' ').sort == other_query.split(' ').sort
  end

  def search_pinned?(query)
    return unless query.present?
    return false if current_user.pinned_searches.empty?

    current_user.pinned_searches.any? do |pinned_search|
      search_query_matches?(query, pinned_search.query)
    end
  end

  def notification_status(status)
    return unless status.present?
    content_tag(:span,
      octicon(NOTIFICATION_STATUS_OCTICON[status], height: 24, class: status),
      class: "badge badge-light badge-pr #{status}",
      title: status.humanize,
      data: {toggle: 'tooltip'}
    )
  end

  def comment_status(status)
    return unless status.present?
    content_tag(:span,
      octicon(COMMENT_STATUS_OCTICON[status], height: 24, class: COMMENT_STATUS[status]),
      class: "badge badge-light #{COMMENT_STATUS[status]}",
      title: status.humanize,
      data: {toggle: 'tooltip'}
    )
  end

  def sidebar_notification_status(status)
    octicon(NOTIFICATION_STATUS_OCTICON[status], height: 24, class: "sidebar-icon #{status}")
  end

  def subject_with_number(notification)
    if ['Issue', 'PullRequest'].include?(notification.subject_type)
      capture do
        concat content_tag(:span, "##{notification.subject_number}", class: "notification-number")
        concat " "
        concat notification.subject_title
      end
    else
      notification.subject_title
    end
  end

  def notification_button(subject_type, state = nil)
    return 'issue-closed' if subject_type == 'Issue' && state == 'closed'
    SUBJECT_TYPES[subject_type]
  end

  def notification_button_title(notification)
    return 'Draft' if notification.draft?
    return notification.subject_type.underscore.humanize if notification.state.blank?
    notification.state.underscore.humanize
  end

  def notification_button_color(notification)
    return unless notification.display_subject?
    return 'btn-draft' if notification.draft?
    {
      'open' => 'btn-success',
      'closed' => 'btn-danger',
      'merged' => 'btn-merged'
    }[notification.state]
  end

  def parse_markdown(str)
    return if str.blank?
    CommonMarker.render_html(str, :GITHUB_PRE_LANG, [:tagfilter, :autolink, :table, :strikethrough])
  end

  def notification_link(notification)
    notification.display_thread? ? notification_path(notification, filtered_params) : notification.web_url
  end

  def display_thread?
    Octobox.include_comments? && current_user.display_comments
  end
end
