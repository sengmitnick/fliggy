# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例106: 给张三预订邮轮（海洋光谱号日韩航线6天5晚，含岸上观光+主厨晚餐需求）
#
# 核心验证点:
# 1. 订单创建: 邮轮订单创建成功
# 2. 船只选择: 海洋光谱号
# 3. 行程时长: 6天5晚
# 4. 特殊需求备注: 岸上观光（冲绳）
# 5. 特殊需求备注: 主厨晚餐
# 6. 班次选择: 最近日期的可用班次
module V101V150
  class V106BookCruiseWithPreferencesValidator < BaseValidator
    self.validator_id = 'v106_book_cruise_with_preferences_validator'
    self.task_id = 'b2c4e7f9-1d6a-4b8e-9c3f-5a7e2d8f1b94'
    self.title = '给张三预订邮轮（海洋光谱号日韩航线6天5晚，含岸上观光+主厨晚餐需求）'
    self.description = '预订邮轮（海洋光谱号日韩航线6天5晚，含岸上观光+主厨晚餐需求）'
    self.timeout_seconds = 240
  
    def prepare
      @ship_keyword = '海洋光谱号'
      @departure_port_keyword = '上海'
      @duration_days = 6
      @duration_nights = 5
      @cabin_category = 'interior'
      @adult_count = 2
      @special_requests_keywords = ['岸上观光', '冲绳', '主厨', '晚餐']
    
      # 预查询乘客信息（避免 simulate 中查询 data_version: 0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangjianguo = user.passengers.find_by!(name: '张建国', data_version: 0)
      @chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
      @expected_passenger_names = [@zhangjianguo.name, @chenjing.name]
      
      # 有效联系人电话映射
      @valid_contact_phones = {
        '张建国' => @zhangjianguo.phone,
        '陈静' => @chenjing.phone
      }
    
      # 查询可用船只
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
      # 断言1: 订单已创建（权重25%）
      add_assertion "订单已创建", weight: 25 do
        all_orders = CruiseOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
      
        expect(all_orders).not_to be_empty, "未找到任何邮轮订单"
        @order = all_orders.first
      end
    
      return if @order.nil?
    
      # 断言2: 船只正确（权重15%）
      add_assertion "船只正确（海洋光谱号）", weight: 15 do
        product = @order.cruise_product
        ship = product.cruise_sailing.cruise_ship
        expect(ship.name).to include(@ship_keyword),
          "船只不符合要求。期望包含: #{@ship_keyword}, 实际: #{ship.name}"
      end
    
      # 断言3: 行程天数正确（权重10%）
      add_assertion "行程天数正确（6天5晚）", weight: 10 do
        product = @order.cruise_product
        sailing = product.cruise_sailing
        expect(sailing.duration_days).to eq(@duration_days),
          "行程天数错误。期望: #{@duration_days}天, 实际: #{sailing.duration_days}天"
        expect(sailing.duration_nights).to eq(@duration_nights),
          "行程晚数错误。期望: #{@duration_nights}晚, 实际: #{sailing.duration_nights}晚"
      end
    
      # 断言4: 已备注岸上观光需求（权重20%）
      add_assertion "已备注岸上观光需求", weight: 20 do
        remark = @order.remark || ''
        shore_excursion_mentioned = remark.include?('岸上观光') || 
                                     remark.include?('冲绳') ||
                                     remark.include?('观光')
      
        expect(shore_excursion_mentioned).to be_truthy,
          "未在备注中说明岸上观光需求。实际备注: #{remark.empty? ? '(空)' : remark}"
      end
    
      # 断言5: 已备注餐饮需求（权重20%）
      add_assertion "已备注餐饮需求", weight: 20 do
        remark = @order.remark || ''
        dining_mentioned = remark.include?('主厨') ||
                          remark.include?('晚餐') ||
                          remark.include?('餐饮') ||
                          remark.include?('特色餐')
      
        expect(dining_mentioned).to be_truthy,
          "未在备注中说明餐饮需求。实际备注: #{remark.empty? ? '(空)' : remark}"
      end
    
      # 断言6: 联系人信息正确（权重10%）
      add_assertion "联系人信息正确（张建国或陈静）", weight: 10 do
        valid_contacts = ['张建国', '陈静']
        expect(valid_contacts).to include(@order.contact_name),
          "联系人姓名错误。期望: 张建国或陈静, 实际: #{@order.contact_name}"
        
        expected_phone = @valid_contact_phones[@order.contact_name]
        expect(@order.contact_phone).to eq(expected_phone),
          "联系人电话与姓名不匹配。联系人: #{@order.contact_name}, 期望电话: #{expected_phone}, 实际电话: #{@order.contact_phone}"
      end
    
      # 断言7: 选择了最近日期的班次（权重0%）- 不计分，仅用于记录
      add_assertion "选择了最近日期的班次", weight: 0 do
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
        special_requests_keywords: @special_requests_keywords,
        expected_passenger_names: @expected_passenger_names,
        valid_contact_phones: @valid_contact_phones
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
      @expected_passenger_names = data['expected_passenger_names'] || ['张建国', '陈静']
      @valid_contact_phones = data['valid_contact_phones'] || { '张建国' => '13800138001', '陈静' => '13100131009' }
      @available_ships = CruiseShip.where(data_version: 0).where('name LIKE ?', "%#{@ship_keyword}%")
    end
  
    def simulate
      # 查找演示用户（使用基线 data_version=0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 查找乘客信息（已在 prepare 中预查询）
      zhangjianguo = @zhangjianguo || user.passengers.find_by!(name: '张建国', data_version: 0)
      chenjing = @chenjing || user.passengers.find_by!(name: '陈静', data_version: 0)
      
      # 随机选择联系人
      contact_names = ['张建国', '陈静']
      selected_contact_name = contact_names.sample
      contact_passenger = selected_contact_name == '张建国' ? zhangjianguo : chenjing
      
      # 创建乘客信息数组
      passenger_info = [
        { name: zhangjianguo.name, id_number: zhangjianguo.id_number, phone: zhangjianguo.phone },
        { name: chenjing.name, id_number: chenjing.id_number, phone: chenjing.phone }
      ]
    
      # 查找船只（从基线数据中查找）
      ship = CruiseShip.where(data_version: 0).where('name LIKE ?', "%#{@ship_keyword}%").first
      raise "未找到符合条件的船只" unless ship
    
      # 查找日韩航线（从基线数据中查找）
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
    
      # 查找内舱房舱房类型（从基线数据中查找）
      cabin_type = CabinType.where(data_version: 0, cruise_ship_id: ship.id, category: @cabin_category).first
      raise "未找到符合条件的舱房类型" unless cabin_type
    
      # 查找或创建邮轮产品（关联班次和舱房）
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
    
      # 计算总价（每人价格 × 成人数量）
      total_price = cruise_product.price_per_person * @adult_count
    
      # 创建邮轮订单（包含特殊需求备注）
      CruiseOrder.create!(
        user_id: user.id,
        cruise_product_id: cruise_product.id,
        quantity: @adult_count,
        contact_name: contact_passenger.name,
        contact_phone: contact_passenger.phone,
        passenger_info: passenger_info,
        total_price: total_price,
        remark: '需要预订冲绳岸上观光套餐（首里城+美丽海水族馆）和主厨特选晚餐套餐（铁板烧+意大利餐）',
        accept_terms: true,
        status: 'pending',
        data_version: @data_version
      )
    end
  end
end