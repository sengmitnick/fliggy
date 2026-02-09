# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例39: 预订后天三亚6天5晚性价比跟团游（预算≤4000元/人）
# 
# 任务描述:
#   Agent 需要在系统中搜索三亚的跟团游产品，
#   找到6天5晚且价格≤4000元/人的产品并成功创建预订
# 
# 复杂度分析:
#   1. 需要搜索三亚的跟团游产品
#   2. 需要选择"后天"出发日期
#   3. 需要筛选天数为6天5晚的产品
#   4. 需要筛选价格≤4000元/人的产品
#   ✅ 天数+预算筛选，性价比优选
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 目的地正确（三亚） (20分)
#   - 出发日期正确（后天） (15分)
#   - 天数正确（6天5晚） (15分)
#   - 价格符合预算（≤4000元/人） (30分)
#
module V001V050
  class V039BookTourSanyaValidator < BaseValidator
    self.validator_id = 'v039_book_tour_sanya_validator'
    self.task_id = 'f55024a4-37df-4c37-b0cb-62127f862740'
    self.title = '给张三预订后天三亚6天5晚性价比跟团游（预算≤4000元/人）'
    self.description = '搜索三亚的跟团游产品，找到6天5晚且价格≤4000元/人的产品'
    self.timeout_seconds = 240
  
    def prepare
      @destination = '三亚'
      @duration = 6
      @nights = 5
      @budget_per_person = 4000
      @departure_date = Date.current + 2.days
    
      # 先找到所有符合天数和目的地的产品
      tours = TourGroupProduct.where(
        destination: @destination,
        duration: @duration,
        data_version: 0
      )
    
      # 过滤出预算内的产品（检查tour_packages的价格）
      eligible_tours = tours.select do |tour|
        tour.tour_packages.where('price <= ?', @budget_per_person).any?
      end
    
      @lowest_price = eligible_tours.flat_map { |t| t.tour_packages.pluck(:price) }.compact.min
    
      {
        task: "给张三预订后天出发的#{@destination}#{@duration}天#{@nights}晚跟团游（预算≤#{@budget_per_person}元/人）",
        destination: @destination,
        duration: @duration,
        nights: @nights,
        budget_per_person: @budget_per_person,
        departure_date: @departure_date.to_s,
        departure_date_description: "后天（#{@departure_date.strftime('%Y年%m月%d日')}）",
        hint: "系统中有多个符合预算的跟团游产品，选择价格≤4000元/人的",
        eligible_tours_count: eligible_tours.count,
        lowest_price: @lowest_price
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
    
      add_assertion "目的地正确（#{@destination}）", weight: 20 do
        expect(@booking.tour_group_product.destination).to eq(@destination),
          "目的地不正确。期望: #{@destination}, 实际: #{@booking.tour_group_product.destination}"
      end
    
      add_assertion "出发日期正确（后天）", weight: 15 do
        departure_date = @booking.travel_date
        expect(departure_date).to eq(@departure_date),
          "出发日期不正确。期望: #{@departure_date}（后天）, 实际: #{departure_date}"
      end
    
      add_assertion "天数正确（#{@duration}天#{@nights}晚）", weight: 15 do
        expect(@booking.tour_group_product.duration).to eq(@duration),
          "天数不正确。期望: #{@duration}天, 实际: #{@booking.tour_group_product.duration}天"
      end
    
      add_assertion "价格符合预算（≤#{@budget_per_person}元/人）", weight: 20 do
        price_per_person = @booking.tour_package.price
      
        expect(price_per_person <= @budget_per_person).to be_truthy,
          "价格超出预算。预算: ≤#{@budget_per_person}元/人, 实际: #{price_per_person}元/人"
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
      { destination: @destination, duration: @duration, nights: @nights, budget_per_person: @budget_per_person, departure_date: @departure_date.to_s }
    end
  
    def restore_from_state(data)
      @destination = data['destination']
      @duration = data['duration']
      @nights = data['nights']
      @budget_per_person = data['budget_per_person']
      @departure_date = Date.parse(data['departure_date'])
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      contact = user.contacts.find_by!(name: '张三', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
    
      tours = TourGroupProduct.where(
        destination: @destination,
        duration: @duration,
        data_version: 0
      )
    
      eligible_tours = tours.select do |tour|
        tour.tour_packages.where('price <= ?', @budget_per_person).any?
      end
    
      target_tour = eligible_tours.sample
      raise "未找到符合条件的跟团游（#{@destination}，#{@duration}天，预算≤#{@budget_per_person}元）" if target_tour.nil?
    
      target_package = target_tour.tour_packages.where('price <= ?', @budget_per_person).order(:price).first
      raise "产品 #{target_tour.title} 没有符合预算的套餐" if target_package.nil?
    
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
    
      { action: 'create_tour_booking', tour_name: target_tour.title, price: target_package.price }
    end
    end
end
