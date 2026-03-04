# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例91: 给张三、王芳、小明预订西安秦始皇帝陵博物院讲解（2大1小，选择服务人数最多的导游，7天后）
#
# 任务描述:
#   用户想在7天后预订西安秦始皇帝陵博物院（兵马俑）的深度讲解，家庭出行2大1小。
#   Agent 需要在符合条件的兵马俑导游中，选择served_count（已服务客户数）最多的导游。
#
# 业务流程（6个关键步骤）：
#   1. 搜索西安秦始皇帝陵博物院相关的深度游产品
#   2. 筛选venue为"秦始皇帝陵博物院"的导游
#   3. 对比多个导游的served_count（已服务客户数）
#   4. 选择served_count最多的导游（如人数相同则按rating降序排序）
#   5. 预订该导游的陕西地区产品
#   6. 填写家庭出行信息（2大1小，联系人从家长中选择）
#
# 复杂度分析（6个关键点）：
#   1. 需要理解景点筛选：venue="秦始皇帝陵博物院"
#   2. 需要理解"服务人数最多"条件：对比多个导游的served_count字段
#   3. 需要选择served_count最大值的导游
#   4. 需要处理服务人数相同的情况：按rating降序排序
#   5. 需要理解家庭出行：2成人 + 1儿童
#   6. 需要从家长中选择联系人（张三或王芳）
#   ❌ 不能随机选择：必须精确对比served_count并选择最多的
#
# 评分标准（6项，总计100分）：
#   - 订单已创建（15分）
#   - 向导景点正确（秦始皇帝陵博物院）（15分）
#   - 产品地点正确（陕西）（15分）
#   - 选择了服务人数最多的导游（25分）
#   - 人数信息正确（2大1小）（20分）
#   - 联系人信息正确（从家长中选择：张三或王芳）（10分）
module V051V100
  class V091BookXianTerracottaWarriorsTourValidator < BaseValidator
    self.validator_id = 'v091_book_xian_terracotta_warriors_tour_validator'
    self.task_id = '5bc15e2f-a604-469a-99a1-ccce0e9eabed'
    self.title = '给张三、王芳、小明预订西安秦始皇帝陵博物院讲解（2大1小，选择服务人数最多的导游，7天后）'
    self.description = '预订西安秦始皇帝陵博物院讲解（2大1小，选择服务人数最多的导游，7天后）'
    self.timeout_seconds = 240

    def prepare
      @venue = '秦始皇帝陵博物院'
      @location = '陕西'
      @travel_date = Date.current + 7.days
      @adult_count = 2
      @child_count = 1

      # 预查询联系人信息（使用demo_user数据）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan_contact = user.contacts.find_by!(name: '张三', data_version: 0)
      @wangfang_contact = user.contacts.find_by!(name: '王芳', data_version: 0)

      # 联系人可以是张三或王芳（多选一）
      @valid_contact_names = ['张三', '王芳']
      @valid_contact_phones = {
        '张三' => @zhangsan_contact.phone,
        '王芳' => @wangfang_contact.phone
      }

      @qualified_guides = DeepTravelGuide.where(data_version: 0, venue: @venue)

      {
        task: "请预订下周末（#{@travel_date.strftime('%Y年%m月%d日')}）西安秦始皇帝陵博物院（兵马俑）的深度讲解，家庭出行#{@adult_count}大#{@child_count}小，选择服务人数最多的金牌导游",
        venue: @venue,
        location: @location,
        travel_date: @travel_date.strftime('%Y-%m-%d'),
        adult_count: @adult_count,
        child_count: @child_count,
        hint: "筛选秦始皇帝陵博物院讲解员，选择服务人数最多的导游",
        qualified_guides_count: @qualified_guides.count
      }
    end

    def verify
      add_assertion "订单已创建", weight: 15 do
        @booking = DeepTravelBooking.where(data_version: @data_version).order(created_at: :desc).first
        expect(@booking).not_to be_nil, "未找到任何深度旅行预订记录"
      end

      return unless @booking

      add_assertion "向导景点正确（秦始皇帝陵博物院）", weight: 15 do
        guide = @booking.deep_travel_guide
        expect(guide.venue).to eq(@venue),
          "向导景点不符合要求。期望: #{@venue}, 实际: #{guide.venue}"
      end

      add_assertion "产品地点正确（陕西）", weight: 15 do
        product = @booking.deep_travel_product
        expect(product.location).to eq(@location),
          "产品地点不符合要求。期望: #{@location}, 实际: #{product.location}"
      end

      add_assertion "选择了服务人数最多的导游", weight: 25 do
        most_served = DeepTravelGuide.where(data_version: 0, venue: @venue)
                                     .order(served_count: :desc, rating: :desc).first
        expect(@booking.deep_travel_guide_id).to eq(most_served.id),
          "未选择服务人数最多的导游。应选: #{most_served.name}（已服务#{most_served.served_count}人），实际: #{@booking.deep_travel_guide.name}（已服务#{@booking.deep_travel_guide.served_count}人）"
      end

      add_assertion "人数信息正确（2大1小）", weight: 20 do
        expect(@booking.adult_count).to eq(@adult_count),
          "成人数量错误。期望: #{@adult_count}, 实际: #{@booking.adult_count}"
        expect(@booking.child_count).to eq(@child_count),
          "儿童数量错误。期望: #{@child_count}, 实际: #{@booking.child_count}"
      end

      add_assertion "联系人信息正确（从家长中选择：张三或王芳）", weight: 10 do
        expect(@valid_contact_phones.values).to include(@booking.contact_phone),
          "联系人电话错误。应从家长中选择：#{@valid_contact_names.join('、')}，" \
          "对应电话：#{@valid_contact_phones.values.join('、')}，实际: #{@booking.contact_phone}"
      end
    end

    def execution_state_data
      { venue: @venue, location: @location,
        travel_date: @travel_date.to_s, adult_count: @adult_count, child_count: @child_count,
        valid_contact_names: @valid_contact_names, valid_contact_phones: @valid_contact_phones }
    end

    def restore_from_state(data)
      @venue = data['venue']
      @location = data['location']
      @travel_date = Date.parse(data['travel_date'])
      @adult_count = data['adult_count']
      @child_count = data['child_count']
      @valid_contact_names = data['valid_contact_names']
      @valid_contact_phones = data['valid_contact_phones']
      @qualified_guides = DeepTravelGuide.where(data_version: 0, venue: @venue)
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)

      target_guide = DeepTravelGuide.where(data_version: 0, venue: @venue)
                                    .order(served_count: :desc, rating: :desc).first
      raise "未找到符合条件的向导" unless target_guide

      target_product = target_guide.deep_travel_products.where(data_version: 0, location: @location)
                                   .order(sales_count: :desc).first
      raise "未找到符合条件的产品" unless target_product

      total_price = target_product.price * (@adult_count + @child_count * 0.8)

      DeepTravelBooking.create!(
        user_id: user.id,
        deep_travel_guide_id: target_guide.id,
        deep_travel_product_id: target_product.id,
        travel_date: @travel_date,
        adult_count: @adult_count,
        child_count: @child_count,
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