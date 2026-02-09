# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例40: 预订大后天广州4天3晚跟团游（1成人1儿童）
# 
# 任务描述:
#   Agent 需要在系统中搜索广州的跟团游产品，
#   找到4天3晚的产品并成功创建1成人1儿童的预订
# 
# 复杂度分析:
#   1. 需要搜索广州的跟团游产品
#   2. 需要选择"大后天"出发日期
#   3. 需要筛选天数为4天3晚的产品
#   4. 需要设置1成人+1儿童组合
#   ❌ 天数+人员组成筛选，无价格限制
# 
# 评分标准:
#   - 订单已创建 (25分)
#   - 目的地正确（广州） (20分)
#   - 出发日期正确（大后天） (15分)
#   - 天数正确（4天3晚） (15分)
#   - 人员组成正确（1成人1儿童） (25分)
#
module V001V050
  class V040BookTourGuangzhouValidator < BaseValidator
    self.validator_id = 'v040_book_tour_guangzhou_validator'
    self.task_id = 'ad551c7d-fd66-466b-b84b-f041af95feaf'
    self.title = '给张三和小明预订3天后广州4天3晚跟团游（1成人1儿童）'
    self.description = '搜索广州的跟团游产品，找到4天3晚的产品并为张三（成人）和小明（儿童）预订'
    self.timeout_seconds = 240
  
    def prepare
      @destination = '广州'
      @duration = 4  # 改为4天，数据库中有广州4天的跳团游
      @nights = 3  # 4天=3晚
      @adult_count = 1
      @child_count = 1
      @departure_date = Date.current + 3.days
    
      suitable_tours = TourGroupProduct.where(
        destination: @destination,
        duration: @duration,
        data_version: 0
      )
    
      {
        task: "给张三（成人）和小明（儿童）预订大后天出发的#{@destination}#{@duration}天#{@nights}晚跟团游",
        destination: @destination,
        duration: @duration,
        nights: @nights,
        adult_count: @adult_count,
        child_count: @child_count,
        departure_date: @departure_date.to_s,
        departure_date_description: "大后天（#{@departure_date.strftime('%Y年%m月%d日')}）",
        hint: "系统中有多个跟团游产品，选择天数正确并设置1成人1儿童",
        suitable_tours_count: suitable_tours.count
      }
    end
  
    def verify
      add_assertion "订单已创建", weight: 25 do
        all_tour_group_bookings = TourGroupBooking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        expect(all_tour_group_bookings).not_to be_empty, "未找到任何TourGroupBooking记录"
        @booking = all_tour_group_bookings.first
        # Replaced by expect(all_tour_group_bookings).not_to be_empty above, "未找到任何跟团游订单记录"
      end
    
      return unless @booking
    
      add_assertion "目的地正确（#{@destination}）", weight: 20 do
        expect(@booking.tour_group_product.destination).to eq(@destination),
          "目的地不正确。期望: #{@destination}, 实际: #{@booking.tour_group_product.destination}"
      end
    
      add_assertion "出发日期正确（大后天）", weight: 15 do
        departure_date = @booking.travel_date
        expect(departure_date).to eq(@departure_date),
          "出发日期不正确。期望: #{@departure_date}（大后天）, 实际: #{departure_date}"
      end
    
      add_assertion "天数正确（#{@duration}天#{@nights}晚）", weight: 15 do
        expect(@booking.tour_group_product.duration).to eq(@duration),
          "天数不正确。期望: #{@duration}天, 实际: #{@booking.tour_group_product.duration}天"
      end
    
      add_assertion "人员组成正确（1成人1儿童）", weight: 15 do
        adult_ok = @booking.adult_count == @adult_count
        child_ok = @booking.child_count == @child_count
      
        expect(adult_ok && child_ok).to be_truthy,
          "人员组成不正确。期望: #{@adult_count}成人#{@child_count}儿童, 实际: #{@booking.adult_count}成人#{@booking.child_count}儿童"
      end
    
      add_assertion "联系人信息正确（张三 13800138000）", weight: 5 do
        expect(@booking.contact_name).to eq('张三'),
          "联系人姓名错误。期望: 张三（demo_user数据）, 实际: #{@booking.contact_name}"
        expect(@booking.contact_phone).to eq('13800138000'),
          "联系电话错误。期望: 13800138000（demo_user数据）, 实际: #{@booking.contact_phone}"
      end
    
      add_assertion "出行人信息正确（成人张三+儿童小明）", weight: 10 do
        travelers = @booking.booking_travelers.where(data_version: @data_version)
        expect(travelers.size).to eq(2), "出行人数量错误。期望: 2人, 实际: #{travelers.size}人"
        
        adults = travelers.where(traveler_type: 'adult')
        children = travelers.where(traveler_type: 'child')
        
        expect(adults.size).to eq(1), "成人出行人数量错误。期望: 1人, 实际: #{adults.size}人"
        expect(children.size).to eq(1), "儿童出行人数量错误。期望: 1人, 实际: #{children.size}人"
        
        adult = adults.first
        expect(adult.traveler_name).to eq('张三'),
          "成人出行人姓名错误。期望: 张三（demo_user数据）, 实际: #{adult.traveler_name}"
        expect(adult.id_number).to eq('110101199001011234'),
          "成人身份证号错误。期望: 110101199001011234（demo_user数据）, 实际: #{adult.id_number}"
        
        child = children.first
        expect(child.traveler_name).to eq('小明'),
          "儿童出行人姓名错误。期望: 小明（demo_user数据）, 实际: #{child.traveler_name}"
        expect(child.id_number).not_to be_nil,
          "儿童出行人缺少身份证号"
      end
    end
  
    private
  
    def execution_state_data
      { destination: @destination, duration: @duration, nights: @nights, adult_count: @adult_count, child_count: @child_count, departure_date: @departure_date.to_s }
    end
  
    def restore_from_state(data)
      @destination = data['destination']
      @duration = data['duration']
      @nights = data['nights']
      @adult_count = data['adult_count']
      @child_count = data['child_count']
      @departure_date = Date.parse(data['departure_date'])
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      contact = user.contacts.find_by!(name: '张三', data_version: 0)
      adult_passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      child_passenger = user.passengers.find_by!(name: '小明', data_version: 0)
    
      target_tour = TourGroupProduct.where(
        destination: @destination,
        duration: @duration,
        data_version: 0
      ).sample
    
      target_package = target_tour.tour_packages.order(:price).first
      raise "产品 #{target_tour.title} 没有可用套餐" if target_package.nil?
    
      total_price = target_package.price * (@adult_count + @child_count)
    
      booking = TourGroupBooking.create!(
        tour_group_product_id: target_tour.id,
        tour_package_id: target_package.id,
        user_id: user.id,
        travel_date: @departure_date,
        adult_count: @adult_count,
        child_count: @child_count,
        contact_name: contact.name,
        contact_phone: contact.phone,
        insurance_type: 'none',
        total_price: total_price,
        status: 'pending',
        data_version: @data_version
      )
    
      # 创建出行人信息
      BookingTraveler.create!(
        tour_group_booking_id: booking.id,
        traveler_name: adult_passenger.name,
        id_number: adult_passenger.id_number,
        traveler_type: 'adult',
        data_version: @data_version
      )
    
      BookingTraveler.create!(
        tour_group_booking_id: booking.id,
        traveler_name: child_passenger.name,
        id_number: child_passenger.id_number,
        traveler_type: 'child',
        data_version: @data_version
      )
    
      { action: 'create_tour_booking', tour_name: target_tour.title, adults: @adult_count, children: @child_count }
    end
    end
end
