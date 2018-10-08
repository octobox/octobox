class UpdateSubjectLabelMapping < ActiveRecord::Migration[5.2]
  def change

    return if Label.count.zero?
    # this query is to find unique labels in the order they are created by grouping them on GITHUB_ID;
    # I have extracted the labels GITHUB_ID and ID to create mapping between the two.
    # I ran the inner query IN POSTGRE server to check that ORDER of labels is by created_at ASC

    records = fetch_unique_labels
    return if records.blank?

    # creating a mapping of Label GITHUB_ID and ID ordered by created_at ASC
    github_id_label_id_map = {}
    records.map { |record| github_id_label_id_map[record['github_id']] = record['id'] }

    # this query is get mapping between Labels and Repository through subjects table
    label_repo_map = {}
    label_github_ids = github_id_label_id_map.keys.join(",")

    label_repos = fetch_label_repo_mapping(label_github_ids)
    label_repos.map { |label| label_repo_map[label["github_id"]] = label["repository_id"] }

    updated_labels = []
    subject_label_records = []

    # finding labels in batches to reduce Memory footprint and also decrease the load on DB
    Label.in_batches(of: 2000) do |labels|
      labels.each do |label|
        subject_label_records << {
          label_id: github_id_label_id_map[label.github_id],
          subject_id: label.subject_id
        }
        updated_labels << {
          id: label.id,
          repository_id: label_repo_map[label.github_id]
        }
      end
    end

    # on_duplicate_key_ignore skips a record if a UNIQUE key constraint is violated
    # so if there is already a Subject and Label mapping present it will be skipped

    # this is to contain the RACE condition which can arise is their is already a record in SubjectLabel
    # table but we have generated on extra during batch processing
    SubjectLabel.import subject_label_records, on_duplicate_key_ignore: true, :batch_size => 5000
    import_labels(updated_labels)
  end
end
