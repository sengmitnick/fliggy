# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例93: 预订武汉黄鹤楼讲解（经验最丰富的导游）
module V051V100
  class V093BookWuhanYellowCraneTowerTourValidator < BaseValidator
    self.validator_id = 'v093_book_wuhan_yellow_crane_tower_tour_validator'
    self.task_id = '5da3a869-cfbc-4ea3-bd95-c84f378ae696'
    self.title = '给张三等3人预订武汉黄鹤楼讲解（经验最丰富的导游）'
    self.description = '给张三、李四、王芳预订后天的武汉黄鹤楼讲解（3位成人），选择经验年限最长的导游'
    self.timeout_seconds = 240
  
    def prepare
      @venue = '武汉黄鹤楼'
      @location = '华中'
      @travel_date = Date.current + 2.days
      @adult_count = 3
    
      # 预查询联系人信息（使用demo_user数据）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan_contact = user.contacts.find_by!(name: '张三', data_version: 0)
      @lisi_contact = user.contacts.find_by!(name: '李四', data_version: 0)
      @wangfang_contact = user.contacts.find_by!(name: '王芳', data_version: 0)

      # 联系人可以是张三、李四或王芳（多选一）
      @valid_contact_names = ['张三', '李四', '王芳']
      @valid_contact_phones = {
        '张三' => @zhangsan_contact.phone,
        '李四' => @lisi_contact.phone,
        '王芳' => @wangfang_contact.phone
      }
    
      @qualified_guides = DeepTravelGuide.where(data_version: 0, venue: @venue)
    
      {
        task: "请预订后天（#{@travel_date.strftime('%Y年%m月%d日')}）武汉黄鹤楼的深度讲解，为#{@adult_count}位成人，选择经验年限最长的导游",
        venue: @venue,
        location: @location,
        travel_date: @travel_date.strftime('%Y-%m-%d'),
        adult_count: @adult_count,
        hint: "筛选黄鹤楼讲解员，选择经验最丰富的导游",
        qualified_guides_count: @qualified_guides.count
      }
    end
  
    def verify
      add_assertion "订单已创建", weight: 20 do
        all_deep_travel_bookings = DeepTravelBooking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        expect(all_deep_travel_bookings).not_to be_empty, "未找到任何DeepTravelBooking记录"
        @booking = all_deep_travel_bookings.first
        # Replaced by expect(all_deep_travel_bookings).not_to be_empty above, "未找到任何深度旅行预订记录"
      end
    
      return unless @booking
    
      add_assertion "向导景点正确（武汉黄鹤楼）", weight: 15 do
        guide = @booking.deep_travel_guide
        expect(guide.venue).to eq(@venue),
          "向导景点不符合要求。期望: #{@venue}, 实际: #{guide.venue}"
      end
    
      add_assertion "产品地点正确（华中）", weight: 15 do
        product = @booking.deep_travel_product
        expect(product.location).to eq(@location),
          "产品地点不符合要求。期望: #{@location}, 实际: #{product.location}"
      end
    
      add_assertion "选择了经验年限最长的导游", weight: 30 do
        most_experienced = DeepTravelGuide.where(data_version: 0, venue: @venue)
                                          .order(experience_years: :desc, rating: :desc).first
        expect(@booking.deep_travel_guide_id).to eq(most_experienced.id),
          "未选择经验最丰富的导游。应选: #{most_experienced.name}（经验#{most_experienced.experience_years}年），实际: #{@booking.deep_travel_guide.name}（经验#{@booking.deep_travel_guide.experience_years}年）"
      end
    
      add_assertion "人数信息正确（3成人）", weight: 10 do
        expect(@booking.adult_count).to eq(@adult_count),
          "成人数不符合。期望: #{@adult_count}, 实际: #{@booking.adult_count}"
      end

      add_assertion "联系人信息正确（从出行人中选择：张三、李四或王芳）", weight: 10 do
        expect(@valid_contact_phones.values).to include(@booking.contact_phone),
          "联系人电话错误。应从出行人中选择：#{@valid_contact_names.join('、')}，" \
          "对应电话：#{@valid_contact_phones.values.join('、')}，实际: #{@booking.contact_phone}"
      end
    end
  
    def execution_state_data
      { venue: @venue, location: @location,
        travel_date: @travel_date.to_s, adult_count: @adult_count,
        valid_contact_names: @valid_contact_names, valid_contact_phones: @valid_contact_phones }
    end
  
    def restore_from_state(data)
      @venue = data['venue']
      @location = data['location']
      @travel_date = Date.parse(data['travel_date'])
      @adult_count = data['adult_count']
      @valid_contact_names = data['valid_contact_names']
      @valid_contact_phones = data['valid_contact_phones']
      @qualified_guides = DeepTravelGuide.where(data_version: 0, venue: @venue)
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
    
      target_guide = DeepTravelGuide.where(data_version: 0, venue: @venue)
                                    .order(experience_years: :desc, rating: :desc).first
      raise "未找到符合条件的向导" unless target_guide
    
      target_product = target_guide.deep_travel_products.where(data_version: 0, location: @location)
                                   .order(sales_count: :desc).first
      raise "未找到符合条件的产品" unless target_product
    
      total_price = target_product.price * @adult_count
    
      DeepTravelBooking.create!(
        user_id: user.id,
        deep_travel_guide_id: target_guide.id,
        deep_travel_product_id: target_product.id,
        travel_date: @travel_date,
        adult_count: @adult_count,
        child_count: 0,
        contact_name: zhangsan.name,
        contact_phone: zhangsan.phone,
        total_price: total_price,
        insurance_price: 0,
        status: 'pending',
        data_version: @data_version
      )
    end
    end
end
