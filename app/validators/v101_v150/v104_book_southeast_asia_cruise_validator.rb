# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例104: 给王芳、刘强预订香港出发东南亚邮轮（爱达新星号，7天6晚，海景房，选择最近的班次）
#
# 任务描述:
#   用户想预订香港出发的东南亚邮轮，为2位成人（王芳、刘强）。
#   要求爱达新星号，行程7天6晚，选择最近的一个班次，预订海景房（性价比之选）。
#   Agent 需要在符合条件的班次中，选择departure_date（出发日期）最早的班次。
#
# 业务流程（6个关键步骤）：
#   1. 搜索香港出发的东南亚邮轮产品
#   2. 筛选船只名包含"爱达新星号"的班次
#   3. 筛选出发港包含"香港"、行程7天6晚的班次
#   4. 筛选东南亚航线（region='southeast_asia'）的班次
#   5. 选择departure_date最早的班次
#   6. 预订海景房（category='ocean_view'），为2位成人
#
# 复杂度分析（6个关键点）：
#   1. 需要理解邮轮筛选：船只名包含"爱达新星号"
#   2. 需要理解出发港筛选：departure_port包含"香港"
#   3. 需要理解行程天数：duration_days=7且duration_nights=6
#   4. 需要理解航线区域筛选：region='southeast_asia'（东南亚航线）
#   5. 需要选择最近的班次：对比多个班次的departure_date，选择最早的
#   6. 需要填写2位成人的出行信息，联系人从出行人中选择
#   ❌ 不能随机选择：必须精确筛选并选择最早日期的班次
#
# 评分标准（9项，总计100分）：
#   - 订单已创建（15分）
#   - 船只正确（爱达新星号）（10分）
#   - 出发港正确（香港）（10分）
#   - 行程天数正确（7天6晚）（10分）
#   - 舱房类型正确（海景房）（10分）
#   - 预订数量正确（2位成人）（10分）
#   - 联系人信息正确（王芳或刘强）（10分）
#   - 选择了最近日期的班次（15分）
#   - 乘客信息正确（王芳、刘强）（10分）
module V101V150
  class V104BookSoutheastAsiaCruiseValidator < BaseValidator
    self.validator_id = 'v104_book_southeast_asia_cruise_validator'
    self.task_id = '8a7d1f3e-9c2b-4e85-a1f4-5d6c8e2b7a91'
    self.title = '给王芳、刘强预订香港出发东南亚邮轮（爱达新星号，7天6晚，海景房，选择最近的班次）'
    self.description = '预订香港出发东南亚邮轮（爱达新星号，7天6晚，海景房）'
    self.timeout_seconds = 240
  
    def prepare
      @ship_keyword = '爱达新星号'
      @departure_port_keyword = '香港'
      @duration_days = 7
      @duration_nights = 6
      @cabin_category = 'ocean_view'
      @adult_count = 2
    
      # 预查询乘客信息（避免 simulate 中查询 data_version: 0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @expected_passenger_names = [@wangfang.name, @liuqiang.name]
      
      # 有效联系人电话映射
      @valid_contact_phones = {
        '王芳' => @wangfang.phone,
        '刘强' => @liuqiang.phone
      }
    
      # 查询可用船只
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
      # 断言1: 订单已创建（15%）
      add_assertion "订单已创建", weight: 15 do
        all_orders = CruiseOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
      
        expect(all_orders).not_to be_empty, "未找到任何邮轮订单"
        @order = all_orders.first
      end
    
      return if @order.nil?
    
      # 断言2: 船只正确（10%）
      add_assertion "船只正确（爱达新星号）", weight: 10 do
        product = @order.cruise_product
        ship = product.cruise_sailing.cruise_ship
        expect(ship.name).to include(@ship_keyword),
          "船只不符合要求。期望包含: #{@ship_keyword}, 实际: #{ship.name}"
      end
    
      # 断言3: 出发港正确（10%）
      add_assertion "出发港正确（香港）", weight: 10 do
        product = @order.cruise_product
        sailing = product.cruise_sailing
        expect(sailing.departure_port).to include(@departure_port_keyword),
          "出发港不符合要求。期望包含: #{@departure_port_keyword}, 实际: #{sailing.departure_port}"
      end
    
      # 断言4: 行程天数正确（10%）
      add_assertion "行程天数正确（7天6晚）", weight: 10 do
        product = @order.cruise_product
        sailing = product.cruise_sailing
        expect(sailing.duration_days).to eq(@duration_days),
          "行程天数错误。期望: #{@duration_days}天, 实际: #{sailing.duration_days}天"
        expect(sailing.duration_nights).to eq(@duration_nights),
          "行程晚数错误。期望: #{@duration_nights}晚, 实际: #{sailing.duration_nights}晚"
      end
    
      # 断言5: 舱房类型正确（10%）
      add_assertion "舱房类型正确（海景房）", weight: 10 do
        product = @order.cruise_product
        cabin = product.cabin_type
        expect(cabin.category).to eq(@cabin_category),
          "舱房类型错误。期望: #{@cabin_category}（海景房），实际: #{cabin.category}（#{cabin.name}）"
      end
    
      # 断言6: 预订数量正确（10%）
      add_assertion "预订数量正确（#{@adult_count}位成人）", weight: 10 do
        expect(@order.quantity).to eq(@adult_count),
          "预订数量错误。期望: #{@adult_count}位成人, 实际: #{@order.quantity}位"
      end
    
      # 断言7: 联系人信息正确（10%）- 验证联系人为王芳或刘强，且电话匹配
      add_assertion "联系人信息正确（王芳或刘强）", weight: 10 do
        valid_contacts = ['王芳', '刘强']
        expect(valid_contacts).to include(@order.contact_name),
          "联系人姓名错误。期望: 王芳或刘强, 实际: #{@order.contact_name}"
        
        expected_phone = @valid_contact_phones[@order.contact_name]
        expect(@order.contact_phone).to eq(expected_phone),
          "联系人电话与姓名不匹配。联系人: #{@order.contact_name}, 期望电话: #{expected_phone}, 实际电话: #{@order.contact_phone}"
      end
    
      # 断言8: 选择了最近日期的班次（15%）- 在所有符合条件的班次中选择最早的
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
          "未选择最近日期的班次。应选: #{nearest.departure_date}（#{nearest.departure_date.strftime('%m月%d日')}），实际: #{actual_sailing.departure_date}（#{actual_sailing.departure_date.strftime('%m月%d日')}）"
      end
  
      # 断言9: 乘客信息正确（10%）- 验证填写了王芳、刘强的乘客信息
      add_assertion "乘客信息正确（王芳、刘强）", weight: 10 do
        passenger_list = @order.passenger_list
        expect(passenger_list).not_to be_empty, "未填写乘客信息（passenger_info为空）"
        expect(passenger_list.size).to eq(@adult_count),
          "乘客数量错误。期望: #{@adult_count}位, 实际: #{passenger_list.size}位"
        
        passenger_names = passenger_list.map { |p| p['name'] || p[:name] }.compact
        @expected_passenger_names.each do |expected_name|
          expect(passenger_names).to include(expected_name),
            "缺少乘客信息。期望包含: #{expected_name}, 实际乘客: #{passenger_names.join('、')}"
        end
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
      @expected_passenger_names = data['expected_passenger_names'] || ['王芳', '刘强']
      @valid_contact_phones = data['valid_contact_phones'] || { '王芳' => '13900139001', '刘强' => '13700137002' }
      @available_ships = CruiseShip.where(data_version: 0).where('name LIKE ?', "%#{@ship_keyword}%")
    end
  
    def simulate
      # 查找演示用户（使用基线 data_version=0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 查找乘客信息（已在 prepare 中预查询）
      wangfang = @wangfang || user.passengers.find_by!(name: '王芳', data_version: 0)
      liuqiang = @liuqiang || user.passengers.find_by!(name: '刘强', data_version: 0)
      
      # 随机选择联系人
      contact_names = ['王芳', '刘强']
      selected_contact_name = contact_names.sample
      contact_passenger = selected_contact_name == '王芳' ? wangfang : liuqiang
      
      # 创建乘客信息数组
      passenger_info = [
        { name: wangfang.name, id_number: wangfang.id_number, phone: wangfang.phone },
        { name: liuqiang.name, id_number: liuqiang.id_number, phone: liuqiang.phone }
      ]
    
      # 查找船只（从基线数据中查找）
      ship = CruiseShip.where(data_version: 0).where('name LIKE ?', "%#{@ship_keyword}%").first
      raise "未找到符合条件的船只" unless ship
    
      # 查找东南亚航线（从基线数据中查找）
      southeast_asia_route = CruiseRoute.where(data_version: 0).find_by(region: 'southeast_asia')
      raise "未找到东南亚航线" unless southeast_asia_route
    
      # 查找符合条件的班次（7天6晚，香港出发）
      available_sailings = CruiseSailing.where(
        data_version: 0,
        cruise_ship_id: ship.id,
        cruise_route_id: southeast_asia_route.id,
        duration_days: @duration_days,
        duration_nights: @duration_nights
      ).where('departure_port LIKE ?', "%#{@departure_port_keyword}%")
      raise "未找到符合条件的班次" if available_sailings.empty?
    
      # 选择最近日期的班次
      nearest_sailing = available_sailings.order(departure_date: :asc).first
    
      # 查找海景房舱房类型（从基线数据中查找）
      cabin_type = CabinType.where(data_version: 0, cruise_ship_id: ship.id, category: @cabin_category).first
      raise "未找到符合条件的舱房类型" unless cabin_type
    
      # 查找或创建邮轮产品（关联班次和舱房）
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
    
      # 计算总价（每人价格 × 成人数量）
      total_price = cruise_product.price_per_person * @adult_count
    
      # 创建邮轮订单
      CruiseOrder.create!(
        user_id: user.id,
        cruise_product_id: cruise_product.id,
        quantity: @adult_count,
        contact_name: contact_passenger.name,
        contact_phone: contact_passenger.phone,
        passenger_info: passenger_info,
        total_price: total_price,
        accept_terms: true,
        status: 'pending',
        data_version: @data_version
      )
    end
  end
end
