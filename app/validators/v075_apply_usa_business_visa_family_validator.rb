# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例75: 办理美国商务签证（家庭申请，2人，价格最低）
# 
# 任务描述:
#   Agent 需要为2位家庭成员办理美国商务签证，
#   识别商务签证类型并选择价格最低的产品（支持家庭申请）
# 
# 复杂度分析:
#   1. 需要搜索"美国"国家的签证产品
#   2. 需要选择"商务签证"类型
#   3. 需要确认产品支持家庭申请（supports_family=true）
#   4. 需要对比多个产品的价格
#   5. 需要选择价格最低的商务签证
#   6. 需要填写正确的人数（2人）
#   ❌ 不能一次性提供：需要先搜索→筛选商务签证→确认家庭支持→对比价格
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 国家正确（美国）(15分)
#   - 签证类型正确（商务签证）(20分)
#   - 人数正确（2人）(10分)
#   - 产品支持家庭申请 (15分)
#   - 选择了价格最低的商务签证 (20分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v075_apply_usa_business_visa_family_validator/start
#   
#   # Agent 通过界面操作完成办理...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V075ApplyUsaBusinessVisaFamilyValidator < BaseValidator
  self.validator_id = 'v075_apply_usa_business_visa_family_validator'
  self.task_id = '100fd8a9-ca4c-48ee-8139-1e599dc77b16'
  self.title = '办理美国商务签证（家庭申请，2人，价格最低）'
  self.description = '为2位家庭成员办理美国商务签证，选择价格最低且支持家庭申请的产品'
  self.timeout_seconds = 240
  
  # 准备阶段：设置任务参数
  def prepare
    # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
    @country_name = '美国'
    @product_type = '旅游商务签证'
    @traveler_count = 2
    
    # 查找美国的商务签证产品（注意：查询基线数据 data_version=0）
    usa = Country.find_by(name: @country_name, data_version: 0)
    raise "未找到国家: #{@country_name}" unless usa
    
    # 查找支持家庭申请的商务签证产品
    @available_products = VisaProduct.where(
      country_id: usa.id,
      product_type: @product_type,
      supports_family: true,
      data_version: 0
    )
    
    # 找到价格最低的产品
    @cheapest_product = @available_products.min_by { |p| p.price || Float::INFINITY }
    @cheapest_price = @cheapest_product&.price || Float::INFINITY
    
    # 返回给 Agent 的任务信息
    {
      task: "请为2位家庭成员办理#{@country_name}#{@product_type}，选择价格最低且支持家庭申请的产品",
      country_name: @country_name,
      product_type: @product_type,
      traveler_count: @traveler_count,
      hint: "美国商务签证适合因商务活动前往美国的申请人。系统中有多个商务签证产品，请确认产品支持家庭申请（supports_family），并选择价格最低的",
      available_products_count: @available_products.count,
      note: "商务签证通常需要提供公司证明、邀请函等材料，办理周期较长"
    }
  end
  
  # 验证阶段：检查订单是否符合要求
  def verify
    # 断言1: 必须有订单创建（最近创建的一条）
    add_assertion "订单已创建", weight: 20 do
      @visa_order = VisaOrder.order(created_at: :desc).first
      expect(@visa_order).not_to be_nil, "未找到任何签证订单记录"
    end
    
    return unless @visa_order # 如果没有订单，后续断言无法继续
    
    # 断言2: 国家正确
    add_assertion "国家正确（美国）", weight: 15 do
      actual_country = @visa_order.visa_product.country.name
      expect(actual_country).to eq(@country_name),
        "国家错误。期望: #{@country_name}, 实际: #{actual_country}"
    end
    
    # 断言3: 签证类型正确（商务签证）
    add_assertion "签证类型正确（商务签证）", weight: 20 do
      actual_type = @visa_order.visa_product.product_type
      expect(actual_type).to eq(@product_type),
        "签证类型错误。期望: #{@product_type}, 实际: #{actual_type}"
    end
    
    # 断言4: 人数正确（2人）
    add_assertion "人数正确（2人）", weight: 10 do
      expect(@visa_order.traveler_count).to eq(@traveler_count),
        "旅行人数错误。期望: #{@traveler_count}人（家庭申请）, 实际: #{@visa_order.traveler_count}人"
    end
    
    # 断言5: 产品支持家庭申请
    add_assertion "产品支持家庭申请", weight: 15 do
      supports_family = @visa_order.visa_product.supports_family
      
      expect(supports_family).to be_truthy,
        "所选产品不支持家庭申请。期望: supports_family=true, 实际: supports_family=#{supports_family}"
    end
    
    # 断言6: 选择了价格最低的商务签证（核心评分项）
    add_assertion "选择了价格最低的商务签证", weight: 20 do
      # 获取所有支持家庭申请的美国商务签证产品
      usa = Country.find_by(name: @country_name, data_version: 0)
      all_products = VisaProduct.where(
        country_id: usa.id,
        product_type: @product_type,
        supports_family: true,
        data_version: 0
      )
      
      # 找到价格最低的
      cheapest_product = all_products.min_by { |p| p.price || Float::INFINITY }
      actual_price = @visa_order.visa_product.price || Float::INFINITY
      cheapest_price = cheapest_product.price || Float::INFINITY
      
      expect(@visa_order.visa_product_id).to eq(cheapest_product.id),
        "未选择价格最低的商务签证。" \
        "应选: #{cheapest_product.name}（#{cheapest_price}元/人，#{cheapest_product.processing_days}个工作日），" \
        "实际选择: #{@visa_order.visa_product.name}（#{actual_price}元/人，#{@visa_order.visa_product.processing_days}个工作日）"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      country_name: @country_name,
      product_type: @product_type,
      traveler_count: @traveler_count,
      cheapest_price: @cheapest_price
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @country_name = data['country_name']
    @product_type = data['product_type']
    @traveler_count = data['traveler_count']
    @cheapest_price = data['cheapest_price']
    
    # 重新加载可用产品列表
    usa = Country.find_by(name: @country_name, data_version: 0)
    if usa
      @available_products = VisaProduct.where(
        country_id: usa.id,
        product_type: @product_type,
        supports_family: true,
        data_version: 0
      )
      @cheapest_product = @available_products.min_by { |p| p.price || Float::INFINITY }
    end
  end
  
  # 模拟 AI Agent 操作：办理美国商务签证（家庭申请，2人，最低价格）
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找美国
    usa = Country.find_by!(name: @country_name, data_version: 0)
    
    # 3. 查找支持家庭申请的美国商务签证产品
    visa_products = VisaProduct.where(
      country_id: usa.id,
      product_type: @product_type,
      supports_family: true,
      data_version: 0
    )
    
    raise "未找到符合条件的签证产品" if visa_products.empty?
    
    # 4. 选择价格最低的
    cheapest_product = visa_products.min_by { |p| p.price || Float::INFINITY }
    
    raise "未找到可用的签证产品" unless cheapest_product
    
    # 5. 创建签证订单
    visa_order = VisaOrder.create!(
      user_id: user.id,
      visa_product_id: cheapest_product.id,
      traveler_count: @traveler_count,
      unit_price: cheapest_product.price,
      total_price: cheapest_product.price * @traveler_count,
      expected_date: Date.current + 90.days,  # 预计出行日期90天后
      delivery_method: 'express',
      delivery_address: '上海市浦东新区陆家嘴环路1000号',
      contact_name: '王强',
      contact_phone: '13900139000',
      status: 'pending',
      insurance_selected: false,
      insurance_price: 0
    )
    
    # 返回操作信息
    {
      action: 'create_visa_order',
      order_id: visa_order.id,
      visa_product_name: cheapest_product.name,
      country_name: usa.name,
      product_type: cheapest_product.product_type,
      processing_days: cheapest_product.processing_days,
      price: cheapest_product.price,
      traveler_count: @traveler_count,
      total_price: visa_order.total_price,
      supports_family: cheapest_product.supports_family,
      user_email: user.email
    }
  end
end