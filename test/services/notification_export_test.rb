require 'test_helper'

class NotificationExportTest < ActiveSupport::TestCase
  ExportableNotification = Struct.new(:json) do
    def to_json(*)
      json
    end
  end

  test 'exports notifications as a json array' do
    relation = fake_relation([
      ExportableNotification.new('{"id":1}'),
      ExportableNotification.new('{"id":2}')
    ])

    export = NotificationExport.new(relation, batch_size: 2)

    assert_equal '[{"id":1},{"id":2}]', export.each.to_a.join
    assert_equal 2, relation.batch_size
  end

  test 'exports an empty json array when there are no notifications' do
    relation = fake_relation([])

    export = NotificationExport.new(relation)

    assert_equal '[]', export.each.to_a.join
  end

  private

  def fake_relation(notifications)
    Class.new do
      attr_reader :batch_size

      define_method(:initialize) do |items|
        @items = items
      end

      define_method(:find_each) do |batch_size:, &block|
        @batch_size = batch_size
        @items.each { |item| block.call(item) }
      end
    end.new(notifications)
  end
end
