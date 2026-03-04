# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例89: 给张三预订北京故宫文化深度游（高评分文化讲解，选择服务客户数最多的向导，5天后）
#
# 任务描述:
#   用户想在5天后预订北京故宫的文化深度游，要求向导评分≥4.9分且是文化讲解类型。
#   Agent 需要在符合条件的向导中，选择服务客户数最多（served_count最大）的向导。
#
# 业务流程（5个关键步骤）：
#   1. 搜索北京故宫相关的深度游产品
#   2. 筛选评分≥4.9分的向导
#   3. 筛选文化讲解类型的向导
#   4. 在符合条件的向导中，对比served_count（已服务客户数）
#   5. 选择served_count最多的向导进行预订
#
# 复杂度分析（5个关键点）：
#   1. 需要理解"高评分"条件：评分≥4.9分
#   2. 需要理解"文化讲解"：向导title需包含"文化讲解"
#   3. 需要对比多个向导的served_count字段
#   4. 需要选择served_count最大值的向导
#   5. 需要预订该向导的故宫产品
#   ❌ 不能随机选择：必须精确对比served_count并选择最多的
#
# 评分标准（6项，总计100分）：
#   - 订单已创建（20分）
#   - 向导评分符合要求（≥4.9分）（15分）
#   - 向导类型正确（文化讲解）（15分）
#   - 产品地点正确（北京）（15分）
#   - 选择了服务客户数最多的向导（25分）
#   - 联系人信息正确（张三）（10分）
module V051V100
  class V089BookBeijingForbiddenCityCultureTourValidator < BaseValidator
    self.validator_id = 'v089_book_beijing_forbidden_city_culture_tour_validator'
    self.task_id = 'a5f889d8-3913-4451-97a9-3fce8e3e463b'
    self.title = '给张三预订北京故宫文化深度游（高评分文化讲解，选择服务客户数最多的向导，5天后）'
    self.description = '预订北京故宫文化深度游（高评分文化讲解，选择服务客户数最多的向导，5天后）'
    self.timeout_seconds = 240
  
    def prepare
      # Demo user data
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @zhangsan.name
      @expected_contact_phone = @zhangsan.phone
      
      @min_rating = 4.9
      @title_keyword = '文化讲解'
      @location = '北京'
      @product_keyword = '故宫'
      @travel_date = Date.current + 5.days
      @adult_count = 1
    
      @qualified_guides = DeepTravelGuide.where(data_version: 0)
                                         .where('rating >= ?', @min_rating)
                                         .where('title LIKE ?', "%#{@title_keyword}%")
    
      {
        task: "请预订5天后（#{@travel_date.strftime('%Y年%m月%d日')}）#{@location}故宫的文化深度游，要求评分≥#{@min_rating}分的历史学者讲解，为#{@adult_count}位成人，选择服务客户数最多的向导",
        location: @location,
        product_keyword: @product_keyword,
        min_rating: @min_rating,
        title_keyword: @title_keyword,
        travel_date: @travel_date.strftime('%Y-%m-%d'),
        adult_count: @adult_count,
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
    
      add_assertion "向导评分符合要求（≥4.9分）", weight: 15 do
        guide = @booking.deep_travel_guide
        expect(guide.rating.to_f >= @min_rating).to be_truthy,
          "向导评分不符合要求。期望: ≥#{@min_rating}分, 实际: #{guide.rating}分"
      end
    
      add_assertion "向导类型正确（文化讲解）", weight: 15 do
        guide = @booking.deep_travel_guide
        expect(guide.title).to include(@title_keyword),
          "向导类型不符合要求。期望包含: #{@title_keyword}, 实际: #{guide.title}"
      end
    
      add_assertion "产品地点正确（北京）", weight: 15 do
        product = @booking.deep_travel_product
        expect(product.location).to eq(@location),
          "产品地点不符合要求。期望: #{@location}, 实际: #{product.location}"
      end
    
      add_assertion "选择了服务最多的向导", weight: 25 do
        qualified_guides = DeepTravelGuide.where(data_version: 0)
                                          .where('rating >= ?', @min_rating)
                                          .where('title LIKE ?', "%#{@title_keyword}%")
        best_guide = qualified_guides.order(served_count: :desc).first
        expect(@booking.deep_travel_guide_id).to eq(best_guide.id),
          "未选择服务最多的向导。应选: #{best_guide.name}（已服务#{best_guide.served_count}人），实际: #{@booking.deep_travel_guide.name}（已服务#{@booking.deep_travel_guide.served_count}人）"
      end
      
      add_assertion "联系人信息正确（张三）", weight: 10 do
        expect(@booking.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}，实际: #{@booking.contact_name}"
        expect(@booking.contact_phone).to eq(@expected_contact_phone),
          "联系人电话错误。期望: #{@expected_contact_phone}，实际: #{@booking.contact_phone}"
      end
    end
  
    def execution_state_data
      { min_rating: @min_rating, title_keyword: @title_keyword, location: @location, product_keyword: @product_keyword,
        travel_date: @travel_date.to_s, adult_count: @adult_count, expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone }
    end
  
    def restore_from_state(data)
      @min_rating = data['min_rating']
      @title_keyword = data['title_keyword']
      @location = data['location']
      @product_keyword = data['product_keyword']
      @travel_date = Date.parse(data['travel_date'])
      @adult_count = data['adult_count']
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
      @qualified_guides = DeepTravelGuide.where(data_version: 0)
                                         .where('rating >= ?', @min_rating)
                                         .where('title LIKE ?', "%#{@title_keyword}%")
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      target_guide = DeepTravelGuide.where(data_version: 0)
                                    .where('rating >= ?', @min_rating)
                                    .where('title LIKE ?', "%#{@title_keyword}%")
                                    .order(served_count: :desc).first
      raise "未找到符合条件的向导" unless target_guide
    
      target_product = target_guide.deep_travel_products.where(data_version: 0)
                                   .where('location = ? AND title LIKE ?', @location, "%#{@product_keyword}%")
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
        contact_name: @expected_contact_name,
        contact_phone: @expected_contact_phone,
        total_price: total_price,
        insurance_price: 0,
        status: 'pending',
        data_version: @data_version
      )
    end
    end
end