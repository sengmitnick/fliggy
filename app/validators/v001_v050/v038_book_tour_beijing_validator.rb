# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例38: 给张三预订明天北京4天3晚跟团游（2成人）
# 
# 任务描述:
#   Agent 需要在系统中搜索北京的跟团游产品，
#   找到4天3晚的产品并成功创建2成人的预订
# 
# 复杂度分析:
#   1. 需要搜索北京的跟团游产品
#   2. 需要选择"明天"出发日期
#   3. 需要筛选天数为4天3晚的产品
#   4. 需要设置2个成人
#   ❌ 天数+人数筛选，无价格限制
# 
# 评分标准:
#   - 订单已创建 (25分)
#   - 目的地正确（北京） (20分)
#   - 出发日期正确（明天） (15分)
#   - 天数正确（4天3晚） (20分)
#   - 成人数量正确（2人） (10分)
#   - 联系人信息正确（从出行人中选择：张三或李四） (5分)
#   - 出行人信息正确（2位成人） (5分)
#
module V001V050
  class V038BookTourBeijingValidator < BaseValidator
    self.validator_id = 'v038_book_tour_beijing_validator'
    self.task_id = '7e12c3ec-f7d0-4e6f-9f78-82db90598ec7'
    self.title = '给张三预订明天北京4天3晚跟团游（2成人）'
    self.description = '预订明天北京4天3晚跟团游（2成人）'
    self.timeout_seconds = 240
  
    def prepare
      @destination = '北京'
      @duration = 4
      @nights = 3
      @adult_count = 2
      @departure_date = Date.current + 1.day
      
      # 查询出行人和联系人（demo_user 数据）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan_contact = user.contacts.find_by!(name: '张三', data_version: 0)
      @lisi_contact = user.contacts.find_by!(name: '李四', data_version: 0)
      
      # 联系人可以是张三或李四（多选一）
      @valid_contact_names = ['张三', '李四']
      @valid_contact_phones = {
        '张三' => @zhangsan_contact.phone,
        '李四' => @lisi_contact.phone
      }
    
      suitable_tours = TourGroupProduct.where(
        destination: @destination,
        duration: @duration,
        data_version: 0
      )
    
      {
        task: "给张三预订明天出发的#{@destination}#{@duration}天#{@nights}晚跟团游（#{@adult_count}位成人）",
        destination: @destination,
        duration: @duration,
        nights: @nights,
        adult_count: @adult_count,
        departure_date: @departure_date.to_s,
        departure_date_description: "明天（#{@departure_date.strftime('%Y年%m月%d日')}）",
        hint: "系统中有多个跟团游产品，选择天数正确并设置2位成人",
        suitable_tours_count: suitable_tours.count
      }
    end
  
    def verify
      # 断言1: 订单已创建 (25分)
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
    
      # 断言2: 目的地正确（北京） (20分)
      add_assertion "目的地正确（#{@destination}）", weight: 20 do
        expect(@booking.tour_group_product.destination).to eq(@destination),
          "目的地不正确。期望: #{@destination}, 实际: #{@booking.tour_group_product.destination}"
      end
    
      # 断言3: 出发日期正确（明天） (15分)
      add_assertion "出发日期正确（明天）", weight: 15 do
        departure_date = @booking.travel_date
        expect(departure_date).to eq(@departure_date),
          "出发日期不正确。期望: #{@departure_date}（明天）, 实际: #{departure_date}"
      end
    
      # 断言4: 天数正确（4天3晚） (20分)
      add_assertion "天数正确（#{@duration}天#{@nights}晚）", weight: 20 do
        expect(@booking.tour_group_product.duration).to eq(@duration),
          "天数不正确。期望: #{@duration}天, 实际: #{@booking.tour_group_product.duration}天"
      end
    
      # 断言5: 成人数量正确（2人） (10分)
      add_assertion "成人数量正确（#{@adult_count}人）", weight: 10 do
        expect(@booking.adult_count).to eq(@adult_count),
          "成人数量不正确。期望: #{@adult_count}人, 实际: #{@booking.adult_count}人"
      end
    
      # 断言6: 联系人信息正确（从出行人中选择：张三或李四） (5分)
      add_assertion "联系人信息正确（从出行人中选择：张三或李四）", weight: 5 do
        expect(@valid_contact_phones.values).to include(@booking.contact_phone),
          "联系人电话错误。应从出行人中选择：#{@valid_contact_names.join('、')}，" \
          "对应电话：#{@valid_contact_phones.values.join('、')}，实际: #{@booking.contact_phone}"
      end
    
      # 断言7: 出行人信息正确（2位成人） (5分)
      add_assertion "出行人信息正确（#{@adult_count}位成人）", weight: 5 do
        travelers = @booking.booking_travelers.where(data_version: @data_version, traveler_type: 'adult')
        expect(travelers.size).to eq(@adult_count),
          "成人出行人数量错误。期望: #{@adult_count}人, 实际: #{travelers.size}人"
        
        # 验证所有出行人都来自 demo_user 的 passengers
        user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
        valid_passenger_names = user.passengers.where(data_version: 0).pluck(:name)
        
        travelers.each do |traveler|
          expect(valid_passenger_names).to include(traveler.traveler_name),
            "出行人 #{traveler.traveler_name} 不在 demo_user passengers 列表中"
          expect(traveler.id_number).not_to be_nil,
            "出行人 #{traveler.traveler_name} 缺少身份证号"
        end
      end
    end
  
    private
  
    def execution_state_data
      { destination: @destination, duration: @duration, nights: @nights, adult_count: @adult_count, departure_date: @departure_date.to_s,
        valid_contact_names: @valid_contact_names, valid_contact_phones: @valid_contact_phones }
    end
  
    def restore_from_state(data)
      @destination = data['destination']
      @duration = data['duration']
      @nights = data['nights']
      @adult_count = data['adult_count']
      @departure_date = Date.parse(data['departure_date'])
      @valid_contact_names = data['valid_contact_names']
      @valid_contact_phones = data['valid_contact_phones']
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      contact = user.contacts.find_by!(name: '张三', data_version: 0)
      passengers = user.passengers.where(data_version: 0).limit(@adult_count).to_a
    
      target_tour = TourGroupProduct.where(
        destination: @destination,
        duration: @duration,
        data_version: 0
      ).sample
    
      target_package = target_tour.tour_packages.order(:price).first
      raise "产品 #{target_tour.title} 没有可用套餐" if target_package.nil?
    
      child_count = 0
      total_price = target_package.price * (@adult_count + child_count)
    
      booking = TourGroupBooking.create!(
        tour_group_product_id: target_tour.id,
        tour_package_id: target_package.id,
        user_id: user.id,
        travel_date: @departure_date,
        adult_count: @adult_count,
        child_count: child_count,
        contact_name: contact.name,
        contact_phone: contact.phone,
        insurance_type: 'none',
        total_price: total_price,
        status: 'pending',
        data_version: @data_version
      )
    
      # 创建出行人信息
      passengers.each do |passenger|
        BookingTraveler.create!(
          tour_group_booking_id: booking.id,
          traveler_name: passenger.name,
          id_number: passenger.id_number,
          traveler_type: 'adult',
          data_version: @data_version
        )
      end
    
      { action: 'create_tour_booking', tour_name: target_tour.title, adults: @adult_count }
    end
    end
end