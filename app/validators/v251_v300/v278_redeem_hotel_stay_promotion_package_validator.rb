# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例278: 给张三囤武汉万豪酒店套餐（2晚连住）
# 
# 任务描述:
#   帮张三囤购武汉万豪酒店套餐（2晚连住通兑），先囤货后预约，有效期内随时使用。
#   Agent 需要搜索武汉万豪酒店套餐，选择2晚连住套餐，使用囤货模式（stockup）购买。
# 
# 业务流程（6个关键步骤）：
#   1. 搜索万豪酒店品牌的酒店套餐产品
#   2. 筛选武汉地区的套餐（city = '武汉'）
#   3. 筛选2晚及以上的套餐（night_count >= 2）
#   4. 确认用户余额充足（需要≥套餐价格）
#   5. 使用囤货模式（stockup）购买套餐（不需指定入住日期）
#   6. 填写联系人信息（张三）并提交订单
# 
# 复杂度分析（6个关键点）：
#   1. 需要理解品牌筛选：万豪酒店套餐（title LIKE '%万豪%'）
#   2. 需要理解城市筛选：武汉地区（city = '武汉'）
#   3. 需要理解套餐晚数：2晚连住（night_count >= 2）
#   4. 需要理解囤货模式：stockup（先购买后预约，不需指定入住日期和酒店）
#   5. 需要检查余额是否充足：user.balance >= package.price
#   6. 需要理解有效期：套餐购买后在有效期（valid_days）内可随时使用
#   ❌ 不能一次性提供：需要先搜索套餐→检查余额→囤货购买
# 
# 评分标准（5项，总计100分）：
#   1. 创建了酒店套餐购买订单（20分）
#   2. 购买的是指定酒店品牌套餐（万豪）（30分）- 核心业务逻辑
#   3. 城市正确（武汉）（20分）- 核心地域筛选
#   4. 支付金额正确（15分）
#   5. 订单状态正确（pending/confirmed/paid）（15分）
# 
# 使用方法:
#   rake validator:simulate_single[v278_redeem_hotel_stay_promotion_package_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
module V251V300
  class V278RedeemHotelStayPromotionPackageValidator < BaseValidator
    self.validator_id = 'v278_redeem_hotel_stay_promotion_package_validator'
    self.task_id = '64e513f9-454d-4346-af2b-cc7b87b03178'
    self.title = '给张三囤武汉万豪酒店套餐（2晚连住）'
    self.description = '帮张三囤武汉地区2晚连住万豪酒店套餐，有效期内随时使用'
    self.timeout_seconds = 300
    
    def prepare
      @package_keyword = '万豪酒店'
      @city = '武汉'
      @night_count = 2
      @package = HotelPackage.where('title LIKE ?', "%#{@package_keyword}%")
                            .where(city: @city)
                            .where('night_count >= ?', @night_count)
                            .where(data_version: 0)
                            .first!
      
      # 确保用户有足够余额
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < @package.price
        raise "用户余额不足。需要: ¥#{@package.price}，当前: ¥#{user.balance}"
      end
      
      {
        task: "请囤「#{@package.title}」酒店套餐（#{@city}地区），有效期内随时使用",
        package_title: @package.title,
        city: @city,
        price: @package.price.to_f,
        night_count: @package.night_count,
        valid_days: @package.valid_days,
        hint: "这是一个#{@city}地区的#{@night_count}晚连住万豪酒店套餐，囤起来有效期365天，适合长期出差或旅游的用户"
      }
    end
    
    def verify
      add_assertion "创建了酒店套餐购买订单", weight: 20 do
        @order = HotelPackageOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@order).not_to be_nil, "未找到酒店套餐购买订单"
      end
      
      return unless @order
      
      add_assertion "购买的是指定酒店品牌套餐（#{@package_keyword}）", weight: 30 do
        package = @order.hotel_package
        expect(package).not_to be_nil, "订单没有关联套餐"
        expect(package.title).to include(@package_keyword),
          "套餐不匹配。期望包含: #{@package_keyword}, 实际: #{package.title}"
      end
      
      add_assertion "城市正确（#{@city}）", weight: 20 do
        package = @order.hotel_package
        actual_city = package.city
        expect(actual_city).to eq(@city),
          "城市错误。期望: #{@city}, 实际: #{actual_city}"
      end
      
      add_assertion "支付金额正确", weight: 15 do
        expect(@order.total_price).to be > 0,
          "支付金额错误。实际: #{@order.total_price}元"
      end
      
      add_assertion "订单状态正确", weight: 15 do
        expect(@order.status).to eq('pending').or(eq('confirmed')).or(eq('paid')),
          "订单状态错误。期望: pending/confirmed/paid, 实际: #{@order.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      package = HotelPackage.where('title LIKE ?', "%#{@package_keyword}%")
                           .where(city: @city)
                           .where('night_count >= ?', @night_count)
                           .where(data_version: 0)
                           .first!
      
      HotelPackageOrder.create!(
        user_id: user.id,
        hotel_package_id: package.id,
        hotel_id: package.hotel_id,
        package_option_id: 1,
        passenger_id: user.id,
        quantity: 1,
        total_price: package.price,
        booking_type: 'stockup',
        status: 'pending',
        contact_name: user.name || '张三',
        contact_phone: user.phone || '13800138000',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        package_keyword: @package_keyword,
        city: @city,
        night_count: @night_count,
        package_id: @package&.id
      }
    end
    
    def restore_from_state(data)
      @package_keyword = data['package_keyword']
      @city = data['city']
      @night_count = data['night_count']
      @package = HotelPackage.find(data['package_id']) if data['package_id']
    end
  end
end
