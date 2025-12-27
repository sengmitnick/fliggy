class Api::MembershipsController < ApplicationController
  before_action :authenticate_user!

  def check
    flight_id = params[:flight_id]
    return_flight_id = params[:return_flight_id]
    
    if flight_id.blank?
      render json: { is_member: false, missing_airlines: [] }, status: :ok
      return
    end
    
    # 收集需要检查的所有航空公司
    airlines_to_check = []
    
    # 检查去程航班
    flight = Flight.find_by(id: flight_id)
    if flight.present?
      airlines_to_check << flight.airline
    end
    
    # 检查回程航班（如果是往返机票）
    if return_flight_id.present?
      return_flight = Flight.find_by(id: return_flight_id)
      if return_flight.present?
        airlines_to_check << return_flight.airline
      end
    end
    
    # 去重
    airlines_to_check.uniq!
    
    # 如果没有找到有效的航班，返回非会员
    if airlines_to_check.empty?
      render json: { is_member: false, missing_airlines: [] }, status: :ok
      return
    end
    
    # 检查用户是否是所有相关航空公司的会员
    missing_airlines = current_user.missing_memberships(airlines_to_check)
    is_member = missing_airlines.empty?
    
    render json: { 
      is_member: is_member, 
      missing_airlines: missing_airlines,
      checked_airlines: airlines_to_check
    }, status: :ok
  end
end
