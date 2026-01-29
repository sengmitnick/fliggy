# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例90: 预订三亚潜水体验（PADI认证教练，最低价格）
class V090BookSanyaDivingExperienceValidator < BaseValidator
  self.validator_id = 'v090_book_sanya_diving_experience_validator'
  self.title = '预订三亚潜水体验（PADI认证教练，选择最低价格产品）'
  self.description = '预订3天后的三亚潜水体验，要求PADI认证潜水教练，选择该教练最便宜的产品'
  self.timeout_seconds = 240
  
  def prepare
    @title_keyword = '潜水教学'
    @location = '三亚'
    @travel_date = Date.current + 3.days
    @adult_count = 1
    
    @qualified_guides = DeepTravelGuide.where(data_version: 0)
                                       .where('title LIKE ?', "%#{@title_keyword}%")
    
    {
      task: "请预订3天后（#{@travel_date.strftime('%Y年%m月%d日')}）#{@location}的潜水体验，要求PADI认证潜水教练，为#{@adult_count}位成人，选择该教练价格最便宜的产品",
      location: @location,
      title_keyword: @title_keyword,
      travel_date: @travel_date.strftime('%Y-%m-%d'),
      adult_count: @adult_count,
      hint: "筛选潜水教学类向导，选择三亚地区最便宜的产品",
      qualified_guides_count: @qualified_guides.count
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 20 do
      @booking = DeepTravelBooking.order(created_at: :desc).first
      expect(@booking).not_to be_nil, "未找到任何深度旅行预订记录"
    end
    
    return unless @booking
    
    add_assertion "向导类型正确（潜水教学）", weight: 25 do
      guide = @booking.deep_travel_guide
      expect(guide.title).to include(@title_keyword),
        "向导类型不符合要求。期望包含: #{@title_keyword}, 实际: #{guide.title}"
    end
    
    add_assertion "产品地点正确（三亚）", weight: 25 do
      product = @booking.deep_travel_product
      expect(product.location).to eq(@location),
        "产品地点不符合要求。期望: #{@location}, 实际: #{product.location}"
    end
    
    add_assertion "选择了该教练最便宜的三亚产品", weight: 30 do
      guide = @booking.deep_travel_guide
      cheapest_product = guide.deep_travel_products.where(data_version: 0, location: @location)
                              .order(price: :asc).first
      expect(@booking.deep_travel_product_id).to eq(cheapest_product.id),
        "未选择该教练最便宜的三亚产品。应选: #{cheapest_product.title}（#{cheapest_product.price}元），实际: #{@booking.deep_travel_product.title}（#{@booking.deep_travel_product.price}元）"
    end
  end
  
  def execution_state_data
    { title_keyword: @title_keyword, location: @location, travel_date: @travel_date.to_s, adult_count: @adult_count }
  end
  
  def restore_from_state(data)
    @title_keyword = data['title_keyword']
    @location = data['location']
    @travel_date = Date.parse(data['travel_date'])
    @adult_count = data['adult_count']
    @qualified_guides = DeepTravelGuide.where(data_version: 0).where('title LIKE ?', "%#{@title_keyword}%")
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    target_guide = DeepTravelGuide.where(data_version: 0)
                                  .where('title LIKE ?', "%#{@title_keyword}%")
                                  .first
    raise "未找到符合条件的向导" unless target_guide
    
    target_product = target_guide.deep_travel_products.where(data_version: 0, location: @location)
                                 .order(price: :asc).first
    raise "未找到符合条件的产品" unless target_product
    
    total_price = target_product.price * @adult_count
    
    DeepTravelBooking.create!(
      user_id: user.id,
      deep_travel_guide_id: target_guide.id,
      deep_travel_product_id: target_product.id,
      travel_date: @travel_date,
      adult_count: @adult_count,
      child_count: 0,
      contact_name: '李四',
      contact_phone: '13800138002',
      total_price: total_price,
      insurance_price: 0,
      status: 'pending'
    )
  end
end
