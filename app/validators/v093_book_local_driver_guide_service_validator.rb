# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例93: 预订本地司导服务（经验年限≥10年）
class V093BookLocalDriverGuideServiceValidator < BaseValidator
  self.validator_id = 'v093_book_local_driver_guide_service_validator'
  self.task_id = '5da3a869-cfbc-4ea3-bd95-c84f378ae696'
  self.title = '预订本地司导服务（经验≥10年，价格最低）'
  self.description = '预订明天的本地司导服务，要求经验≥10年，选择价格最低的产品'
  self.timeout_seconds = 240
  
  def prepare
    @title_keyword = '司导'
    @min_experience_years = 10
    @travel_date = Date.current + 1.days
    @adult_count = 3
    
    @qualified_guides = DeepTravelGuide.where(data_version: 0)
                                       .where('title LIKE ?', "%#{@title_keyword}%")
                                       .where('experience_years >= ?', @min_experience_years)
    
    {
      task: "请预订明天（#{@travel_date.strftime('%Y年%m月%d日')}）的本地司导服务，要求经验≥#{@min_experience_years}年，为#{@adult_count}位成人，选择价格最低的产品",
      title_keyword: @title_keyword,
      min_experience_years: @min_experience_years,
      travel_date: @travel_date.strftime('%Y-%m-%d'),
      adult_count: @adult_count,
      hint: "筛选司导类向导且经验≥10年，选择价格最低的产品",
      qualified_guides_count: @qualified_guides.count
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 20 do
      @booking = DeepTravelBooking.order(created_at: :desc).first
      expect(@booking).not_to be_nil, "未找到任何深度旅行预订记录"
    end
    
    return unless @booking
    
    add_assertion "向导类型正确（司导）", weight: 20 do
      guide = @booking.deep_travel_guide
      expect(guide.title).to include(@title_keyword),
        "向导类型不符合要求。期望包含: #{@title_keyword}, 实际: #{guide.title}"
    end
    
    add_assertion "经验年限符合要求（≥10年）", weight: 30 do
      guide = @booking.deep_travel_guide
      expect(guide.experience_years >= @min_experience_years).to be_truthy,
        "经验年限不符合要求。期望: ≥#{@min_experience_years}年, 实际: #{guide.experience_years}年"
    end
    
    add_assertion "选择了符合条件中价格最低的产品", weight: 30 do
      qualified_guides = DeepTravelGuide.where(data_version: 0)
                                        .where('title LIKE ?', "%#{@title_keyword}%")
                                        .where('experience_years >= ?', @min_experience_years)
      all_products = DeepTravelProduct.where(data_version: 0, deep_travel_guide_id: qualified_guides.pluck(:id))
      cheapest = all_products.order(price: :asc).first
      expect(@booking.deep_travel_product_id).to eq(cheapest.id),
        "未选择价格最低的产品。应选: #{cheapest.title}（#{cheapest.price}元），实际: #{@booking.deep_travel_product.title}（#{@booking.deep_travel_product.price}元）"
    end
  end
  
  def execution_state_data
    { title_keyword: @title_keyword, min_experience_years: @min_experience_years,
      travel_date: @travel_date.to_s, adult_count: @adult_count }
  end
  
  def restore_from_state(data)
    @title_keyword = data['title_keyword']
    @min_experience_years = data['min_experience_years']
    @travel_date = Date.parse(data['travel_date'])
    @adult_count = data['adult_count']
    @qualified_guides = DeepTravelGuide.where(data_version: 0)
                                       .where('title LIKE ?', "%#{@title_keyword}%")
                                       .where('experience_years >= ?', @min_experience_years)
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    qualified_guides = DeepTravelGuide.where(data_version: 0)
                                      .where('title LIKE ?', "%#{@title_keyword}%")
                                      .where('experience_years >= ?', @min_experience_years)
    raise "未找到符合条件的向导" if qualified_guides.empty?
    
    all_products = DeepTravelProduct.where(data_version: 0, deep_travel_guide_id: qualified_guides.pluck(:id))
    target_product = all_products.order(price: :asc).first
    raise "未找到符合条件的产品" unless target_product
    
    total_price = target_product.price * @adult_count
    
    DeepTravelBooking.create!(
      user_id: user.id,
      deep_travel_guide_id: target_product.deep_travel_guide_id,
      deep_travel_product_id: target_product.id,
      travel_date: @travel_date,
      adult_count: @adult_count,
      child_count: 0,
      contact_name: '孙七',
      contact_phone: '13800138005',
      total_price: total_price,
      insurance_price: 0,
      status: 'pending'
    )
  end
end