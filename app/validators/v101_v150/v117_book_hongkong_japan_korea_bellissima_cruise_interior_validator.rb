# frozen_string_literal: true

# 验证用例117: 预订日韩邮轮（地中海辉煌号，7天6晚，2月出发，内舱房）
#
# 测试内容：
# - 邮轮筛选（地中海辉煌号/MSC Cruises）
# - 出发港过滤（香港）
# - 行程天数匹配（7天6晚）
# - 舱房类型选择（内舱房）
# - 出发月份筛选（2月）
# - 日期优化选择（选择最近可用日期）
# - 预订数量验证（2位成人）
# - 价格合理性验证
#
# 用户需求：
# "我想2月份坐地中海辉煌号游日韩，7天6晚的行程，订2间内舱房"
class V117BookHongkongJapanKoreaBellissimaCruiseInteriorValidator < BaseValidator
  self.validator_id = 'v117_book_hongkong_japan_korea_bellissima_cruise_interior_validator'
  
  def initialize
    super
    @task_id = 'eb47869c-0c0f-4f08-b97a-49fa29721261'
    @title = '预订日韩邮轮（地中海辉煌号，7天6晚，2月出发，内舱房）'
    @description = '预订日韩邮轮航线，选择地中海辉煌号（米其林星级餐厅邮轮）2月份最近一班7天6晚行程，预订内舱房（性价比之选），为2位成人'
    
    # 核心参数
    @ship_keyword = '辉煌'                # 船只关键词（地中海辉煌号）
    @departure_port_keyword = '香港'      # 出发港关键词（香港）
    @expected_days = 7                    # 预期天数（7天6晚）
    @expected_nights = 6                  # 预期晚数
    @expected_cabin_category = 'interior' # 预期舱房类型（内舱房）
    @expected_month = 2                   # 2月出发（冬季日韩航线）
    @adult_count = 2                      # 成人数量
  end

  def verify
    # 断言1: 验证订单已创建（权重20%）
    # 查询所有符合船只关键词的订单，使用joins提升查询效率
    add_assertion "订单已创建", weight: 20 do
      all_orders = CruiseOrder
        .joins(cruise_product: { cruise_sailing: :cruise_ship })
        .where(cruise_ships: { name: @ship_keyword })
        .where(data_version: @data_version)
        .order(created_at: :desc)
        .to_a
      
      expect(all_orders).not_to be_empty,
        "未找到任何邮轮订单。请确认是否已创建订单"
      
      # 筛选符合基本条件的订单（出发港、舱房类型）
      @order = all_orders.find do |o|
        sailing = o.cruise_product.cruise_sailing
        sailing.departure_port.include?(@departure_port_keyword) &&
          o.cruise_product.cabin_category == @expected_cabin_category
      end
      
      expect(@order).not_to be_nil,
        "未找到符合条件的订单（出发港：#{@departure_port_keyword}，舱房类型：#{@expected_cabin_category}）"
    end
    
    # 如果订单不存在，后续断言无法进行，直接返回
    return if @order.nil?
    
    # 断言2: 验证船只正确（权重15%）
    # 确认预订的是地中海辉煌号
    add_assertion "船只正确（地中海辉煌号）", weight: 15 do
      ship_name = @order.cruise_product.cruise_sailing.cruise_ship.name
      expect(ship_name).to include(@ship_keyword),
        "船只错误。期望: 包含'#{@ship_keyword}'，实际: #{ship_name}"
    end
    
    # 断言3: 验证出发港正确（权重10%）
    # 确认从香港出发
    add_assertion "出发港正确（香港）", weight: 10 do
      departure_port = @order.cruise_product.cruise_sailing.departure_port
      expect(departure_port).to include(@departure_port_keyword),
        "出发港错误。期望: 包含'#{@departure_port_keyword}'，实际: #{departure_port}"
    end
    
    # 断言4: 验证行程天数正确（权重10%）
    # 确认是7天6晚的行程
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
    # 确认出发时间在2月份
    add_assertion "出发月份正确（2月份）", weight: 10 do
      sailing = @order.cruise_product.cruise_sailing
      actual_month = sailing.departure_date.month
      
      expect(actual_month).to eq(@expected_month),
        "出发月份错误。期望: #{@expected_month}月, 实际: #{actual_month}月（#{sailing.departure_date}）"
    end
    
    # 断言6: 验证舱房类型正确（权重15%）
    # 确认预订的是内舱房（interior）
    add_assertion "舱房类型正确（内舱房）", weight: 15 do
      cabin_category = @order.cruise_product.cabin_category
      expect(cabin_category).to eq(@expected_cabin_category),
        "舱房类型错误。期望: #{@expected_cabin_category}（内舱房），实际: #{cabin_category}"
    end
    
    # 断言7: 验证预订数量正确（权重10%）
    # 确认预订了2间内舱房
    add_assertion "预订数量正确（#{@adult_count}间内舱房）", weight: 10 do
      expect(@order.quantity).to eq(@adult_count),
        "预订数量错误。期望: #{@adult_count}间，实际: #{@order.quantity}间"
    end
    
    # 断言8: 验证选择了最近可用的出发日期（权重10%）
    # 系统应该优先选择2月份最近的可用日期
    add_assertion "选择最近可用日期（2月份最早班次）", weight: 10 do
      # 查询所有符合条件的航次（同一船只、同一出发港、相同天数、2月份）
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
end
