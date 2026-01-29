# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例40: 预订大后天广州5天4晚跟团游（1成人1儿童）
# 
# 任务描述:
#   Agent 需要在系统中搜索广州的跟团游产品，
#   找到5天4晚的产品并成功创建1成人1儿童的预订
# 
# 复杂度分析:
#   1. 需要搜索广州的跟团游产品
#   2. 需要选择"大后天"出发日期
#   3. 需要筛选天数为5天4晚的产品
#   4. 需要设置1成人+1儿童组合
#   ❌ 天数+人员组成筛选，无价格限制
# 
# 评分标准:
#   - 订单已创建 (25分)
#   - 目的地正确（广州） (25分)
#   - 天数正确（5天4晚） (20分)
#   - 人员组成正确（1成人1儿童） (30分)
#
class V040BookTourGuangzhouValidator < BaseValidator
  self.validator_id = 'v040_book_tour_guangzhou_validator'
  self.task_id = 'ad551c7d-fd66-466b-b84b-f041af95feaf'
  self.title = '预订大后天广州5天4晚跟团游（1成人1儿童）'
  self.description = '搜索广州的跟团游产品，找到5天4晚的产品并预订1成人1儿童'
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
      task: "请预订大后天出发的#{@destination}#{@duration}天#{@nights}晚跟团游（#{@adult_count}成人#{@child_count}儿童）",
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
      @booking = TourGroupBooking.order(created_at: :desc).first
      expect(@booking).not_to be_nil, "未找到任何跟团游订单记录"
    end
    
    return unless @booking
    
    add_assertion "目的地正确（#{@destination}）", weight: 25 do
      expect(@booking.tour_group_product.destination).to eq(@destination)
    end
    
    add_assertion "天数正确（#{@duration}天#{@nights}晚）", weight: 20 do
      expect(@booking.tour_group_product.duration).to eq(@duration)
    end
    
    add_assertion "人员组成正确（1成人1儿童）", weight: 30 do
      adult_ok = @booking.adult_count == @adult_count
      child_ok = @booking.child_count == @child_count
      
      expect(adult_ok && child_ok).to be_truthy,
        "人员组成不正确。期望: #{@adult_count}成人#{@child_count}儿童, 实际: #{@booking.adult_count}成人#{@booking.child_count}儿童"
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
    
    target_tour = TourGroupProduct.where(
      destination: @destination,
      duration: @duration,
      data_version: 0
    ).sample
    
    target_package = target_tour.tour_packages.order(:price).first
    raise "产品 #{target_tour.title} 没有可用套餐" if target_package.nil?
    
    total_price = target_package.price * (@adult_count + @child_count)
    
    TourGroupBooking.create!(
      tour_group_product_id: target_tour.id,
      tour_package_id: target_package.id,
      user_id: user.id,
      travel_date: @departure_date,
      adult_count: @adult_count,
      child_count: @child_count,
      contact_name: '张三',
      contact_phone: '13800138000',
      insurance_type: 'none',
      total_price: total_price,
      status: 'pending'
    )
    
    { action: 'create_tour_booking', tour_name: target_tour.title, adults: @adult_count, children: @child_count }
  end
end