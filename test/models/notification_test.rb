require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  test 'is invalid without required associations' do
    notification = Notification.new

    assert_not notification.valid?
    assert_includes notification.errors.attribute_names, :user
    assert_includes notification.errors.attribute_names, :post
  end
end
