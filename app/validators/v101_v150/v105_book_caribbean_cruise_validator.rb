# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例105: 预订加勒比邮轮（海洋光谱号，10天9晚，迈阿密出发）
#
# 核心验证点:
# 1. 船只选择: 海洋光谱号
# 2. 出发港口: 迈阿密
# 3. 行程时长: 10天9晚
# 4. 舱房类型: 豪华套房（suite）
# 5. 班次选择: 最近日期的可用班次
# 6. 订单信息: 联系人、电话、成人数量、总价计算
module V101V150
  class V105BookCaribbeanCruiseValidator < BaseValidator
    self.validator_id = 'v105_book_caribbean_cruise_validator'
    self.task_id = 'f5e2d8c1-4a9b-3d76-8e1f-6c3a5b4d9e72'
    self.title = '预订加勒比邮轮（海洋光谱号，10天9晚，迈阿密出发）'
    self.description = '预订加勒比航线邮轮，选择海洋光谱号10天9晚行程，迈阿密出发，选择最近可用的班次，预订豪华套房'
    self.timeout_seconds = 240
  
    def prepare
      @ship_keyword = '海洋光谱号'
      @departure_port_keyword = '迈阿密'
      @duration_days = 10
      @duration_nights = 9
      @cabin_category = 'suite'
      @adult_count = 2
    
      # 查询可用船只
      @available_ships = CruiseShip.where(data_version: 0).where('name LIKE ?', "%#{@ship_keyword}%")
    
      {
        task: "请预订加勒比邮轮，要求#{@ship_keyword}，行程#{@duration_days}天#{@duration_nights}晚，从#{@departure_port_keyword}出发，选择最近的一个班次，预订豪华套房（suite），为#{@adult_count}位成人",
        ship_keyword: @ship_keyword,
        departure_port_keyword: @departure_port_keyword,
        duration: "#{@duration_days}天#{@duration_nights}晚",
        cabin_category: '豪华套房（suite）',
        adult_count: @adult_count,
        hint: "筛选船只名包含'海洋光谱号'、出发港包含'迈阿密'、duration_days=10且duration_nights=9的班次，选择最近日期的班次，预订豪华套房（category='suite'）",
        available_ships_count: @available_ships.count
      }
    end
  
    def verify
      # 断言1: 订单已创建（权重20%）
      add_assertion "订单已创建", weight: 20 do
        all_orders = CruiseOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
      
        expect(all_orders).not_to be_empty, "未找到任何邮轮订单"
        @order = all_orders.first
      end
    
      return if @order.nil?
    
      # 断言2: 船只正确（权重20%）
      add_assertion "船只正确（海洋光谱号）", weight: 20 do
        product = @order.cruise_product
        ship = product.cruise_sailing.cruise_ship
        expect(ship.name).to include(@ship_keyword),
          "船只不符合要求。期望包含: #{@ship_keyword}, 实际: #{ship.name}"
      end
    
      # 断言3: 出发港正确（权重15%）
      add_assertion "出发港正确（迈阿密）", weight: 15 do
        product = @order.cruise_product
        sailing = product.cruise_sailing
        expect(sailing.departure_port).to include(@departure_port_keyword),
          "出发港不符合要求。期望包含: #{@departure_port_keyword}, 实际: #{sailing.departure_port}"
      end
    
      # 断言4: 行程天数正确（权重15%）
      add_assertion "行程天数正确（10天9晚）", weight: 15 do
        product = @order.cruise_product
        sailing = product.cruise_sailing
        expect(sailing.duration_days).to eq(@duration_days),
          "行程天数错误。期望: #{@duration_days}天, 实际: #{sailing.duration_days}天"
        expect(sailing.duration_nights).to eq(@duration_nights),
          "行程晚数错误。期望: #{@duration_nights}晚, 实际: #{sailing.duration_nights}晚"
      end
    
      # 断言5: 舱房类型正确（权重15%）
      add_assertion "舱房类型正确（豪华套房）", weight: 15 do
        product = @order.cruise_product
        cabin = product.cabin_type
        expect(cabin.category).to eq(@cabin_category),
          "舱房类型错误。期望: #{@cabin_category}（豪华套房），实际: #{cabin.category}（#{cabin.name}）"
      end
    
      # 断言6: 选择了最近日期的班次（权重15%）
      add_assertion "选择了最近日期的班次", weight: 15 do
        ship = CruiseShip.where(data_version: 0).where('name LIKE ?', "%#{@ship_keyword}%").first
        caribbean_route = CruiseRoute.where(data_version: 0).find_by(region: 'caribbean')
      
        available_sailings = CruiseSailing.where(
          data_version: 0,
          cruise_ship_id: ship.id,
          cruise_route_id: caribbean_route&.id,
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
      # 查找演示用户（使用基线 data_version=0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 查找船只（从基线数据中查找）
      ship = CruiseShip.where(data_version: 0).where('name LIKE ?', "%#{@ship_keyword}%").first
      raise "未找到符合条件的船只" unless ship
    
      # 查找加勒比航线（从基线数据中查找）
      caribbean_route = CruiseRoute.where(data_version: 0).find_by(region: 'caribbean')
      raise "未找到加勒比航线" unless caribbean_route
    
      # 查找符合条件的班次（10天9晚，迈阿密出发）
      available_sailings = CruiseSailing.where(
        data_version: 0,
        cruise_ship_id: ship.id,
        cruise_route_id: caribbean_route.id,
        duration_days: @duration_days,
        duration_nights: @duration_nights
      ).where('departure_port LIKE ?', "%#{@departure_port_keyword}%")
      raise "未找到符合条件的班次" if available_sailings.empty?
    
      # 选择最近日期的班次
      nearest_sailing = available_sailings.order(departure_date: :asc).first
    
      # 查找豪华套房舱房类型（从基线数据中查找）
      cabin_type = CabinType.where(data_version: 0, cruise_ship_id: ship.id, category: @cabin_category).first
      raise "未找到符合条件的舱房类型" unless cabin_type
    
      # 查找或创建邮轮产品（关联班次和舱房）
      cruise_product = CruiseProduct.find_or_create_by!(
        cruise_sailing_id: nearest_sailing.id,
        cabin_type_id: cabin_type.id,
        data_version: @data_version
      ) do |product|
        product.merchant_name = '皇家加勒比国际游轮旗舰店'
        product.price_per_person = 15000.0
        product.occupancy_requirement = 2
        product.stock = 5
        product.sales_count = 0
        product.is_refundable = true
        product.requires_confirmation = false
        product.status = 'on_sale'
      end
    
      # 计算总价（每人价格 × 成人数量）
      total_price = cruise_product.price_per_person * @adult_count
    
      # 创建邮轮订单
      CruiseOrder.create!(
        user_id: user.id,
        cruise_product_id: cruise_product.id,
        quantity: @adult_count,
        contact_name: '赵六',
        contact_phone: '13800138009',
        total_price: total_price,
        accept_terms: true,
        status: 'pending',
        data_version: @data_version
      )
    end
  end
end
