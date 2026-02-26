# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例95: 给张三预订香港出发日韩邮轮（海洋光谱号，6天5晚，1月出发）
# 测试内容：邮轮筛选、出发港过滤、行程天数匹配、舱房类型选择、出发月份筛选、日期优化选择、预订数量验证
module V051V100
  class V095BookShanghaiToJapanKoreaCruiseValidator < BaseValidator
    self.validator_id = 'v095_book_shanghai_to_japan_korea_cruise_validator'
    self.task_id = '25e31a26-07fd-4515-91c9-91e037c21aa4'
    self.title = '给张三预订香港出发日韩邮轮（海洋光谱号，6天5晚，1月出发）'
    self.description = '预订香港出发日韩邮轮（海洋光谱号，6天5晚，1月出发）'
    self.timeout_seconds = 240
  
    def prepare
      @ship_keyword = '海洋光谱号'
      @departure_port_keyword = '香港'
      @duration_days = 6
      @duration_nights = 5
      @cabin_category = 'interior'
      @adult_count = 2
      @expected_month = 1  # 1月出发（冬季日韩航线）
    
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_passenger_names = [@zhangsan.name, @lisi.name]
      
      # 有效联系人电话映射
      @valid_contact_phones = {
        '张三' => @zhangsan.phone,
        '李四' => @lisi.phone
      }
    
      @available_ships = CruiseShip.where(data_version: 0).where('name LIKE ?', "%#{@ship_keyword}%")
    
      {
        task: "请预订香港出发的日韩邮轮，要求#{@ship_keyword}，行程#{@duration_days}天#{@duration_nights}晚，选择1月份最近的一个班次，预订内舱房（性价比之选），为#{@adult_count}位成人",
        ship_keyword: @ship_keyword,
        departure_port_keyword: @departure_port_keyword,
        duration: "#{@duration_days}天#{@duration_nights}晚",
        cabin_category: '内舱房（interior）',
        adult_count: @adult_count,
        departure_month: '1月（冬季日韩航线）',
        hint: "筛选船只名包含'海洋光谱号'、出发港包含'香港'、duration_days=6且duration_nights=5的班次，选择1月份最近日期的班次，预订内舱房（category='interior'），预订数量为2位成人",
        available_ships_count: @available_ships.count,
        expected_passengers: @expected_passenger_names.join('、')
      }
    end
  
    def verify
      # 断言1: 订单已创建（15%）
      add_assertion "订单已创建", weight: 15 do
        all_orders = CruiseOrder
          .joins(cruise_product: { cruise_sailing: :cruise_ship })
          .where(cruise_ships: { name: @ship_keyword })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
    
        expect(all_orders).not_to be_empty, "未找到任何邮轮订单"
        @order = all_orders.first
      end
    
      return unless @order
    
      # 断言2: 船只正确（10%）
      add_assertion "船只正确（#{@ship_keyword}）", weight: 10 do
        product = @order.cruise_product
        ship = product.cruise_sailing.cruise_ship
        expect(ship.name).to include(@ship_keyword),
          "船只不符合要求。期望包含: #{@ship_keyword}, 实际: #{ship.name}"
      end
    
      # 断言3: 出发港正确（10%）
      add_assertion "出发港正确（#{@departure_port_keyword}）", weight: 10 do
        product = @order.cruise_product
        sailing = product.cruise_sailing
        expect(sailing.departure_port).to include(@departure_port_keyword),
          "出发港不符合要求。期望包含: #{@departure_port_keyword}, 实际: #{sailing.departure_port}"
      end
    
      # 断言4: 行程天数正确（10%）
      add_assertion "行程天数正确（#{@duration_days}天#{@duration_nights}晚）", weight: 10 do
        product = @order.cruise_product
        sailing = product.cruise_sailing
        expect(sailing.duration_days).to eq(@duration_days),
          "行程天数错误。期望: #{@duration_days}天, 实际: #{sailing.duration_days}天"
        expect(sailing.duration_nights).to eq(@duration_nights),
          "行程晚数错误。期望: #{@duration_nights}晚, 实际: #{sailing.duration_nights}晚"
      end
    
      # 断言5: 出发月份正确（10%）- 验证选择了1月份出发的班次
      add_assertion "出发月份正确（1月份）", weight: 10 do
        sailing = @order.cruise_product.cruise_sailing
        actual_month = sailing.departure_date.month
        expect(actual_month).to eq(@expected_month),
          "出发月份错误。期望: #{@expected_month}月, 实际: #{actual_month}月（#{sailing.departure_date}）"
      end
    
      # 断言6: 舱房类型正确（15%）
      add_assertion "舱房类型正确（内舱房）", weight: 15 do
        product = @order.cruise_product
        cabin = product.cabin_type
        expect(cabin.category).to eq(@cabin_category),
          "舱房类型错误。期望: #{@cabin_category}（内舱房），实际: #{cabin.category}（#{cabin.name}）"
      end
    
      # 断言7: 预订数量正确（10%）- 验证为2位成人预订
      add_assertion "预订数量正确（#{@adult_count}位成人）", weight: 10 do
        expect(@order.quantity).to eq(@adult_count),
          "预订数量错误。期望: #{@adult_count}位成人, 实际: #{@order.quantity}位"
      end
    
      # 断言8: 乘客信息正确（10%）- 验证包含张三和李四
      add_assertion "乘客信息正确（张三、李四）", weight: 10 do
        passenger_list = @order.passenger_list
        expect(passenger_list).not_to be_empty,
          "乘客信息缺失"
        
        passenger_names = passenger_list.map { |p| p['name'] || p[:name] }.compact.sort
        expect(passenger_names).to match_array(@expected_passenger_names.sort),
          "乘客信息错误。期望: #{@expected_passenger_names.sort.join('、')}, 实际: #{passenger_names.join('、')}"
      end
    
      # 断言9: 联系人信息正确（5%）- 验证联系人为张三或李四，且电话匹配
      add_assertion "联系人信息正确（张三或李四）", weight: 5 do
        valid_contacts = ['张三', '李四']
        expect(valid_contacts).to include(@order.contact_name),
          "联系人姓名错误。期望: 张三或李四, 实际: #{@order.contact_name}"
        
        expected_phone = @valid_contact_phones[@order.contact_name]
        expect(@order.contact_phone).to eq(expected_phone),
          "联系人电话与姓名不匹配。联系人: #{@order.contact_name}, 期望电话: #{expected_phone}, 实际电话: #{@order.contact_phone}"
      end
    
      # 断言10: 选择了1月份最近日期的班次（5%）- 在所有符合条件的1月班次中选择最早的
      add_assertion "选择了1月份最近日期的班次", weight: 5 do
        ship = CruiseShip.where(data_version: 0).where('name LIKE ?', "%#{@ship_keyword}%").first
        
        # 筛选符合条件的班次：正确的出发港、行程天数、出发月份
        available_sailings = CruiseSailing.where(
          data_version: 0,
          cruise_ship_id: ship.id,
          duration_days: @duration_days,
          duration_nights: @duration_nights
        ).where('departure_port LIKE ?', "%#{@departure_port_keyword}%")
         .where('EXTRACT(MONTH FROM departure_date) = ?', @expected_month)
      
        nearest = available_sailings.order(departure_date: :asc).first
        actual_sailing = @order.cruise_product.cruise_sailing
        
        expect(actual_sailing.id).to eq(nearest.id),
          "未选择1月份最近日期的班次。应选: #{nearest.departure_date}（#{nearest.departure_date.strftime('%m月%d日')}），实际: #{actual_sailing.departure_date}（#{actual_sailing.departure_date.strftime('%m月%d日')}）"
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
        expected_month: @expected_month,
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
      @expected_month = data['expected_month']
      @expected_passenger_names = data['expected_passenger_names'] || ['张三', '李四']
      @valid_contact_phones = data['valid_contact_phones'] || { '张三' => '13800138000', '李四' => '13900139000' }
      @available_ships = CruiseShip.where(data_version: 0).where('name LIKE ?', "%#{@ship_keyword}%")
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      lisi = user.passengers.find_by!(name: '李四', data_version: 0)
    
      # 查找船只
      ship = CruiseShip.where(data_version: 0).where('name LIKE ?', "%#{@ship_keyword}%").first
      raise "未找到符合条件的船只" unless ship
    
      # 查找符合条件的班次：船只、行程天数、出发港、出发月份
      available_sailings = CruiseSailing.where(
        data_version: 0,
        cruise_ship_id: ship.id,
        duration_days: @duration_days,
        duration_nights: @duration_nights
      ).where('departure_port LIKE ?', "%#{@departure_port_keyword}%")
       .where('EXTRACT(MONTH FROM departure_date) = ?', @expected_month)
       
      raise "未找到符合条件的班次" if available_sailings.empty?
    
      # 选择1月份最近日期的班次
      nearest_sailing = available_sailings.order(departure_date: :asc).first
    
      # 查找内舱房
      cabin_type = CabinType.where(data_version: 0, cruise_ship_id: ship.id, category: @cabin_category).first
      raise "未找到符合条件的舱房类型" unless cabin_type
    
      # 查找或创建邮轮产品
      cruise_product = CruiseProduct.find_or_create_by!(
        cruise_sailing_id: nearest_sailing.id,
        cabin_type_id: cabin_type.id,
        data_version: 0
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
    
      # 随机选择联系人（张三或李四）
      contact_names = ['张三', '李四']
      selected_contact_name = contact_names.sample
      contact_passenger = selected_contact_name == '张三' ? zhangsan : lisi
      
      # 创建乘客信息数组
      passenger_info = [
        { name: zhangsan.name, id_number: zhangsan.id_number, phone: zhangsan.phone },
        { name: lisi.name, id_number: lisi.id_number, phone: lisi.phone }
      ]
    
      # 创建订单（2位成人）
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