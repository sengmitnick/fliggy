# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例90: 预订上海外滩历史文化讲解（评分最高）
class V090BookSanyaDivingExperienceValidator < BaseValidator
  self.validator_id = 'v090_book_sanya_diving_experience_validator'
  self.task_id = 'b0ae1fdc-ef74-465b-ade9-04b581d0eb17'
  self.title = '预订上海外滩历史文化讲解（评分最高的特级导游）'
  self.description = '预订3天后的上海外滩历史文化讲解，要求评分最高的特级导游'
  self.timeout_seconds = 240
  
  def prepare
    @venue = '上海外滩'
    @location = '华东'
    @travel_date = Date.current + 3.days
    @adult_count = 1
    
    @qualified_guides = DeepTravelGuide.where(data_version: 0, venue: @venue)
    
    {
      task: "请预订3天后（#{@travel_date.strftime('%Y年%m月%d日')}）#{@venue}的历史文化讲解，要求评分最高的特级导游，为#{@adult_count}位成人",
      venue: @venue,
      location: @location,
      travel_date: @travel_date.strftime('%Y-%m-%d'),
      adult_count: @adult_count,
      hint: "筛选上海外滩讲解员，选择评分最高的导游",
      qualified_guides_count: @qualified_guides.count
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 20 do
      @booking = DeepTravelBooking.order(created_at: :desc).first
      expect(@booking).not_to be_nil, "未找到任何深度旅行预订记录"
    end
    
    return unless @booking
    
    add_assertion "向导景点正确（上海外滩）", weight: 25 do
      guide = @booking.deep_travel_guide
      expect(guide.venue).to eq(@venue),
        "向导景点不符合要求。期望: #{@venue}, 实际: #{guide.venue}"
    end
    
    add_assertion "产品地点正确（华东）", weight: 25 do
      product = @booking.deep_travel_product
      expect(product.location).to eq(@location),
        "产品地点不符合要求。期望: #{@location}, 实际: #{product.location}"
    end
    
    add_assertion "选择了评分最高的外滩导游", weight: 30 do
      highest_rated = DeepTravelGuide.where(data_version: 0, venue: @venue)
                                     .order(rating: :desc, served_count: :desc).first
      expect(@booking.deep_travel_guide_id).to eq(highest_rated.id),
        "未选择评分最高的导游。应选: #{highest_rated.name}（评分#{highest_rated.rating}），实际: #{@booking.deep_travel_guide.name}（评分#{@booking.deep_travel_guide.rating}）"
    end
  end
  
  def execution_state_data
    { venue: @venue, location: @location, travel_date: @travel_date.to_s, adult_count: @adult_count }
  end
  
  def restore_from_state(data)
    @venue = data['venue']
    @location = data['location']
    @travel_date = Date.parse(data['travel_date'])
    @adult_count = data['adult_count']
    @qualified_guides = DeepTravelGuide.where(data_version: 0, venue: @venue)
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    target_guide = DeepTravelGuide.where(data_version: 0, venue: @venue)
                                  .order(rating: :desc, served_count: :desc).first
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
      contact_name: '李四',
      contact_phone: '13800138002',
      total_price: total_price,
      insurance_price: 0,
      status: 'pending'
    )
  end
end