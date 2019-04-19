class Search
  attr_accessor :parsed_query
  attr_accessor :scope

  def initialize(query: '', scope:, params: {})
    @parsed_query = SearchParser.new(query)
    @scope = scope
    convert(params)
  end

  def results
    res = scope
    res = scope.search_by_subject_title(parsed_query.freetext) if parsed_query.freetext.present?
    res = res.repo(repo) if repo.present?
    res = res.exclude_repo(exclude_repo) if exclude_repo.present?
    res = res.owner(owner) if owner.present?
    res = res.exclude_owner(exclude_owner) if exclude_owner.present?
    res = res.type(type) if type.present?
    res = res.exclude_type(exclude_type) if exclude_type.present?
    res = res.reason(reason) if reason.present?
    res = res.exclude_reason(exclude_reason) if exclude_reason.present?
    res = res.label(label) if label.present?
    res = res.exclude_label(exclude_label) if exclude_label.present?
    res = res.state(state) if state.present?
    res = res.exclude_state(exclude_state) if exclude_state.present?
    res = res.author(author) if author.present?
    res = res.exclude_author(exclude_author) if exclude_author.present?
    res = res.assigned(assignee) if assignee.present?
    res = res.exclude_assigned(exclude_assignee) if exclude_assignee.present?
    res = res.status(status) if status.present?
    res = res.exclude_status(exclude_status) if exclude_status.present?
    res = res.starred(starred) unless starred.nil?
    res = res.archived(archived) unless archived.nil?
    res = res.archived(!inbox) unless inbox.nil?
    res = res.unread(unread) unless unread.nil?
    res = res.bot_author(bot_author) unless bot_author.nil?
    res = res.unlabelled unless unlabelled.nil?
    res = res.is_private(is_private) unless is_private.nil?
    res = res.draft(is_draft) unless is_draft.nil?
    res = lock_conditionally(res)
    res = mute_conditionally(res)
    res = apply_sort(res)
    res
  end

  def to_query
    query_string = @parsed_query.operators.map do |key, value|
      "#{key}:#{value.join(',')}"
    end.join(' ') + " #{@parsed_query.freetext}"

    query_string.strip
  end

  def inbox_selected?
    inbox == true && archived != true
  end

  def archive_selected?
    inbox != true && archived == true
  end

  private

  def convert(params)
    [:starred, :unlabelled, :bot].each do |param|
      @parsed_query[param] = ['true'] if params[param].present?
    end

    @parsed_query[:archived] = ['true'] if params[:archive].present?
    @parsed_query[:inbox] = ['true'] if params[:archive].blank? && params[:starred].blank? && params[:q].blank?

    [:reason, :type, :unread, :state, :is_private, :draft].each do |filter|
      next if params[filter].blank?
      @parsed_query[filter] = Array(params[filter]).map(&:underscore)
    end

    [:repo, :owner, :author, :label].each do |filter|
      next if params[filter].blank?
      @parsed_query[filter] = Array(params[filter])
    end

    @parsed_query[:assignee] = Array(params[:assigned]) if params[:assigned].present?
  end

  def lock_conditionally(scope)
    return scope if is_locked.nil?
    is_locked ? scope.locked : scope.not_locked
  end

  def mute_conditionally(scope)
    return scope if is_muted.nil?
    is_muted ? scope.muted : scope.unmuted
  end

  def apply_sort(scope)
    case sort_by
    when 'subject'
      scope.reorder("upper(notifications.subject_title) #{sort_order}")
    when 'updated'
      scope.reorder(updated_at: sort_order)
    when 'read'
      scope.reorder(last_read_at: sort_order)
    else
      scope.newest
    end
  end

  def sort_by
    parsed_query[:sort].first
  end

  def sort_order
    order = parsed_query[:order].first
    case order
    when 'asc'
      :asc
    when 'desc'
      :desc
    else
      default_sort_order
    end
  end

  def default_sort_order
    case sort_by
    when 'subject'
      :asc
    else
      :desc
    end
  end

  def repo
    parsed_query[:repo]
  end

  def exclude_repo
    parsed_query[:'-repo']
  end

  def owner
    parsed_query[:owner].presence || parsed_query[:org].presence || parsed_query[:user]
  end

  def exclude_owner
    parsed_query[:'-owner'].presence || parsed_query[:'-org'].presence || parsed_query[:'-user']
  end

  def author
    parsed_query[:author]
  end

  def exclude_author
    parsed_query[:'-author']
  end

  def unread
    boolean_prefix(:unread)
  end

  def type
    parsed_query[:type].map(&:classify)
  end

  def exclude_type
    parsed_query[:'-type'].map(&:classify)
  end

  def reason
    parsed_query[:reason].map{|r| r.downcase.tr(' ', '_') }
  end

  def exclude_reason
    parsed_query[:'-reason'].map{|r| r.downcase.tr(' ', '_') }
  end

  def state
    parsed_query[:state].map(&:downcase)
  end

  def exclude_state
    parsed_query[:'-state'].map(&:downcase)
  end

  def label
    parsed_query[:label]
  end

  def exclude_label
    parsed_query[:'-label']
  end

  def assignee
    parsed_query[:assignee]
  end

  def exclude_assignee
    parsed_query[:'-assignee']
  end

  def status
    parsed_query[:status]
  end

  def exclude_status
    parsed_query[:'-status']
  end

  def starred
    boolean_prefix(:starred)
  end

  def inbox
    boolean_prefix(:inbox)
  end

  def archived
    boolean_prefix(:archived)
  end

  def bot_author
    boolean_prefix(:bot)
  end

  def unlabelled
    boolean_prefix(:unlabelled)
  end

  def is_private
    boolean_prefix(:private)
  end

  def is_locked
    boolean_prefix(:locked)
  end

  def is_muted
    boolean_prefix(:muted)
  end

  def is_draft
    boolean_prefix(:draft)
  end

  private

  def boolean_prefix(name)
    return nil unless parsed_query[name].present?
    parsed_query[name].first.try(:downcase) == "true"
  end
end
