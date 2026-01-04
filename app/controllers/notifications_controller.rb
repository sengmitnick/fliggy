class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def category
    @category = params[:category]
    unless Notification::CATEGORIES.keys.include?(@category)
      redirect_to messages_path, alert: '无效的消息分类'
      return
    end

    @category_name = Notification::CATEGORIES[@category]
    @notifications = current_user.notifications.by_category(@category).recent.page(params[:page]).per(20)
    
    # Mark all as read when viewing category
    current_user.notifications.by_category(@category).unread.update_all(read: true)
  end

  def show
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_read! unless @notification.read?
  end

  def mark_as_read
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_read!
    redirect_back(fallback_location: messages_path, notice: '已标记为已读')
  end

  private
  # Write your private methods here
end
