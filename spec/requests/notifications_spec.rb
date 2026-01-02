require 'rails_helper'

RSpec.describe "Notifications", type: :request do
  let(:user) { create(:user) }
  let(:notification) do
    user.notifications.create!(
      category: 'itinerary',
      title: '机票出票成功',
      content: '您购买的深圳-北京 CA1234已出票，点击查看详情',
      read: false
    )
  end

  before do
    sign_in_as(user)
  end

  describe "GET /notifications/:id" do
    it "returns http success" do
      get notification_path(notification)
      expect(response).to have_http_status(:success)
    end

    it "marks notification as read" do
      expect(notification.read).to be false
      get notification_path(notification)
      notification.reload
      expect(notification.read).to be true
    end

    it "displays notification details" do
      get notification_path(notification)
      expect(response.body).to include('机票出票成功')
      expect(response.body).to include('您购买的深圳-北京 CA1234已出票，点击查看详情')
    end
  end

  describe "PATCH /notifications/:id/mark_as_read" do
    it "marks notification as read" do
      expect(notification.read).to be false
      patch mark_as_read_notification_path(notification)
      notification.reload
      expect(notification.read).to be true
    end

    it "redirects back" do
      patch mark_as_read_notification_path(notification)
      expect(response).to have_http_status(:redirect)
    end
  end
end
