class ErrorsController < ApplicationController
  def unprocessable
    render status: 422
  end
  def internal
    render status: 500
  end
end
