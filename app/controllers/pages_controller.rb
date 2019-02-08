# frozen_string_literal: true
class PagesController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :check_octobox_io, only: [:pricing, :privacy, :terms]
end
