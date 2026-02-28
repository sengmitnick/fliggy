# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例284: 给张三和王芳预订下周末度假套餐
#
# 任务描述:
#   给张三和王芳（夫妻）预订2天1晚含餐的下周末度假套餐
#
# 评分标准:
#   - 创建酒店套餐订单 (20%)
#   - 套餐时长正确（1晚） (15%)
#   - 联系人信息正确 (15%)
#   - 入住日期正确（下周六） (20%)
#   - 退房日期正确（下周日） (20%)
#   - 订单状态正确 (10%)
module V251V300
  class V284BookWeekendGetawayPackageValidator < BaseValidator
    self.validator_id = 'v284_book_weekend_getaway_package_validator'
    self.task_id = '1c21acda-6325-4222-95e3-d62e336cf477'
    self.title = '给张三和王芳（夫妻）预订2天1晚含餐的下周末度假套餐'
    self.description = '给张三和王芳（夫妻）预订2天1晚含餐的下周末度假套餐'
    self.timeout_seconds = 300
    
    def prepare
      # 计算下周末的日期（下周六和下周日）
      today = Date.current
      days_until_next_saturday = (6 - today.wday + 7) % 7
      days_until_next_saturday = 7 if days_until_next_saturday == 0 # 如果今天是周六，则取下个周公
      @check_in_date = today + days_until_next_saturday.days
      @check_out_date = @check_in_date + 1.day
      
      @night_count = 1
      @package = HotelPackage.where(night_count: @night_count, data_version: 0)
                            .order(price: :asc)
                            .first!
      
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @zhangsan.name
      @expected_contact_phone = @zhangsan.phone
      
      if user.balance < @package.price
        user.update!(balance: @package.price + 500)
      end
      
      {
        task: "请给张三和王芳（夫妻）预订适合下周末度假的#{@night_count}晚酒店套餐「#{@package.title}」，#{@check_in_date.strftime('%Y年%-m月%-d日')}入住，#{@check_out_date.strftime('%Y年%-m月%-d日')}退房，享受短途休闲",
        package_title: @package.title,
        night_count: @night_count,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        price: @package.price.to_f,
        hint: "选择1晚的短途度假套餐，适合下周末放松"
      }
    end
    
    def verify
      add_assertion "创建了酒店套餐订单", weight: 20 do
        @order = HotelPackageOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@order).not_to be_nil, "未找到酒店套餐订单"
      end
      
      return unless @order
      
      add_assertion "套餐时长正确（#{@night_count}晚）", weight: 15 do
        package = @order.hotel_package
        expect(package).not_to be_nil, "订单没有关联套餐"
        expect(package.night_count).to eq(@night_count),
          "套餐时长错误。期望: #{@night_count}晚（周末短途）, 实际: #{package.night_count}晚"
      end
      
      add_assertion "联系人信息正确（张三）", weight: 15 do
        expect(@order.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@order.contact_name}"
        expect(@order.contact_phone).to eq(@expected_contact_phone),
          "联系人电话错误。期望: #{@expected_contact_phone}, 实际: #{@order.contact_phone}"
      end
      
      add_assertion "入住日期正确（下周六）", weight: 20 do
        expect(@order.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date.strftime('%Y-%m-%d')}（下周六）, 实际: #{@order.check_in_date&.strftime('%Y-%m-%d')}"
        expect(@check_in_date.saturday?).to be_truthy,
          "入住日期不是周六。实际: #{@check_in_date.strftime('%A')}"
      end
      
      add_assertion "退房日期正确（下周日）", weight: 20 do
        expect(@order.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date.strftime('%Y-%m-%d')}（下周日）, 实际: #{@order.check_out_date&.strftime('%Y-%m-%d')}"
        expect(@check_out_date.sunday?).to be_truthy,
          "退房日期不是周日。实际: #{@check_out_date.strftime('%A')}"
      end
      
      add_assertion "订单状态正确", weight: 10 do
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
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
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
        night_count: @night_count,
        package_id: @package&.id,
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @night_count = data['night_count']
      @package = HotelPackage.find(data['package_id']) if data['package_id']
      @check_in_date = Date.parse(data['check_in_date']) if data['check_in_date']
      @check_out_date = Date.parse(data['check_out_date']) if data['check_out_date']
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
    end
  end
end
