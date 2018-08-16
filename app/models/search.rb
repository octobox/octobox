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
    res = res.starred(starred) unless starred.nil?
    res = res.archived(archived) unless archived.nil?
    res = res.unread(unread) unless unread.nil?
    res = res.bot_author unless bot_author.nil?
    res = res.unlabelled unless unlabelled.nil?
    res
  end

  private

  def repo
    parsed_query[:repo].first
  end

  def owner
    parsed_query[:owner].first
  end

  def author
    parsed_query[:author].first
  end

  def unread
    return nil unless parsed_query[:unread].present?
    parsed_query[:unread].first.downcase == "true"
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
    parsed_query[:label].first
  end

  def starred
    return nil unless parsed_query[:starred].present?
    parsed_query[:starred].first.try(:downcase) == "true"
  end

  def archived
    return nil unless parsed_query[:archived].present?
    parsed_query[:archived].first.downcase == "true"
  end

  def bot_author
    return nil unless parsed_query[:bot].present?
    parsed_query[:bot].first.downcase == "true"
  end

  def unlabelled
    return nil unless parsed_query[:unlabelled].present?
    parsed_query[:unlabelled].first.downcase == "true"
  end
end
