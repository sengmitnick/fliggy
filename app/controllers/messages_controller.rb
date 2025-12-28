class MessagesController < ApplicationController

  def index
    @full_render = true
    if current_user
      # 已登录用户：加载真实通知数据
      @notifications_by_category = Notification::CATEGORIES.keys.map do |category|
        notifications = current_user.notifications.by_category(category).recent.limit(1)
        latest = notifications.first
        unread_count = current_user.notifications.by_category(category).unread.count
        
        {
          category: category,
          display_name: Notification::CATEGORIES[category],
          latest_notification: latest,
          unread_count: unread_count,
          has_messages: latest.present?
        }
      end
      
      @total_unread = current_user.notifications.unread.count
    else
      # 未登录用户：显示演示数据
      @notifications_by_category = [
        { category: 'group', display_name: '群聊广场', latest_notification: nil, unread_count: 0, has_messages: false },
        { category: 'folded', display_name: '折叠的消息', latest_notification: OpenStruct.new(title: '纽约打卡清单✅', created_at: Time.current, read: false), unread_count: 1, has_messages: true },
        { category: 'interactive', display_name: '互动消息', latest_notification: OpenStruct.new(title: '特价机票群入群邀请', created_at: Time.current - 5.hours, read: false), unread_count: 1, has_messages: true },
        { category: 'member', display_name: '会员消息', latest_notification: OpenStruct.new(title: '里程账户变动提醒', created_at: Date.new(2025, 12, 18), read: true), unread_count: 0, has_messages: true },
        { category: 'itinerary', display_name: '行程服务', latest_notification: OpenStruct.new(title: '机票出票成功', created_at: Date.new(2025, 12, 15), read: true), unread_count: 0, has_messages: true },
        { category: 'account', display_name: '账户通知', latest_notification: OpenStruct.new(title: '奖励变动通知、返现到账提醒', created_at: nil, read: true), unread_count: 0, has_messages: true },
        { category: 'hotel', display_name: '国际酒店消息', latest_notification: OpenStruct.new(title: '查看您咨询的国际酒店消息', created_at: nil, read: true), unread_count: 0, has_messages: true },
        { category: 'subscription', display_name: '订阅消息', latest_notification: OpenStruct.new(title: '你主动设置的消息提醒', created_at: nil, read: true), unread_count: 0, has_messages: true }
      ]
      @total_unread = 1
    end
  end

  private
  # Write your private methods here
end
