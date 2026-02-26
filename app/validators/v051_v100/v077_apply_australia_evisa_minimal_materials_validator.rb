# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例77: 给张三办理澳大利亚电子签证（1人，材料最少，邮寄方式）
# 
# 任务描述:
#   Agent 需要办理澳大利亚电子签证，
#   选择所需材料最少的产品，使用邮寄方式
# 
# 复杂度分析:
#   1. 需要搜索"澳大利亚"国家的签证产品
#   2. 需要选择"旅游签证"类型
#   3. 需要对比所需材料数量（material_count）
#   4. 需要选择材料数量最少的产品
#   5. 使用邮寄方式（delivery_method: 'mail'）
#   ❌ 不能一次性提供：需要先搜索→筛选类型→对比材料数
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 国家正确（澳大利亚）(15分)
#   - 签证类型正确（旅游签证）(15分)
#   - 使用邮寄方式 (20分)
#   - 选择了所需材料最少的产品 (25分)
#   - 联系人和地址信息正确 (5分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v077_apply_australia_evisa_minimal_materials_validator/start
#   
#   # Agent 通过界面操作完成办理...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V051V100
  class V077ApplyAustraliaEvisaMinimalMaterialsValidator < BaseValidator
    self.validator_id = 'v077_apply_australia_evisa_minimal_materials_validator'
    self.task_id = '0c821879-db54-42b8-9526-3336bb7af223'
    self.title = '给张三办理澳大利亚电子签证（1人，材料最少，邮寄方式）'
    self.description = '办理澳大利亚电子签证（1人，材料最少，邮寄方式）'
    self.timeout_seconds = 240
  
    # 准备阶段：设置任务参数
    def prepare
      # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
      @country_name = '澳大利亚'
      @product_type = '旅游签证'
      @traveler_count = 1
    
      # 查找澳大利亚的旅游签证产品（注意：查询基线数据 data_version=0）
      australia = Country.find_by(name: @country_name, data_version: 0)
      raise "未找到国家: #{@country_name}" unless australia
    
      # 查找旅游签证产品
      @available_products = VisaProduct.where(
        country_id: australia.id,
        product_type: @product_type,
        data_version: 0
      )
    
      # 找到所需材料最少的产品
      @minimal_materials_product = @available_products.min_by { |p| p.material_count || 999 }
      @minimal_count = @minimal_materials_product&.material_count || 999
    
      # 返回给 Agent 的任务信息
      {
        task: "请办理#{@country_name}#{@product_type}（#{@traveler_count}人），选择所需材料最少的产品，使用邮寄方式",
        country_name: @country_name,
        product_type: @product_type,
        traveler_count: @traveler_count,
        hint: "澳大利亚旅游签证为电子签证，无需邮寄护照原件。请选择所需材料数量（material_count）最少的产品，并使用邮寄方式（delivery_method: 'mail'）",
        available_products_count: @available_products.count,
        note: "材料越少办理越便捷，邮寄方式需要填写收货地址"
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
      add_assertion "国家正确（澳大利亚）", weight: 15 do
        actual_country = @visa_order.visa_product.country.name
        expect(actual_country).to eq(@country_name),
          "国家错误。期望: #{@country_name}, 实际: #{actual_country}"
      end
    
      # 断言3: 签证类型正确（旅游签证）
      add_assertion "签证类型正确（旅游签证）", weight: 15 do
        actual_type = @visa_order.visa_product.product_type
        expect(actual_type).to eq(@product_type),
          "签证类型错误。期望: #{@product_type}, 实际: #{actual_type}。" \
          "澳大利亚旅游签证为电子签证，无需邮寄护照原件"
      end
    
      # 断言4: 使用邮寄方式
      add_assertion "使用邮寄方式", weight: 20 do
        delivery_method = @visa_order.delivery_method
      
        expect(delivery_method).to eq('mail'),
          "配送方式错误。期望: mail（邮寄），实际: #{delivery_method}"
      end
    
      # 断言5: 选择了所需材料最少的产品（核心评分项）
      add_assertion "选择了所需材料最少的产品", weight: 25 do
        # 获取所有澳大利亚旅游签证产品
        australia = Country.find_by(name: @country_name, data_version: 0)
        all_products = VisaProduct.where(
          country_id: australia.id,
          product_type: @product_type,
          data_version: 0
        )
      
        # 找到所需材料最少的
        minimal_product = all_products.min_by { |p| p.material_count || 999 }
        actual_count = @visa_order.visa_product.material_count || 999
        minimal_count = minimal_product.material_count || 999
      
        expect(@visa_order.visa_product_id).to eq(minimal_product.id),
          "未选择所需材料最少的产品。" \
          "应选: #{minimal_product.name}（需要#{minimal_count}种材料，#{minimal_product.processing_days}个工作日，#{minimal_product.price}元），" \
          "实际选择: #{@visa_order.visa_product.name}（需要#{actual_count}种材料，#{@visa_order.visa_product.processing_days}个工作日，#{@visa_order.visa_product.price}元）"
      end
    
      # 断言6: 联系人姓名正确（王芳）
      add_assertion "联系人姓名正确（王芳）", weight: 2 do
        expect(@visa_order.contact_name).to eq('王芳'),
          "联系人姓名错误。期望: 王芳，实际: #{@visa_order.contact_name}"
      end
    
      # 断言7: 联系电话正确（王芳的电话）
      add_assertion "联系电话正确（王芳的电话）", weight: 2 do
        expect(@visa_order.contact_phone).to eq('13700137001'),
          "联系电话错误。期望: 13700137001（王芳），实际: #{@visa_order.contact_phone}"
      end
    
      # 断言8: 收货地址与联系人匹配
      add_assertion "收货地址与联系人匹配", weight: 1 do
        # 王芳地址: 广东省广州天河区珠江新城花城大道85号
        expected_pattern = /广东.*广州.*天河.*85/
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
        minimal_count: @minimal_count
      }
    end
  
    # 从状态恢复实例变量
    def restore_from_state(data)
      @country_name = data['country_name']
      @product_type = data['product_type']
      @traveler_count = data['traveler_count']
      @minimal_count = data['minimal_count']
    
      # 重新加载可用产品列表
      australia = Country.find_by(name: @country_name, data_version: 0)
      if australia
        @available_products = VisaProduct.where(
          country_id: australia.id,
          product_type: @product_type,
          data_version: 0
        )
        @minimal_materials_product = @available_products.min_by { |p| p.material_count || 999 }
      end
    end
  
    # 模拟 AI Agent 操作：办理澳大利亚电子签证（材料最少，上门取件）
    def simulate
      # 1. 查找测试用户和联系人（数据包中已创建）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      contact_passenger = user.passengers.find_by!(name: '王芳', data_version: 0)
      contact_address = user.addresses.find_by!(name: '王芳', data_version: 0)
    
      # 2. 查找澳大利亚
      australia = Country.find_by!(name: @country_name, data_version: 0)
    
      # 3. 查找澳大利亚旅游签证产品
      visa_products = VisaProduct.where(
        country_id: australia.id,
        product_type: @product_type,
        data_version: 0
      )
    
      raise "未找到符合条件的签证产品" if visa_products.empty?
    
      # 4. 选择所需材料最少的
      minimal_product = visa_products.min_by { |p| p.material_count || 999 }
    
      raise "未找到可用的签证产品" unless minimal_product
    
      # 5. 拼接完整地址
      full_address = [contact_address.province, contact_address.city, contact_address.district, contact_address.detail].compact.join
    
      # 6. 创建签证订单
      visa_order = VisaOrder.create!(
        user_id: user.id,
        visa_product_id: minimal_product.id,
        traveler_count: @traveler_count,
        unit_price: minimal_product.price,
        total_price: minimal_product.price * @traveler_count,
        expected_date: Date.current + 60.days,  # 预计出行日期60天后
        delivery_method: 'mail',  # 邮寄方式
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
        visa_product_name: minimal_product.name,
        country_name: australia.name,
        product_type: minimal_product.product_type,
        processing_days: minimal_product.processing_days,
        material_count: minimal_product.material_count,
        delivery_method: 'mail',
        price: minimal_product.price,
        traveler_count: @traveler_count,
        total_price: visa_order.total_price,
        user_email: user.email
      }
    end
    end
end