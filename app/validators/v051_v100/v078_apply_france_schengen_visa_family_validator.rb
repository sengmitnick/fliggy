# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例78: 给张三办理法国申根签证（3人，选最便宜）
# 
# 任务描述:
#   Agent 需要为3人办理法国签证，
#   对比不同产品的价格，选择价格最便宜的产品
# 
# 复杂度分析:
#   1. 需要搜索"法国"国家的签证产品
#   2. 需要识别可以用于申根区的签证类型
#   3. 需要对比不同产品的价格（price）
#   4. 需要选择价格最低的产品
#   5. 需要填写正确的人数（3人）
#   ❌ 不能一次性提供：需要先搜索→筛选签证类型→对比价格→选最便宜
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 国家正确（法国）(15分)
#   - 人数正确（3人）(10分)
#   - 选择了价格最便宜的产品 (35分)
#   - 订单价格计算正确 (15分)
#   - 联系人信息正确 (5分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v078_apply_france_schengen_visa_family_validator/start
#   
#   # Agent 通过界面操作完成办理...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V051V100
  class V078ApplyFranceSchengenVisaFamilyValidator < BaseValidator
    self.validator_id = 'v078_apply_france_schengen_visa_family_validator'
    self.task_id = '29391193-cb90-41b1-b5c7-152b6da0630b'
    self.title = '给张三办理法国申根签证（3人，选最便宜）'
    self.description = '办理申根签证（法国，3人，选最便宜）'
    self.timeout_seconds = 240
  
    # 准备阶段：设置任务参数
    def prepare
      # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
      @country_name = '法国'
      @traveler_count = 3
    
      # 查找法国的签证产品（注意：查询基线数据 data_version=0）
      france = Country.find_by(name: @country_name, data_version: 0)
      raise "未找到国家: #{@country_name}" unless france
    
      # 查找所有签证产品
      @available_products = VisaProduct.where(
        country_id: france.id,
        data_version: 0
      )
    
      # 找到价格最低的产品
      @cheapest_product = @available_products.min_by { |p| p.price || Float::INFINITY }
      @cheapest_price = @cheapest_product&.price || Float::INFINITY
    
      # 返回给 Agent 的任务信息
      {
        task: "请为3人办理#{@country_name}签证，对比不同产品的价格后选择最便宜的",
        country_name: @country_name,
        traveler_count: @traveler_count,
        hint: "申根签证可以在申根区26个国家自由通行。请对比不同产品的价格，选择价格最低的产品",
        available_products_count: @available_products.count,
        note: "法国签证是申根签证的一种，可在整个申根区自由旅行"
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
      add_assertion "国家正确（法国）", weight: 15 do
        actual_country = @visa_order.visa_product.country.name
        expect(actual_country).to eq(@country_name),
          "国家错误。期望: #{@country_name}, 实际: #{actual_country}"
      end
    
      # 断言3: 人数正确（3人）
      add_assertion "人数正确（3人）", weight: 10 do
        expect(@visa_order.traveler_count).to eq(@traveler_count),
          "旅行人数错误。期望: #{@traveler_count}人, 实际: #{@visa_order.traveler_count}人"
      end
    
      # 断言4: 选择了价格最便宜的产品（核心评分项）
      add_assertion "选择了价格最便宜的产品", weight: 35 do
        # 获取所有法国签证产品
        france = Country.find_by(name: @country_name, data_version: 0)
        all_products = VisaProduct.where(
          country_id: france.id,
          data_version: 0
        )
      
        # 找到价格最低的
        cheapest_product = all_products.min_by { |p| p.price || Float::INFINITY }
        actual_price = @visa_order.visa_product.price || Float::INFINITY
        cheapest_price = cheapest_product.price || Float::INFINITY
      
        expect(@visa_order.visa_product_id).to eq(cheapest_product.id),
          "未选择价格最便宜的产品。" \
          "应选: #{cheapest_product.name}（#{cheapest_price}元/人，#{cheapest_product.processing_days}个工作日），" \
          "实际选择: #{@visa_order.visa_product.name}（#{actual_price}元/人，#{@visa_order.visa_product.processing_days}个工作日）"
      end
    
      # 断言5: 订单价格计算正确
      add_assertion "订单价格计算正确", weight: 15 do
        expected_total = @visa_order.visa_product.price * @visa_order.traveler_count
        actual_total = @visa_order.total_price
      
        expect(actual_total).to eq(expected_total),
          "订单总价错误。期望: #{expected_total}元（单价#{@visa_order.visa_product.price}元 × #{@visa_order.traveler_count}人），实际: #{actual_total}元"
      end
    
      # 断言6: 联系人姓名正确（张三、李四、王芳任选其一）
      add_assertion "联系人姓名正确（3人中任选其一）", weight: 5 do
        valid_names = ['张三', '李四', '王芳']
        expect(valid_names).to include(@visa_order.contact_name),
          "联系人姓名错误。期望: #{valid_names.join('或')}（3人任选其一），实际: #{@visa_order.contact_name}"
      end
    end
  
    private
  
    # 保存执行状态数据
    def execution_state_data
      {
        country_name: @country_name,
        traveler_count: @traveler_count,
        cheapest_price: @cheapest_price
      }
    end
  
    # 从状态恢复实例变量
    def restore_from_state(data)
      @country_name = data['country_name']
      @traveler_count = data['traveler_count']
      @cheapest_price = data['cheapest_price']
    
      # 重新加载可用产品列表
      france = Country.find_by(name: @country_name, data_version: 0)
      if france
        @available_products = VisaProduct.where(
          country_id: france.id,
          data_version: 0
        )
        @cheapest_product = @available_products.min_by { |p| p.price || Float::INFINITY }
      end
    end
  
    # 模拟 AI Agent 操作：办理法国申根签证（3人，选最便宜）
    def simulate
      # 1. 查找测试用户
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 2. 随机选择联系人（张三、李四、王芳任选其一）
      contact_names = ['张三', '李四', '王芳']
      selected_contact_name = contact_names.sample
      contact_passenger = user.passengers.find_by!(name: selected_contact_name, data_version: 0)
      contact_address = user.addresses.find_by!(name: selected_contact_name, data_version: 0)
    
      # 3. 查找法国
      france = Country.find_by!(name: @country_name, data_version: 0)
    
      # 4. 查找所有法国签证产品
      visa_products = VisaProduct.where(
        country_id: france.id,
        data_version: 0
      )
    
      raise "未找到符合条件的签证产品" if visa_products.empty?
    
      # 5. 选择价格最低的产品
      selected_product = visa_products.min_by { |p| p.price || Float::INFINITY }
    
      raise "未找到可用的签证产品" unless selected_product
    
      # 6. 拼接完整地址
      full_address = [contact_address.province, contact_address.city, contact_address.district, contact_address.detail].compact.join
    
      # 7. 创建签证订单
      visa_order = VisaOrder.create!(
        user_id: user.id,
        visa_product_id: selected_product.id,
        traveler_count: @traveler_count,
        unit_price: selected_product.price,
        total_price: selected_product.price * @traveler_count,
        expected_date: Date.current + 45.days,  # 预计出行日期45天后
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
        visa_product_name: selected_product.name,
        country_name: france.name,
        product_type: selected_product.product_type,
        processing_days: selected_product.processing_days,
        price: selected_product.price,
        traveler_count: @traveler_count,
        total_price: visa_order.total_price,
        user_email: user.email
      }
    end
    end
end
