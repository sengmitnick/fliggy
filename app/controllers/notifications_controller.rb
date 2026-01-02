class NotificationsController < ApplicationController
  before_action :authenticate_user!

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
