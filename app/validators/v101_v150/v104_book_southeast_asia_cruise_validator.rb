# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例104: 预订东南亚邮轮
class V104BookSoutheastAsiaCruiseValidator < BaseValidator
  self.validator_id = 'v104_book_southeast_asia_cruise_validator'
  self.task_id = '8a7d1f3e-9c2b-4e85-a1f4-5d6c8e2b7a91'
  self.title = '预订东南亚邮轮（爱达新星号，7天6晚，香港出发）'
  self.description = '预订东南亚航线邮轮，选择爱达新星号7天6晚行程，香港出发，预订海景房（性价比之选）'
  self.timeout_seconds = 240
  
  def prepare
    @ship_keyword = '爱达新星号'
    @departure_port_keyword = '香港'
    @duration_days = 7
    @duration_nights = 6
    @cabin_category = 'ocean_view'
    @adult_count = 2
    
    @available_ships = CruiseShip.where(data_version: 0).where('name LIKE ?', "%#{@ship_keyword}%")
    
    {
      task: "请预订东南亚邮轮，要求#{@ship_keyword}，行程#{@duration_days}天#{@duration_nights}晚，从#{@departure_port_keyword}出发，选择最近的一个班次，预订海景房（性价比之选），为#{@adult_count}位成人",
      ship_keyword: @ship_keyword,
      departure_port_keyword: @departure_port_keyword,
      duration: "#{@duration_days}天#{@duration_nights}晚",
      cabin_category: '海景房（ocean_view）',
      adult_count: @adult_count,
      hint: "筛选船只名包含'爱达新星号'、出发港包含'香港'、duration_days=7且duration_nights=6的班次，选择最近日期的班次，预订海景房（category='ocean_view'）",
      available_ships_count: @available_ships.count
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 20 do
      all_orders = CruiseOrder
        .where(data_version: @data_version)
        .order(created_at: :desc)
        .to_a
      
      expect(all_orders).not_to be_empty, "未找到任何邮轮订单"
      @order = all_orders.first
    end
    
    return if @order.nil?
    
    add_assertion "船只正确（爱达新星号）", weight: 20 do
      product = @order.cruise_product
      ship = product.cruise_sailing.cruise_ship
      expect(ship.name).to include(@ship_keyword),
        "船只不符合要求。期望包含: #{@ship_keyword}, 实际: #{ship.name}"
    end
    
    add_assertion "出发港正确（香港）", weight: 15 do
      product = @order.cruise_product
      sailing = product.cruise_sailing
      expect(sailing.departure_port).to include(@departure_port_keyword),
        "出发港不符合要求。期望包含: #{@departure_port_keyword}, 实际: #{sailing.departure_port}"
    end
    
    add_assertion "行程天数正确（7天6晚）", weight: 15 do
      product = @order.cruise_product
      sailing = product.cruise_sailing
      expect(sailing.duration_days).to eq(@duration_days),
        "行程天数错误。期望: #{@duration_days}天, 实际: #{sailing.duration_days}天"
      expect(sailing.duration_nights).to eq(@duration_nights),
        "行程晚数错误。期望: #{@duration_nights}晚, 实际: #{sailing.duration_nights}晚"
    end
    
    add_assertion "舱房类型正确（海景房）", weight: 15 do
      product = @order.cruise_product
      cabin = product.cabin_type
      expect(cabin.category).to eq(@cabin_category),
        "舱房类型错误。期望: #{@cabin_category}（海景房），实际: #{cabin.category}（#{cabin.name}）"
    end
    
    add_assertion "选择了最近日期的班次", weight: 15 do
      ship = CruiseShip.where(data_version: 0).where('name LIKE ?', "%#{@ship_keyword}%").first
      southeast_asia_route = CruiseRoute.where(data_version: 0).find_by(region: 'southeast_asia')
      
      available_sailings = CruiseSailing.where(
        data_version: 0,
        cruise_ship_id: ship.id,
        cruise_route_id: southeast_asia_route&.id,
        duration_days: @duration_days,
        duration_nights: @duration_nights
      ).where('departure_port LIKE ?', "%#{@departure_port_keyword}%")
      
      expect(available_sailings).not_to be_empty, "未找到符合条件的班次"
      
      nearest = available_sailings.order(departure_date: :asc).first
      actual_sailing = @order.cruise_product.cruise_sailing
      expect(actual_sailing.id).to eq(nearest.id),
        "未选择最近日期的班次。应选: #{nearest.departure_date}, 实际: #{actual_sailing.departure_date}"
    end
  end
  
  def execution_state_data
    { 
      ship_keyword: @ship_keyword, 
      departure_port_keyword: @departure_port_keyword, 
      duration_days: @duration_days,
      duration_nights: @duration_nights, 
      cabin_category: @cabin_category, 
      adult_count: @adult_count 
    }
  end
  
  def restore_from_state(data)
    @ship_keyword = data['ship_keyword']
    @departure_port_keyword = data['departure_port_keyword']
    @duration_days = data['duration_days']
    @duration_nights = data['duration_nights']
    @cabin_category = data['cabin_category']
    @adult_count = data['adult_count']
    @available_ships = CruiseShip.where(data_version: 0).where('name LIKE ?', "%#{@ship_keyword}%")
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    ship = CruiseShip.where(data_version: 0).where('name LIKE ?', "%#{@ship_keyword}%").first
    raise "未找到符合条件的船只" unless ship
    
    southeast_asia_route = CruiseRoute.where(data_version: 0).find_by(region: 'southeast_asia')
    raise "未找到东南亚航线" unless southeast_asia_route
    
    available_sailings = CruiseSailing.where(
      data_version: 0,
      cruise_ship_id: ship.id,
      cruise_route_id: southeast_asia_route.id,
      duration_days: @duration_days,
      duration_nights: @duration_nights
    ).where('departure_port LIKE ?', "%#{@departure_port_keyword}%")
    raise "未找到符合条件的班次" if available_sailings.empty?
    
    nearest_sailing = available_sailings.order(departure_date: :asc).first
    
    cabin_type = CabinType.where(data_version: 0, cruise_ship_id: ship.id, category: @cabin_category).first
    raise "未找到符合条件的舱房类型" unless cabin_type
    
    # Find or create CruiseProduct
    cruise_product = CruiseProduct.find_or_create_by!(
      cruise_sailing_id: nearest_sailing.id,
      cabin_type_id: cabin_type.id,
      data_version: @data_version
    ) do |product|
      product.merchant_name = 'AIDA邮轮旗舰店'
      product.price_per_person = 4500.0
      product.occupancy_requirement = 2
      product.stock = 10
      product.sales_count = 0
      product.is_refundable = true
      product.requires_confirmation = false
      product.status = 'on_sale'
    end
    
    total_price = cruise_product.price_per_person * @adult_count
    
    CruiseOrder.create!(
      user_id: user.id,
      cruise_product_id: cruise_product.id,
      quantity: @adult_count,
      contact_name: '王五',
      contact_phone: '13800138008',
      total_price: total_price,
      accept_terms: true,
      status: 'pending',
      data_version: @data_version
    )
  end
end
