# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例38: 预订明天北京4天3晚跟团游（2成人）
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
#   - 目的地正确（北京） (25分)
#   - 天数正确（4天3晚） (25分)
#   - 成人数量正确（2人） (25分)
#
class V038BookTourBeijingValidator < BaseValidator
  self.validator_id = 'v038_book_tour_beijing_validator'
  self.title = '预订明天北京4天3晚跟团游（2成人）'
  self.description = '搜索北京的跟团游产品，找到4天3晚的产品并预订2位成人'
  self.timeout_seconds = 240
  
  def prepare
    @destination = '北京'
    @duration = 4
    @nights = 3
    @adult_count = 2
    @departure_date = Date.current + 1.day
    
    suitable_tours = TourGroupProduct.where(
      destination: @destination,
      duration: @duration,
      data_version: 0
    )
    
    {
      task: "请预订明天出发的#{@destination}#{@duration}天#{@nights}晚跟团游（#{@adult_count}位成人）",
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
    add_assertion "订单已创建", weight: 25 do
      @booking = TourGroupBooking.order(created_at: :desc).first
      expect(@booking).not_to be_nil, "未找到任何跟团游订单记录"
    end
    
    return unless @booking
    
    add_assertion "目的地正确（#{@destination}）", weight: 25 do
      expect(@booking.tour_group_product.destination).to eq(@destination)
    end
    
    add_assertion "天数正确（#{@duration}天#{@nights}晚）", weight: 25 do
      expect(@booking.tour_group_product.duration).to eq(@duration)
    end
    
    add_assertion "成人数量正确（#{@adult_count}人）", weight: 25 do
      expect(@booking.adult_count).to eq(@adult_count),
        "成人数量不正确。期望: #{@adult_count}人, 实际: #{@booking.adult_count}人"
    end
  end
  
  private
  
  def execution_state_data
    { destination: @destination, duration: @duration, nights: @nights, adult_count: @adult_count, departure_date: @departure_date.to_s }
  end
  
  def restore_from_state(data)
    @destination = data['destination']
    @duration = data['duration']
    @nights = data['nights']
    @adult_count = data['adult_count']
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
    
    child_count = 0
    total_price = target_package.price * (@adult_count + child_count)
    
    TourGroupBooking.create!(
      tour_group_product_id: target_tour.id,
      tour_package_id: target_package.id,
      user_id: user.id,
      travel_date: @departure_date,
      adult_count: @adult_count,
      child_count: child_count,
      contact_name: '张三',
      contact_phone: '13800138000',
      insurance_type: 'none',
      total_price: total_price,
      status: 'pending'
    )
    
    { action: 'create_tour_booking', tour_name: target_tour.title, adults: @adult_count }
  end
end
