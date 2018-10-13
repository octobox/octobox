class PrimaryLinks < SidebarLinks

  PRIMARY_ACTIONS = {
    inbox:   { css_class: 'text-primary', icon: 'inbox' },
    archive: { css_class: 'text-success', icon: 'archive' },
    starred: { css_class: 'star-active',  icon: 'star' },
    snoozed: { css_class: 'text-danger',  icon: 'clock' }
  }.freeze

  private

    def after_init(args = {})
      @unread_notifications = args[:unread_notifications]
    end

    def links
      html = ""
      PRIMARY_ACTIONS.keys.each do |action_type|
        html << content_tag(:li,
          action_link(action_type),
          class: "nav-item",
          role: "presentation"
        )
      end
      return content_tag(:ul, html.html_safe, class: "nav nav-pills flex-column nav-filters")
    end

    def active?(action_type)
      if action_type == :inbox
        params[:archive].blank? && params[:starred].blank? && params[:snoozed].blank? && params[:q].blank?
      else
        params[action_type].present?
      end
    end

    def action_octicon(action_type)
      octicon(
        PRIMARY_ACTIONS[action_type][:icon],
        height: 16,
        class: "sidebar-icon #{PRIMARY_ACTIONS[action_type][:css_class]}"
      )
    end

    def action_path(action_type)
      if action_type == :inbox
        make_path({primary: true})
      else
        make_path({primary: true}, {action_type.to_sym => true})
      end
    end

    def action_link(action_type)
      link_to action_path(action_type), class: "nav-link  #{'active' if active?(action_type)}" do
        concat action_octicon(action_type)
        concat action_type.to_s.titleize
        concat action_badge({primary: true, count: @unread_notifications.sum(&:last), active: active?(action_type)})
      end
    end
end
