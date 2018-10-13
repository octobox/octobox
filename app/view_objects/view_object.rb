require "octicons_helper"

class ViewObject
  attr_reader :context

  include Rails.application.routes.url_helpers
  include ActionView::Helpers
  include ActionView::Context
  include OcticonsHelper

  delegate :params, :controller_name, :controller_path, :action_name, :to => :context

  def initialize(context, args = {})
    @context ||= context
    after_init(args)
  end

  def after_init(args = {})
  end
end