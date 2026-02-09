# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例76: 办理韩国团体签证（5人以上，成功率100%，最便宜）
# 
# 任务描述:
#   Agent 需要为5人团队办理韩国签证，
#   要求选择成功率100%且价格最便宜的团体签证产品
# 
# 复杂度分析:
#   1. 需要搜索"韩国"国家的签证产品
#   2. 需要识别"团体签证"类型（适合多人出行）
#   3. 需要筛选成功率为100%的产品
#   4. 需要对比价格，选择最便宜的
#   5. 需要填写正确的人数（5人）
#   ❌ 不能一次性提供：需要先搜索→识别团体签→筛选成功率→对比价格
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 国家正确（韩国）(15分)
#   - 签证类型正确（团体签证）(25分)
#   - 人数正确（5人）(10分)
#   - 成功率100% (15分)
#   - 选择了价格最便宜的产品 (15分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v076_apply_korea_group_visa_validator/start
#   
#   # Agent 通过界面操作完成办理...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V051V100
  class V076ApplyKoreaGroupVisaValidator < BaseValidator
    self.validator_id = 'v076_apply_korea_group_visa_validator'
    self.task_id = 'c8b9e386-8c54-40ca-a684-bcb5f833bb16'
    self.title = '给李四等5人办理韩国团体签证（成功率100%，最便宜）'
    self.description = '帮李四、王芳、刘强、陈静、小明这5个人办理韩国团体签证，要求成功率100%且价格最便宜'
    self.timeout_seconds = 240
  
    # 准备阶段：设置任务参数
    def prepare
      # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
      @country_name = '韩国'
      @product_type = '团体签证'
      @traveler_count = 5
      @required_success_rate = 100.0
    
      # 查找韩国的团体签证产品（注意：查询基线数据 data_version=0）
      korea = Country.find_by(name: @country_name, data_version: 0)
      raise "未找到国家: #{@country_name}" unless korea
    
      # 查找成功率为100%的团体签证产品
      @available_products = VisaProduct.where(
        country_id: korea.id,
        product_type: @product_type,
        data_version: 0
      ).select { |p| p.success_rate == @required_success_rate }
    
      # 找到价格最低的产品
      @cheapest_product = @available_products.min_by { |p| p.price || Float::INFINITY }
      @cheapest_price = @cheapest_product&.price || Float::INFINITY
    
      # 返回给 Agent 的任务信息
      {
        task: "请为5人团队办理#{@country_name}#{@product_type}，要求成功率100%且价格最便宜",
        country_name: @country_name,
        product_type: @product_type,
        traveler_count: @traveler_count,
        required_success_rate: "100%",
        hint: "团体签证适合5人以上团队出行，材料简化、价格优惠。请选择成功率100%且价格最便宜的产品",
        available_products_count: @available_products.count,
        note: "团体签证通常要求统一进出，不能单独离团"
      }
    end
  
    # 验证阶段：检查订单是否符合要求
    def verify
      # 断言1: 必须有订单创建（最近创建的一条）
      add_assertion "订单已创建", weight: 20 do
        all_visa_orders = VisaOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        expect(all_visa_orders).not_to be_empty, "未找到任何VisaOrder记录"
        @visa_order = all_visa_orders.first
        # Replaced by expect(all_visa_orders).not_to be_empty above, "未找到任何签证订单记录"
      end
    
      return unless @visa_order # 如果没有订单，后续断言无法继续
    
      # 断言2: 国家正确
      add_assertion "国家正确（韩国）", weight: 15 do
        actual_country = @visa_order.visa_product.country.name
        expect(actual_country).to eq(@country_name),
          "国家错误。期望: #{@country_name}, 实际: #{actual_country}"
      end
    
      # 断言3: 签证类型正确（团体签证）
      add_assertion "签证类型正确（团体签证）", weight: 20 do
        actual_type = @visa_order.visa_product.product_type
        expect(actual_type).to eq(@product_type),
          "签证类型错误。期望: #{@product_type}, 实际: #{actual_type}。" \
          "团体签证适合多人团队出行，价格优惠且办理简便"
      end
    
      # 断言4: 人数正确（5人）
      add_assertion "人数正确（5人）", weight: 10 do
        expect(@visa_order.traveler_count).to eq(@traveler_count),
          "旅行人数错误。期望: #{@traveler_count}人（团队出行）, 实际: #{@visa_order.traveler_count}人"
      end
    
      # 断言5: 成功率100%
      add_assertion "成功率100%", weight: 10 do
        success_rate = @visa_order.visa_product.success_rate
      
        expect(success_rate).to eq(@required_success_rate),
          "成功率不符合要求。期望: #{@required_success_rate}%, 实际: #{success_rate}%"
      end
    
      # 断言6: 选择了价格最便宜的产品
      add_assertion "选择了价格最便宜的产品", weight: 15 do
        # 获取所有成功率100%的韩国团体签证产品
        korea = Country.find_by(name: @country_name, data_version: 0)
        all_products = VisaProduct.where(
          country_id: korea.id,
          product_type: @product_type,
          data_version: 0
        ).select { |p| p.success_rate == @required_success_rate }
      
        # 找到价格最低的
        cheapest_product = all_products.min_by { |p| p.price || Float::INFINITY }
        actual_price = @visa_order.visa_product.price || Float::INFINITY
        cheapest_price = cheapest_product.price || Float::INFINITY
      
        expect(@visa_order.visa_product_id).to eq(cheapest_product.id),
          "未选择价格最便宜的产品。" \
          "应选: #{cheapest_product.name}（#{cheapest_price}元/人，成功率#{cheapest_product.success_rate}%），" \
          "实际选择: #{@visa_order.visa_product.name}（#{actual_price}元/人，成功率#{@visa_order.visa_product.success_rate}%）"
      end
    
      # 断言7: 联系人姓名正确（李四、王芳、刘强、陈静、小明任选其一）
      add_assertion "联系人姓名正确（5人中任选其一）", weight: 3 do
        valid_names = ['李四', '王芳', '刘强', '陈静', '小明']
        expect(valid_names).to include(@visa_order.contact_name),
          "联系人姓名错误。期望: #{valid_names.join('或')}（5人任选其一），实际: #{@visa_order.contact_name}"
      end
    
      # 断言8: 联系电话与联系人匹配
      add_assertion "联系电话与联系人匹配", weight: 3 do
        # 李四: 13900139000, 王芳: 13700137001, 刘强: 13600136001, 陈静: 13300133001, 小明: 13500135001
        valid_pairs = {
          '李四' => '13900139000',
          '王芳' => '13700137001',
          '刘强' => '13600136001',
          '陈静' => '13300133001',
          '小明' => '13500135001'
        }
      
        expected_phone = valid_pairs[@visa_order.contact_name]
        expect(@visa_order.contact_phone).to eq(expected_phone),
          "联系电话与联系人不匹配。联系人: #{@visa_order.contact_name}，期望电话: #{expected_phone}，实际电话: #{@visa_order.contact_phone}"
      end
    
      # 断言9: 收货地址与联系人匹配
      add_assertion "收货地址与联系人匹配", weight: 4 do
        # 李四: 上海浦东, 王芳: 广州天河, 刘强: 深圳南山, 陈静: 杭州西湖, 小明: 成都高新
        valid_addresses = {
          '李四' => /上海.*浦东.*陆家嘴.*1000/,
          '王芳' => /广东.*广州.*天河.*85/,
          '刘强' => /广东.*深圳.*南山.*科技园/,
          '陈静' => /杭州.*西湖.*文三路.*123/,
          '小明' => /四川.*成都.*高新.*天府/
        }
      
        expected_pattern = valid_addresses[@visa_order.contact_name]
        actual_address = @visa_order.delivery_address || ''
      
        expect(actual_address).to match(expected_pattern),
          "收货地址与联系人不匹配。联系人: #{@visa_order.contact_name}，期望包含: #{expected_pattern.source}，实际地址: #{actual_address}"
      end
    end
  
    private
  
    # 保存执行状态数据
    def execution_state_data
      {
        country_name: @country_name,
        product_type: @product_type,
        traveler_count: @traveler_count,
        required_success_rate: @required_success_rate,
        cheapest_price: @cheapest_price
      }
    end
  
    # 从状态恢复实例变量
    def restore_from_state(data)
      @country_name = data['country_name']
      @product_type = data['product_type']
      @traveler_count = data['traveler_count']
      @required_success_rate = data['required_success_rate']
      @cheapest_price = data['cheapest_price']
    
      # 重新加载可用产品列表
      korea = Country.find_by(name: @country_name, data_version: 0)
      if korea
        @available_products = VisaProduct.where(
          country_id: korea.id,
          product_type: @product_type,
          data_version: 0
        ).select { |p| p.success_rate == @required_success_rate }
        @cheapest_product = @available_products.min_by { |p| p.price || Float::INFINITY }
      end
    end
  
    # 模拟 AI Agent 操作：办理韩国团体签证（5人，成功率100%，最便宜）
    def simulate
      # 1. 查找测试用户
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 2. 随机选择联系人（李四、王芳、刘强、陈静、小明任选其一）
      contact_names = ['李四', '王芳', '刘强', '陈静', '小明']
      selected_contact_name = contact_names.sample
      contact_passenger = user.passengers.find_by!(name: selected_contact_name, data_version: 0)
      contact_address = user.addresses.find_by!(name: selected_contact_name, data_version: 0)
    
      # 3. 查找韩国
      korea = Country.find_by!(name: @country_name, data_version: 0)
    
      # 4. 查找成功率100%的韩国团体签证产品
      visa_products = VisaProduct.where(
        country_id: korea.id,
        product_type: @product_type,
        data_version: 0
      ).select { |p| p.success_rate == @required_success_rate }
    
      raise "未找到符合条件的签证产品" if visa_products.empty?
    
      # 5. 选择价格最低的
      cheapest_product = visa_products.min_by { |p| p.price || Float::INFINITY }
    
      raise "未找到可用的签证产品" unless cheapest_product
    
      # 6. 拼接完整地址
      full_address = "#{contact_address.province}#{contact_address.city}#{contact_address.district}#{contact_address.detail}"
    
      # 7. 创建签证订单
      visa_order = VisaOrder.create!(
        user_id: user.id,
        visa_product_id: cheapest_product.id,
        traveler_count: @traveler_count,
        unit_price: cheapest_product.price,
        total_price: cheapest_product.price * @traveler_count,
        expected_date: Date.current + 30.days,  # 预计出行日期30天后
        delivery_method: 'express',
        delivery_address: full_address,
        contact_name: contact_passenger.name,
        contact_phone: contact_passenger.phone,
        status: 'pending',
        insurance_selected: false,
        insurance_price: 0,
        data_version: @data_version
      )
    
      # 返回操作信息
      {
        action: 'create_visa_order',
        order_id: visa_order.id,
        visa_product_name: cheapest_product.name,
        country_name: korea.name,
        product_type: cheapest_product.product_type,
        processing_days: cheapest_product.processing_days,
        success_rate: cheapest_product.success_rate,
        price: cheapest_product.price,
        traveler_count: @traveler_count,
        total_price: visa_order.total_price,
        user_email: user.email
      }
    end
    end
end
