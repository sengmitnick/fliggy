# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例89: 预订北京故宫文化深度游（高评分文化讲解）
class V089BookBeijingForbiddenCityCultureTourValidator < BaseValidator
  self.validator_id = 'v089_book_beijing_forbidden_city_culture_tour_validator'
  self.title = '预订北京故宫文化深度游（历史学者讲解，评分≥4.9）'
  self.description = '预订5天后的故宫文化深度游，要求评分≥4.9分的历史学者讲解，选择服务最多的向导'
  self.timeout_seconds = 240
  
  def prepare
    @min_rating = 4.9
    @title_keyword = '文化讲解'
    @location = '北京'
    @product_keyword = '故宫'
    @travel_date = Date.current + 5.days
    @adult_count = 2
    
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
      @booking = DeepTravelBooking.order(created_at: :desc).first
      expect(@booking).not_to be_nil, "未找到任何深度旅行预订记录"
    end
    
    return unless @booking
    
    add_assertion "向导评分符合要求（≥4.9分）", weight: 25 do
      guide = @booking.deep_travel_guide
      expect(guide.rating.to_f >= @min_rating).to be_truthy,
        "向导评分不符合要求。期望: ≥#{@min_rating}分, 实际: #{guide.rating}分"
    end
    
    add_assertion "向导类型正确（文化讲解）", weight: 20 do
      guide = @booking.deep_travel_guide
      expect(guide.title).to include(@title_keyword),
        "向导类型不符合要求。期望包含: #{@title_keyword}, 实际: #{guide.title}"
    end
    
    add_assertion "产品地点正确（北京）", weight: 15 do
      product = @booking.deep_travel_product
      expect(product.location).to eq(@location),
        "产品地点不符合要求。期望: #{@location}, 实际: #{product.location}"
    end
    
    add_assertion "选择了服务最多的向导", weight: 20 do
      qualified_guides = DeepTravelGuide.where(data_version: 0)
                                        .where('rating >= ?', @min_rating)
                                        .where('title LIKE ?', "%#{@title_keyword}%")
      best_guide = qualified_guides.order(served_count: :desc).first
      expect(@booking.deep_travel_guide_id).to eq(best_guide.id),
        "未选择服务最多的向导。应选: #{best_guide.name}（已服务#{best_guide.served_count}人），实际: #{@booking.deep_travel_guide.name}（已服务#{@booking.deep_travel_guide.served_count}人）"
    end
  end
  
  def execution_state_data
    { min_rating: @min_rating, title_keyword: @title_keyword, location: @location, product_keyword: @product_keyword,
      travel_date: @travel_date.to_s, adult_count: @adult_count }
  end
  
  def restore_from_state(data)
    @min_rating = data['min_rating']
    @title_keyword = data['title_keyword']
    @location = data['location']
    @product_keyword = data['product_keyword']
    @travel_date = Date.parse(data['travel_date'])
    @adult_count = data['adult_count']
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
      contact_name: '张三',
      contact_phone: '13800138001',
      total_price: total_price,
      insurance_price: 0,
      status: 'pending'
    )
  end
end
