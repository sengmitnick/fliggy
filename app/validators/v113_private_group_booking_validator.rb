# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例113: 预订私家团（杭州4天3晚）
#
# 任务描述:
#   预订杭州私家团，4天3晚，2成人1儿童，独立成团
#
# 评分标准:
#   - 订单已创建 (25分)
#   - 目的地正确（杭州）(15分)
#   - 旅游类型正确（独立成团）(20分)
#   - 天数正确（4天）(15分)
#   - 人数正确（2成人1儿童）(25分)
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v113_private_group_booking_validator/start
#   
#   # Agent 通过界面操作完成任务...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V113PrivateGroupBookingValidator < BaseValidator
  self.validator_id = 'v113_private_group_booking_validator'
  self.task_id = '6835d498-1040-44bb-bedf-2d628e59de70'
  self.title = '预订私家团（杭州4天3晚）'
  self.description = '预订杭州私家团，4天3晚，2成人1儿童，独立成团'
  self.timeout_seconds = 300
  
  def prepare
    @destination = '杭州'
    @duration = 4
    @adult_count = 2
    @child_count = 1
    @travel_type = '独立成团'
    @travel_date = Date.current + 10.days  # 10天后出发
    
    # 查找符合条件的私家团产品
    @qualified_products = TourGroupProduct.where(
      travel_type: @travel_type,
      duration: @duration,
      data_version: 0
    ).where("destination LIKE ?", "%#{@destination}%")
    
    # 找到价格适中的产品
    @target_product = @qualified_products.order(:price).first
    
    {
      task: "请预订#{@destination}私家团，#{@duration}天#{@duration - 1}晚，#{@adult_count}个成人#{@child_count}个儿童，独立成团（#{@travel_date.strftime('%Y年%m月%d日')}出发）",
      requirements: {
        destination: @destination,
        travel_type: @travel_type,
        travel_type_description: '独立成团/私家团（非跟团游、非自由行）',
        duration: @duration,
        adult_count: @adult_count,
        child_count: @child_count,
        travel_date: @travel_date.to_s,
        features: '独立成团，专属导游'
      },
      hint: "系统中有多个#{@destination}私家团产品可选，请选择#{@duration}天行程的独立成团产品",
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
      
      expect(@bookings).not_to be_empty, "未找到任何#{@destination}私家团订单"
      @booking = @bookings.first
    end
    
    return if @bookings.nil? || @bookings.empty?
    
    add_assertion "目的地正确（#{@destination}）", weight: 15 do
      expect(@booking.tour_group_product.destination).to include(@destination),
        "目的地错误。期望包含: #{@destination}，实际: #{@booking.tour_group_product.destination}"
    end
    
    add_assertion "旅游类型正确（独立成团）", weight: 20 do
      expect(@booking.tour_group_product.travel_type).to eq(@travel_type),
        "旅游类型错误。期望: #{@travel_type}（私家团），实际: #{@booking.tour_group_product.travel_type}"
    end
    
    add_assertion "天数正确（#{@duration}天）", weight: 15 do
      expect(@booking.tour_group_product.duration).to eq(@duration),
        "天数错误。期望: #{@duration}天，实际: #{@booking.tour_group_product.duration}天"
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
    
    # 查找符合条件的私家团产品
    target_product = TourGroupProduct.where(
      travel_type: @travel_type,
      duration: @duration,
      data_version: 0
    ).where("destination LIKE ?", "%#{@destination}%")
     .order(:price)
     .first
    
    raise "未找到符合条件的私家团产品" unless target_product
    
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
      contact_name: '王五',
      contact_phone: '13700137000',
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
