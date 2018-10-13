class GeneralLinks < SidebarLinks

  GENERAL_ACTIONS = {
    'unread'       => { css_class: '',             icon: 'mail' },
    'read'         => { css_class: '',             icon: 'mail-read' },
    'assigned'     => { css_class: '',             icon: 'person' },
    'bot'          => { css_class: '',             icon: 'hubot' },
    'unlabelled'   => { css_class: '',             icon: 'tag' },
    'Public'       => { css_class: '',             icon: 'lock' },
    'Private'      => { css_class: 'private-repo', icon: 'repo' },
  }.freeze

  ACTION_TYPE_UNREAD = "unread".freeze
  ACTION_TYPE_IS_PRIVATE = "is_private".freeze

  private

    def after_init(args = {})
      @action_type = args[:action_name]
      @value = args[:value] || nil
      @count = args[:count]
      @text = args[:text]
      @query_param = args[:query_param]
      @active = active?(@action_type)
    end

    def active?(action_type)
      if action_type == ACTION_TYPE_UNREAD
        return @text == ACTION_TYPE_UNREAD ? params[action_type] == 'true' : params[action_type] == 'false'
      end
      return params[action_type].present?
    end

    def links
      content_tag(:li,
        action_link(@action_type),
        class: "nav-item",
        role: "presentation"
      )
    end

    def action_octicon(action_type)
      action_type = @text if [ACTION_TYPE_UNREAD, ACTION_TYPE_IS_PRIVATE].include?(action_type)
      octicon(
        GENERAL_ACTIONS[action_type][:icon],
        height: 16,
        class: "sidebar-icon #{GENERAL_ACTIONS[action_type][:css_class]}"
      )
    end

    def action_type_read?(action_type)
      (action_type == ACTION_TYPE_UNREAD && @text == 'read')
    end

    def action_type_public_repo?(action_type)
      (action_type == ACTION_TYPE_IS_PRIVATE && @text == 'Public')
    end

    def action_path(action_type)
      action_param = {action_type.to_sym => true}
      if action_type == 'assigned'
        action_param = {action_type.to_sym => @query_param}
      elsif action_type_read?(action_type) || action_type_public_repo?(action_type)
        action_param = {action_type.to_sym => false}
      end
      make_path({action_type: action_type, active: @active}, action_param)
    end

    def action_link(action_type)
      link_to action_path(action_type), class: "nav-link filter #{'active' if @active}" do
        concat action_octicon(action_type)
        concat @text
        concat action_badge({active: @active, count: @count})
      end
    end
end