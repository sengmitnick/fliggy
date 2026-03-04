# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例92: 给张三、李四预订苏州园林讲解（2成人，选择粉丝数最多的导游，10天后）
#
# 任务描述:
#   用户想在10天后预订苏州园林的深度讲解，为2位成人（张三、李四）。
#   Agent 需要在符合条件的苏州园林导游中，选择follower_count（粉丝数）最多的导游。
#
# 业务流程（5个关键步骤）：
#   1. 搜索苏州园林相关的深度游产品
#   2. 筛选venue为"苏州园林"的导游
#   3. 对比多个导游的follower_count（粉丝数）
#   4. 选择follower_count最多的导游（如粉丝数相同则按rating降序排序）
#   5. 预订该导游的华东地区产品
#
# 复杂度分析（5个关键点）：
#   1. 需要理解景点筛选：venue="苏州园林"
#   2. 需要理解"粉丝数最多"条件：对比多个导游的follower_count字段
#   3. 需要选择follower_count最大值的导游
#   4. 需要处理粉丝数相同的情况：按rating降序排序
#   5. 需要填写2位成人的出行信息，联系人从出行人中选择
#   ❌ 不能随机选择：必须精确对比follower_count并选择最多的
#
# 评分标准（6项，总计100分）：
#   - 订单已创建（20分）
#   - 向导景点正确（苏州园林）（15分）
#   - 产品地点正确（华东）（15分）
#   - 选择了粉丝数最多的导游（30分）
#   - 人数信息正确（2成人）（10分）
#   - 联系人信息正确（从出行人中选择：张三或李四）（10分）
module V051V100
  class V092BookSuzhouGardenTourValidator < BaseValidator
    self.validator_id = 'v092_book_suzhou_garden_tour_validator'
    self.task_id = 'aca21330-8a40-44bc-873b-4f93472a424d'
    self.title = '给张三、李四预订苏州园林讲解（2成人，选择粉丝数最多的导游，10天后）'
    self.description = '预订苏州园林讲解（2成人，选择粉丝数最多的导游，10天后）'
    self.timeout_seconds = 240
  
    def prepare
      @venue = '苏州园林'
      @location = '华东'
      @travel_date = Date.current + 10.days
      @adult_count = 2
    
      # 预查询联系人信息（使用demo_user数据）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan_contact = user.contacts.find_by!(name: '张三', data_version: 0)
      @lisi_contact = user.contacts.find_by!(name: '李四', data_version: 0)

      # 联系人可以是张三或李四（多选一）
      @valid_contact_names = ['张三', '李四']
      @valid_contact_phones = {
        '张三' => @zhangsan_contact.phone,
        '李四' => @lisi_contact.phone
      }
    
      @qualified_guides = DeepTravelGuide.where(data_version: 0, venue: @venue)
    
      {
        task: "请预订10天后（#{@travel_date.strftime('%Y年%m月%d日')}）苏州园林的深度讲解，为#{@adult_count}位成人，选择粉丝数最多的导游",
        venue: @venue,
        location: @location,
        travel_date: @travel_date.strftime('%Y-%m-%d'),
        adult_count: @adult_count,
        hint: "筛选苏州园林讲解员，选择粉丝数最多的导游",
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
    
      add_assertion "向导景点正确（苏州园林）", weight: 15 do
        guide = @booking.deep_travel_guide
        expect(guide.venue).to eq(@venue),
          "向导景点不符合要求。期望: #{@venue}, 实际: #{guide.venue}"
      end
    
      add_assertion "产品地点正确（华东）", weight: 15 do
        product = @booking.deep_travel_product
        expect(product.location).to eq(@location),
          "产品地点不符合要求。期望: #{@location}, 实际: #{product.location}"
      end
    
      add_assertion "选择了粉丝数最多的导游", weight: 30 do
        most_followed = DeepTravelGuide.where(data_version: 0, venue: @venue)
                                       .order(follower_count: :desc, rating: :desc).first
        expect(@booking.deep_travel_guide_id).to eq(most_followed.id),
          "未选择粉丝数最多的导游。应选: #{most_followed.name}（粉丝#{most_followed.follower_count}人），实际: #{@booking.deep_travel_guide.name}（粉丝#{@booking.deep_travel_guide.follower_count}人）"
      end
    
      add_assertion "人数信息正确（2成人）", weight: 10 do
        expect(@booking.adult_count).to eq(@adult_count),
          "成人数不符合。期望: #{@adult_count}, 实际: #{@booking.adult_count}"
      end

      add_assertion "联系人信息正确（从出行人中选择：张三或李四）", weight: 10 do
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
                                    .order(follower_count: :desc, rating: :desc).first
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