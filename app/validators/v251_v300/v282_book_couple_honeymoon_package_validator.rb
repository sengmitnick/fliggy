# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例282: 给张三和王芳预订蜜月酒店套餐
#
# 任务描述:
#   给张三和王芳（夫妻）预订高端浪漫酒店套餐，适合蜜月旅行
#
# 评分标准:
#   - 创建酒店套餐订单 (25%)
#   - 套餐适合情侣（希尔顿品牌） (20%)
#   - 联系人信息正确 (15%)
#   - 套餐时长正确（≥2晚） (20%)
#   - 订单状态正确 (20%)
module V251V300
  class V282BookCoupleHoneymoonPackageValidator < BaseValidator
    self.validator_id = 'v282_book_couple_honeymoon_package_validator'
    self.task_id = '34788f50-b5af-484d-b9ee-e8fe13d134bf'
    self.title = '给张三和王芳（夫妻）预订高端浪漫酒店套餐，适合蜜月旅行'
    self.description = '给张三和王芳（夫妻）预订高端浪漫酒店套餐，适合蜜月旅行'
    self.timeout_seconds = 300
    
    def prepare
      @keyword = '希尔顿'
      @min_night_count = 2
      @package = HotelPackage.where('title LIKE ?', "%#{@keyword}%")
                            .where(data_version: 0)
                            .where('night_count >= ?', @min_night_count)
                            .order(price: :desc)
                            .first!
      
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @zhangsan.name
      @expected_contact_phone = @zhangsan.phone
      
      if user.balance < @package.price
        user.update!(balance: @package.price + 1000)
      end
      
      {
        task: "请给张三和王芳（夫妻）预订适合蜜月的高端酒店套餐「#{@package.title}」，享受浪漫体验",
        package_title: @package.title,
        price: @package.price.to_f,
        night_count: @package.night_count,
        hint: "选择希尔顿品牌的高档浪漫酒店套餐，至少2晚"
      }
    end
    
    def verify
      add_assertion "创建了酒店套餐订单", weight: 25 do
        @order = HotelPackageOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@order).not_to be_nil, "未找到酒店套餐订单"
      end
      
      return unless @order
      
      add_assertion "预订的是高端酒店套餐（#{@keyword}）", weight: 20 do
        package = @order.hotel_package
        expect(package).not_to be_nil, "订单没有关联套餐"
        expect(package.title).to include(@keyword),
          "酒店品牌不匹配。期望包含: #{@keyword}, 实际: #{package.title}"
      end
      
      add_assertion "联系人信息正确（张三）", weight: 15 do
        expect(@order.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@order.contact_name}"
        expect(@order.contact_phone).to eq(@expected_contact_phone),
          "联系人电话错误。期望: #{@expected_contact_phone}, 实际: #{@order.contact_phone}"
      end
      
      add_assertion "套餐时长正确（≥#{@min_night_count}晚）", weight: 20 do
        package = @order.hotel_package
        expect(package.night_count).to be >= @min_night_count,
          "套餐时长不足。期望: ≥#{@min_night_count}晚, 实际: #{package.night_count}晚"
      end
      
      add_assertion "订单状态正确", weight: 20 do
        expect(@order.status).to eq('pending').or(eq('confirmed')).or(eq('paid')),
          "订单状态错误。期望: pending/confirmed/paid, 实际: #{@order.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      
      HotelPackageOrder.create!(
        user_id: user.id,
        hotel_package_id: @package.id,
        hotel_id: @package.hotel_id,
        package_option_id: 1,
        passenger_id: user.id,
        quantity: 1,
        total_price: @package.price,
        booking_type: 'stockup',
        status: 'pending',
        contact_name: zhangsan.name,
        contact_phone: zhangsan.phone,
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        keyword: @keyword,
        min_night_count: @min_night_count,
        package_id: @package&.id,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @keyword = data['keyword']
      @min_night_count = data['min_night_count']
      @package = HotelPackage.find(data['package_id']) if data['package_id']
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
    end
  end
end
