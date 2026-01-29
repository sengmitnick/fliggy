# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例92: 预订旅拍服务（高粉丝跟拍摄影师）
class V092BookTravelPhotographyServiceValidator < BaseValidator
  self.validator_id = 'v092_book_travel_photography_service_validator'
  self.title = '预订旅拍服务（粉丝数≥15000的跟拍摄影师）'
  self.description = '预订10天后的旅拍服务，要求粉丝数≥15000的跟拍摄影师，选择评分最高的'
  self.timeout_seconds = 240
  
  def prepare
    @title_keyword = '跟拍'
    @min_follower_count = 15000
    @travel_date = Date.current + 10.days
    @adult_count = 1
    
    @qualified_guides = DeepTravelGuide.where(data_version: 0)
                                       .where('title LIKE ?', "%#{@title_keyword}%")
                                       .where('follower_count >= ?', @min_follower_count)
    
    {
      task: "请预订10天后（#{@travel_date.strftime('%Y年%m月%d日')}）的旅拍服务，要求粉丝数≥#{@min_follower_count}的跟拍摄影师，为#{@adult_count}位成人，选择评分最高的摄影师",
      title_keyword: @title_keyword,
      min_follower_count: @min_follower_count,
      travel_date: @travel_date.strftime('%Y-%m-%d'),
      adult_count: @adult_count,
      hint: "筛选跟拍类向导且粉丝数≥15000，选择评分最高的",
      qualified_guides_count: @qualified_guides.count
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 20 do
      @booking = DeepTravelBooking.order(created_at: :desc).first
      expect(@booking).not_to be_nil, "未找到任何深度旅行预订记录"
    end
    
    return unless @booking
    
    add_assertion "向导类型正确（跟拍）", weight: 20 do
      guide = @booking.deep_travel_guide
      expect(guide.title).to include(@title_keyword),
        "向导类型不符合要求。期望包含: #{@title_keyword}, 实际: #{guide.title}"
    end
    
    add_assertion "粉丝数符合要求（≥15000）", weight: 30 do
      guide = @booking.deep_travel_guide
      expect(guide.follower_count >= @min_follower_count).to be_truthy,
        "粉丝数不符合要求。期望: ≥#{@min_follower_count}, 实际: #{guide.follower_count}"
    end
    
    add_assertion "选择了评分最高的摄影师", weight: 30 do
      highest_rated = DeepTravelGuide.where(data_version: 0)
                                     .where('title LIKE ?', "%#{@title_keyword}%")
                                     .where('follower_count >= ?', @min_follower_count)
                                     .order(rating: :desc).first
      expect(@booking.deep_travel_guide_id).to eq(highest_rated.id),
        "未选择评分最高的摄影师。应选: #{highest_rated.name}（评分#{highest_rated.rating}），实际: #{@booking.deep_travel_guide.name}（评分#{@booking.deep_travel_guide.rating}）"
    end
  end
  
  def execution_state_data
    { title_keyword: @title_keyword, min_follower_count: @min_follower_count,
      travel_date: @travel_date.to_s, adult_count: @adult_count }
  end
  
  def restore_from_state(data)
    @title_keyword = data['title_keyword']
    @min_follower_count = data['min_follower_count']
    @travel_date = Date.parse(data['travel_date'])
    @adult_count = data['adult_count']
    @qualified_guides = DeepTravelGuide.where(data_version: 0)
                                       .where('title LIKE ?', "%#{@title_keyword}%")
                                       .where('follower_count >= ?', @min_follower_count)
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    target_guide = DeepTravelGuide.where(data_version: 0)
                                  .where('title LIKE ?', "%#{@title_keyword}%")
                                  .where('follower_count >= ?', @min_follower_count)
                                  .order(rating: :desc).first
    raise "未找到符合条件的向导" unless target_guide
    
    target_product = target_guide.deep_travel_products.where(data_version: 0)
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
      contact_name: '赵六',
      contact_phone: '13800138004',
      total_price: total_price,
      insurance_price: 0,
      status: 'pending'
    )
  end
end
