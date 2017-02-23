module NotificationsHelper
  REASON_LABELS = {
    'comment'      => 'primary',
    'author'       => 'success',
    'state_change' => 'info',
    'mention'      => 'warning',
    'assign'       => 'danger',
    'subscribed'   => 'subscribed',
    'team_mention' => 'team_mention'
  }.freeze

  SUBJECT_TYPES = {
    'RepositoryInvitation' => 'mail-read',
    'Issue'                => 'issue-opened',
    'PullRequest'          => 'git-pull-request',
    'Commit'               => 'git-commit',
    'Release'              => 'tag'
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
      q:        params[:q]
    }
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
    function_button('Mute selected', 'mute', 'mute_selected') unless params[:archive]
  end

  def mark_read_selected_button
    function_button('Mark as read', 'eye', 'mark_read_selected')
  end

  def archive_selected_button
    action = params[:archive] ? 'unarchive' : 'archive'
    function_button("#{action.capitalize} selected", 'checklist', "archive_toggle #{action}_selected")
  end

  def select_all_button(cur_selected, total)
    button_tag(type: 'button', class: "select_all btn btn-default hidden", 'data-toggle': "tooltip", 'data-placement': "top", 'title': "Number of items selected") do
      octicon('check', height: 16) +
        content_tag(:span, " #{cur_selected}", class: 'bold hidden-xs') +
        " |" +
        content_tag(:span, " #{total}", class: 'hidden-xs')
    end if cur_selected < total
  end

  def function_button(title, octicon, css_class)
    button_tag(type: 'button', class: "#{css_class} btn btn-default hidden") do
      octicon(octicon, height: 16) + content_tag(:span, " #{title}", class: 'hidden-xs')
    end
  end

  def no_url_filter_parameters_present
    notification_param_keys.all?{|param| params[param].blank? }
  end

  def notification_icon(subject_type)
    SUBJECT_TYPES[subject_type]
  end

  def reason_label(reason)
    REASON_LABELS.fetch(reason, 'default')
  end

  def filter_option(param, &block)
    if filters[param].present?
      link_to root_path(filters.except(param)), class: "btn btn-default" do
        concat octicon('x', :height => 16)
        concat ' '
        concat block.call
      end
    end
  end

  def filter_link(param, value, count, &block)
    sidebar_filter_link(params[param] == value.to_s, param, value, count) do
      block.call
    end
  end

  def org_filter_link(param, value, count, &block)
    sidebar_filter_link(params[param] == value.to_s, param, value, nil, :repo, 'owner-label') do
      block.call
    end
  end

  def repo_filter_link(param, value, count, &block)
    active = params[param] == value || params[:owner] == value.split('/')[0]
    sidebar_filter_link(active, param, value, count, :owner, 'repo-label') do
      block.call
    end
  end

  def sidebar_filter_link(active, param, value, count, except = nil, link_class = nil, &block)
    content_tag :li, class: (active ? 'active' : '') do
      active = (active && not_repo_in_active_org(param))
      link_to root_path(filtered_params(param => (active ? nil : value)).except(except)), class: "filter #{link_class}" do
        block.call
        if active && not_repo_in_active_org(param)
          concat content_tag(:span, octicon('x', :height => 16), class: 'label text-muted')
        elsif count.present?
          concat content_tag(:span, count, class: 'label label-muted')
        end
      end
    end
  end

  def not_repo_in_active_org(param)
    return true unless param == :repo
    !params[:owner].present?
  end
end
