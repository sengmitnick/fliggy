class Api::MembershipsController < ApplicationController
  before_action :authenticate_user!

  def check
    flight_id = params[:flight_id]
    
    if flight_id.blank?
      render json: { is_member: false }, status: :ok
      return
    end
    
    flight = Flight.find_by(id: flight_id)
    
    if flight.nil?
      render json: { is_member: false }, status: :ok
      return
    end
    
    # 检查当前用户是否为该航空公司的会员
    # 这里使用 User 模型中的 airline_member 字段
    # 实际项目中，可能需要根据具体的航空公司来检查会员状态
    is_member = current_user.airline_member || false
    
    render json: { is_member: is_member }, status: :ok
  end
end
