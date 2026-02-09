# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例79: 给张三和李四购买泰国旅游保险（10天后出行，保障10天，最便宜）
# 
# 任务描述:
#   Agent 需要为张三和李四的泰国出行购买境外旅游保险（10天后出发），
#   选择适合亚洲地区的境外保险产品且价格最便宜的
# 
# 复杂度分析:
#   1. 需要搜索"境外旅游"类型的保险产品（international类型）
#   2. 需要识别适合泰国（亚洲地区）的保险产品
#   3. 需要指定出行时间（10天后开始）
#   4. 需要填写2位投保人信息（姓名和身份证号）
#   5. 需要填写1位联系人信息（从多个联系人中选择）
#   6. 需要计算10天2人的总价
#   7. 需要对比多个保险公司的境外产品价格
#   8. 需要选择最便宜的亚洲版境外保险
#   ❌ 不能一次性提供：需要先搜索→筛选适合地区→计算价格→对比→购买
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 保险类型正确（境外旅游international）(20分)
#   - 目的地正确（泰国）(10分)
#   - 出行开始时间正确（10天后）(5分)
#   - 保障天数正确（10天）(5分)
#   - 人数正确（2人）(5分)
#   - 投保人信息正确（姓名+身份证号）(10分)
#   - 联系人信息正确（多选一）(5分)
#   - 选择了最便宜的境外保险产品 (20分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v079_buy_international_travel_insurance_thailand_validator/start
#   
#   # Agent 通过界面操作完成购买...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V051V100
  class V079BuyInternationalTravelInsuranceThailandValidator < BaseValidator
    self.validator_id = 'v079_buy_international_travel_insurance_thailand_validator'
    self.task_id = 'cf2c9d61-fcb6-4467-8b45-4ab03e553a23'
    self.title = '给张三和李四购买泰国旅游保险（10天后出行，保障10天，最便宜）'
    self.description = '帮张三、李四这2人买泰国旅游保险，10天后出发，保障期10天，选择最便宜的亚洲版境外保险'
    self.timeout_seconds = 240
  
    # 准备阶段：设置任务参数
    def prepare
      # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
      @product_type = 'international'
      @destination = '泰国'
      @days = 10
      @quantity = 2
      @start_date = Date.current + 10.days  # 10天后开始
      @end_date = @start_date + @days - 1  # 保障结束日期
    
      # 查询投保人数据（从 passengers 表获取，包含身份证号）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_insured_names = [@zhangsan.name, @lisi.name]
      @expected_insured_id_numbers = [@zhangsan.id_number, @lisi.id_number]
    
      # 查询联系人数据（从 contacts 表获取，可以多选一）
      @available_contacts = user.contacts.where(data_version: 0).to_a
      @valid_contact_names = @available_contacts.map(&:name)
      @valid_contact_phones = @available_contacts.map { |c| [c.name, c.phone] }.to_h
    
      # 查找境外旅游保险产品（注意：查询基线数据 data_version=0）
      @available_products = InsuranceProduct.where(
        product_type: @product_type,
        data_version: 0
      ).where('min_days <= ? AND max_days >= ?', @days, @days)
    
      # 计算相对时间描述
      days_until_start = (@start_date - Date.current).to_i
      start_time_desc = "#{days_until_start}天后"
    
      # 返回给 Agent 的任务信息
      {
        task: "请为张三、李四购买泰国旅游保险（#{start_time_desc}出发，保障期#{@days}天），选择适合亚洲地区且价格最便宜的产品",
        product_type: "境外旅游",
        destination: @destination,
        start_time: start_time_desc,
        days: @days,
        quantity: @quantity,
        insured_persons: "张三、李四",
        start_date: @start_date.to_s,
        end_date: @end_date.to_s,
        hint: "泰国属于东南亚国家，建议选择亚洲版境外保险（比全球版便宜）。系统中有多家保险公司提供境外旅游保险，请对比价格后选择最便宜的。投保人信息需要填写姓名和身份证号",
        available_products_count: @available_products.count,
        note: "境外旅游保险通常包含境外医疗、紧急救援、个人财物保障等"
      }
    end
  
    # 验证阶段：检查订单是否符合要求
    def verify
      # 断言1: 必须有订单创建（最近创建的一条）
      add_assertion "订单已创建", weight: 20 do
        all_insurance_orders = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        expect(all_insurance_orders).not_to be_empty, "未找到任何InsuranceOrder记录"
        @insurance_order = all_insurance_orders.first
        # Replaced by expect(all_insurance_orders).not_to be_empty above, "未找到任何保险订单记录"
      end
    
      return unless @insurance_order # 如果没有订单，后续断言无法继续
    
      # 断言2: 保险类型正确（境外旅游）
      add_assertion "保险类型正确（境外旅游international）", weight: 20 do
        actual_type = @insurance_order.insurance_product.product_type
        expect(actual_type).to eq(@product_type),
          "保险类型错误。期望: #{@product_type}（境外旅游），实际: #{actual_type}。" \
          "前往泰国需要购买境外旅游保险，不是境内旅游保险"
      end
    
      # 断言3: 目的地正确
      add_assertion "目的地正确（#{@destination}）", weight: 10 do
        actual_destination = @insurance_order.destination
        expect(actual_destination).to include(@destination),
          "目的地错误。期望包含: #{@destination}, 实际: #{actual_destination || '未填写'}"
      end
    
      # 断言4: 出行开始时间正确（10天后）
      add_assertion "出行开始时间正确（10天后，#{@start_date}）", weight: 5 do
        actual_start_date = @insurance_order.start_date
        expect(actual_start_date).to eq(@start_date),
          "出行开始时间错误。期望: #{@start_date}（10天后）, 实际: #{actual_start_date}"
      end
    
      # 断言5: 保障天数正确
      add_assertion "保障天数正确（#{@days}天）", weight: 5 do
        actual_days = @insurance_order.days
        expect(actual_days).to eq(@days),
          "保障天数错误。期望: #{@days}天, 实际: #{actual_days}天"
      end
    
      # 断言6: 人数正确（2人）
      add_assertion "人数正确（#{@quantity}人）", weight: 5 do
        actual_quantity = @insurance_order.quantity
        expect(actual_quantity).to eq(@quantity),
          "购买人数错误。期望: #{@quantity}人, 实际: #{actual_quantity}人"
      end
    
      # 断言7: 投保人信息填写正确（姓名和身份证号）
      add_assertion "投保人信息填写正确（张三、李四的姓名和身份证号）", weight: 10 do
        insured_persons = @insurance_order.insured_persons || []
        expect(insured_persons).not_to be_empty, "未填写投保人信息"
        expect(insured_persons.size).to eq(@quantity), 
          "投保人数量错误。期望: #{@quantity}人, 实际: #{insured_persons.size}人"
        
        # 验证姓名
        actual_names = insured_persons.map { |p| p['name'] }.compact.sort
        expect(actual_names).to match_array(@expected_insured_names.sort),
          "投保人姓名错误。期望: #{@expected_insured_names.join('、')}, 实际: #{actual_names.join('、')}"
        
        # 验证身份证号
        @expected_insured_names.each do |name|
          person = insured_persons.find { |p| p['name'] == name }
          expect(person).not_to be_nil, "未找到投保人'#{name}'"
          expect(person['id_number']).not_to be_nil, "投保人'#{name}'未填写身份证号"
          expect(person['id_number']).not_to be_empty, "投保人'#{name}'的身份证号为空"
          
          # 验证身份证号是否正确（从 passengers 表）
          expected_id_number = (name == '张三' ? @zhangsan.id_number : @lisi.id_number)
          expect(person['id_number']).to eq(expected_id_number),
            "投保人'#{name}'的身份证号错误。期望: #{expected_id_number}, 实际: #{person['id_number']}"
        end
      end
    
      # 断言8: 联系人信息正确（从多个联系人中任选一个）
      add_assertion "联系人信息正确（从可用联系人中选择）", weight: 5 do
        # 注意：InsuranceOrder 没有单独的 contact_name/contact_phone 字段
        # 联系人信息可能存储在其他字段或作为投保人之一
        # 这里我们验证至少有一个投保人的电话与某个联系人匹配
        insured_persons = @insurance_order.insured_persons || []
        
        # 检查是否使用了可用联系人中的某个（通过姓名匹配）
        has_valid_contact = insured_persons.any? { |p| @valid_contact_names.include?(p['name']) }
        
        expect(has_valid_contact).to be_truthy,
          "未找到有效的联系人信息。期望投保人中至少有一人来自联系人列表: #{@valid_contact_names.join('、')}"
      end
    
      # 断言9: 选择了最便宜的境外保险产品
      add_assertion "选择了最便宜的境外保险产品", weight: 20 do
        # 获取所有境外旅游保险产品
        all_products = InsuranceProduct.where(
          product_type: @product_type,
          data_version: 0
        ).where('min_days <= ? AND max_days >= ?', @days, @days)
      
        # 计算每个产品的10天总价
        products_with_price = all_products.map do |p|
          {
            product: p,
            price_per_day: p.price_per_day,
            total_price: p.price_per_day * @days
          }
        end
      
        # 找到最便宜的
        cheapest = products_with_price.min_by { |p| p[:total_price] }
      
        actual_total = @insurance_order.insurance_product.price_per_day * @days
        cheapest_total = cheapest[:total_price]
      
        expect(@insurance_order.insurance_product_id).to eq(cheapest[:product].id),
          "未选择最便宜的境外保险产品。" \
          "应选: #{cheapest[:product].name}（#{cheapest[:product].company}，每天#{cheapest[:price_per_day]}元，#{@days}天共#{cheapest_total}元），" \
          "实际选择: #{@insurance_order.insurance_product.name}（#{@insurance_order.insurance_product.company}，每天#{@insurance_order.insurance_product.price_per_day}元，#{@days}天共#{actual_total}元）"
      end
    end
  
    private
  
    # 保存执行状态数据
    def execution_state_data
      {
        product_type: @product_type,
        destination: @destination,
        days: @days,
        quantity: @quantity,
        start_date: @start_date&.to_s,
        end_date: @end_date&.to_s,
        expected_insured_names: @expected_insured_names,
        expected_insured_id_numbers: @expected_insured_id_numbers,
        valid_contact_names: @valid_contact_names,
        valid_contact_phones: @valid_contact_phones
      }
    end
  
    # 从状态恢复实例变量
    def restore_from_state(data)
      @product_type = data['product_type']
      @destination = data['destination']
      @days = data['days']
      @quantity = data['quantity']
      @start_date = data['start_date'] ? Date.parse(data['start_date']) : nil
      @end_date = data['end_date'] ? Date.parse(data['end_date']) : nil
      @expected_insured_names = data['expected_insured_names'] || []
      @expected_insured_id_numbers = data['expected_insured_id_numbers'] || []
      @valid_contact_names = data['valid_contact_names'] || []
      @valid_contact_phones = data['valid_contact_phones'] || {}
    
      # 重新加载投保人和联系人数据
      user = User.find_by(email: 'demo@travel01.com', data_version: 0)
      if user
        @zhangsan = user.passengers.find_by(name: '张三', data_version: 0)
        @lisi = user.passengers.find_by(name: '李四', data_version: 0)
        @available_contacts = user.contacts.where(data_version: 0).to_a
      end
    
      # 重新加载可用产品列表
      @available_products = InsuranceProduct.where(
        product_type: @product_type,
        data_version: 0
      ).where('min_days <= ? AND max_days >= ?', @days, @days)
    end
  
    # 模拟 AI Agent 操作：为泰国出行购买境外旅游保险，选择最便宜的产品
    def simulate
      # 1. 查找测试用户（数据包中已创建）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 2. 查找境外旅游保险产品
      available_products = InsuranceProduct.where(
        product_type: @product_type,
        data_version: 0
      ).where('min_days <= ? AND max_days >= ?', @days, @days)
    
      raise "未找到境外旅游保险产品" if available_products.empty?
    
      # 3. 选择价格最便宜的
      cheapest_product = available_products.min_by do |p|
        p.price_per_day * @days
      end
    
      raise "未找到可用的保险产品" unless cheapest_product
    
      # 4. 准备投保人信息（从 prepare 中已查询的数据使用）
      insured_persons_data = [
        { name: @zhangsan.name, id_number: @zhangsan.id_number },
        { name: @lisi.name, id_number: @lisi.id_number }
      ]
    
      # 5. 创建保险订单
      unit_price = cheapest_product.price_per_day * @days
    
      insurance_order = InsuranceOrder.create!(
        user_id: user.id,
        insurance_product_id: cheapest_product.id,
        source: 'standalone',  # 单独购买
        start_date: @start_date,
        end_date: @end_date,
        days: @days,
        destination: @destination,
        destination_type: 'international',
        insured_persons: insured_persons_data,
        unit_price: unit_price,
        quantity: @quantity,
        total_price: unit_price * @quantity,
        status: 'pending',
        data_version: @data_version
      )
    
      # 返回操作信息
      {
        action: 'create_insurance_order',
        order_id: insurance_order.id,
        insurance_product_name: cheapest_product.name,
        company: cheapest_product.company,
        product_type: cheapest_product.product_type,
        price_per_day: cheapest_product.price_per_day,
        days: @days,
        quantity: @quantity,
        insured_persons: insured_persons_data,
        unit_price: unit_price,
        total_price: insurance_order.total_price,
        destination: @destination,
        start_date: @start_date.to_s,
        end_date: @end_date.to_s,
        user_email: user.email
      }
    end
    end
end
