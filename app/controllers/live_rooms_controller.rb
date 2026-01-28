class LiveRoomsController < ApplicationController
  before_action :authenticate_user!, only: [:follow, :unfollow]

  def index
    @live_room = LiveRoom.new(
      name: "旅游环境01 直播间",
      host_name: "飞鱼旅行",
      viewer_count: 32000
    )
    
    @live_products = LiveProduct.where(live_room_name: @live_room.name)
                                .order(:position)
                                .includes(:productable)
                                
    @is_following = @live_room.followed_by?(Current.user)
  end
  
  def follow
    @live_room_name = params[:id]
    
    # Check if already following
    existing_follow = Follow.find_by(
      user: Current.user,
      followable_type: "LiveRoom",
      followable_id: @live_room_name
    )
    
    if existing_follow
      respond_to do |format|
        format.json { render json: { error: "已经关注过了" }, status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash-messages", partial: "shared/flash_messages", locals: { flash: { alert: "已经关注过了" } }) }
        format.html { redirect_to live_rooms_path, alert: "已经关注过了" }
      end
      return
    end
    
    Follow.create!(
      user: Current.user,
      followable_type: "LiveRoom",
      followable_id: @live_room_name
    )
    
    respond_to do |format|
      format.json { render json: { success: true, is_following: true } }
      format.turbo_stream { render turbo_stream: turbo_stream.replace("follow-button-#{@live_room_name}", partial: "live_rooms/follow_button", locals: { live_room_name: @live_room_name, is_following: true }) }
      format.html { redirect_to live_rooms_path, notice: "关注成功" }
    end
  end
  
  def unfollow
    @live_room_name = params[:id]
    
    follow = Follow.find_by(
      user: Current.user,
      followable_type: "LiveRoom",
      followable_id: @live_room_name
    )
    
    follow.destroy if follow
    
    respond_to do |format|
      format.json { render json: { success: true, is_following: false } }
      format.turbo_stream { render turbo_stream: turbo_stream.replace("follow-button-#{@live_room_name}", partial: "live_rooms/follow_button", locals: { live_room_name: @live_room_name, is_following: false }) }
      format.html { redirect_to live_rooms_path, notice: "取消关注成功" }
    end
  end

  private
  # Write your private methods here
end
