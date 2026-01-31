# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例106: 预订邮轮（包含岸上观光+餐饮需求）
module V101V150
  class V106BookCruiseWithPreferencesValidator < BaseValidator
    self.validator_id = 'v106_book_cruise_with_preferences_validator'
    self.task_id = 'b2c4e7f9-1d6a-4b8e-9c3f-5a7e2d8f1b94'
    self.title = '预订邮轮（海洋光谱号日韩航线，含岸上观光+主厨晚餐需求）'
    self.description = '预订日韩邮轮行程，在special_requests中备注冲绳岸上观光和主厨晚餐需求'
    self.timeout_seconds = 240
  
    def prepare
      @ship_keyword = '海洋光谱号'
      @departure_port_keyword = '上海'
      @duration_days = 6
      @duration_nights = 5
      @cabin_category = 'interior'
      @adult_count = 2
      @special_requests_keywords = ['岸上观光', '冲绳', '主厨', '晚餐']
    
      @available_ships = CruiseShip.where(data_version: 0).where('name LIKE ?', "%#{@ship_keyword}%")
    
      {
        task: "请预订上海出发的日韩邮轮，要求#{@ship_keyword}，行程#{@duration_days}天#{@duration_nights}晚，选择最近的一个班次，预订内舱房，为#{@adult_count}位成人。在订单备注（remark）中说明需要预订冲绳岸上观光套餐和主厨特选晚餐",
        ship_keyword: @ship_keyword,
        departure_port_keyword: @departure_port_keyword,
        duration: "#{@duration_days}天#{@duration_nights}晚",
        cabin_category: '内舱房（interior）',
        adult_count: @adult_count,
        special_requirements: '岸上观光套餐（冲绳）+ 主厨特选晚餐',
        hint: "筛选船只名包含'海洋光谱号'、出发港包含'上海'、duration_days=6且duration_nights=5的班次，选择最近日期的班次，预订内舱房。在remark字段中备注需要岸上观光和主厨晚餐",
        available_ships_count: @available_ships.count
      }
    end
  
    def verify
      add_assertion "订单已创建", weight: 25 do
        all_orders = CruiseOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
      
        expect(all_orders).not_to be_empty, "未找到任何邮轮订单"
        @order = all_orders.first
      end
    
      return if @order.nil?
    
      add_assertion "船只正确（海洋光谱号）", weight: 15 do
        product = @order.cruise_product
        ship = product.cruise_sailing.cruise_ship
        expect(ship.name).to include(@ship_keyword),
          "船只不符合要求。期望包含: #{@ship_keyword}, 实际: #{ship.name}"
      end
    
      add_assertion "行程天数正确（6天5晚）", weight: 10 do
        product = @order.cruise_product
        sailing = product.cruise_sailing
        expect(sailing.duration_days).to eq(@duration_days),
          "行程天数错误。期望: #{@duration_days}天, 实际: #{sailing.duration_days}天"
        expect(sailing.duration_nights).to eq(@duration_nights),
          "行程晚数错误。期望: #{@duration_nights}晚, 实际: #{sailing.duration_nights}晚"
      end
    
      add_assertion "已备注岸上观光需求", weight: 20 do
        remark = @order.remark || ''
        shore_excursion_mentioned = remark.include?('岸上观光') || 
                                     remark.include?('冲绳') ||
                                     remark.include?('观光')
      
        expect(shore_excursion_mentioned).to be_truthy,
          "未在备注中说明岸上观光需求。实际备注: #{remark.empty? ? '(空)' : remark}"
      end
    
      add_assertion "已备注餐饮需求", weight: 20 do
        remark = @order.remark || ''
        dining_mentioned = remark.include?('主厨') ||
                          remark.include?('晚餐') ||
                          remark.include?('餐饮') ||
                          remark.include?('特色餐')
      
        expect(dining_mentioned).to be_truthy,
          "未在备注中说明餐饮需求。实际备注: #{remark.empty? ? '(空)' : remark}"
      end
    
      add_assertion "选择了最近日期的班次", weight: 10 do
        ship = CruiseShip.where(data_version: 0).where('name LIKE ?', "%#{@ship_keyword}%").first
        japan_korea_route = CruiseRoute.where(data_version: 0).find_by(region: 'japan_korea')
      
        available_sailings = CruiseSailing.where(
          data_version: 0,
          cruise_ship_id: ship.id,
          cruise_route_id: japan_korea_route&.id,
          duration_days: @duration_days,
          duration_nights: @duration_nights
        ).where('departure_port LIKE ?', "%#{@departure_port_keyword}%")
      
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
        adult_count: @adult_count,
        special_requests_keywords: @special_requests_keywords
      }
    end
  
    def restore_from_state(data)
      @ship_keyword = data['ship_keyword']
      @departure_port_keyword = data['departure_port_keyword']
      @duration_days = data['duration_days']
      @duration_nights = data['duration_nights']
      @cabin_category = data['cabin_category']
      @adult_count = data['adult_count']
      @special_requests_keywords = data['special_requests_keywords'] || ['岸上观光', '冲绳', '主厨', '晚餐']
      @available_ships = CruiseShip.where(data_version: 0).where('name LIKE ?', "%#{@ship_keyword}%")
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      ship = CruiseShip.where(data_version: 0).where('name LIKE ?', "%#{@ship_keyword}%").first
      raise "未找到符合条件的船只" unless ship
    
      japan_korea_route = CruiseRoute.where(data_version: 0).find_by(region: 'japan_korea')
      raise "未找到日韩航线" unless japan_korea_route
    
      available_sailings = CruiseSailing.where(
        data_version: 0,
        cruise_ship_id: ship.id,
        cruise_route_id: japan_korea_route.id,
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
        product.merchant_name = '邮轮旅游网'
        product.price_per_person = 3500.0
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
        contact_name: '孙七',
        contact_phone: '13800138010',
        total_price: total_price,
        remark: '需要预订冲绳岸上观光套餐（首里城+美丽海水族馆）和主厨特选晚餐套餐（铁板烧+意大利餐）',
        accept_terms: true,
        status: 'pending',
        data_version: @data_version
      )
    end
  end
end
