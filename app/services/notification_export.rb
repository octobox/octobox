# frozen_string_literal: true

class NotificationExport
  BATCH_SIZE = 1_000

  def initialize(notifications, batch_size: BATCH_SIZE)
    @notifications = notifications
    @batch_size = batch_size
  end

  def each
    return enum_for(:each) unless block_given?

    first = true

    yield '['
    notifications.find_each(batch_size: batch_size) do |notification|
      yield ',' unless first
      yield notification.to_json
      first = false
    end
    yield ']'
  end

  private

  attr_reader :notifications, :batch_size
end
