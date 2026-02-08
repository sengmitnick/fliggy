# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例41: 预订明天杭州3天2晚跟团游
# 
# 任务描述:
#   Agent 需要在系统中搜索杭州的跟团游产品，
#   找到3天2晚的产品并成功创建预订
# 
# 复杂度分析:
#   1. 需要搜索杭州的跟团游产品
#   2. 需要选择"明天"出发日期
#   3. 需要筛选天数为3天2晚的产品
#   ❌ 目的地+天数筛选，无价格和人数限制
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 目的地正确（杭州） (25分)
#   - 出发日期正确（明天） (15分)
#   - 天数正确（3天2晚） (30分)
#   - 人数正确（1成人0儿童） (10分)
#
module V001V050
  class V041BookTourHangzhouValidator < BaseValidator
    self.validator_id = 'v041_book_tour_hangzhou_validator'
    self.task_id = '919fcf7b-af3e-484c-a6a1-e8d86fbf4ee7'
    self.title = '预订明天杭州3天2晚跟团游（1成人）'
    self.description = '搜索杭州的跟团游产品，找到3天2晚的产品并完成预订'
    self.timeout_seconds = 240
  
    def prepare
      @destination = '杭州'
      @duration = 3
      @nights = 2
      @departure_date = Date.current + 1.day
    
      suitable_tours = TourGroupProduct.where(
        destination: @destination,
        duration: @duration,
        data_version: 0
      )
    
      {
        task: "请预订明天出发的#{@destination}#{@duration}天#{@nights}晚跟团游",
        destination: @destination,
        duration: @duration,
        nights: @nights,
        departure_date: @departure_date.to_s,
        departure_date_description: "明天（#{@departure_date.strftime('%Y年%m月%d日')}）",
        hint: "系统中有多个跟团游产品，选择天数正确即可",
        suitable_tours_count: suitable_tours.count
      }
    end
  
    def verify
      add_assertion "订单已创建", weight: 20 do
        all_tour_group_bookings = TourGroupBooking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        expect(all_tour_group_bookings).not_to be_empty, "未找到任何TourGroupBooking记录"
        @booking = all_tour_group_bookings.first
        # Replaced by expect(all_tour_group_bookings).not_to be_empty above, "未找到任何跟团游订单记录"
      end
    
      return unless @booking
    
      add_assertion "目的地正确（#{@destination}）", weight: 25 do
        expect(@booking.tour_group_product.destination).to eq(@destination),
          "目的地不正确。期望: #{@destination}, 实际: #{@booking.tour_group_product.destination}"
      end
    
      add_assertion "出发日期正确（明天）", weight: 15 do
        departure_date = @booking.travel_date
        expect(departure_date).to eq(@departure_date),
          "出发日期不正确。期望: #{@departure_date}（明天）, 实际: #{departure_date}"
      end
    
      add_assertion "天数正确（#{@duration}天#{@nights}晚）", weight: 30 do
        expect(@booking.tour_group_product.duration).to eq(@duration),
          "天数不正确。期望: #{@duration}天, 实际: #{@booking.tour_group_product.duration}天"
      end
    
      add_assertion "人数正确（1成人0儿童）", weight: 10 do
        expect(@booking.adult_count).to eq(1),
          "成人数量错误。期望: 1, 实际: #{@booking.adult_count}"
        expect(@booking.child_count).to eq(0),
          "儿童数量错误。期望: 0, 实际: #{@booking.child_count}"
      end
    end
  
    private
  
    def execution_state_data
      { destination: @destination, duration: @duration, nights: @nights, departure_date: @departure_date.to_s }
    end
  
    def restore_from_state(data)
      @destination = data['destination']
      @duration = data['duration']
      @nights = data['nights']
      @departure_date = Date.parse(data['departure_date'])
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      target_tour = TourGroupProduct.where(
        destination: @destination,
        duration: @duration,
        data_version: 0
      ).sample
    
      target_package = target_tour.tour_packages.order(:price).first
      raise "产品 #{target_tour.title} 没有可用套餐" if target_package.nil?
    
      adult_count = 1
      child_count = 0
      total_price = target_package.price * (adult_count + child_count)
    
      TourGroupBooking.create!(
        tour_group_product_id: target_tour.id,
        tour_package_id: target_package.id,
        user_id: user.id,
        travel_date: @departure_date,
        adult_count: adult_count,
        child_count: child_count,
        contact_name: '张三',
        contact_phone: '13800138000',
        insurance_type: 'none',
        total_price: total_price,
        status: 'pending'
      )
    
      { action: 'create_tour_booking', tour_name: target_tour.title }
    end
    end
end
