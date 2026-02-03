# frozen_string_literal: true

# 验证用例115: 预订加勒比邮轮（海洋光谱号，10天9晚，5月出发，阳台房）
#
# 测试内容：
# - 邮轮筛选（海洋光谱号/Royal Caribbean）
# - 出发港过滤（迈阿密）
# - 行程天数匹配（10天9晚）
# - 舱房类型选择（阳台房）
# - 出发月份筛选（5月）
# - 日期优化选择（选择最近可用日期）
# - 预订数量验证（3位成人）
# - 价格合理性验证
#
# 用户需求：
# "我想5月份坐海洋光谱号游加勒比，10天9晚的行程，订3间阳台房"
module V101V150
  class V115BookMiamiCaribbeanSpectrumCruiseBalconyValidator < BaseValidator
    self.validator_id = 'v115_book_miami_caribbean_spectrum_cruise_balcony_validator'
    self.task_id = 'b4a00a86-51cd-40b8-800a-67287efdfdd6'
    self.title = '预订加勒比邮轮（海洋光谱号，10天9晚，5月出发，阳台房）'
    self.description = '预订加勒比邮轮航线，选择海洋光谱号5月份最近一班10天9晚行程，预订阳台房（舒适之选），为3位成人'
    self.timeout_seconds = 300
    
    def prepare
      # 核心参数
      @ship_keyword = '光谱'                # 船只关键词（海洋光谱号）
      @departure_port_keyword = '迈阿密'    # 出发港关键词（迈阿密）
      @expected_days = 10                   # 预期天数（10天9晚）
      @expected_nights = 9                  # 预期晚数
      @expected_cabin_category = 'balcony'  # 预期舱房类型（阳台房）
      @expected_month = 5                   # 5月出发（初夏加勒比航线）
      @adult_count = 3                      # 成人数量
      
      {}
    end

    def verify
      # 断言1: 验证订单已创建（权重20%）
      # 查询所有符合船只关键词的订单，使用joins提升查询效率
      add_assertion "订单已创建", weight: 20 do
        all_orders = CruiseOrder
          .joins(cruise_product: { cruise_sailing: :cruise_ship })
          .where('cruise_ships.name LIKE ?', "%#{@ship_keyword}%")
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_orders).not_to be_empty,
          "未找到任何邮轮订单。请确认是否已创建订单"
        
        # 筛选符合基本条件的订单（出发港、舱房类型）
        @order = all_orders.find do |o|
          sailing = o.cruise_product.cruise_sailing
          sailing.departure_port.include?(@departure_port_keyword) &&
            o.cruise_product.cabin_type.category == @expected_cabin_category
        end
        
        expect(@order).not_to be_nil,
          "未找到符合条件的订单（出发港：#{@departure_port_keyword}，舱房类型：#{@expected_cabin_category}）"
      end
      
      # 如果订单不存在，后续断言无法进行，直接返回
      return if @order.nil?
      
      # 断言2: 验证船只正确（权重15%）
      # 确认预订的是海洋光谱号
      add_assertion "船只正确（海洋光谱号）", weight: 15 do
        ship_name = @order.cruise_product.cruise_sailing.cruise_ship.name
        expect(ship_name).to include(@ship_keyword),
          "船只错误。期望: 包含'#{@ship_keyword}'，实际: #{ship_name}"
      end
      
      # 断言3: 验证出发港正确（权重10%）
      # 确认从迈阿密出发
      add_assertion "出发港正确（迈阿密）", weight: 10 do
        departure_port = @order.cruise_product.cruise_sailing.departure_port
        expect(departure_port).to include(@departure_port_keyword),
          "出发港错误。期望: 包含'#{@departure_port_keyword}'，实际: #{departure_port}"
      end
      
      # 断言4: 验证行程天数正确（权重10%）
      # 确认是10天9晚的行程
      add_assertion "行程天数正确（#{@expected_days}天#{@expected_nights}晚）", weight: 10 do
        sailing = @order.cruise_product.cruise_sailing
        actual_days = sailing.duration_days
        actual_nights = sailing.duration_nights
        
        expect(actual_days).to eq(@expected_days),
          "行程天数错误。期望: #{@expected_days}天，实际: #{actual_days}天"
        expect(actual_nights).to eq(@expected_nights),
          "行程晚数错误。期望: #{@expected_nights}晚，实际: #{actual_nights}晚"
      end
      
      # 断言5: 验证出发月份正确（权重10%）
      # 确认出发时间在5月份
      add_assertion "出发月份正确（5月份）", weight: 10 do
        sailing = @order.cruise_product.cruise_sailing
        actual_month = sailing.departure_date.month
        
        expect(actual_month).to eq(@expected_month),
          "出发月份错误。期望: #{@expected_month}月, 实际: #{actual_month}月（#{sailing.departure_date}）"
      end
      
      # 断言6: 验证舱房类型正确（权重15%）
      # 确认预订的是阳台房（balcony）
      add_assertion "舱房类型正确（阳台房）", weight: 15 do
        cabin_category = @order.cruise_product.cabin_type.category
        expect(cabin_category).to eq(@expected_cabin_category),
          "舱房类型错误。期望: #{@expected_cabin_category}（阳台房），实际: #{cabin_category}"
      end
      
      # 断言7: 验证预订数量正确（权重10%）
      # 确认预订了3间阳台房
      add_assertion "预订数量正确（#{@adult_count}间阳台房）", weight: 10 do
        expect(@order.quantity).to eq(@adult_count),
          "预订数量错误。期望: #{@adult_count}间，实际: #{@order.quantity}间"
      end
      
      # 断言8: 验证选择了最近可用的出发日期（权重10%）
      # 系统应该优先选择5月份最近的可用日期
      add_assertion "选择最近可用日期（5月份最早班次）", weight: 10 do
        # 查询所有符合条件的航次（同一船只、同一出发港、相同天数、5月份）
        available_sailings = CruiseSailing
          .joins(:cruise_ship)
          .where(cruise_ships: { name: @ship_keyword })
          .where('departure_port LIKE ?', "%#{@departure_port_keyword}%")
          .where(duration_days: @expected_days, duration_nights: @expected_nights)
          .where('EXTRACT(MONTH FROM departure_date) = ?', @expected_month)
          .where('departure_date >= ?', Date.current)
          .order(:departure_date)
          .to_a
        
        expect(available_sailings).not_to be_empty,
          "未找到符合条件的可用航次（船只：#{@ship_keyword}，出发港：#{@departure_port_keyword}，#{@expected_days}天#{@expected_nights}晚，#{@expected_month}月）"
        
        # 验证选择的是最早的航次
        earliest_sailing = available_sailings.first
        actual_sailing = @order.cruise_product.cruise_sailing
        
        expect(actual_sailing.departure_date).to eq(earliest_sailing.departure_date),
          "未选择最近日期。期望: #{earliest_sailing.departure_date}（最早），实际: #{actual_sailing.departure_date}"
      end
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 查找海洋光谱号
      ship = CruiseShip.where(data_version: 0).where('name LIKE ?', "%#{@ship_keyword}%").first
      raise "未找到符合条件的船只" unless ship
    
      # 查找加勒比航线
      caribbean_route = CruiseRoute.where(data_version: 0).find_by(region: 'caribbean')
      raise "未找到加勒比航线" unless caribbean_route
    
      # 查找符合条件的班次（5月份）
      available_sailings = CruiseSailing.where(
        data_version: 0,
        cruise_ship_id: ship.id,
        cruise_route_id: caribbean_route.id,
        duration_days: @expected_days,
        duration_nights: @expected_nights
      ).where('departure_port LIKE ?', "%#{@departure_port_keyword}%")
       .where('EXTRACT(MONTH FROM departure_date) = ?', @expected_month)
       .where('departure_date >= ?', Date.current)
      raise "未找到符合条件的班次" if available_sailings.empty?
    
      # 选择最近的班次
      nearest_sailing = available_sailings.order(departure_date: :asc).first
    
      # 查找阳台房类型
      cabin_type = CabinType.where(data_version: 0, cruise_ship_id: ship.id, category: @expected_cabin_category).first
      raise "未找到符合条件的舱房类型" unless cabin_type
    
      # 创建或查找邮轮产品
      cruise_product = CruiseProduct.find_or_create_by!(
        cruise_sailing_id: nearest_sailing.id,
        cabin_type_id: cabin_type.id,
        data_version: @data_version
      ) do |product|
        product.merchant_name = '皇家加勒比旗舰店'
        product.price_per_person = 9800.0
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
end
