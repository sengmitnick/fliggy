# frozen_string_literal: true

require_relative '../base_validator'

# V309: 预订北京深度旅行服务（5天后，4人，导游+包车+景点讲解）
#
# 任务描述:
#   用户需要预订北京的深度旅行服务（5天后，4人），包含专业导游、包车和景点讲解。
#   需要创建2个订单：深度旅行订单和包车订单，两个订单的服务日期需一致，且状态和价格有效。
#
# 评分标准:
#   - 创建了深度旅行订单 (20%)
#   - 地点正确（北京） (10%)
#   - 创建了包车订单 (25%)
#   - 服务日期正确（5天后） (15%)
#   - 联系人信息正确（张三） (10%)
#   - 参与人数正确（4人成人） (10%)
#   - 订单状态和价格有效 (10%)
module V301V350
  class V309BookLocalGuideCarCommentaryValidator < BaseValidator
    self.validator_id = 'v309_book_local_guide_car_commentary_validator'
    self.task_id = 'f4d35905-7889-4569-8f32-a0b6c76a7873'
    self.title = '张三、李四、刘强、王芳想5天后去北京玩深度游，需4人，要导游、包车和景点讲解'
    self.description = '张三、李四、刘强、王芳想5天后去北京玩深度游，需4人，要导游、包车和景点讲解'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Pre-query existing passengers from demo_user (4 adults for deep travel)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      
      # Expected contact info (any of the 4 travelers can be contact)
      @expected_contact_names = [@zhangsan.name, @lisi.name, @liuqiang.name, @wangfang.name]
      @expected_contact_phones = {
        @zhangsan.name => @zhangsan.phone,
        @lisi.name => @lisi.phone,
        @liuqiang.name => @liuqiang.phone,
        @wangfang.name => @wangfang.phone
      }
      @expected_id_numbers = {
        @zhangsan.name => @zhangsan.id_number,
        @lisi.name => @lisi.id_number,
        @liuqiang.name => @liuqiang.id_number,
        @wangfang.name => @wangfang.id_number
      }
      
      @travel_date = Date.current + 5.days
      @participant_count = 4
      @location = '北京'
      
      # 查找北京地区的深度旅行产品
      @deep_travel_product = DeepTravelProduct
        .joins(:deep_travel_guide)
        .where(location: @location, data_version: 0)
        .where('deep_travel_products.title LIKE ?', '%讲解%')
        .first
      
      @deep_travel_product ||= DeepTravelProduct
        .joins(:deep_travel_guide)
        .where(location: @location, data_version: 0)
        .first
      
      raise "未找到#{@location}的深度旅行产品" unless @deep_travel_product
      
      @guide = @deep_travel_product.deep_travel_guide
      
      # 查找包车服务
      @car = Car.where(data_version: 0, category: 'mpv').first
      @car ||= Car.where(data_version: 0).first
      raise "未找到可用车辆" unless @car
      
      {
        task: "请预订#{@location}的深度旅行服务（#{@travel_date.strftime('%Y年%m月%d日')}，#{@participant_count}人），包含当地司导、包车和景点讲解服务。",
        requirements: {
          location: @location,
          travel_date: @travel_date,
          participant_count: @participant_count,
          services: ['专业导游', '包车服务', '景点讲解']
        },
        hint: "需要预订深度旅行产品（导游讲解）和包车服务。"
      }
    end
    
    def verify
      add_assertion "创建了深度旅行订单", weight: 20 do
        @deep_travel_booking = DeepTravelBooking
          .joins(:deep_travel_product)
          .where(data_version: @data_version)
          .first
        
        expect(@deep_travel_booking).not_to be_nil, "未找到深度旅行订单"
      end
      
      return if @deep_travel_booking.nil?
      
      add_assertion "地点正确（#{@location}）", weight: 10 do
        expect(@deep_travel_booking.deep_travel_product.location).to eq(@location),
          "地点错误。期望: #{@location}，实际: #{@deep_travel_booking.deep_travel_product.location}"
      end
      
      add_assertion "创建了包车订单", weight: 25 do
        @car_order = CarOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@car_order).not_to be_nil, "未找到包车订单"
      end
      
      add_assertion "服务日期正确", weight: 15 do
        expect(@deep_travel_booking.travel_date).to eq(@travel_date),
          "深度旅行日期错误。期望: #{@travel_date}（5天后），实际: #{@deep_travel_booking.travel_date}"
        
        if @car_order
          expect(@car_order.pickup_datetime.to_date).to eq(@travel_date),
            "包车取车日期错误。期望: #{@travel_date}（5天后），实际: #{@car_order.pickup_datetime.to_date}"
        end
      end
      
      add_assertion "联系人信息正确（张三、李四、刘强或王芳）", weight: 10 do
        expect(@expected_contact_names).to include(@deep_travel_booking.contact_name),
          "联系人姓名错误。期望: #{@expected_contact_names.join('、')}中的一个, 实际: #{@deep_travel_booking.contact_name}"
        expected_phone = @expected_contact_phones[@deep_travel_booking.contact_name]
        expect(@deep_travel_booking.contact_phone).to eq(expected_phone),
          "联系电话错误。期望: #{expected_phone}（#{@deep_travel_booking.contact_name}）, 实际: #{@deep_travel_booking.contact_phone}"
      end
      
      add_assertion "参与人数正确（4人成人）", weight: 10 do
        expect(@deep_travel_booking.adult_count).to eq(@participant_count),
          "成人数量错误。期望: #{@participant_count}人，实际: #{@deep_travel_booking.adult_count}人"
        expect(@deep_travel_booking.child_count).to eq(0),
          "儿童数量错误。期望: 0人，实际: #{@deep_travel_booking.child_count}人"
      end
      
      add_assertion "订单状态和价格有效", weight: 10 do
        expect(@deep_travel_booking.status).to be_in(['pending', 'paid', 'confirmed'])
        expect(@deep_travel_booking.total_price).to be > 0
        
        if @car_order
          expect(@car_order.status).to be_in(['pending', 'paid', 'confirmed'])
          expect(@car_order.total_price).to be > 0
        end
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 随机选择一位作为联系人
      contact_person = [@zhangsan, @lisi, @liuqiang, @wangfang].sample
      
      # 1. 创建深度旅行订单 - Use randomly selected contact
      DeepTravelBooking.create!(
        user: user,
        deep_travel_guide: @guide,
        deep_travel_product: @deep_travel_product,
        travel_date: @travel_date,
        adult_count: @participant_count,
        child_count: 0,
        contact_name: contact_person.name,
        contact_phone: contact_person.phone,
        total_price: @deep_travel_product.price,
        insurance_price: 0,
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 创建包车订单 - Use randomly selected contact
      pickup_datetime = @travel_date.to_time + 9.hours
      return_datetime = @travel_date.to_time + 18.hours
      
      CarOrder.create!(
        user: user,
        car: @car,
        pickup_datetime: pickup_datetime,
        return_datetime: return_datetime,
        total_price: @car.price_per_day,
        pickup_location: @location,
        driver_name: contact_person.name,
        driver_id_number: contact_person.id_number,
        contact_phone: contact_person.phone,
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        travel_date: @travel_date.to_s,
        participant_count: @participant_count,
        location: @location,
        deep_travel_product_id: @deep_travel_product&.id,
        guide_id: @guide&.id,
        car_id: @car&.id,
        expected_contact_names: @expected_contact_names,
        expected_contact_phones: @expected_contact_phones,
        expected_id_numbers: @expected_id_numbers
      }
    end
    
    def restore_from_state(data)
      @travel_date = Date.parse(data['travel_date'])
      @participant_count = data['participant_count']
      @location = data['location']
      @expected_contact_names = data['expected_contact_names']
      @expected_contact_phones = data['expected_contact_phones']
      @expected_id_numbers = data['expected_id_numbers']
      
      @deep_travel_product = DeepTravelProduct.find(data['deep_travel_product_id']) if data['deep_travel_product_id']
      @guide = DeepTravelGuide.find(data['guide_id']) if data['guide_id']
      @car = Car.find(data['car_id']) if data['car_id']
    end
  end
end
