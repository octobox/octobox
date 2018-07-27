# frozen_string_literal: true
class PagesController < ApplicationController
  skip_before_action :authenticate_user!
end
