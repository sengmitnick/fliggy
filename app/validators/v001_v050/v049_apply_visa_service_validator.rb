# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例49: 给张三办理泰国旅游签证（1人，最快出签）
# 
# 任务描述:
#   Agent 需要在系统中搜索泰国旅游签证服务，
#   选择processing_days最短的签证产品并成功创建订单
# 
# 复杂度分析:
#   1. 需要搜索"泰国"国家的签证产品（从多个国家中筛选）
#   2. 需要选择"旅游签证"类型（排除商务签、探亲签等）
#   3. 需要对比多个服务商的办理时长（processing_days）
#   4. 需要选择最快出签的服务商
#   5. 需要填写出行信息（联系人、地址等）
#   ❌ 不能一次性提供：需要先搜索→筛选类型→对比时效→预订
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 国家正确（泰国）(15分)
#   - 签证类型正确（旅游签证）(15分)
#   - 选择了最快出签的服务商 (30分)
#   - 订单价格和人数正确 (10分)
#   - 联系人和地址信息正确（来自demo_user） (10分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v049_apply_visa_service_validator/start
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V001V050
  class V049ApplyVisaServiceValidator < BaseValidator
    self.validator_id = 'v049_apply_visa_service_validator'
    self.task_id = '98c2a07d-46cc-4dba-ab27-fc783c9d3c09'
    self.title = '给张三办理泰国旅游签证（1人，最快出签）'
    self.description = '办理泰国旅游签证（1人，最快出签）'
    self.timeout_seconds = 240
  
    # 准备阶段：设置任务参数
    def prepare
      # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
      @country_name = '泰国'
      @product_type = '旅游签证'
      @traveler_count = 1
    
      # 查找泰国的旅游签证产品（注意：查询基线数据 data_version=0）
      thailand = Country.find_by(name: @country_name, data_version: 0)
      raise "未找到国家: #{@country_name}" unless thailand
    
      @available_products = VisaProduct.where(
        country_id: thailand.id,
        product_type: @product_type,
        data_version: 0
      )
    
      # 返回给 Agent 的任务信息
      {
        task: "请办理#{@country_name}#{@product_type}（#{@traveler_count}人），选择最快出签的服务商",
        country_name: @country_name,
        product_type: @product_type,
        traveler_count: @traveler_count,
        hint: "系统中有多个服务商提供该签证服务，请对比办理时长（processing_days）后选择最快的",
        available_products_count: @available_products.count
      }
    end
  
    # 验证阶段：检查订单是否符合要求
    def verify
      # 断言1: 订单已创建 (20分)
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
    
      # 断言2: 国家正确（泰国） (15分)
      add_assertion "国家正确（泰国）", weight: 15 do
        actual_country = @visa_order.visa_product.country.name
        expect(actual_country).to eq(@country_name),
          "国家错误。期望: #{@country_name}, 实际: #{actual_country}"
      end
    
      # 断言3: 签证类型正确（旅游签证） (15分)
      add_assertion "签证类型正确（旅游签证）", weight: 15 do
        actual_type = @visa_order.visa_product.product_type
        expect(actual_type).to eq(@product_type),
          "签证类型错误。期望: #{@product_type}, 实际: #{actual_type}"
      end
    
      # 断言4: 选择了最快出签的服务商 (30分) - 核心评分项
      add_assertion "选择了最快出签的服务商", weight: 30 do
        # 获取所有泰国旅游签证产品
        thailand = Country.find_by(name: @country_name, data_version: 0)
        all_products = VisaProduct.where(
          country_id: thailand.id,
          product_type: @product_type,
          data_version: 0
        )
      
        # 找到办理时长最短的
        fastest_product = all_products.min_by { |p| p.processing_days || 999 }
        actual_days = @visa_order.visa_product.processing_days || 999
        fastest_days = fastest_product.processing_days || 999
      
        expect(@visa_order.visa_product_id).to eq(fastest_product.id),
          "未选择最快出签的服务商。" \
          "应选: #{fastest_product.name}（#{fastest_days}个工作日，#{fastest_product.price}元），" \
          "实际选择: #{@visa_order.visa_product.name}（#{actual_days}个工作日，#{@visa_order.visa_product.price}元）"
      end
    
      # 断言5: 订单价格和人数正确 (10分)
      add_assertion "订单价格和人数正确", weight: 10 do
        expected_total = @visa_order.visa_product.price * @visa_order.traveler_count
        actual_total = @visa_order.total_price
      
        expect(@visa_order.traveler_count).to eq(@traveler_count),
          "旅行人数错误。期望: #{@traveler_count}人, 实际: #{@visa_order.traveler_count}人"
      
        expect(actual_total).to eq(expected_total),
          "订单总价错误。期望: #{expected_total}元（单价#{@visa_order.visa_product.price}元 × #{@visa_order.traveler_count}人），实际: #{actual_total}元"
      end
    
      # 断言6: 联系人和地址信息正确（张三 13800138000 北京朝阳） (10分)
      add_assertion "联系人和地址信息正确（张三 13800138000 北京朝阳）", weight: 10 do
        expect(@visa_order.contact_name).to eq('张三'),
          "联系人姓名错误。期望: 张三, 实际: #{@visa_order.contact_name}"
        expect(@visa_order.contact_phone).to eq('13800138000'),
          "联系人电话错误。期望: 13800138000, 实际: #{@visa_order.contact_phone}"
        expect(@visa_order.delivery_address).to include('北京'),
          "地址错误。期望包含: 北京, 实际: #{@visa_order.delivery_address}"
      end
    end
  
    private
  
    # 保存执行状态数据
    def execution_state_data
      {
        country_name: @country_name,
        product_type: @product_type,
        traveler_count: @traveler_count
      }
    end
  
    # 从状态恢复实例变量
    def restore_from_state(data)
      @country_name = data['country_name']
      @product_type = data['product_type']
      @traveler_count = data['traveler_count']
    
      # 重新加载可用产品列表
      thailand = Country.find_by(name: @country_name, data_version: 0)
      if thailand
        @available_products = VisaProduct.where(
          country_id: thailand.id,
          product_type: @product_type,
          data_version: 0
        )
      end
    end
  
    # 模拟 AI Agent 操作：办理泰国旅游签证，选择最快出签的服务商
    def simulate
      # 1. 查找测试用户（数据包中已创建）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      contact = user.contacts.find_by!(name: '张三', data_version: 0)
      address = user.addresses.find_by!(is_default: true, data_version: 0)
    
      # 2. 查找泰国
      thailand = Country.find_by!(name: @country_name, data_version: 0)
    
      # 3. 查找泰国的旅游签证产品
      visa_products = VisaProduct.where(
        country_id: thailand.id,
        product_type: @product_type,
        data_version: 0
      )
    
      raise "未找到符合条件的签证产品" if visa_products.empty?
    
      # 4. 选择办理时长最短的
      fastest_product = visa_products.min_by { |p| p.processing_days || 999 }
    
      raise "未找到可用的签证产品" unless fastest_product
    
      # 5. 创建签证订单
      full_address = [address.province, address.city, address.district, address.detail].compact.join
      visa_order = VisaOrder.create!(
        user_id: user.id,
        visa_product_id: fastest_product.id,
        traveler_count: @traveler_count,
        unit_price: fastest_product.price,
        total_price: fastest_product.price * @traveler_count,
        expected_date: Date.current + 30.days,  # 预计出行日期30天后
        delivery_method: 'express',
        delivery_address: full_address,
        contact_name: contact.name,
        contact_phone: contact.phone,
        status: 'pending',
        insurance_selected: false,
        insurance_price: 0
      )
    
      # 返回操作信息
      {
        action: 'create_visa_order',
        order_id: visa_order.id,
        visa_product_name: fastest_product.name,
        country_name: thailand.name,
        product_type: fastest_product.product_type,
        processing_days: fastest_product.processing_days,
        price: fastest_product.price,
        traveler_count: @traveler_count,
        total_price: visa_order.total_price,
        user_email: user.email
      }
    end
    end
end