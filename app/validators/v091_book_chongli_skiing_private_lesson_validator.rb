# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例91: 预订崇礼滑雪私教课（单板双板均可，家庭出行）
class V091BookChongliSkiingPrivateLessonValidator < BaseValidator
  self.validator_id = 'v091_book_chongli_skiing_private_lesson_validator'
  self.task_id = '5bc15e2f-a604-469a-99a1-ccce0e9eabed'
  self.title = '预订崇礼滑雪私教课（单板双板均可，家庭出行2大1小）'
  self.description = '预订下周末崇礼万龙滑雪场私教课，家庭出行2大1小，选择评分最高的滑雪教练'
  self.timeout_seconds = 240
  
  def prepare
    @title_keyword = '滑雪教学'
    @location_keyword = '崇礼'
    @product_keyword = '私教'
    @travel_date = Date.current + 7.days
    @adult_count = 2
    @child_count = 1
    
    @qualified_guides = DeepTravelGuide.where(data_version: 0)
                                       .where('title LIKE ?', "%#{@title_keyword}%")
    
    {
      task: "请预订下周末（#{@travel_date.strftime('%Y年%m月%d日')}）崇礼万龙滑雪场的私教课，家庭出行#{@adult_count}大#{@child_count}小，选择评分最高的滑雪教练",
      location_keyword: @location_keyword,
      product_keyword: @product_keyword,
      title_keyword: @title_keyword,
      travel_date: @travel_date.strftime('%Y-%m-%d'),
      adult_count: @adult_count,
      child_count: @child_count,
      hint: "筛选滑雪教学类向导，选择评分最高的教练，产品需包含'崇礼'和'私教'关键词",
      qualified_guides_count: @qualified_guides.count
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 15 do
      @booking = DeepTravelBooking.order(created_at: :desc).first
      expect(@booking).not_to be_nil, "未找到任何深度旅行预订记录"
    end
    
    return unless @booking
    
    add_assertion "向导类型正确（滑雪教学）", weight: 20 do
      guide = @booking.deep_travel_guide
      expect(guide.title).to include(@title_keyword),
        "向导类型不符合要求。期望包含: #{@title_keyword}, 实际: #{guide.title}"
    end
    
    add_assertion "产品地点包含关键词（崇礼）", weight: 20 do
      product = @booking.deep_travel_product
      location_match = product.location.include?(@location_keyword) || product.title.include?(@location_keyword)
      expect(location_match).to be_truthy,
        "产品地点不符合要求。期望包含: #{@location_keyword}, 实际: #{product.location} / #{product.title}"
    end
    
    add_assertion "选择了评分最高的滑雪教练", weight: 25 do
      highest_rated = DeepTravelGuide.where(data_version: 0)
                                     .where('title LIKE ?', "%#{@title_keyword}%")
                                     .order(rating: :desc).first
      expect(@booking.deep_travel_guide_id).to eq(highest_rated.id),
        "未选择评分最高的教练。应选: #{highest_rated.name}（评分#{highest_rated.rating}），实际: #{@booking.deep_travel_guide.name}（评分#{@booking.deep_travel_guide.rating}）"
    end
    
    add_assertion "人数信息正确（2大1小）", weight: 20 do
      expect(@booking.adult_count).to eq(@adult_count),
        "成人数量错误。期望: #{@adult_count}, 实际: #{@booking.adult_count}"
      expect(@booking.child_count).to eq(@child_count),
        "儿童数量错误。期望: #{@child_count}, 实际: #{@booking.child_count}"
    end
  end
  
  def execution_state_data
    { title_keyword: @title_keyword, location_keyword: @location_keyword, product_keyword: @product_keyword,
      travel_date: @travel_date.to_s, adult_count: @adult_count, child_count: @child_count }
  end
  
  def restore_from_state(data)
    @title_keyword = data['title_keyword']
    @location_keyword = data['location_keyword']
    @product_keyword = data['product_keyword']
    @travel_date = Date.parse(data['travel_date'])
    @adult_count = data['adult_count']
    @child_count = data['child_count']
    @qualified_guides = DeepTravelGuide.where(data_version: 0).where('title LIKE ?', "%#{@title_keyword}%")
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    target_guide = DeepTravelGuide.where(data_version: 0)
                                  .where('title LIKE ?', "%#{@title_keyword}%")
                                  .order(rating: :desc).first
    raise "未找到符合条件的向导" unless target_guide
    
    target_product = target_guide.deep_travel_products.where(data_version: 0)
                                 .where('title LIKE ? OR location LIKE ?', "%#{@location_keyword}%", "%#{@location_keyword}%")
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
      contact_name: '王五',
      contact_phone: '13800138003',
      total_price: total_price,
      insurance_price: 0,
      status: 'pending'
    )
  end
end