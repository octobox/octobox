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
      status:   params[:status],
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
      link_to root_path(filters.except(param)), class: 'btn btn-default' do
        concat octicon('x', :height => 16)
        concat ' '
        concat block.call
      end
    end
  end
end
