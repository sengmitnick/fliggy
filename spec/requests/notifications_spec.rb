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

  describe "GET /notifications/:category" do
    context "with valid category" do
      before do
        # Create multiple notifications for testing
        5.times do |i|
          user.notifications.create!(
            category: 'itinerary',
            title: "酒店预订确认通知 ##{i + 1}",
            content: "您的酒店预订已确认，订单号：#{12345600 + i}",
            read: false
          )
        end
      end

      it "returns http success" do
        get category_notifications_path('itinerary')
        expect(response).to have_http_status(:success)
      end

      it "displays all notifications for the category" do
        get category_notifications_path('itinerary')
        expect(response.body).to include('行程服务')
        expect(response.body).to include('酒店预订确认通知 #1')
        expect(response.body).to include('酒店预订确认通知 #5')
      end

      it "marks all unread notifications as read" do
        expect(user.notifications.by_category('itinerary').unread.count).to eq(5)
        get category_notifications_path('itinerary')
        expect(user.notifications.by_category('itinerary').unread.count).to eq(0)
      end

      it "supports pagination for large result sets" do
        # Create exactly 25 notifications to test pagination (already has 5 from before block)
        20.times do |i|
          user.notifications.create!(
            category: 'itinerary',
            title: "酒店预订确认通知 ##{i + 6}",
            content: "您的酒店预订已确认，订单号：#{12345605 + i}",
            read: false
          )
        end

        # Should have 25 total notifications now (5 from before + 20 new)
        expect(user.notifications.by_category('itinerary').count).to eq(25)
        
        get category_notifications_path('itinerary')
        # Verify all notifications are accessible
        expect(response.body).to include('酒店预订确认通知 #1')
      end
    end

    context "with invalid category" do
      it "redirects to messages page with error" do
        get category_notifications_path('invalid_category')
        expect(response).to redirect_to(messages_path)
        follow_redirect!
        expect(response.body).to include('无效的消息分类')
      end
    end

    context "with empty category" do
      it "displays empty state" do
        get category_notifications_path('account')
        expect(response).to have_http_status(:success)
        expect(response.body).to include('暂无消息')
      end
    end
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
