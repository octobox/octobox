class ErrorsController < ApplicationController
  def unprocessable
    render status: 422
  end
end
