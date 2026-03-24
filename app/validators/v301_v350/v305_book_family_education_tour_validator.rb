# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例305: 预订北京跟团游（刘强、陈静、小明，12天后出发，≥2天，2大1小）
#
# 任务描述:
#   刘强、陈静带着小明预订北京的跟团游。
#   要求：12天后出发，行程≥2天，2大1小家庭套票。
#   Agent 需要预订跟团游产品，联系人使用刘强、陈静或小明的信息。
#
# 业务流程（5个关键步骤）：
#   1. 搜索北京的跟团游产品
#   2. 确定出行日期（12天后）
#   3. 选择行程时长≥2天的产品
#   4. 填写预订信息（2位成人，1位儿童）
#   5. 填写联系人信息（刘强、陈静或小明的姓名和电话）
#
# 复杂度分析（4个关键点）：
#   1. 需要计算正确的出行日期（12天后）
#   2. 需要选择demo用户的家庭成员（刘强、陈静、小明）作为联系人
#   3. 需要正确填写人数组合（2大1小）
#   4. 需要确保行程时长≥2天
#
# 评分标准（6项，总计100分）：
#   - 创建了跟团游预订 (25%)
#   - 目的地正确（北京） (15%)
#   - 预订2大1小组合 (20%)
#   - 出行日期正确（12天后） (15%)
#   - 联系人信息正确（刘强、陈静或小明） (15%)
#   - 行程时长≥2天 (10%)
module V301V350
  class V305BookFamilyEducationTourValidator < BaseValidator
    self.validator_id = 'v305_book_family_education_tour_validator'
    self.task_id = '5134922f-5d41-431e-b1f0-36ea208edf7f'
    self.title = '预订北京跟团游（刘强、陈静、小明，12天后出发，≥2天，2大1小）'
    self.description = '预订北京跟团游，刘强、陈静带小明一家三口，12天后出发，行程至少2天，2大1小家庭套票'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Pre-query existing passengers from demo_user (family: 刘强+陈静+小明)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
      @xiaoming = user.passengers.find_by!(name: '小明', data_version: 0)
      
      # Expected contact info (multi-choice: 刘强、陈静 or 小明)
      @expected_contact_names = [@liuqiang.name, @chenjing.name, @xiaoming.name]
      @expected_contact_phones = {
        @liuqiang.name => @liuqiang.phone,
        @chenjing.name => @chenjing.phone,
        @xiaoming.name => @xiaoming.phone
      }
      
      @destination = '北京'
      @travel_date = Date.current + 12.days
      
      if user.balance < 6000
        user.update!(balance: 9000)
      end
      
      {
        task: "请预订#{@destination}的跟团游，#{@travel_date.strftime('%Y年%-m月%-d日')}出发，适合2大1小家庭出游，行程至少2天",
        destination: @destination,
        travel_date: @travel_date.to_s,
        hint: "选择适合家庭的旅游产品，预订2大1小家庭套票，联系人使用demo_user的家庭成员（刘强、陈静或小明）"
      }
    end
    
    def verify
      add_assertion "创建了跟团游预订", weight: 25 do
        @tour_booking = TourGroupBooking
          .joins(:tour_group_product)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@tour_booking).not_to be_nil, "未找到跟团游预订"
      end
      
      return unless @tour_booking
      
      add_assertion "目的地正确（#{@destination}）", weight: 15 do
        expect(@tour_booking.tour_group_product.destination).to eq(@destination),
          "目的地错误。期望: #{@destination}，实际: #{@tour_booking.tour_group_product.destination}"
      end
      
      add_assertion "预订2大1小组合", weight: 20 do
        expect(@tour_booking.adult_count).to eq(2),
          "成人数量错误。期望: 2大人，实际: #{@tour_booking.adult_count}大人"
        expect(@tour_booking.child_count).to eq(1),
          "儿童数量错误。期望: 1儿童，实际: #{@tour_booking.child_count}儿童"
      end
      
      add_assertion "出行日期正确", weight: 15 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}（12天后），实际: #{@tour_booking.travel_date}"
      end
      
      add_assertion "联系人信息正确（刘强、陈静或小明）", weight: 15 do
        expect(@expected_contact_names).to include(@tour_booking.contact_name),
          "联系人姓名错误。期望: #{@expected_contact_names.join('或')}，实际: #{@tour_booking.contact_name}"
        expected_phone = @expected_contact_phones[@tour_booking.contact_name]
        if expected_phone
          expect(@tour_booking.contact_phone).to eq(expected_phone),
            "联系电话错误。期望: #{expected_phone}，实际: #{@tour_booking.contact_phone}"
        end
      end
      
      add_assertion "行程时长≥2天", weight: 10 do
        tour = @tour_booking.tour_group_product
        expect(tour.duration).to be >= 2,
          "行程天数不足。期望≥2天，实际: #{tour.duration}天"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择跟团游(至少2天)
      tour_product = TourGroupProduct
        .where(destination: @destination, data_version: 0)
        .where("duration >= ?", 2)
        .order(rating: :desc)
        .first!
      
      tour_package = tour_product.tour_packages.first!
      
      # Randomly select one family member as contact
      contact_person = [@liuqiang, @chenjing, @xiaoming].sample
      
      # Use existing family passengers from demo_user (no NEW creation)
      TourGroupBooking.create!(
        user_id: user.id,
        tour_group_product_id: tour_product.id,
        tour_package_id: tour_package.id,
        travel_date: @travel_date,
        adult_count: 2,
        child_count: 1,
        contact_name: contact_person.name,
        contact_phone: contact_person.phone,
        total_price: tour_package.price * 2 + (tour_package.child_price || tour_package.price * 0.5),  # 2大1小价格
        status: 'pending',
        insurance_type: 'standard',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        destination: @destination,
        travel_date: @travel_date&.to_s,
        expected_contact_names: @expected_contact_names,
        expected_contact_phones: @expected_contact_phones
      }
    end
    
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @expected_contact_names = data['expected_contact_names']
      @expected_contact_phones = data['expected_contact_phones']
    end
  end
end
