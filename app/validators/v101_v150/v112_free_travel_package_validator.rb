# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例112: 预订自由行套餐（上海一日游）
#
# 任务描述:
#   预订上海自由行一日游，2成人，当天往返
#
# 评分标准:
#   - 订单已创建 (25分)
#   - 目的地正确（上海）(15分)
#   - 旅游类型正确（自由出行）(20分)
#   - 天数正确（1天）(15分)
#   - 人数正确（2成人）(25分)
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v112_free_travel_package_validator/start
#   
#   # Agent 通过界面操作完成任务...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V112FreeTravelPackageValidator < BaseValidator
  self.validator_id = 'v112_free_travel_package_validator'
  self.task_id = '2d8eeaf8-2fa3-41a1-be59-669915973d05'
  self.title = '预订自由行套餐（上海一日游）'
  self.description = '预订上海自由行一日游，2成人，当天往返'
  self.timeout_seconds = 300
  
  def prepare
    @destination = '上海'
    @duration = 1
    @adult_count = 2
    @child_count = 0
    @travel_type = '自由出行'
    @travel_date = Date.current + 5.days  # 5天后出发
    
    # 查找符合条件的自由行产品
    @qualified_products = TourGroupProduct.where(
      travel_type: @travel_type,
      duration: @duration,
      data_version: 0
    ).where("destination LIKE ?", "%#{@destination}%")
    
    # 找到价格适中的产品
    @target_product = @qualified_products.order(:price).first
    
    {
      task: "请预订#{@destination}自由行一日游，#{@adult_count}个成人，当天往返（#{@travel_date.strftime('%Y年%m月%d日')}出发）",
      requirements: {
        destination: @destination,
        travel_type: @travel_type,
        travel_type_description: '自由出行（非跟团游、非独立成团）',
        duration: @duration,
        adult_count: @adult_count,
        child_count: @child_count,
        travel_date: @travel_date.to_s,
        inclusions: '包含机票和酒店'
      },
      hint: "系统中有多个#{@destination}一日游产品可选，请选择自由出行类型的一日游产品",
      statistics: {
        total_products: @qualified_products.count,
        price_range: {
          min: @qualified_products.minimum(:price),
          max: @qualified_products.maximum(:price)
        }
      }
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 25 do
      all_bookings = TourGroupBooking.joins(:tour_group_product)
                                     .where(tour_group_products: { travel_type: @travel_type })
                                     .where(data_version: @data_version)
                                     .order(created_at: :desc)
                                     .to_a
      
      @bookings = all_bookings.select do |b|
        b.tour_group_product.destination&.include?(@destination)
      end
      
      expect(@bookings).not_to be_empty, "未找到任何#{@destination}自由行订单"
      @booking = @bookings.first
    end
    
    return if @bookings.nil? || @bookings.empty?
    
    add_assertion "目的地正确（#{@destination}）", weight: 15 do
      expect(@booking.tour_group_product.destination).to include(@destination),
        "目的地错误。期望包含: #{@destination}，实际: #{@booking.tour_group_product.destination}"
    end
    
    add_assertion "旅游类型正确（自由出行）", weight: 20 do
      expect(@booking.tour_group_product.travel_type).to eq(@travel_type),
        "旅游类型错误。期望: #{@travel_type}（自由行），实际: #{@booking.tour_group_product.travel_type}"
    end
    
    add_assertion "天数正确（#{@duration}天一日游）", weight: 15 do
      expect(@booking.tour_group_product.duration).to eq(@duration),
        "天数错误。期望: #{@duration}天（一日游），实际: #{@booking.tour_group_product.duration}天"
    end
    
    add_assertion "人数正确（#{@adult_count}成人#{@child_count}儿童）", weight: 25 do
      expect(@booking.adult_count).to eq(@adult_count),
        "成人数量错误。期望: #{@adult_count}人，实际: #{@booking.adult_count}人"
      expect(@booking.child_count).to eq(@child_count),
        "儿童数量错误。期望: #{@child_count}人，实际: #{@booking.child_count}人"
    end
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 查找符合条件的自由行产品
    target_product = TourGroupProduct.where(
      travel_type: @travel_type,
      duration: @duration,
      data_version: 0
    ).where("destination LIKE ?", "%#{@destination}%")
     .order(:price)
     .first
    
    raise "未找到符合条件的自由行产品" unless target_product
    
    # 选择套餐（最便宜的）
    target_package = target_product.tour_packages.order(:price).first
    raise "产品没有可用套餐" unless target_package
    
    # 计算总价
    total_price = target_package.price * @adult_count + target_package.child_price * @child_count
    
    # 创建订单
    TourGroupBooking.create!(
      tour_group_product_id: target_product.id,
      tour_package_id: target_package.id,
      user_id: user.id,
      travel_date: @travel_date,
      adult_count: @adult_count,
      child_count: @child_count,
      contact_name: '李四',
      contact_phone: '13900139000',
      insurance_type: 'none',
      total_price: total_price,
      status: 'pending',
      data_version: @data_version
    )
  end
  
  private
  
  def execution_state_data
    {
      destination: @destination,
      duration: @duration,
      adult_count: @adult_count,
      child_count: @child_count,
      travel_type: @travel_type,
      travel_date: @travel_date.to_s
    }
  end
  
  def restore_from_state(data)
    @destination = data['destination']
    @duration = data['duration']
    @adult_count = data['adult_count']
    @child_count = data['child_count']
    @travel_type = data['travel_type']
    @travel_date = Date.parse(data['travel_date'])
    
    @qualified_products = TourGroupProduct.where(
      travel_type: @travel_type,
      duration: @duration,
      data_version: 0
    ).where("destination LIKE ?", "%#{@destination}%")
  end
end
