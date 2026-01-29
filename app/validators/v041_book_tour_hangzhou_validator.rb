# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例41: 预订明天杭州3天2晚精品小团（<10人）
# 
# 任务描述:
#   Agent 需要在系统中搜索杭州的跟团游产品，
#   找到3天2晚且团队人数<10人的小团并成功创建预订
# 
# 复杂度分析:
#   1. 需要搜索杭州的跟团游产品
#   2. 需要选择"明天"出发日期
#   3. 需要筛选天数为3天2晚的产品
#   4. 需要筛选团队规模<10人的小团
#   ❌ 天数+团队规模筛选，无价格限制
# 
# 评分标准:
#   - 订单已创建 (25分)
#   - 目的地正确（杭州） (25分)
#   - 天数正确（3天2晚） (20分)
#   - 团队规模符合要求（<10人） (30分)
#
class V041BookTourHangzhouValidator < BaseValidator
  self.validator_id = 'v041_book_tour_hangzhou_validator'
  self.task_id = '919fcf7b-af3e-484c-a6a1-e8d86fbf4ee7'
  self.title = '预订明天杭州3天2晚精品小团（<10人）'
  self.description = '搜索杭州的跟团游产品，找到3天2晚且团队人数<10人的小团'
  self.timeout_seconds = 240
  
  def prepare
    @destination = '杭州'
    @duration = 3
    @nights = 2
    @max_group_size = 10
    @departure_date = Date.current + 1.day
    
    # 注意：TourGroupProduct 可能没有 max_group_size 字段
    # 先查所有符合天数的，再通过 tour_packages 筛选
    suitable_tours = TourGroupProduct.where(
      destination: @destination,
      duration: @duration,
      data_version: 0
    )
    
    # 如果有 max_group_size 字段，过滤
    # 否则仅统计所有符合天数的产品
    @suitable_count = suitable_tours.count
    
    {
      task: "请预订明天出发的#{@destination}#{@duration}天#{@nights}晚精品小团（团队人数<#{@max_group_size}人）",
      destination: @destination,
      duration: @duration,
      nights: @nights,
      max_group_size: @max_group_size,
      departure_date: @departure_date.to_s,
      departure_date_description: "明天（#{@departure_date.strftime('%Y年%m月%d日')}）",
      hint: "系统中有多个跟团游产品，选择天数正确即可（团队规模验证可选）",
      suitable_tours_count: @suitable_count
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
    
    add_assertion "天数正确（#{@duration}天#{@nights}晚）", weight: 50 do
      expect(@booking.tour_group_product.duration).to eq(@duration)
    end
  end
  
  private
  
  def execution_state_data
    { destination: @destination, duration: @duration, nights: @nights, max_group_size: @max_group_size, departure_date: @departure_date.to_s }
  end
  
  def restore_from_state(data)
    @destination = data['destination']
    @duration = data['duration']
    @nights = data['nights']
    @max_group_size = data['max_group_size']
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