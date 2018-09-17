class Search
  attr_accessor :parsed_query
  attr_accessor :scope

  def initialize(query: '', scope:)
    @parsed_query = SearchParser.new(query)
    @scope = scope
  end

  def results
    res = scope
    res = scope.search_by_subject_title(parsed_query.freetext) if parsed_query.freetext.present?
    res = res.repo(repo) if repo.present?
    res = res.owner(owner) if owner.present?
    res = res.type(type) if type.present?
    res = res.reason(reason) if reason.present?
    res = res.label(label) if label.present?
    res = res.state(state) if state.present?
    res = res.author(author) if author.present?
    res = res.assigned(assignee) if assignee.present?
    res = res.starred(starred) unless starred.nil?
    res = res.archived(archived) unless archived.nil?
    res = res.archived(!inbox) unless inbox.nil?
    res = res.unread(unread) unless unread.nil?
    res = res.bot_author unless bot_author.nil?
    res = res.unlabelled unless unlabelled.nil?
    res = res.is_private(is_private) unless is_private.nil?
    res = lock_conditionally(res)
    res = mute_conditionally(res)
    res = apply_sort(res)
    res
  end

  private

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

  def owner
    parsed_query[:owner]
  end

  def author
    parsed_query[:author]
  end

  def unread
    boolean_prefix(:unread)
  end

  def type
    parsed_query[:type].map(&:classify)
  end

  def reason
    parsed_query[:reason].map{|r| r.downcase.gsub(' ', '_') }
  end

  def state
    parsed_query[:state].map(&:downcase)
  end

  def label
    parsed_query[:label]
  end

  def assignee
    parsed_query[:assignee]
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

  private

  def boolean_prefix(name)
    return nil unless parsed_query[name].present?
    parsed_query[name].first.try(:downcase) == "true"
  end
end
