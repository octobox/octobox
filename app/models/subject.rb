class Subject < ApplicationRecord
  has_many :notifications, foreign_key: :subject_url, primary_key: :url

  has_many :subject_labels, :dependent => :destroy
  has_many :labels, :through => :subject_labels

  has_many :users, through: :notifications
  belongs_to :repository, foreign_key: :repository_full_name, primary_key: :full_name, optional: true

  BOT_AUTHOR_REGEX = /\A(.*)\[bot\]\z/.freeze
  private_constant :BOT_AUTHOR_REGEX

  scope :label, ->(label_name) { joins(:labels).where(Label.arel_table[:name].matches(label_name)) }
  scope :repository, ->(full_name) { where(arel_table[:url].matches("%/repos/#{full_name}/%")) }

  validates :url, presence: true, uniqueness: true

  after_update :sync_involved_users

  def author_url
    "#{Octobox.config.github_domain}#{author_url_path}"
  end

  def update_labels(remote_labels)
    existing_labels = Label.select('repository_id, github_id').where(
      'github_id in (?) and repository_id = ?', remote_labels.map{|l| l['id'] }, repository.id
    )

    new_labels = remote_labels.select{ |l| existing_labels.collect(&:github_id).exclude?(l['id']) }
    updated_labels = (remote_labels-new_labels).each do |label|
      if matching_label = existing_labels.select { |l| l.github_id == label['id'] }
        label['db_id'] = matching_label.id
      end
    end

    add_labels_to_repository(new_labels)
    modify_labels(updated_labels)
    detach_removed_subject_labels(remote_labels.map{|l| l['id'] })
  end

  def sync_involved_users
    return unless Octobox.github_app?
    involved_user_ids.each { |user_id| SyncNotificationsWorker.perform_in(1.minute, user_id) }
  end

  def self.sync(remote_subject)
    subject = Subject.find_or_create_by(url: remote_subject['url'])

    # webhook payloads don't always have 'repository' info
    if remote_subject['repository']
      full_name = remote_subject['repository']['full_name']
    else
      full_name = extract_full_name(remote_subject['url'])
    end

    subject.update({
      repository_full_name: full_name,
      github_id: remote_subject['id'],
      state: remote_subject['merged_at'].present? ? 'merged' : remote_subject['state'],
      author: remote_subject['user']['login'],
      html_url: remote_subject['html_url'],
      created_at: remote_subject['created_at'],
      updated_at: remote_subject['updated_at'],
      assignees: ":#{Array(remote_subject['assignees'].try(:map) {|a| a['login'] }).join(':')}:",
      locked: remote_subject['locked']
    })
    subject.update_labels(remote_subject['labels']) if remote_subject['labels'].present?
    subject.sync_involved_users
  end

  private

  def add_labels_to_repository(labels_to_be_added)
    labels_to_be_added.map! {
      |l| Label.new(github_id: l['id'], color: l['color'], name: l['name'], repository: repository)
    }
    Label.import labels_to_be_added
    attach_label_to_subject(labels_to_be_added.select{|label| label['id']})
  end

  def modify_labels(labels_to_be_updated)
    labels_to_be_updated.map! { |l|
      Label.new(id: l['db_id'], github_id: l['id'], color: l['color'], name: l['name'], repository: repository)
    }
    Label.import labels_to_be_updated, on_duplicate_key_update: [:color, :github_id, :name]
  end

  def attach_label_to_subject(label_github_ids)
    labels = Label.select('id').where('github_id in (?)', label_github_ids)
    labels.map!{ |label_id| SubjectLabel.new(subject_id: self.id, label: label_id) }
    SubjectLabel.import labels
  end

  def detach_removed_subject_labels(remote_label_ids)
    labels_to_be_deleted = subject_labels.to_a.reject{ |l| remote_label_ids.include?(l.github_id) }
    labels_to_be_deleted.destroy_all
  end

  def self.extract_full_name(url)
    url.match(/\/repos\/([\w.-]+\/[\w.-]+)\//)[1]
  end

  def involved_user_ids
    ids = users.pluck(:id)
    ids += repository.users.not_recently_synced.pluck(:id) if repository.present?
    ids.uniq
  end

  def author_url_path
    if bot_author?
      "/apps/#{BOT_AUTHOR_REGEX.match(author)[1]}"
    else
      "/#{author}"
    end
  end

  def bot_author?
    BOT_AUTHOR_REGEX.match?(author)
  end
end
