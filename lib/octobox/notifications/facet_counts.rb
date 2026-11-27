module Octobox
  module Notifications
    module FacetCounts
      extend ActiveSupport::Concern

      ATTRIBUTE_FACETS = %w[subject_type unread reason repository_full_name].freeze
      SUBJECT_FACETS = %w[state status].freeze
      DISTINCT_COUNT = 'COUNT(DISTINCT notifications.id)'.freeze

      class_methods do
        def attribute_facet_counts
          counts, _totals = grouping_set_counts(ATTRIBUTE_FACETS.map { |column| "notifications.#{column}" })
          ATTRIBUTE_FACETS.map(&:to_sym).zip(counts).to_h
        end

        def subject_facet_counts(github_login)
          filters = {
            draft: 'subjects.draft',
            bot: "subjects.author LIKE '%[bot]' OR subjects.author LIKE '%-bot'",
            assigned: sanitize_sql_array(['subjects.assignees ILIKE ?', "%:#{github_login}:%"]),
            unlabelled: "notifications.subject_type IN ('Issue', 'PullRequest') AND NOT EXISTS (SELECT 1 FROM labels WHERE labels.subject_id = subjects.id)"
          }
          counts, totals = joins(:subject).grouping_set_counts(SUBJECT_FACETS.map { |column| "subjects.#{column}" }, filters.values)
          SUBJECT_FACETS.map(&:to_sym).zip(counts).to_h.merge(filters.keys.zip(totals).to_h)
        end

        # Counts every column's groups in one pass with GROUPING SETS. Each filter
        # is counted over the whole relation and returned in the second element.
        def grouping_set_counts(columns, filters = [])
          relation = reorder(nil)
          # pluck would otherwise join every included association
          relation = relation.unscope(:includes) unless relation.eager_loading?

          sets = columns.map { |column| "(#{column})" }
          sets << '()' if filters.any?
          selects = ["GROUPING(#{columns.join(', ')})", *columns, DISTINCT_COUNT]
          selects.concat(filters.map { |filter| "#{DISTINCT_COUNT} FILTER (WHERE #{filter})" })

          rows = relation.group(Arel.sql("GROUPING SETS (#{sets.join(', ')})")).pluck(*selects.map { |sql| Arel.sql(sql) })

          counts = columns.map { {} }
          totals = Array.new(filters.size, 0)
          rows.each do |grouping, *values|
            # GROUPING sets a bit for each column left out of the row's grouping set
            index = columns.each_index.find { |i| grouping[columns.size - 1 - i].zero? }
            if index
              counts[index][values[index]] = values[columns.size]
            else
              totals = values.drop(columns.size + 1)
            end
          end
          [counts, totals]
        end
      end
    end
  end
end
