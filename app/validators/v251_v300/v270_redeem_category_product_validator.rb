# frozen_string_literal: true

module V251V300
  # V270: 给刘强按分类兑换商品（年货精选 - 三只松鼠零食大礼包）
  #
  # 场景: 用户在年货精选分类中选择商品兑换（三只松鼠零食大礼包，销量最高的年货商品）
  # 考点: 分类筛选功能、特定品类商品兑换
  #
  # 业务流程:
  #   1. 用户输入：商品分类（年货精选）、收货人（刘强）
  #   2. 系统筛选：查找年货精选分类商品，按销量排序，选择销量最高的商品（三只松鼠零食大礼包，销量678）
  #   3. 用户选择：选择三只松鼠零食大礼包（800积分+68元），确认积分和现金金额
  #   4. 提交订单：使用刘强的收货地址
  #
  # 复杂度分析:
  #   1. **分类筛选逻辑**（中）：需按category='spring_festival'筛选并按销量排序
  #   2. **年货商品特征**（低）：需验证商品属于年货精选分类
  #
  # 评分标准（总分100%）:
  #   - 创建了兑换订单 (25%)
  #   - 商品属于年货精选分类 (25%)
  #   - 商品是三只松鼠零食大礼包（销量最高） (额外验证)
  #   - 商品信息完整 (10%)
  #   - 订单金额正确（800积分+68元） (10%)
  #   - 收货人信息正确（刘强） (15%)
  #   - 订单状态有效 (15%)
  class V270RedeemCategoryProductValidator < BaseValidator
    self.validator_id = 'v270_redeem_category_product_validator'
    self.task_id = 'c479d048-ba73-4eb7-b867-53a0abd4cdb3'
    self.title = '帮刘强在年货精选分类中兑换三只松鼠零食大礼包'
    self.description = '帮刘强在积分商城年货精选分类中兑换商品（三只松鼠零食大礼包，销量最高的年货商品，需要800积分+68元）'
    self.timeout_seconds = 300
    
    def prepare
      @category = 'spring_festival'
      @category_name = '年货精选'
      
      # 查找年货精选分类商品
      @category_products = MembershipProduct
        .where(category: @category, data_version: 0)
        .order(sales_count: :desc)
        .limit(5)
        .to_a
      
      raise "未找到#{@category_name}分类商品" if @category_products.empty?
      
      # 选择第一个商品
      @product = @category_products.first
      @product_name = @product.name
      
      # 确保用户有足够的积分和余额
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 查询刘强的地址信息
      @liuqiang_address = user.addresses.find_by!(name: '刘强', data_version: 0)
      @expected_shipping_address = [@liuqiang_address.province, @liuqiang_address.city, @liuqiang_address.district, @liuqiang_address.detail].compact.join
      @expected_contact_name = @liuqiang_address.name
      @expected_contact_phone = @liuqiang_address.phone
      
      membership = user.membership
      
      if membership.points < @product.price_mileage
        raise "用户积分不足。需要: #{@product.price_mileage}积分，当前: #{membership.points}积分"
      end
      
      if user.balance < @product.price_cash
        raise "用户余额不足。需要: ¥#{@product.price_cash}，当前: ¥#{user.balance}"
      end
      
      {
        task: "请帮刘强在积分商城的「#{@category_name}」分类中选择销量最高的商品进行兑换（三只松鼠零食大礼包）",
        requirements: {
          category: @category_name,
          product_name: '三只松鼠零食大礼包',
          highest_sales: true,
          available_products: @category_products.map(&:name),
          recipient: '刘强'
        },
        hint: "#{@category_name}分类包含传统节日礼品、特色食品等商品，请按销量排序选择销量最高的三只松鼠零食大礼包（800积分+68元），收货地址使用刘强的地址。"
      }
    end
    
    def verify
      add_assertion "创建了兑换订单", weight: 25 do
        @all_orders = MembershipOrder
          .joins(:membership_product)
          .includes(:membership_product)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(@all_orders).not_to be_empty, "未找到任何兑换订单"
        @order = @all_orders.first
      end
      
      return if @all_orders.nil? || @all_orders.empty?
      
      add_assertion "商品属于#{@category_name}分类", weight: 25 do
        product = @order.membership_product
        expect(product.category).to eq(@category),
          "商品分类错误。期望: #{@category}(#{@category_name}), 实际: #{product.category}(#{product.category_name})"
      end
      
      add_assertion "商品信息完整", weight: 10 do
        product = @order.membership_product
        expect(product.name).not_to be_empty
        expect(product.description).not_to be_empty
      end
      
      add_assertion "订单金额正确", weight: 10 do
        expect(@order.total_cash).to eq(@order.price_cash * @order.quantity)
        expect(@order.total_mileage).to eq(@order.price_mileage * @order.quantity)
      end
      
      add_assertion "收货人信息正确（刘强）", weight: 15 do
        expect(@order.contact_name).to eq(@expected_contact_name),
          "收货人姓名错误。期望: #{@expected_contact_name}, 实际: #{@order.contact_name}"
        expect(@order.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}, 实际: #{@order.contact_phone}"
      end
      
      add_assertion "订单状态有效", weight: 15 do
        expect(@order.status).to be_in(['pending', 'paid', 'shipping', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      MembershipOrder.create!(
        user: user,
        membership_product: @product,
        quantity: 1,
        price_cash: @product.price_cash,
        price_mileage: @product.price_mileage,
        total_cash: @product.price_cash,
        total_mileage: @product.price_mileage,
        contact_name: @expected_contact_name,
        contact_phone: @expected_contact_phone,
        shipping_address: @expected_shipping_address,
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      { 
        product_id: @product&.id, 
        category: @category,
        liuqiang_address_id: @liuqiang_address&.id
      }
    end
    
    def restore_from_state(data)
      @category = data['category']
      @category_name = '年货精选'
      @product = MembershipProduct.find(data['product_id']) if data['product_id']
      @product_name = @product&.name
      
      # 恢复地址信息
      if data['liuqiang_address_id']
        @liuqiang_address = Address.find(data['liuqiang_address_id'])
        @expected_shipping_address = [@liuqiang_address.province, @liuqiang_address.city, @liuqiang_address.district, @liuqiang_address.detail].compact.join
        @expected_contact_name = @liuqiang_address.name
        @expected_contact_phone = @liuqiang_address.phone
      end
      
      @category_products = MembershipProduct
        .where(category: @category, data_version: 0)
        .order(sales_count: :desc)
        .limit(5)
        .to_a
    end
  end
end
