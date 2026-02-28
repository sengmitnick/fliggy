# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例113: 给刘强预订杭州私家团（4天3晚，2成人1儿童）
#
# 任务描述:
#   帮刘强预订杭州私家团，4天3晚，2成人（刘强、陈静）1儿童（小红），独立成团
#
# 评分标准:
#   - 订单已创建 (20分)
#   - 目的地正确（杭州）(15分)
#   - 旅游类型正确（独立成团）(20分)
#   - 天数正确（4天）(10分)
#   - 联系人信息正确（刘强）(10分)
#   - 人数正确（2成人1儿童）(10分)
#   - 游客信息正确（刘强、陈静、小红）(15分)
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v113_private_group_booking_validator/start
#   
#   # Agent 通过界面操作完成任务...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V101V150
  class V113PrivateGroupBookingValidator < BaseValidator
    self.validator_id = 'v113_private_group_booking_validator'
    self.task_id = '6835d498-1040-44bb-bedf-2d628e59de70'
    self.title = '帮刘强预订杭州私家团，4天3晚，2成人（刘强、陈静）1儿童（小红），独立成团'
    self.description = '帮刘强预订杭州私家团，4天3晚，2成人（刘强、陈静）1儿童（小红），独立成团'
    self.timeout_seconds = 300
  
    def prepare
      @destination = '杭州'
      @duration = 4
      @adult_count = 2
      @child_count = 1
      @travel_type = '独立成团'
      @travel_date = Date.current + 10.days  # 10天后出发
    
      # 预查询乘客信息（避免 simulate 中查询 data_version: 0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
      @xiaohong = user.passengers.find_by!(name: '小红', data_version: 0)
      
      @expected_contact_name = @liuqiang.name
      @expected_contact_phone = @liuqiang.phone
      @expected_adult_names = [@liuqiang.name, @chenjing.name].sort
      @expected_child_names = [@xiaohong.name]
    
      # 查找符合条件的私家团产品
      @qualified_products = TourGroupProduct.where(
        travel_type: @travel_type,
        duration: @duration,
        data_version: 0
      ).where("destination LIKE ?", "%#{@destination}%")
    
      # 找到价格适中的产品
      @target_product = @qualified_products.order(:price).first
    
      {
        task: "请预订#{@destination}私家团，#{@duration}天#{@duration - 1}晚，#{@adult_count}个成人（刘强、陈静）#{@child_count}个儿童（小红），独立成团（#{@travel_date.strftime('%Y年%m月%d日')}出发）",
        requirements: {
          destination: @destination,
          travel_type: @travel_type,
          travel_type_description: '独立成团/私家团（非跟团游、非自由行）',
          duration: @duration,
          adult_count: @adult_count,
          child_count: @child_count,
          travel_date: @travel_date.to_s,
          features: '独立成团，专属导游',
          travelers: '刘强、陈静（成人）和小红（儿童）'
        },
        hint: "系统中有多个#{@destination}私家团产品可选，请选择#{@duration}天行程的独立成团产品，3个游客（刘强、陈静、小红）",
        statistics: {
          total_products: @qualified_products.count,
          price_range: {
            min: @qualified_products.minimum(:price),
            max: @qualified_products.maximum(:price)
          }
        }
      }
    end
  
    def verify
      add_assertion "订单已创建", weight: 20 do
        all_bookings = TourGroupBooking.joins(:tour_group_product)
                                       .where(tour_group_products: { travel_type: @travel_type })
                                       .where(data_version: @data_version)
                                       .order(created_at: :desc)
                                       .to_a
      
        @bookings = all_bookings.select do |b|
          b.tour_group_product.destination&.include?(@destination)
        end
      
        expect(@bookings).not_to be_empty, "未找到任何#{@destination}私家团订单"
        @booking = @bookings.first
      end
    
      return if @bookings.nil? || @bookings.empty?
    
      add_assertion "目的地正确（#{@destination}）", weight: 15 do
        expect(@booking.tour_group_product.destination).to include(@destination),
          "目的地错误。期望包含: #{@destination}，实际: #{@booking.tour_group_product.destination}"
      end
    
      add_assertion "旅游类型正确（独立成团）", weight: 20 do
        expect(@booking.tour_group_product.travel_type).to eq(@travel_type),
          "旅游类型错误。期望: #{@travel_type}（私家团），实际: #{@booking.tour_group_product.travel_type}"
      end
    
      add_assertion "天数正确（#{@duration}天）", weight: 10 do
        expect(@booking.tour_group_product.duration).to eq(@duration),
          "天数错误。期望: #{@duration}天，实际: #{@booking.tour_group_product.duration}天"
      end
    
      add_assertion "联系人信息正确（刘强 13600136001）", weight: 10 do
        expect(@booking.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@booking.contact_name}"
        expect(@booking.contact_phone).to eq(@expected_contact_phone),
          "联系人电话错误。期望: #{@expected_contact_phone}, 实际: #{@booking.contact_phone}"
      end
    
      add_assertion "人数正确（#{@adult_count}成人#{@child_count}儿童）", weight: 10 do
        expect(@booking.adult_count).to eq(@adult_count),
          "成人数量错误。期望: #{@adult_count}人，实际: #{@booking.adult_count}人"
        expect(@booking.child_count).to eq(@child_count),
          "儿童数量错误。期望: #{@child_count}人，实际: #{@booking.child_count}人"
      end
      
      add_assertion "游客信息正确（刘强、陈静、小红）", weight: 15 do
        travelers = @booking.booking_travelers.where(data_version: @data_version).to_a
        
        expect(travelers.size).to eq(3),
          "游客数量不正确。期望: 3个游客（2成人1儿童）, 实际: #{travelers.size}个游客"
        
        # 分离成人和儿童游客
        adult_travelers = travelers.select { |t| t.traveler_type == 'adult' }
        child_travelers = travelers.select { |t| t.traveler_type == 'child' }
        
        expect(adult_travelers.size).to eq(2),
          "成人游客数量不正确。期望: 2个, 实际: #{adult_travelers.size}个"
        expect(child_travelers.size).to eq(1),
          "儿童游客数量不正确。期望: 1个, 实际: #{child_travelers.size}个"
        
        # 验证成人游客（刘强、陈静）
        adult_names = adult_travelers.map(&:traveler_name).sort
        expect(adult_names).to eq(@expected_adult_names),
          "成人游客名单不正确。期望: #{@expected_adult_names.join('、')}, 实际: #{adult_names.join('、')}"
        
        # 验证刘强的身份证号
        liuqiang = adult_travelers.find { |t| t.traveler_name == '刘强' }
        expect(liuqiang).not_to be_nil, "未找到游客刘强"
        expect(liuqiang.id_number).to eq(@liuqiang.id_number),
          "刘强身份证号错误。期望: #{@liuqiang.id_number}, 实际: #{liuqiang.id_number}"
        
        # 验证陈静的身份证号
        chenjing = adult_travelers.find { |t| t.traveler_name == '陈静' }
        expect(chenjing).not_to be_nil, "未找到游客陈静"
        expect(chenjing.id_number).to eq(@chenjing.id_number),
          "陈静身份证号错误。期望: #{@chenjing.id_number}, 实际: #{chenjing.id_number}"
        
        # 验证儿童游客（小红）
        child_names = child_travelers.map(&:traveler_name)
        expect(child_names).to eq(@expected_child_names),
          "儿童游客名单不正确。期望: #{@expected_child_names.join('、')}, 实际: #{child_names.join('、')}"
        
        # 验证小红的身份证号
        xiaohong = child_travelers.find { |t| t.traveler_name == '小红' }
        expect(xiaohong).not_to be_nil, "未找到游客小红"
        expect(xiaohong.id_number).to eq(@xiaohong.id_number),
          "小红身份证号错误。期望: #{@xiaohong.id_number}, 实际: #{xiaohong.id_number}"
      end
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 查找符合条件的私家团产品
      target_product = TourGroupProduct.where(
        travel_type: @travel_type,
        duration: @duration,
        data_version: 0
      ).where("destination LIKE ?", "%#{@destination}%")
       .order(:price)
       .first
    
      raise "未找到符合条件的私家团产品" unless target_product
    
      # 选择套餐（最便宜的）
      target_package = target_product.tour_packages.order(:price).first
      raise "产品没有可用套餐" unless target_package
    
      # 计算总价
      total_price = target_package.price * @adult_count + target_package.child_price * @child_count
    
      # 创建订单
      booking = TourGroupBooking.create!(
        tour_group_product_id: target_product.id,
        tour_package_id: target_package.id,
        user_id: user.id,
        travel_date: @travel_date,
        adult_count: @adult_count,
        child_count: @child_count,
        contact_name: @liuqiang.name,
        contact_phone: @liuqiang.phone,
        insurance_type: 'none',
        total_price: total_price,
        status: 'pending',
        data_version: @data_version
      )
      
      # 创建成人出行人记录（刘强、陈静）
      BookingTraveler.create!(
        tour_group_booking_id: booking.id,
        traveler_name: @liuqiang.name,
        id_number: @liuqiang.id_number,
        traveler_type: 'adult',
        data_version: @data_version
      )
      
      BookingTraveler.create!(
        tour_group_booking_id: booking.id,
        traveler_name: @chenjing.name,
        id_number: @chenjing.id_number,
        traveler_type: 'adult',
        data_version: @data_version
      )
      
      # 创建儿童出行人记录（小红）
      BookingTraveler.create!(
        tour_group_booking_id: booking.id,
        traveler_name: @xiaohong.name,
        id_number: @xiaohong.id_number,
        traveler_type: 'child',
        data_version: @data_version
      )
    end
  
    private
  
    def execution_state_data
      {
        destination: @destination,
        duration: @duration,
        adult_count: @adult_count,
        child_count: @child_count,
        travel_type: @travel_type,
        travel_date: @travel_date.to_s,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone,
        expected_adult_names: @expected_adult_names,
        expected_child_names: @expected_child_names
      }
    end
  
    def restore_from_state(data)
      @destination = data['destination']
      @duration = data['duration']
      @adult_count = data['adult_count']
      @child_count = data['child_count']
      @travel_type = data['travel_type']
      @travel_date = Date.parse(data['travel_date'])
      @expected_contact_name = data['expected_contact_name'] || '刘强'
      @expected_contact_phone = data['expected_contact_phone'] || '13600136001'
      @expected_adult_names = data['expected_adult_names'] || ['刘强', '陈静'].sort
      @expected_child_names = data['expected_child_names'] || ['小红']
    
      # 重新查询乘客信息用于验证身份证号
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
      @xiaohong = user.passengers.find_by!(name: '小红', data_version: 0)
    
      @qualified_products = TourGroupProduct.where(
        travel_type: @travel_type,
        duration: @duration,
        data_version: 0
      ).where("destination LIKE ?", "%#{@destination}%")
    end
  end
end
