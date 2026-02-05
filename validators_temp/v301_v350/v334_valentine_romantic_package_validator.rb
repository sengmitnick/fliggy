# frozen_string_literal: true

module V301V350
  class V334ValentineRomanticPackageValidator < BaseValidator
    self.validator_id = 334
    self.task_id = "9a66ffac-98dc-4c5f-bc3c-1450bbb46a23"
    self.title = "情人节浪漫套餐（情侣酒店+晚餐）"
    self.description = "用户需要预订2月14日情人节浪漫套餐"
    self.timeout_seconds = 180

    def prepare
      # 情人节（明年2月14日）
      @check_in_date = Date.today + 45.days
      @check_out_date = @check_in_date + 1.day
      @hotel_name = "杭州西湖浪漫情侣酒店"
      
      # 创建旅行社(用于酒店套餐)
      @agency = TravelAgency.find_by!(
        name: "杭州浪漫之旅旅行社",
        data_version: 0
      )
      
      # 创建情侣主题酒店
      @hotel = Hotel.find_by!(
        name: @hotel_name,
        city: "杭州",
        data_version: 0
      )

      # 创建情人节套餐
      @package = HotelPackage.find_by!(
        name: "情人节浪漫套餐",
        hotel_id: @hotel.id,
        data_version: 0
      )

      {
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        hotel_name: @hotel_name,
        package_name: @package.name,
        task_info: "情人节浪漫套餐预订（情侣酒店+烛光晚餐）"
      }
    end

    def simulate
      raise NotImplementedError, "请实现AI Agent逻辑：查询用户信息、查询#{@check_in_date}的#{@hotel_name}情人节套餐、创建预订"
    end

    def verify
      add_assertion "创建了情人节套餐预订", weight: 30 do
        all_orders = HotelPackageOrder
          .joins(:hotel_package)
          .includes(:hotel_package, hotel_package: :hotel)
          .where(hotel_packages: { hotels: { name: @hotel_name } })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_orders).not_to be_empty, "未找到任何情人节套餐预订"
        
        @package_orders = all_orders.select { |o|
          o.check_in_date.to_date == @check_in_date
        }
        
        expect(@package_orders.size).to be >= 1, "未找到符合条件的预订"
      end

      return if @package_orders.nil? || @package_orders.empty?

      add_assertion "酒店正确（#{@hotel_name}）", weight: 15 do
        @package_orders.each do |order|
          expect(order.hotel_package.hotel.name).to eq(@hotel_name),
            "酒店错误。期望: #{@hotel_name}, 实际: #{order.hotel_package.hotel.name}"
        end
      end

      add_assertion "入住日期正确（情人节：#{@check_in_date}）", weight: 20 do
        @package_orders.each do |order|
          actual_date = order.check_in_date.to_date
          expect(actual_date).to eq(@check_in_date),
            "入住日期错误。期望: #{@check_in_date}（2月14日情人节），实际: #{actual_date}"
        end
      end

      add_assertion "离店日期正确（#{@check_out_date}）", weight: 15 do
        @package_orders.each do |order|
          actual_date = order.check_out_date.to_date
          expect(actual_date).to eq(@check_out_date),
            "离店日期错误。期望: #{@check_out_date}, 实际: #{actual_date}"
        end
      end

      add_assertion "包含情人节浪漫特色内容", weight: 20 do
        @package_orders.each do |order|
          package_name = order.hotel_package.name
          highlights = order.hotel_package.highlights || ""
          expect(package_name.include?("情人节") || highlights.include?("烛光") || highlights.include?("玫瑰")).to be true,
            "缺少情人节浪漫特色内容"
        end
      end
    end

    def execution_state_data
      {
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s,
        hotel_name: @hotel_name,
        hotel_id: @hotel&.id,
        package_id: @package&.id
      }
    end

    def restore_from_state(state)
      @check_in_date = Date.parse(state['check_in_date']) if state['check_in_date']
      @check_out_date = Date.parse(state['check_out_date']) if state['check_out_date']
      @hotel_name = state['hotel_name']
      @hotel = Hotel.find_by(id: state['hotel_id']) if state['hotel_id']
      @package = HotelPackage.find_by(id: state['package_id']) if state['package_id']
    end
  end
end
