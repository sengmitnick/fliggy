# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例: 预订高评分深度旅行向导服务
# 
# 任务描述:
#   Agent 需要在深度旅行服务中搜索专业向导，
#   找到评分≥4.8分且服务客户数≥1000人的向导并成功预订其产品
# 
# 复杂度分析:
#   1. 需要理解"深度旅行向导"这一特殊服务类型（非常规机酒火车）
#   2. 需要同时满足两个筛选条件（评分 AND 服务数量）
#   3. 需要从7位向导中筛选出符合条件的（4位符合条件）
#   4. 需要在符合条件的向导中选择服务最多的（最有经验）
#   5. 需要选择该向导的产品并填写完整预订信息
#   6. 需要计算总价（向导服务费 × 人数）
#   ❌ 不能一次性提供：需要先浏览向导列表→筛选评分和经验→选择向导→选择产品→填写信息→预订
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 向导评分符合要求（≥4.8分）(20分)
#   - 服务客户数符合要求（≥1000人）(20分)
#   - 选择了经验最丰富的向导（服务数最多）(20分)
#   - 订单信息完整且合理（日期、人数、联系方式、价格）(20分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/book_deep_travel_guide/prepare
#   
#   # Agent 通过界面操作完成搜索和预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V016BookDeepTravelGuideValidator < BaseValidator
  self.validator_id = 'v016_book_deep_travel_guide_validator'
  self.task_id = '749afa1f-b65f-4f1e-a886-3afc82d59cb1'
  self.title = '为1位成人预订7天后的高评分深度旅行向导服务'
  self.description = '需要搜索评分≥4.8分、服务客户≥1000人的深度旅行向导，为1位成人预订7天后的向导服务，并选择经验最丰富（服务客户数最多）的向导'
  self.timeout_seconds = 300
  
  # 准备阶段：设置任务参数
  def prepare
    # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
    @min_rating = 4.8
    @min_served_count = 1000
    @travel_date = Date.current + 7.days  # 一周后出行
    @adult_count = 1  # 1位成人
    
    # 查找符合条件的向导（注意：查询基线数据 data_version=0）
    qualified_guides = DeepTravelGuide.where(data_version: 0)
                                      .where('rating >= ?', @min_rating)
                                      .where('served_count >= ?', @min_served_count)
    
    # 找到经验最丰富的向导（服务客户数最多）
    @best_guide = qualified_guides.order(served_count: :desc, rating: :desc).first
    
    @total_guides = DeepTravelGuide.where(data_version: 0).count
    @qualified_guides_count = qualified_guides.count
    
    # 返回给 Agent 的任务信息
    {
      task: "请为1位成人预订#{(@travel_date - Date.current).to_i}天后（#{@travel_date.strftime('%Y年%m月%d日')}）的深度旅行向导服务，要求向导评分≥#{@min_rating}分、服务客户≥#{@min_served_count}人，并选择经验最丰富（服务客户数最多）的向导",
      requirements: {
        min_rating: @min_rating,
        min_rating_description: "评分至少#{@min_rating}分（满分5分）",
        min_served_count: @min_served_count,
        min_served_count_description: "至少服务过#{@min_served_count}位客户",
        travel_date: @travel_date.to_s,
        date_description: "出行日期：#{@travel_date.strftime('%Y年%m月%d日')}（#{(@travel_date - Date.current).to_i}天后）",
        travelers: "#{@adult_count}位成人"
      },
      hint: "系统中有多位向导可选，请选择同时满足评分和经验要求且服务客户数最多的向导",
      statistics: {
        total_guides: @total_guides,
        qualified_guides: @qualified_guides_count
      }
    }
  end
  
  # 验证阶段：检查订单是否符合要求
  def verify
    # 断言1: 必须有订单创建（最近创建的一条）
    add_assertion "订单已创建", weight: 20 do
      @booking = DeepTravelBooking.order(created_at: :desc).first
      expect(@booking).not_to be_nil, "未找到任何深度旅行预订记录"
    end
    
    return unless @booking  # 如果没有订单，后续断言无法继续
    
    # 断言2: 向导评分符合要求
    add_assertion "向导评分符合要求（≥4.8分）", weight: 20 do
      guide = @booking.deep_travel_guide
      expect(guide).not_to be_nil, "订单未关联向导信息"
      
      actual_rating = guide.rating.to_f
      expect(actual_rating >= @min_rating).to be_truthy,
        "向导评分不符合要求。要求: ≥#{@min_rating}分, 实际: #{actual_rating}分 (向导: #{guide.name})"
    end
    
    # 断言3: 服务客户数符合要求
    add_assertion "服务客户数符合要求（≥1000人）", weight: 20 do
      guide = @booking.deep_travel_guide
      actual_served_count = guide.served_count.to_i
      
      expect(actual_served_count >= @min_served_count).to be_truthy,
        "服务客户数不符合要求。要求: ≥#{@min_served_count}人, 实际: #{actual_served_count}人 (向导: #{guide.name})"
    end
    
    # 断言4: 选择了经验最丰富的向导（核心评分项）
    add_assertion "选择了经验最丰富的向导（服务数最多）", weight: 20 do
      # 查找所有符合条件的向导
      qualified_guides = DeepTravelGuide.where(data_version: 0)
                                        .where('rating >= ?', @min_rating)
                                        .where('served_count >= ?', @min_served_count)
      
      # 找到服务客户数最多的（评分相同时选评分高的）
      best_guide = qualified_guides.order(served_count: :desc, rating: :desc).first
      
      # 验证是否选择了最优向导
      expect(@booking.deep_travel_guide_id).to eq(best_guide.id),
        "未选择经验最丰富的向导。应选: #{best_guide.name}（#{best_guide.title}，评分#{best_guide.rating}分，已服务#{best_guide.served_count}人）, " \
        "实际选择: #{@booking.deep_travel_guide.name}（#{@booking.deep_travel_guide.title}，评分#{@booking.deep_travel_guide.rating}分，已服务#{@booking.deep_travel_guide.served_count}人）"
    end
    
    # 断言5: 订单信息完整且合理（核心评分项）
    add_assertion "订单信息完整且合理", weight: 20 do
      errors = []
      guide = @booking.deep_travel_guide
      product = @booking.deep_travel_product
      
      # 检查必填字段
      errors << "缺少出行日期" if @booking.travel_date.blank?
      errors << "成人数量无效（应≥1）" if @booking.adult_count.to_i <= 0
      errors << "缺少联系人姓名" if @booking.contact_name.blank?
      errors << "缺少联系电话" if @booking.contact_phone.blank?
      
      # 检查电话格式
      unless @booking.contact_phone.match?(/\A1[3-9]\d{9}\z/)
        errors << "联系电话格式不正确（应为11位手机号）"
      end
      
      # 检查价格合理性（应该基于产品价格和人数计算）
      expected_min_price = product.price * @booking.adult_count
      if @booking.total_price.to_f <= 0
        errors << "总价无效（≤0元）"
      elsif @booking.total_price < expected_min_price
        errors << "总价异常低（预期至少#{expected_min_price}元，实际#{@booking.total_price}元）"
      end
      
      # 检查日期合理性（不能预订过去的日期）
      if @booking.travel_date && @booking.travel_date < Date.current
        errors << "出行日期不合理（不能早于今天）"
      end
      
      expect(errors).to be_empty,
        "订单信息存在问题: #{errors.join('; ')}"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      min_rating: @min_rating,
      min_served_count: @min_served_count,
      travel_date: @travel_date.to_s,
      adult_count: @adult_count,
      total_guides: @total_guides,
      qualified_guides_count: @qualified_guides_count,
      best_guide_id: @best_guide&.id
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @min_rating = data['min_rating']
    @min_served_count = data['min_served_count']
    @travel_date = Date.parse(data['travel_date'])
    @adult_count = data['adult_count']
    @total_guides = data['total_guides']
    @qualified_guides_count = data['qualified_guides_count']
    @best_guide = DeepTravelGuide.find_by(id: data['best_guide_id']) if data['best_guide_id']
  end
  
  # 模拟 AI Agent 操作：搜索并预订最优深度旅行向导
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找符合条件的向导，选择服务客户数最多的
    target_guide = DeepTravelGuide.where(data_version: 0)
                                  .where('rating >= ?', @min_rating)
                                  .where('served_count >= ?', @min_served_count)
                                  .order(served_count: :desc, rating: :desc)
                                  .first
    
    raise "未找到符合条件的向导" unless target_guide
    
    # 3. 选择该向导的第一个产品（featured产品或销量最高的）
    target_product = target_guide.deep_travel_products
                                 .where(data_version: 0)
                                 .order(featured: :desc, sales_count: :desc)
                                 .first
    
    raise "向导#{target_guide.name}没有可用产品" unless target_product
    
    # 4. 计算总价（产品价格 × 成人数量）
    total_price = target_product.price * @adult_count
    
    # 5. 创建预订订单
    booking = DeepTravelBooking.create!(
      user_id: user.id,
      deep_travel_guide_id: target_guide.id,
      deep_travel_product_id: target_product.id,
      travel_date: @travel_date,
      adult_count: @adult_count,
      child_count: 0,
      contact_name: user.email.split('@').first,
      contact_phone: '13800138000',
      total_price: total_price,
      insurance_price: 0,
      status: 'pending',
      notes: '期待这次深度旅行体验'
    )
    
    # 返回操作信息
    {
      action: 'create_deep_travel_booking',
      booking_id: booking.id,
      order_number: booking.order_number,
      guide_name: target_guide.name,
      guide_title: target_guide.title,
      guide_rating: target_guide.rating,
      guide_served_count: target_guide.served_count,
      guide_experience_years: target_guide.experience_years,
      product_title: target_product.title,
      product_subtitle: target_product.subtitle,
      product_location: target_product.location,
      product_price: target_product.price,
      travel_date: @travel_date.to_s,
      travelers: "#{@adult_count}位成人",
      total_price: total_price,
      user_email: user.email
    }
  end
end