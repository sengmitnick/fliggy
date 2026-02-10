# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例295: 给刘强和陈静预订穆斯林友好服务
#
# 任务描述:
#   给刘强和陈静预订6天后出发的西安跟团游，需要清真餐饮和配备礼拜室的酒店
#
# 评分标准:
#   - 创建跟团游预订 (35%)
#   - 创建酒店预订 (30%)
#   - 联系人信息正确（刘强或陈静）(15%)
#   - 出行日期正确 (10%)
#   - 订单状态正确 (10%)
module V251V300
  class V295BookMuslimFriendlyServiceValidator < BaseValidator
    self.validator_id = 'v295_book_muslim_friendly_service_validator'
    self.task_id = '16fd7e2d-f8e9-49c8-91fc-72958aa2ec90'
    self.title = '给刘强和陈静预订穆斯林友好服务（6天后西安，含清真餐）'
    self.description = '帮刘强和陈静这对夫妻订6天后的西安跟团游，他们是穆斯林，需要清真餐饮和配备礼拜室的酒店'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '西安'
      @travel_date = Date.current + 6.days
      
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
      
      # 有效联系人电话映射
      @valid_contact_phones = {
        '刘强' => @liuqiang.phone,
        '陈静' => @chenjing.phone
      }
      
      if user.balance < 3000
        user.update!(balance: 5000)
      end
      
      {
        task: "请为刘强和陈静预订#{@destination}穆斯林友好旅游套餐，#{@travel_date.strftime('%Y年%-m月%-d日')}出发，需要清真餐饮和配备礼拜室的酒店",
        destination: @destination,
        travel_date: @travel_date.to_s,
        hint: "选择提供清真餐的跟团游和穆斯林友好酒店"
      }
    end
    
    def verify
      add_assertion "创建了跟团游预订", weight: 35 do
        @tour_booking = TourGroupBooking
          .joins(:tour_group_product)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@tour_booking).not_to be_nil, "未找到跟团游预订"
      end
      
      return unless @tour_booking
      
      add_assertion "创建了酒店预订", weight: 30 do
        @hotel_booking = HotelBooking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@hotel_booking).not_to be_nil, "未找到酒店预订"
      end
      
      add_assertion "联系人信息正确（刘强或陈静）", weight: 15 do
        valid_contacts = ['刘强', '陈静']
        expect(valid_contacts).to include(@tour_booking.contact_name),
          "联系人姓名错误。期望: 刘强或陈静, 实际: #{@tour_booking.contact_name}"
        
        expected_phone = @valid_contact_phones[@tour_booking.contact_name]
        expect(@tour_booking.contact_phone).to eq(expected_phone),
          "联系电话与联系人不匹配。联系人: #{@tour_booking.contact_name}, 期望电话: #{expected_phone}, 实际电话: #{@tour_booking.contact_phone}"
      end
      
      add_assertion "出行日期正确（#{@travel_date}）", weight: 10 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}（6天后），实际: #{@tour_booking.travel_date}"
      end
      
      add_assertion "订单状态正确", weight: 10 do
        valid_statuses = ['pending', 'confirmed', 'paid']
        expect(valid_statuses).to include(@tour_booking.status),
          "跟团游订单状态错误: #{@tour_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
      
      # 随机选择联系人
      contact_names = ['刘强', '陈静']
      selected_contact_name = contact_names.sample
      contact_passenger = selected_contact_name == '刘强' ? liuqiang : chenjing
      
      # 1. 预订跟团游
      tour_product = TourGroupProduct.where(data_version: 0).order(rating: :desc).first!
      tour_package = tour_product.tour_packages.first!
      
      TourGroupBooking.create!(
        user_id: user.id,
        tour_group_product_id: tour_product.id,
        tour_package_id: tour_package.id,
        travel_date: @travel_date,
        adult_count: 2,
        child_count: 0,
        contact_name: contact_passenger.name,
        contact_phone: contact_passenger.phone,
        insurance_type: 'none',
        total_price: tour_package.price * 2,
        status: 'confirmed',
        data_version: @data_version
      )
      
      # 2. 预订穆斯林友好酒店
      hotel = Hotel.where(data_version: 0).order(rating: :desc).first!
      
      HotelBooking.create!(
        hotel_room_id: hotel.hotel_rooms.first!.id,
        user_id: user.id,
        rooms_count: 1,
        adults_count: 2,
        children_count: 0,
        hotel_id: hotel.id,
        check_in_date: @travel_date,
        check_out_date: @travel_date + 3.days,
        guest_name: contact_passenger.name,
        guest_phone: contact_passenger.phone,
        payment_method: '花呗',
        total_price: hotel.price * 3,
        status: 'pending',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        destination: @destination,
        travel_date: @travel_date&.to_s,
        valid_contact_phones: @valid_contact_phones
      }
    end
    
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @valid_contact_phones = data['valid_contact_phones'] || {}
    end
  end
end
