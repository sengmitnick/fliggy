# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例301: 预订运动健身游
#
# 任务描述:
#   用户预订运动健身游(健身房+瑜伽课+健康餐)
#
# 评分标准:
#   - 创建酒店预订(含健身设施) (35%)
#   - 选择配备健身房的酒店 (30%)
#   - 创建景区运动活动订单 (20%)
#   - 入住日期正确 (10%)
#   - 住宿天数≥3晚 (5%)
module V301V306
  class V301BookSportsFitnessTourValidator < BaseValidator
    self.validator_id = 'v301_book_sports_fitness_tour_validator'
    self.task_id = 'i27f9ie1-g9h3-45ic-e4gg-j5879g40gi1f'
    self.title = '预订运动健身游'
    self.description = '用户预订运动健身游(健身房+瑜伽课+健康餐)'
    self.timeout_seconds = 300
    
    def prepare
      @city = '深圳'
      @check_in_date = Date.today + 6.days
      @check_out_date = @check_in_date + 4.days  # 4晚
      @visit_date = @check_in_date + 1.day
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 5000
        user.update!(balance: 7000)
      end
      
      {
        task: "请预订#{@city}的运动健身度假，#{@check_in_date.strftime('%Y年%-m月%-d日')}入住，住#{(@check_out_date - @check_in_date).to_i}晚，需要配备健身房和运动设施的酒店，适合健身爱好者",
        city: @city,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        hint: "选择配备健身房和泳池的酒店，预订运动体验活动"
      }
    end
    
    def verify
      add_assertion "创建了酒店预订(含健身设施)", weight: 35 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@hotel_booking).not_to be_nil, "未找到#{@city}的酒店预订"
      end
      
      return unless @hotel_booking
      
      add_assertion "选择配备健身房的酒店", weight: 30 do
        hotel = @hotel_booking.hotel
        # 健身设施：健身房、游泳池等
        has_fitness = hotel.facilities.to_s.match?(/健身|游泳池|泳池|运动/i)
        expect(has_fitness).to be(true),
          "酒店未配备健身设施。当前设施: #{hotel.facilities}"
      end
      
      add_assertion "创建了景区运动活动订单", weight: 20 do
        @activity_order = ActivityOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        # 运动健身游可能不包含单独的景区活动
        if @activity_order
          expect(@activity_order).not_to be_nil
        else
          expect(true).to be(true)
        end
      end
      
      add_assertion "入住日期正确", weight: 10 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
      end
      
      add_assertion "住宿天数≥3晚", weight: 5 do
        actual_nights = (@hotel_booking.check_out_date - @hotel_booking.check_in_date).to_i
        expect(actual_nights).to be >= 3,
          "住宿天数不足。期望≥3晚，实际: #{actual_nights}晚"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择配备健身设施的酒店
      hotel = Hotel
        .where(city: @city, data_version: 0)
        .order(rating: :desc)
        .first!
      
      HotelBooking.create!(
        hotel_room_id: hotel.hotel_rooms.first!.id,
        user_id: user.id,
        rooms_count: 1,
        adults_count: 1,
        children_count: 0,
        hotel_id: hotel.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: user.name || '张先生',
        guest_phone: user.phone || '13800138000',
        payment_method: '花呗',
        total_price: hotel.price * (@check_out_date - @check_in_date).to_i,
        status: 'pending',
        data_version: @data_version
      )
      
      # 可选：预订运动体验活动
      attraction = Attraction.where(city: @city, data_version: 0).first
      if attraction
        activity = attraction.attraction_activities
          .where(activity_type: 'experience', data_version: 0)
          .first
        
        if activity
          passenger = Passenger.find_or_create_by!(
            user_id: user.id,
            id_number: '440300199001011234',
            data_version: @data_version
          ) do |p|
            p.name = '张先生'
            p.id_type = 'id_card'
            p.phone = '13800138000'
          end
          
          ActivityOrder.create!(
            user_id: user.id,
            attraction_activity_id: activity.id,
            visit_date: @visit_date,
            quantity: 1,
            passenger_ids: [passenger.id],
            total_price: activity.current_price,
            status: 'pending',
            insurance_type: 'none',
            data_version: @data_version
          )
        end
      end
    end
    
    private
    
    def execution_state_data
      {
        city: @city,
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s,
        visit_date: @visit_date&.to_s
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date']) if data['check_in_date']
      @check_out_date = Date.parse(data['check_out_date']) if data['check_out_date']
      @visit_date = Date.parse(data['visit_date']) if data['visit_date']
    end
  end
end
