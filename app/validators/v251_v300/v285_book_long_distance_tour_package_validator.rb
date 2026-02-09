# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例285: 给张三和王芳预订云南长线游套餐
#
# 任务描述:
#   给张三和王芳（夫妻）预订7天6晚云南深度游套餐（昆明出发）
#
# 评分标准:
#   - 创建跟团游预订 (20%)
#   - 行程时长正确（≥7天） (15%)
#   - 联系人信息正确 (15%)
#   - 目的地正确（云南） (15%)
#   - 出发城市正确（昆明） (15%)
#   - 长线游价格合理 (10%)
#   - 订单状态正确 (10%)
module V251V300
  class V285BookLongDistanceTourPackageValidator < BaseValidator
    self.validator_id = 'v285_book_long_distance_tour_package_validator'
    self.task_id = '017fa810-5e0d-4b89-9eef-1ac127ff20fe'
    self.title = '给张三和王芳预订云南长线游套餐'
    self.description = '给张三和王芳（夫妻）预订7天6晚云南深度游套餐（昆明出发）'
    self.timeout_seconds = 300
    
    def prepare
      @duration = 7
      @adult_count = 2
      @destination = '云南'
      @departure_city = '昆明'
      
      @product = TourGroupProduct
        .where('duration >= ?', @duration)
        .where(destination: @destination, departure_city: @departure_city)
        .where(data_version: 0)
        .order(price: :desc)
        .first!
      
      # 预查询套餐（必须存在于数据包）
      @package = @product.tour_packages.where(data_version: 0).first!
      
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @zhangsan.name
      @expected_contact_phone = @zhangsan.phone
      
      total_price = @package.price * @adult_count
      if user.balance < total_price
        user.update!(balance: total_price + 1000)
      end
      
      {
        task: "请给张三和王芳（夫妻）预订从#{@departure_city}出发的#{@product.duration}天云南长线游套餐「#{@product.title}」，游览多个城市",
        product_title: @product.title,
        duration: @product.duration,
        destination: @destination,
        departure_city: @departure_city,
        price: @product.price.to_f,
        hint: "选择天数较长的跟团游产品（≥7天），适合深度旅游"
      }
    end
    
    def verify
      add_assertion "创建了跟团游预订", weight: 20 do
        @booking = TourGroupBooking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@booking).not_to be_nil, "未找到跟团游预订"
      end
      
      return unless @booking
      
      add_assertion "行程时长正确（≥#{@duration}天）", weight: 15 do
        product = @booking.tour_group_product
        expect(product).not_to be_nil, "订单没有关联产品"
        expect(product.duration).to be >= @duration,
          "行程时长不足。期望: ≥#{@duration}天（长线游）, 实际: #{product.duration}天"
      end
      
      add_assertion "联系人信息正确（张三）", weight: 15 do
        expect(@booking.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@booking.contact_name}"
        expect(@booking.contact_phone).to eq(@expected_contact_phone),
          "联系人电话错误。期望: #{@expected_contact_phone}, 实际: #{@booking.contact_phone}"
      end
      
      add_assertion "目的地正确（#{@destination}）", weight: 15 do
        product = @booking.tour_group_product
        expect(product.destination).to eq(@destination),
          "目的地错误。期望: #{@destination}, 实际: #{product.destination}"
      end
      
      add_assertion "出发城市正确（#{@departure_city}）", weight: 15 do
        product = @booking.tour_group_product
        expect(product.departure_city).to eq(@departure_city),
          "出发城市错误。期望: #{@departure_city}, 实际: #{product.departure_city}"
      end
      
      add_assertion "长线游价格合理", weight: 10 do
        expect(@booking.total_price).to be > 1000,
          "长线游价格过低，不合理。实际: #{@booking.total_price}元（≥7天产品应该高于1000元）"
      end
      
      add_assertion "订单状态正确", weight: 10 do
        expect(@booking.status).to eq('pending').or(eq('confirmed')),
          "订单状态错误。期望: pending/confirmed, 实际: #{@booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      
      TourGroupBooking.create!(
        user_id: user.id,
        tour_group_product_id: @product.id,
        tour_package_id: @package.id,
        adult_count: @adult_count,
        child_count: 0,
        contact_name: zhangsan.name,
        contact_phone: zhangsan.phone,
        travel_date: Date.current + 14.days,
        total_price: @package.price * @adult_count,
        status: 'confirmed',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        duration: @duration,
        adult_count: @adult_count,
        destination: @destination,
        departure_city: @departure_city,
        product_id: @product&.id,
        package_id: @package&.id,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @duration = data['duration']
      @adult_count = data['adult_count']
      @destination = data['destination']
      @departure_city = data['departure_city']
      @product = TourGroupProduct.find(data['product_id']) if data['product_id']
      @package = TourPackage.find(data['package_id']) if data['package_id']
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
    end
  end
end
