# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例285: 给张三和王芳预订云南私家团长线游（7天6晚，昆明出发，14天后出发，夫妻出行）
# 
# 任务描述:
#   张三和王芳（夫妻）计划从昆明出发，进行7天6晚的云南深度游。
#   Agent 需要搜索符合条件的私家团长线游产品，完成2人的旅游预订。
# 
# 产品类型说明:
#   - TourGroupProduct 模型包含多种 tour_category 类型：
#     * group_tour: 跟团游（与陆生人拼团）
#     * private_group: 私家团（独立成团，不与陆生人拼团） ← 本用例使用
#     * free_travel: 自由行（自己安排行程）
#   - 本验证用例使用 private_group（私家团/独立成团）产品
# 
# 业务流程（8个关键步骤）：
#   1. 搜索云南地区的旅游产品（TourGroupProduct）
#   2. 筛选长线游产品（duration ≥ 7天）
#   3. 筛选昆明出发的产品（departure_city=昆明）
#   4. 理解产品类型（私家团 private_group 即独立成团）
#   5. 选择合适的旅游套餐（tour_packages）
#   6. 设置出行人数（成人2人：张三和王芳夫妻）
#   7. 选择出行日期（travel_date，至少14天后）
#   8. 填写联系人信息（张三或王芳均可）并提交订单
# 
# 复杂度分析（8个关键点）：
#   1. 需要理解目的地筛选：云南地区的旅游产品
#   2. 需要理解行程时长：长线游（≥7天深度游）vs 短途游（1-3天）
#   3. 需要理解出发城市：昆明出发（而非其他城市）
#   4. 需要理解产品类型：私家团（private_group）= 独立成团，不与陆生人拼团
#   5. 需要理解产品结构：TourGroupProduct（产品）+ TourPackage（套餐）+ TourGroupBooking（预订）
#   6. 需要理解人数设置：成人2人（夫妻出行）、儿童0人
#   7. 需要理解联系人：张三或王芳均可作为联系人
#   8. 需要理解价格计算：长线游价格较高（通常 > 1000元/人）
#   ❌ 不能随机选择：必须精确选择云南+昆明出发+7天以上的产品
# 
# 评分标准（8项，总计100分）：
#   - 创建旅游预订（20分）
#   - 行程时长正确（≥7天）（15分）
#   - 联系人信息正确（张三或王芳）（12分）
#   - 目的地正确（云南）（12分）
#   - 出发城市正确（昆明）（15分）
#   - 成人数量正确（2人）（8分）
#   - 长线游价格合理（>1000元）（10分）
#   - 订单状态正确（8分）
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v285_book_long_distance_tour_package_validator/start
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V251V300
  class V285BookLongDistanceTourPackageValidator < BaseValidator
    self.validator_id = 'v285_book_long_distance_tour_package_validator'
    self.task_id = '017fa810-5e0d-4b89-9eef-1ac127ff20fe'
    self.title = '给张三和王芳预订云南私家团长线游（7天6晚，昆明出发，14天后出发，夫妻出行）'
    self.description = '预订云南私家团长线游（7天6晚，昆明出发，2成人，独立成团）'
    self.timeout_seconds = 300
    
    # 准备阶段：设置任务参数
    def prepare
      # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
      @duration = 7
      @adult_count = 2  # 张三和王芳夫妻
      @child_count = 0
      @destination = '云南'
      @departure_city = '昆明'
      
      # 查找符合条件的长线游产品（注意：查询基线数据 data_version=0）
      @product = TourGroupProduct
        .where('duration >= ?', @duration)
        .where(destination: @destination, departure_city: @departure_city)
        .where(data_version: 0)
        .order(price: :desc)
        .first!
      
      # 预查询套餐（必须存在于数据包）
      @package = @product.tour_packages.where(data_version: 0).first!
      
      # 预查询乘客信息（张三和王芳夫妻）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      
      # 联系人信息（用于验证非空即可，不限制必须是张三或王芳）
      
      # 确保用户余额充足
      total_price = @package.price * @adult_count
      if user.balance < total_price
        user.update!(balance: total_price + 1000)
      end
      
      # 返回给 Agent 的任务信息
      {
        task: "请给张三和王芳（夫妻）预订从#{@departure_city}出发的#{@product.duration}天云南私家团长线游「#{@product.title}」。重要：成人数量必须是#{@adult_count}人（张三和王芳夫妻），儿童#{@child_count}人，独立成团不与陆生人拼团，游览多个城市享受深度旅游。",
        product_title: @product.title,
        duration: @product.duration,
        destination: @destination,
        departure_city: @departure_city,
        adult_count: @adult_count,
        child_count: @child_count,
        price: @product.price.to_f,
        hint: "选择天数较长的私家团产品（≥7天），适合深度旅游。私家团（private_group）即独立成团，不与陆生人拼团。成人数量必须是2人（张三和王芳夫妻）。联系人信息可以是任何乘客（张三/王芳/李四等）。"
      }
    end
    
    # 验证阶段：检查订单是否符合要求
    def verify
      # 断言1: 创建旅游预订（20分）
      add_assertion "创建了旅游预订", weight: 20 do
        @booking = TourGroupBooking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@booking).not_to be_nil, "未找到跟团游预订"
      end
      
      return unless @booking # 如果没有预订，后续断言无法继续
      
      # 断言2: 行程时长正确（≥7天）（15分）
      add_assertion "行程时长正确（≥#{@duration}天）", weight: 15 do
        product = @booking.tour_group_product
        expect(product).not_to be_nil, "订单没有关联产品"
        expect(product.duration).to be >= @duration,
          "行程时长不足。期望: ≥#{@duration}天（长线游）, 实际: #{product.duration}天"
      end
      
      # 断言3: 联系人信息正确（非空即可）（12分）
      add_assertion "联系人信息正确（姓名和电话非空）", weight: 12 do
        expect(@booking.contact_name).not_to be_nil,
          "联系人姓名为空"
        expect(@booking.contact_name).not_to be_empty,
          "联系人姓名为空字符串"
        
        expect(@booking.contact_phone).not_to be_nil,
          "联系人电话为空"
        expect(@booking.contact_phone).not_to be_empty,
          "联系人电话为空字符串"
        expect(@booking.contact_phone).to match(/^1[3-9]\d{9}$/),
          "联系人电话格式错误。实际: #{@booking.contact_phone}（应为11位手机号）"
      end
      
      # 断言4: 目的地正确（云南）（12分）
      add_assertion "目的地正确（#{@destination}）", weight: 12 do
        product = @booking.tour_group_product
        expect(product.destination).to eq(@destination),
          "目的地错误。期望: #{@destination}, 实际: #{product.destination}"
      end
      
      # 断言5: 出发城市正确（昆明）（15分）
      add_assertion "出发城市正确（#{@departure_city}）", weight: 15 do
        product = @booking.tour_group_product
        expect(product.departure_city).to eq(@departure_city),
          "出发城市错误。期望: #{@departure_city}, 实际: #{product.departure_city}"
      end
      
      # 断言6: 成人数量正确（2人）（8分）
      add_assertion "成人数量正确（#{@adult_count}人：张三和王芳夫妻）", weight: 8 do
        actual_adult_count = @booking.adult_count
        expect(actual_adult_count).to eq(@adult_count),
          "成人数量错误。期望: #{@adult_count}人（张三和王芳夫妻）, 实际: #{actual_adult_count}人"
        
        actual_child_count = @booking.child_count || 0
        expect(actual_child_count).to eq(@child_count),
          "儿童数量错误。期望: #{@child_count}人, 实际: #{actual_child_count}人"
      end
      
      # 断言7: 长线游价格合理（10分）
      add_assertion "长线游价格合理（>1000元）", weight: 10 do
        expect(@booking.total_price).to be > 1000,
          "长线游价格过低，不合理。实际: #{@booking.total_price}元（≥7天产品应该高于1000元）"
      end
      
      # 断言8: 订单状态正确（8分）
      add_assertion "订单状态正确", weight: 8 do
        expect(@booking.status).to eq('pending').or(eq('confirmed')),
          "订单状态错误。期望: pending/confirmed, 实际: #{@booking.status}"
      end
    end
    
    # 模拟 AI Agent 操作：预订云南长线游套餐
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      
      TourGroupBooking.create!(
        user_id: user.id,
        tour_group_product_id: @product.id,
        tour_package_id: @package.id,
        adult_count: @adult_count,  # 张三和王芳夫妻
        child_count: @child_count,
        contact_name: zhangsan.name,
        contact_phone: zhangsan.phone,
        travel_date: Date.current + 14.days,
        total_price: @package.price * @adult_count,
        status: 'confirmed',
        data_version: @data_version
      )
    end
    
    private
    
    # 保存执行状态数据
    def execution_state_data
      {
        duration: @duration,
        adult_count: @adult_count,
        child_count: @child_count,
        destination: @destination,
        departure_city: @departure_city,
        product_id: @product&.id,
        package_id: @package&.id
      }
    end
    
    # 从状态恢复实例变量
    def restore_from_state(data)
      @duration = data['duration']
      @adult_count = data['adult_count']
      @child_count = data['child_count'] || 0
      @destination = data['destination']
      @departure_city = data['departure_city']
      @product = TourGroupProduct.find(data['product_id']) if data['product_id']
      @package = TourPackage.find(data['package_id']) if data['package_id']
    end
  end
end
