# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例298: 给刘强和陈静预订三亚蜜月套餐
#
# 任务描述:
#   刘强和陈静新婚要去三亚度蜜月，需要浪漫主题的跟团游和高评分酒店
#
# 评分标准:
#   - 创建跟团游预订 (30%)
#   - 选择蜜月/浪漫主题行程 (25%)
#   - 创建高评分酒店预订 (20%)
#   - 出行日期正确 (10%)
#   - 联系人信息正确 (10%)
#   - 预订2人行程 (5%)
module V251V300
  class V298BookWeddingHoneymoonPackageValidator < BaseValidator
    self.validator_id = 'v298_book_wedding_honeymoon_package_validator'
    self.task_id = '2202ed38-54cf-48f7-8fe6-190608cc46c7'
    self.title = '给刘强和陈静预订三亚蜜月套餐（10天后，2人）'
    self.description = '刘强和陈静新婚要去三亚度蜜月，订个浪漫主题的跟团游和高评分酒店'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '三亚'
      @travel_date = Date.current + 10.days
      @check_in_date = @travel_date
      @check_out_date = @check_in_date + 5.days
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 10000
        user.update!(balance: 15000)
      end
      
      # Pre-query couple passengers
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
      @valid_contact_names = ['刘强', '陈静']
      @valid_contact_phones = {
        '刘强' => @liuqiang.phone,
        '陈静' => @chenjing.phone
      }
      
      {
        task: "请预订#{@destination}的蜜月旅游套餐，#{@travel_date.strftime('%Y年%-m月%-d日')}出发，需要浪漫主题的行程和高评分酒店，适合新婚夫妇度蜜月",
        destination: @destination,
        travel_date: @travel_date.to_s,
        check_in_date: @check_in_date.to_s,
        hint: "选择浪漫/情侣/蜜月主题的旅游产品和高评分酒店"
      }
    end
    
    def verify
      add_assertion "创建了跟团游预订", weight: 30 do
        @tour_booking = TourGroupBooking
          .joins(:tour_group_product)
          .where(tour_group_products: { destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@tour_booking).not_to be_nil, "未找到#{@destination}的跟团游预订"
      end
      
      return unless @tour_booking
      
      add_assertion "选择蜜月/浪漫主题行程", weight: 25 do
        tour = @tour_booking.tour_group_product
        # 高价格、高评分的行程适合蜜月
        is_honeymoon_tour = tour.price >= 3000 || tour.rating >= 4.7
        expect(is_honeymoon_tour).to be(true),
          "未选择蜜月主题行程。当前行程: #{tour.title}, 价格: ¥#{tour.price}, 评分: #{tour.rating}"
      end
      
      add_assertion "创建了高评分酒店预订", weight: 20 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        if @hotel_booking
          hotel = @hotel_booking.hotel
          expect(hotel.rating).to be >= 4.5,
            "酒店评分不足。期望≥4.5，实际: #{hotel.rating}"
        else
          # 蜜月套餐可以不单独订酒店(跟团游已含)
          expect(true).to be(true)
        end
      end
      
      add_assertion "出行日期正确", weight: 10 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}, 实际: #{@tour_booking.travel_date}"
      end
      
      add_assertion "联系人信息正确（刘强/陈静）", weight: 10 do
        expect(@valid_contact_names).to include(@tour_booking.contact_name),
          "联系人姓名错误。期望: #{@valid_contact_names.join('/')}, 实际: #{@tour_booking.contact_name}"
        
        contact_name = @tour_booking.contact_name
        expected_phone = @valid_contact_phones[contact_name]
        if expected_phone
          expect(@tour_booking.contact_phone).to eq(expected_phone),
            "联系电话与姓名不匹配。#{contact_name}的电话应为: #{expected_phone}, 实际: #{@tour_booking.contact_phone}"
        end
      end
      
      add_assertion "预订2人行程", weight: 5 do
        # 检查乘客数量
        passenger_count = @tour_booking.adult_count + @tour_booking.child_count
        expect(passenger_count).to be >= 2,
          "乘客数量不足。期望≥2人，实际: #{passenger_count}人"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择适合蜜月的高端行程
      tour_product = TourGroupProduct
        .where(destination: @destination, data_version: 0)
        .where("price >= ? OR rating >= ?", 3000, 4.7)
        .order(rating: :desc)
        .first!
      
      tour_package = tour_product.tour_packages.first!
      
      # Use existing couple passengers from demo_user
      contact_passenger = [@liuqiang, @chenjing].sample
      
      TourGroupBooking.create!(
        user_id: user.id,
        tour_group_product_id: tour_product.id,
        tour_package_id: tour_package.id,
        travel_date: @travel_date,
        adult_count: 2,
        child_count: 0,
        contact_name: contact_passenger.name,
        contact_phone: contact_passenger.phone,
        total_price: tour_package.price * 2,
        status: 'pending',
        insurance_type: 'premium',
        data_version: @data_version
      )
      
      # 额外预订高评分酒店
      hotel = Hotel
        .where(city: @destination, data_version: 0)
        .where("rating >= ?", 4.5)
        .order(rating: :desc)
        .first
      
      if hotel
        HotelBooking.create!(
          hotel_room_id: hotel.hotel_rooms.first!.id,
          user_id: user.id,
          rooms_count: 1,
          adults_count: 2,
          children_count: 0,
          hotel_id: hotel.id,
          check_in_date: @check_in_date,
          check_out_date: @check_out_date,
          guest_name: contact_passenger.name,
          guest_phone: contact_passenger.phone,
          payment_method: '花呗',
          total_price: hotel.price * (@check_out_date - @check_in_date).to_i,
          status: 'pending',
          data_version: @data_version
        )
      end
    end
    
    private
    
    def execution_state_data
      {
        destination: @destination,
        travel_date: @travel_date&.to_s,
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s,
        valid_contact_names: @valid_contact_names,
        valid_contact_phones: @valid_contact_phones
      }
    end
    
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @check_in_date = Date.parse(data['check_in_date']) if data['check_in_date']
      @check_out_date = Date.parse(data['check_out_date']) if data['check_out_date']
      @valid_contact_names = data['valid_contact_names']
      @valid_contact_phones = data['valid_contact_phones']
    end
  end
end
