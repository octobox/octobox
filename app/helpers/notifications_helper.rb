module NotificationsHelper
  REASON_LABELS = {
    'comment'      => 'primary',
    'author'       => 'success',
    'state_change' => 'info',
    'mention'      => 'warning',
    'assign'       => 'danger'
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

  def mute_selected_button(custom_class=nil)
    unless params[:archive]
      button_tag(type: 'button', class: "mute_selected #{custom_class}") do
        'Mute Selected'
      end
    end
  end

  def archive_selected_button(custom_class=nil)
    action = params[:archive] ? 'unarchive' : 'archive'
    button_tag(type: "button",
               class: "archive_toggle #{action}_selected #{custom_class}") do
      "#{action} selected".capitalize
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
end
