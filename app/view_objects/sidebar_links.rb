class SidebarLinks < ViewObject

  ALL_FILTERS = [
                  :reason, :unread, :repo, :type, :archive, :starred, :owner, :per_page, :q, :bot,
                  :state, :label, :author, :unlabelled, :assigned, :is_private, :status, :snoozed
                ]

  OCTICON_HEIGHT_24 = [:state, :reason]

  def html
    links.html_safe
  end

  private

    def make_path(options = {}, action_param = {})
      if options[:active]
        root_path(filtered_params.except!(options[:action_type].to_sym))
      elsif options[:primary]
        root_path(action_param)
      else
        root_path(filtered_params.merge!(action_param))
      end
    end

    def filtered_params
      filters = {}
      ALL_FILTERS.map { |filter_type| filters[filter_type] = params[filter_type] if params[filter_type].present? }
      filters
    end

    def action_badge(options = {})
      if (options[:primary] && options[:active]) || (!options[:active] && !options[:primary])
        content_tag(:span, options[:count], class: "badge badge-light")
      elsif options[:active]
        content_tag(:span, octicon('x', height: 16), class: 'badge badge-light')
      end
    end

    def links
      raise NotImplementedError
    end

    def active?(action_type)
      raise NotImplementedError
    end

    def octicon_height(action_type)
      OCTICON_HEIGHT_24.include?(action_type) ? 24 : 16
    end

    def action_octicon(action_type)
      raise NotImplementedError
    end

    def action_path(action_type)
      raise NotImplementedError
    end

    def action_link(action_type)
      raise NotImplementedError
    end
end