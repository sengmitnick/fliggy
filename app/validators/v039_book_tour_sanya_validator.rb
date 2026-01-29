# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例39: 预订后天三亚6天5晚便宜跟团游（预算≤4500元/人）
# 
# 任务描述:
#   Agent 需要在系统中搜索三亚的跟团游产品，
#   找到6天5晚且价格≤4500元/人的产品并成功创建预订
# 
# 复杂度分析:
#   1. 需要搜索三亚的跟团游产品
#   2. 需要选择"后天"出发日期
#   3. 需要筛选天数为6天5晚的产品
#   4. 需要筛选价格≤4500元/人的产品
#   ❌ 天数+预算筛选，简化版性价比
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 目的地正确（三亚） (20分)
#   - 天数正确（6天5晚） (20分)
#   - 价格符合预算（≤4500元/人） (40分)
#
class V039BookTourSanyaValidator < BaseValidator
  self.validator_id = 'v039_book_tour_sanya_validator'
  self.task_id = 'f55024a4-37df-4c37-b0cb-62127f862740'
  self.title = '预订后天三亚6天5晚便宜跟团游（预算≤4500元/人）'
  self.description = '搜索三亚的跟团游产品，找到6天5晚且价格≤4500元/人的产品'
  self.timeout_seconds = 240
  
  def prepare
    @destination = '三亚'
    @duration = 6
    @nights = 5
    @budget_per_person = 4500
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
      task: "请预订后天出发的#{@destination}#{@duration}天#{@nights}晚跟团游（预算≤#{@budget_per_person}元/人）",
      destination: @destination,
      duration: @duration,
      nights: @nights,
      budget_per_person: @budget_per_person,
      departure_date: @departure_date.to_s,
      departure_date_description: "后天（#{@departure_date.strftime('%Y年%m月%d日')}）",
      hint: "系统中有多个符合预算的跟团游产品，选择价格≤4500元/人的",
      eligible_tours_count: eligible_tours.count,
      lowest_price: @lowest_price
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 20 do
      @booking = TourGroupBooking.order(created_at: :desc).first
      expect(@booking).not_to be_nil, "未找到任何跟团游订单记录"
    end
    
    return unless @booking
    
    add_assertion "目的地正确（#{@destination}）", weight: 20 do
      expect(@booking.tour_group_product.destination).to eq(@destination)
    end
    
    add_assertion "天数正确（#{@duration}天#{@nights}晚）", weight: 20 do
      expect(@booking.tour_group_product.duration).to eq(@duration)
    end
    
    add_assertion "价格符合预算（≤#{@budget_per_person}元/人）", weight: 40 do
      price_per_person = @booking.tour_package.price
      
      expect(price_per_person <= @budget_per_person).to be_truthy,
        "价格超出预算。预算: ≤#{@budget_per_person}元/人, 实际: #{price_per_person}元/人"
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
    
    tours = TourGroupProduct.where(
      destination: @destination,
      duration: @duration,
      data_version: 0
    )
    
    eligible_tours = tours.select do |tour|
      tour.tour_packages.where('price <= ?', @budget_per_person).any?
    end
    
    target_tour = eligible_tours.sample
    raise "No eligible tours found for #{@destination} with #{@duration} days and budget ≤¥#{@budget_per_person}" if target_tour.nil?
    
    target_package = target_tour.tour_packages.where('price <= ?', @budget_per_person).order(:price).first
    raise "产品 #{target_tour.title} 没有符合预算的套餐" if target_package.nil?
    
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
    
    { action: 'create_tour_booking', tour_name: target_tour.title, price: target_package.price }
  end
end