class SecondaryLinks < SidebarLinks

  SECONDARY_ACTIONS = {
    'state_open'            => { css_class: 'text-success',         icon: 'primitive-square' },
    'state_closed'          => { css_class: 'text-danger',          icon: 'primitive-square' },
    'state_merged'          => { css_class: 'text-subscribed',      icon: 'primitive-square' },
    'state_success'         => { css_class: 'text-secondary',       icon: 'primitive-square' },
    'state_failure'         => { css_class: 'text-secondary',       icon: 'primitive-square' },
    'status_success'        => { css_class: 'text-success',         icon: 'check' },
    'status_failure'        => { css_class: 'text-failure',         icon: 'x' },
    'status_error'          => { css_class: 'text-error',           icon: 'alert' },
    'status_pending'        => { css_class: 'text-pending',         icon: 'primitive-dot' },
    'reason_comment'        => { css_class: 'text-primary',         icon: 'primitive-dot' },
    'reason_author'         => { css_class: 'text-success',         icon: 'primitive-dot' },
    'reason_state_change'   => { css_class: 'text-info',            icon: 'primitive-dot' },
    'reason_mention'        => { css_class: 'text-warning',         icon: 'primitive-dot' },
    'reason_assign'         => { css_class: 'text-danger',          icon: 'primitive-dot' },
    'reason_subscribed'     => { css_class: 'text-subscribed',      icon: 'primitive-dot' },
    'reason_team_mention'   => { css_class: 'text-team_mention',    icon: 'primitive-dot' },
    'reason_security_alert' => { css_class: 'text-security_alert',  icon: 'primitive-dot' },
    'type_Issue'            => { css_class: '',                     icon: 'issue-opened' },
    'type_PullRequest'      => { css_class: '',                     icon: 'git-pull-request' },
    'type_Commit'           => { css_class: '',                     icon: 'git-commit' },
    'type_Release'          => { css_class: '',                     icon: 'tag' },
    'type_RepositoryVulnerabilityAlert' => { css_class: '',         icon: 'alert' },
    'type_RepositoryInvitation'         => { css_class: '',         icon: 'mail-read' },
  }.freeze

  private

    def after_init(args = {})
      @action_types = args[:action_types]
      @action_name = args[:action_name]
    end

    def active?(action_type)
      params[@action_name].present? && params[@action_name] == action_type
    end

    def links
      html = ""
      @action_types.sort_by { |action_type, count| action_type.to_s }.reverse_each do |action_type, count|
        next if action_type.nil?
        html << content_tag(:li,
          action_link(action_type, count),
          class: "nav-item #{'active' if active?(action_type)}",
          role: "presentation"
        )
      end

      return content_tag(:ul, html.html_safe, class: "nav nav-pills flex-column nav-filters")
    end

    def action_octicon(action_type)
      octicon_type = "#{@action_name}_#{action_type}"
      if SECONDARY_ACTIONS[octicon_type].nil?
        content_tag(:span, '', class: 'sidebar-icon')
      else
        octicon(
          SECONDARY_ACTIONS[octicon_type][:icon],
          height: octicon_height(@action_name),
          class: "sidebar-icon #{SECONDARY_ACTIONS[octicon_type][:css_class]} #{action_type}"
        )
      end
    end

    def action_path(action_type)
      make_path({action_type: @action_name, active: active?(action_type)}, {@action_name.to_sym => action_type})
    end

    def action_link(action_type, count)
      link_to action_path(action_type), class: "nav-link filter #{'active' if active?(action_type)}" do
        concat action_octicon(action_type)
        concat action_type.underscore.gsub('repository', ' ').humanize
        concat action_badge({active: active?(action_type), count: count})
      end
    end
end
