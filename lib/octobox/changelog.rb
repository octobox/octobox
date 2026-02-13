module Octobox
  class Changelog
    BASE = /Bump (?<name>.+?) from (?<from>.+?) to (?<to>.+?)/
    BUMP_DEP_REGEX = /#{BASE}$/
    BUMP_DEP_WITH_PR_REGEX = /#{BASE} \((?<pr>#\d+)\)/

    def generate
      puts "Updating the repository"
      system("git fetch origin main 2>&1 > /dev/null")

      puts "=" * 80
      puts "We will be be basing this release on:"
      puts "  Current Commit: #{current_sha[0..6]}"
      puts "  Previous Release: #{previous_release}"

      if current_sha[0..6] == previous_release
        puts "=" * 80
        puts "We have already released #{current_sha}. Exiting"
        exit 1
      end

      changes = { dependencies: {}, other: [] }
      messages.each do |message|
        next if message.include?('Merge pull request') || message == 'Update dependencies'

        case message
        when /^Bump/
          has_pr = message.include?('(#')
          message_match = has_pr ? message.match(BUMP_DEP_WITH_PR_REGEX) : message.match(BUMP_DEP_REGEX)
          curr = changes[:dependencies][message_match[:name]] || {}
          # Between the last "to" and the current "to", we want the maximum version we updated to
          to = [curr[:to], message_match[:to]].compact.max_by { |t| Gem::Version.new(t) }
          # Between the last "from" and the current "from", we want the minimum version we updated from
          from = [curr[:from], message_match[:from]].compact.min_by { |t| Gem::Version.new(t) }
          # Combine the PRs
          prs = [curr[:prs], has_pr ? message_match[:pr] : nil].flatten.compact.sort
          changes[:dependencies][message_match[:name]] = { to: to, from: from, prs: prs }
        else
          changes[:other] << message
        end
      end

      output_final_message(changes)
    end

    def previous_release
      @previous_release ||= `git tag --sort=committerdate 2> /dev/null`.split("\n").last.chomp
    end

    def actual_sha
      @actual_sha ||= `git rev-list -n 1 #{previous_release} 2> /dev/null`.lines.last.chomp
    end

    def current_sha
      @current_sha ||= `git rev-parse --verify HEAD 2> /dev/null`.chomp
    end

    def messages
      @messages = begin
        msgs = `git log --oneline --pretty=format:"%s" --abbrev-commit #{previous_release}..#{current_sha} 2> /dev/null`
        msgs.lines.map(&:chomp)
      end
    end

    def output_final_message(changes)
      puts "=" * 80
      puts <<~EOF
      The following release message was auto generated based on the above information.
      Please make sure it is correct.
      EOF
      puts "=" * 80

      deps = changes[:dependencies].sort_by { |k, _| k }.map.with_object([]) do |(dep, change), acc|
        acc << "Updated #{dep} from #{change[:from]} to #{change[:to]} (#{change[:prs].join(', ')})"
      end
      final_message = <<~EOF
      Dependency Updates
      ---
      - #{deps.join("\n- ")}

      Other
      ---
      - #{changes[:other].join("\n- ")}

      ---

      Full diff: https://github.com/octobox/octobox/compare/#{actual_sha[0..6]}...#{current_sha[0..6]}
      EOF
      puts final_message
    end
  end
end
