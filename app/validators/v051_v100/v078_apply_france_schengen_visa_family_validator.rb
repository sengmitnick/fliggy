# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例78: 办理申根签证（法国，3人家庭，拒签可重新办理）
# 
# 任务描述:
#   Agent 需要为3人家庭办理法国申根签证，
#   要求选择支持拒签后可重新办理（refused_reapply）的产品
# 
# 复杂度分析:
#   1. 需要搜索"法国"国家的签证产品
#   2. 需要识别可以用于申根区的签证类型
#   3. 需要筛选支持拒签重新办理（refused_reapply=true）的产品
#   4. 需要确认产品支持家庭申请（supports_family=true）
#   5. 需要填写正确的人数（3人）
#   ❌ 不能一次性提供：需要先搜索→筛选签证类型→确认拒签重办→确认家庭支持
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 国家正确（法国）(15分)
#   - 人数正确（3人）(10分)
#   - 产品支持家庭申请 (15分)
#   - 产品支持拒签后重新办理 (25分)
#   - 订单价格计算正确 (15分)
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
    self.title = '给张三的3人办理法国申根签证（支持拒签重办）'
    self.description = '帮张三、李四、王芳这3个人办理法国申根签证，选择支持拒签后可重新办理的产品'
    self.timeout_seconds = 240
  
    # 准备阶段：设置任务参数
    def prepare
      # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
      @country_name = '法国'
      @traveler_count = 3
    
      # 查找法国的签证产品（注意：查询基线数据 data_version=0）
      france = Country.find_by(name: @country_name, data_version: 0)
      raise "未找到国家: #{@country_name}" unless france
    
      # 查找支持拒签重办和家庭申请的签证产品
      @available_products = VisaProduct.where(
        country_id: france.id,
        refused_reapply: true,
        supports_family: true,
        data_version: 0
      )
    
      # 如果有多个，选择第一个（或可以按价格、时效排序）
      @recommended_product = @available_products.first
    
      # 返回给 Agent 的任务信息
      {
        task: "请为3人家庭办理#{@country_name}申根签证，选择支持拒签后可重新办理的产品",
        country_name: @country_name,
        traveler_count: @traveler_count,
        hint: "申根签证可以在申根区26个国家自由通行。请选择支持拒签后可重新办理（refused_reapply=true）且支持家庭申请（supports_family=true）的产品",
        available_products_count: @available_products.count,
        note: "拒签重办服务可以在签证被拒后免费或优惠价再次申请，降低风险"
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
          "旅行人数错误。期望: #{@traveler_count}人（家庭申请）, 实际: #{@visa_order.traveler_count}人"
      end
    
      # 断言4: 产品支持家庭申请
      add_assertion "产品支持家庭申请", weight: 15 do
        supports_family = @visa_order.visa_product.supports_family
      
        expect(supports_family).to be_truthy,
          "所选产品不支持家庭申请。期望: supports_family=true, 实际: supports_family=#{supports_family}"
      end
    
      # 断言5: 产品支持拒签后重新办理（核心评分项）
      add_assertion "产品支持拒签后重新办理", weight: 25 do
        refused_reapply = @visa_order.visa_product.refused_reapply
      
        expect(refused_reapply).to be_truthy,
          "所选产品不支持拒签后重新办理。期望: refused_reapply=true, 实际: refused_reapply=#{refused_reapply}。" \
          "拒签重办服务可以在签证被拒后免费或优惠价再次申请，是重要的风险保障"
      end
    
      # 断言6: 订单价格计算正确
      add_assertion "订单价格计算正确", weight: 5 do
        expected_total = @visa_order.visa_product.price * @visa_order.traveler_count
        actual_total = @visa_order.total_price
      
        expect(actual_total).to eq(expected_total),
          "订单总价错误。期望: #{expected_total}元（单价#{@visa_order.visa_product.price}元 × #{@visa_order.traveler_count}人），实际: #{actual_total}元"
      end
    
      # 断言7: 联系人姓名正确（张三、李四、王芳任选其一）
      add_assertion "联系人姓名正确（3人中任选其一）", weight: 3 do
        valid_names = ['张三', '李四', '王芳']
        expect(valid_names).to include(@visa_order.contact_name),
          "联系人姓名错误。期望: #{valid_names.join('或')}（3人任选其一），实际: #{@visa_order.contact_name}"
      end
    
      # 断言8: 联系电话与联系人匹配
      add_assertion "联系电话与联系人匹配", weight: 3 do
        # 张三: 13800138000, 李四: 13900139000, 王芳: 13700137001
        valid_pairs = {
          '张三' => '13800138000',
          '李四' => '13900139000',
          '王芳' => '13700137001'
        }
      
        expected_phone = valid_pairs[@visa_order.contact_name]
        expect(@visa_order.contact_phone).to eq(expected_phone),
          "联系电话与联系人不匹配。联系人: #{@visa_order.contact_name}，期望电话: #{expected_phone}，实际电话: #{@visa_order.contact_phone}"
      end
    
      # 断言9: 收货地址与联系人匹配
      add_assertion "收货地址与联系人匹配", weight: 4 do
        # 张三: 北京朝阳, 李四: 上海浦东, 王芳: 广州天河
        valid_addresses = {
          '张三' => /北京.*朝阳.*建国路.*SOHO/,
          '李四' => /上海.*浦东.*陆家嘴.*1000/,
          '王芳' => /广东.*广州.*天河.*85/
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
        traveler_count: @traveler_count
      }
    end
  
    # 从状态恢复实例变量
    def restore_from_state(data)
      @country_name = data['country_name']
      @traveler_count = data['traveler_count']
    
      # 重新加载可用产品列表
      france = Country.find_by(name: @country_name, data_version: 0)
      if france
        @available_products = VisaProduct.where(
          country_id: france.id,
          refused_reapply: true,
          supports_family: true,
          data_version: 0
        )
        @recommended_product = @available_products.first
      end
    end
  
    # 模拟 AI Agent 操作：办理法国申根签证（3人家庭，支持拒签重办）
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
    
      # 4. 查找支持拒签重办和家庭申请的法国签证产品
      visa_products = VisaProduct.where(
        country_id: france.id,
        refused_reapply: true,
        supports_family: true,
        data_version: 0
      )
    
      raise "未找到符合条件的签证产品" if visa_products.empty?
    
      # 5. 选择第一个符合条件的产品
      selected_product = visa_products.first
    
      raise "未找到可用的签证产品" unless selected_product
    
      # 6. 拼接完整地址
      full_address = "#{contact_address.province}#{contact_address.city}#{contact_address.district}#{contact_address.detail}"
    
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
        refused_reapply: selected_product.refused_reapply,
        supports_family: selected_product.supports_family,
        price: selected_product.price,
        traveler_count: @traveler_count,
        total_price: visa_order.total_price,
        user_email: user.email
      }
    end
    end
end
