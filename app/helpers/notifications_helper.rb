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
    'RepositoryInvitation'         => 'mail-read',
    'Issue'                        => 'issue-opened',
    'PullRequest'                  => 'git-pull-request',
    'Commit'                       => 'git-commit',
    'Release'                      => 'tag',
    'RepositoryVulnerabilityAlert' => 'alert'
  }.freeze

  def filters
    {
      reason:   params[:reason],
      unread:   params[:unread],
      repo:     params[:repo],
      type:     params[:type],
      archive:  params[:archive],
      starred:  params[:starred],
      owner:    params[:owner],
      per_page: params[:per_page],
      q:        params[:q],
      state:    params[:state],
      label:    params[:label],
    }
  end

  def inbox_selected?
    !archive_selected? && !starred_selected?
  end

  def archive_selected?
    filters[:archive].present?
  end

  def starred_selected?
    filters[:starred].present?
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

  def mute_selected_button
    function_button('Mute selected', 'mute', 'mute_selected', 'Mute selected items') unless params[:archive]
  end

  def mark_read_selected_button
    function_button('Mark as read', 'eye', 'mark_read_selected', 'Mark items as read')
  end

  def archive_selected_button
    action = params[:archive] ? 'unarchive' : 'archive'
    function_button("#{action.capitalize} selected", 'checklist', "archive_toggle #{action}_selected", 'Archive selected items')
  end

  def select_all_button(cur_selected, total)
    button_tag(type: 'button', class: "select_all btn btn-sm btn-outline-dark hidden-button", 'data-toggle': "tooltip", 'data-placement': "bottom", 'title': "Number of items selected") do
      octicon('check', height: 16) +
        content_tag(:span, " #{cur_selected}", class: 'bold d-none d-md-inline-block') +
        " |" +
        content_tag(:span, " #{total}", class: 'd-none d-md-inline-block')
    end if cur_selected < total
  end

  def function_button(title, octicon, css_class, tooltip)
    button_tag(type: 'button', class: "#{css_class} btn btn-sm btn-outline-dark hidden-button", 'data-toggle': "tooltip", 'data-placement': "bottom", 'title': tooltip ) do
      octicon(octicon, height: 16) + content_tag(:span, "#{title}", class: 'd-none d-md-inline-block ml-1')
    end
  end

  def no_url_filter_parameters_present
    notification_param_keys.all?{|param| params[param].blank? }
  end

  def notification_icon(subject_type, state = nil)
    return 'issue-closed' if subject_type == 'Issue' && state == 'closed'
    SUBJECT_TYPES[subject_type]
  end

  def notification_icon_title(subject_type, state = nil)
    return subject_type.underscore.humanize if state.blank?
    "#{state.underscore.humanize} #{subject_type.underscore.humanize.downcase}"
  end

  def notification_icon_color(state)
    {
      'open' => 'text-success',
      'closed' => 'text-danger',
      'merged' => 'text-subscribed'
    }[state]
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
    sidebar_filter_link(params[param] == value.to_s, param, value, count) do
      yield
    end
  end

  def org_filter_link(param, value)
    sidebar_filter_link(params[param] == value.to_s, param, value, nil, :repo, 'owner-label') do
      yield
    end
  end

  def repo_filter_link(param, value, count)
    active = params[param] == value || params[:owner] == value.split('/')[0]
    sidebar_filter_link(active, param, value, count, :owner, 'repo-label') do
      yield
    end
  end

  def sidebar_filter_link(active, param, value, count, except = nil, link_class = nil, path_params = nil)
    content_tag :li, class: (active ? 'nav-item active' : 'nav-item') do
      active = (active && not_repo_in_active_org(param))
      path_params ||= filtered_params(param => (active ? nil : value)).except(except)
      link_to root_path(path_params), class: (active ? "nav-link active filter #{link_class}" : "nav-link filter #{link_class}") do
        yield
        if active && not_repo_in_active_org(param)
          concat content_tag(:span, octicon('x', :height => 16), class: 'badge')
        elsif count.present?
          concat content_tag(:span, count, class: 'badge')
        end
      end
    end
  end

  def reason_filter_link(value, count)
    active = params[:reason].present? && params[:reason].split(',').include?(value.to_s)
    link_value = reason_link_param_value(params[:reason], value, active)
    path_params = filtered_params(:reason => link_value)

    sidebar_filter_link(active, :reason, link_value, count, nil, nil, path_params) do
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
    !params[:owner].present?
  end

  def display_subject?
    Octobox.config.fetch_subject
  end

  def parse_markdown(str)
    GitHub::Markup.render('.md', str)
  end
end
