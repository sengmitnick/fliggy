# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例92: 预订苏州园林讲解（粉丝数最多的导游）
class V092BookTravelPhotographyServiceValidator < BaseValidator
  self.validator_id = 'v092_book_travel_photography_service_validator'
  self.task_id = 'aca21330-8a40-44bc-873b-4f93472a424d'
  self.title = '预订苏州园林讲解（粉丝数最多的导游）'
  self.description = '预订10天后苏州园林讲解，选择粉丝数最多的导游'
  self.timeout_seconds = 240
  
  def prepare
    @venue = '苏州园林'
    @location = '华东'
    @travel_date = Date.current + 10.days
    @adult_count = 2
    
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
      @booking = DeepTravelBooking.order(created_at: :desc).first
      expect(@booking).not_to be_nil, "未找到任何深度旅行预订记录"
    end
    
    return unless @booking
    
    add_assertion "向导景点正确（苏州园林）", weight: 20 do
      guide = @booking.deep_travel_guide
      expect(guide.venue).to eq(@venue),
        "向导景点不符合要求。期望: #{@venue}, 实际: #{guide.venue}"
    end
    
    add_assertion "产品地点正确（华东）", weight: 20 do
      product = @booking.deep_travel_product
      expect(product.location).to eq(@location),
        "产品地点不符合要求。期望: #{@location}, 实际: #{product.location}"
    end
    
    add_assertion "选择了粉丝数最多的导游", weight: 25 do
      most_followed = DeepTravelGuide.where(data_version: 0, venue: @venue)
                                     .order(follower_count: :desc, rating: :desc).first
      expect(@booking.deep_travel_guide_id).to eq(most_followed.id),
        "未选择粉丝数最多的导游。应选: #{most_followed.name}（粉丝#{most_followed.follower_count}人），实际: #{@booking.deep_travel_guide.name}（粉丝#{@booking.deep_travel_guide.follower_count}人）"
    end
    
    add_assertion "人数信息正确（2成人）", weight: 20 do
      expect(@booking.adult_count).to eq(@adult_count),
        "成人数不符合。期望: #{@adult_count}, 实际: #{@booking.adult_count}"
    end
  end
  
  def execution_state_data
    { venue: @venue, location: @location,
      travel_date: @travel_date.to_s, adult_count: @adult_count }
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
      contact_name: '赵六',
      contact_phone: '13800138004',
      total_price: total_price,
      insurance_price: 0,
      status: 'pending'
    )
  end
end