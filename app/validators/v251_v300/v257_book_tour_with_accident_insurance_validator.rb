# frozen_string_literal: true

require_relative '../base_validator'

# V257: 给张三和李四预订黄山跟团游并购买境内旅游保险（意外伤害保障）
#
# 任务描述:
#   帮张三和李四预订黄山跟团游（5天后出发，2天行程，2人），
#   并为跟团游购买境内旅游保险（意外伤害保障），
#   保险天数需覆盖旅游天数（至少2天）
#
# 评分标准:
#   - 创建了跟团游订单 (20%)
#   - 出发日期正确（5天后） (5%)
#   - 创建了保险订单 (20%)
#   - 保险类型正确（境内旅游保险 domestic）(15%)
#   - 保险保障天数与旅游天数匹配（≥2天）(15%)
#   - 联系人信息正确（张三或李四） (10%)
#   - 投保人信息正确（张三、李四） (10%)
#   - 订单状态有效 (5%)
module V251V300
  class V257BookTourWithAccidentInsuranceValidator < BaseValidator
    self.validator_id = 'v257_book_tour_with_accident_insurance_validator'
    self.task_id = '685c598f-4c18-4710-ac08-c68f515ff29e'
    self.title = '帮张三和李四预订9ec4山跟团游（5天后出发，2天行程，2人），并购买境内旅游保险（意外伤害保障，保险天数至少2天）'
    self.description = '帮张三和李四预订9ec4山跟团游（5天后出发，2天行程，2人），并购买境内旅游保险（意外伤害保障，保险天数至少2天）'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '黄山'
      @travel_date = Date.current + 5.days
      @adult_count = 2
      
      # 查询 demo_user 和乘客信息（基线数据）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_contact_names = [@zhangsan.name, @lisi.name]
      @expected_contact_phones = { '张三' => @zhangsan.phone, '李四' => @lisi.phone }
      @expected_insured_names = [@zhangsan.name, @lisi.name]
      
      # 查找跟团游产品
      @tour_product = TourGroupProduct
        .where(destination: @destination, data_version: 0)
        .where('duration >= ?', 2)
        .first
      
      raise "未找到#{@destination}的跟团游产品" unless @tour_product
      
      @duration = @tour_product.duration
      
      # 查找适合跟团游的保险产品
      @available_insurances = InsuranceProduct
        .where(product_type: 'domestic', data_version: 0)
        .where('min_days <= ? AND max_days >= ?', @duration, @duration)
        .to_a
      
      raise "未找到适合#{@duration}天的保险产品" if @available_insurances.empty?
      
      {
        task: "请为张三和李四预订#{@destination}跟团游（#{@travel_date.strftime('%Y年%m月%d日')}出发，#{@duration}天，#{@adult_count}人），并购买意外伤害保险。",
        requirements: {
          passengers: '张三、李四',
          destination: @destination,
          travel_date: @travel_date,
          duration: @duration,
          adult_count: @adult_count,
          insurance_type: '境内旅游保险',
          insurance_coverage: '意外伤害'
        },
        hint: "跟团游建议购买境内旅游保险，保障天数应与旅游天数一致。"
      }
    end
    
    def verify
      add_assertion "创建了跟团游订单", weight: 20 do
        all_bookings = TourGroupBooking
          .joins(:tour_group_product)
          .includes(:tour_group_product)
          .where(tour_group_products: { destination: @destination })
          .where(data_version: @data_version)
          .to_a
        
        @tour_booking = all_bookings.first
        expect(@tour_booking).not_to be_nil, "未找到#{@destination}的跟团游订单"
      end
      
      return if @tour_booking.nil?
      
      add_assertion "出发日期正确（5天后#{@travel_date}）", weight: 5 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出发日期错误。期望: #{@travel_date}（5天后），实际: #{@tour_booking.travel_date}"
      end
      
      add_assertion "创建了保险订单", weight: 20 do
        @insurance_order = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@insurance_order).not_to be_nil, "未找到保险订单"
      end
      
      return if @insurance_order.nil?
      
      add_assertion "保险类型正确（境内旅游保险）", weight: 20 do
        product_type = @insurance_order.insurance_product.product_type
        expect(product_type).to eq('domestic'),
          "保险类型错误。期望: domestic（境内旅游），实际: #{product_type}"
      end
      
      add_assertion "保险保障天数与旅游天数匹配", weight: 15 do
        insurance_days = @insurance_order.days
        tour_duration = @tour_booking.tour_group_product.duration
        
        expect(insurance_days).to be >= tour_duration,
          "保险天数不足。旅游天数: #{tour_duration}天，保险天数: #{insurance_days}天"
      end
      
      add_assertion "联系人信息正确（张三或李四）", weight: 10 do
        expect(@expected_contact_names).to include(@tour_booking.contact_name),
          "联系人姓名错误。期望: 张三或李四，实际: #{@tour_booking.contact_name}"
        
        expected_phone = @expected_contact_phones[@tour_booking.contact_name]
        expect(@tour_booking.contact_phone).to eq(expected_phone),
          "联系电话与联系人不匹配。联系人: #{@tour_booking.contact_name}，期望电话: #{expected_phone}，实际电话: #{@tour_booking.contact_phone}"
      end
      
      add_assertion "投保人信息正确（张三、李四）", weight: 10 do
        insured = @insurance_order.insured_persons || []
        @expected_insured_names.each do |name|
          expect(insured).to include(name),
            "投保人列表中缺少#{name}。期望: [张三, 李四]，实际: #{insured.inspect}"
        end
      end
      
      add_assertion "订单状态有效", weight: 5 do
        expect(@tour_booking.status).to be_in(['pending', 'paid', 'confirmed'])
        expect(@insurance_order.status).to be_in(['pending', 'paid'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 创建跟团游订单
      tour_package = @tour_product.tour_packages.where(data_version: 0).first!
      
      # 随机选择联系人（张三或李四）
      contact = [@zhangsan, @lisi].sample
      
      tour_booking = TourGroupBooking.create!(
        user: user,
        tour_group_product: @tour_product,
        tour_package: tour_package,
        travel_date: @travel_date,
        adult_count: @adult_count,
        child_count: 0,
        contact_name: contact.name,
        contact_phone: contact.phone,
        insurance_type: 'none',
        total_price: @tour_product.price * @adult_count,
        status: 'confirmed',
        data_version: @data_version
      )
      
      # 2. 创建保险订单
      insurance_product = @available_insurances.first
      start_date = @travel_date
      end_date = start_date + @duration - 1
      unit_price = insurance_product.price_per_day * @duration
      
      InsuranceOrder.create!(
        user: user,
        insurance_product: insurance_product,
        source: 'standalone',
        related_booking_type: 'TourGroupBooking',
        related_booking_id: tour_booking.id,
        start_date: start_date,
        end_date: end_date,
        days: @duration,
        destination: @destination,
        destination_type: 'domestic',
        insured_persons: [@zhangsan.name, @lisi.name],
        unit_price: unit_price,
        quantity: @adult_count,
        total_price: unit_price * @adult_count,
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        destination: @destination,
        travel_date: @travel_date.to_s,
        adult_count: @adult_count,
        duration: @duration,
        tour_product_id: @tour_product&.id,
        expected_contact_names: @expected_contact_names,
        expected_contact_phones: @expected_contact_phones,
        expected_insured_names: @expected_insured_names
      }
    end
    
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = Date.parse(data['travel_date'])
      @adult_count = data['adult_count']
      @duration = data['duration']
      @expected_contact_names = data['expected_contact_names']
      @expected_contact_phones = data['expected_contact_phones']
      @expected_insured_names = data['expected_insured_names']
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      
      @tour_product = TourGroupProduct.find(data['tour_product_id']) if data['tour_product_id']
      
      @available_insurances = InsuranceProduct
        .where(product_type: 'domestic', data_version: 0)
        .where('min_days <= ? AND max_days >= ?', @duration, @duration)
        .to_a
    end
  end
end
