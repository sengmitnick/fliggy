# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例37: 给张三预订大后天上海周边3天2晚跟团游
# 
# 任务描述:
#   Agent 需要在系统中搜索上海周边的跟团游产品，
#   找到3天2晚的产品并成功创建预订
# 
# 复杂度分析:
#   1. 需要搜索上海周边的跟团游产品
#   2. 需要选择"大后天"出发日期
#   3. 需要筛选天数为3天2晚的产品
#   ❌ 目的地+天数筛选，无价格和人数限制
# 
# 评分标准:
#   - 订单已创建 (25分)
#   - 目的地正确（上海周边） (25分)
#   - 出发日期正确（大后天） (15分)
#   - 天数正确（3天2晚） (20分)
#   - 人数正确（1成人） (15分)
#
module V001V050
  class V037BookTourShanghaiValidator < BaseValidator
    self.validator_id = 'v037_book_tour_shanghai_validator'
    self.task_id = '1bd41d87-7ea1-4d1b-850e-bccde2ac43b1'
    self.title = '给张三预订大后天上海周边3天2晚跟团游'
    self.description = '预订大后天上海周边3天2晚跟团游'
    self.timeout_seconds = 240
  
    def prepare
      @destination = '上海'
      @duration = 3
      @nights = 2
      @departure_date = Date.current + 3.days
    
      suitable_tours = TourGroupProduct.where(
        destination: @destination,
        duration: @duration,
        data_version: 0
      )
    
      {
        task: "给张三预订大后天出发的#{@destination}周边#{@duration}天#{@nights}晚跟团游",
        destination: @destination,
        duration: @duration,
        nights: @nights,
        departure_date: @departure_date.to_s,
        departure_date_description: "大后天（#{@departure_date.strftime('%Y年%m月%d日')}）",
        hint: "系统中有多个跟团游产品，选择天数正确即可",
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
    
      add_assertion "目的地正确（#{@destination}周边）", weight: 25 do
        expect(@booking.tour_group_product.destination).to eq(@destination),
          "目的地不正确。期望: #{@destination}, 实际: #{@booking.tour_group_product.destination}"
      end
    
      add_assertion "出发日期正确（大后天）", weight: 15 do
        departure_date = @booking.travel_date
        expect(departure_date).to eq(@departure_date),
          "出发日期不正确。期望: #{@departure_date}（大后天）, 实际: #{departure_date}"
      end
    
      add_assertion "天数正确（#{@duration}天#{@nights}晚）", weight: 20 do
        expect(@booking.tour_group_product.duration).to eq(@duration),
          "天数不正确。期望: #{@duration}天, 实际: #{@booking.tour_group_product.duration}天"
      end
    
      add_assertion "人数正确（1成人）", weight: 5 do
        expect(@booking.adult_count).to eq(1),
          "成人数量不正确。期望: 1人, 实际: #{@booking.adult_count}人"
        expect(@booking.child_count).to eq(0),
          "儿童数量应为0。实际: #{@booking.child_count}人"
      end
    
      add_assertion "联系人信息正确（张三 13800138000）", weight: 5 do
        expect(@booking.contact_name).to eq('张三'),
          "联系人姓名错误。期望: 张三（demo_user数据）, 实际: #{@booking.contact_name}"
        expect(@booking.contact_phone).to eq('13800138000'),
          "联系电话错误。期望: 13800138000（demo_user数据）, 实际: #{@booking.contact_phone}"
      end
    
      add_assertion "出行人信息正确（张三 110101199001011234）", weight: 10 do
        travelers = @booking.booking_travelers.where(data_version: @data_version)
        expect(travelers.size).to eq(1), "出行人数量错误。期望: 1人, 实际: #{travelers.size}人"
        
        traveler = travelers.first
        expect(traveler.traveler_name).to eq('张三'),
          "出行人姓名错误。期望: 张三（demo_user数据）, 实际: #{traveler.traveler_name}"
        expect(traveler.id_number).to eq('110101199001011234'),
          "出行人身份证号错误。期望: 110101199001011234（demo_user数据）, 实际: #{traveler.id_number}"
        expect(traveler.traveler_type).to eq('adult'),
          "出行人类型错误。期望: adult, 实际: #{traveler.traveler_type}"
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
      contact = user.contacts.find_by!(name: '张三', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
    
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
    
      booking = TourGroupBooking.create!(
        tour_group_product_id: target_tour.id,
        tour_package_id: target_package.id,
        user_id: user.id,
        travel_date: @departure_date,
        adult_count: adult_count,
        child_count: child_count,
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
        traveler_name: passenger.name,
        id_number: passenger.id_number,
        traveler_type: 'adult',
        data_version: @data_version
      )
    
      { action: 'create_tour_booking', tour_name: target_tour.title }
    end
    end
end