# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例14: 搜索覆盖5国以上的欧洲WiFi设备
# 
# 任务描述:
#   Agent 需要搜索欧洲地区的随身WiFi设备，
#   找到覆盖5个以上国家的产品并成功创建订单
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 订单类型正确（WiFi） (20分)
#   - 地区正确（欧洲） (20分)
#   - 覆盖国家数量≥5 (40分)
# 
# 难点:
#   - 需要理解"多国覆盖"的概念
#   - 需要解析国家数量信息
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/search_multi_country_wifi/prepare
#   
#   # Agent 通过界面操作完成搜索和购买...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class SearchMultiCountryWifiValidator < BaseValidator
  self.validator_id = 'search_multi_country_wifi'
  self.title = '搜索覆盖5国以上的欧洲WiFi设备'
  self.description = '搜索欧洲地区的随身WiFi设备，找到覆盖5个以上国家的产品并购买'
  self.timeout_seconds = 300
  
  # 准备阶段：设置任务参数
  def prepare
    # 数据已经通过 load_data_pack 自动加载
    # 注意：现有数据包只有香港地区数据，需要创建欧洲多国覆盖数据
    @region = '欧洲多国'
    @min_countries = 5
    
    # 查找符合条件的WiFi设备（注意：查询基线数据）
    # 使用 region 字段包含"欧洲"或特定关键词
    matching_wifis = InternetWifi.where(data_version: 0)
                                  .where('region LIKE ? OR region LIKE ?', 
                                         '%欧洲%', '%国%')
    
    @total_wifis = matching_wifis.count
    
    # 返回给 Agent 的任务信息
    {
      task: "请搜索覆盖5个以上国家的欧洲随身WiFi设备",
      region: @region,
      min_countries: @min_countries,
      hint: "需要找到支持多国漫游的WiFi设备，覆盖至少5个国家",
      total_wifis: @total_wifis
    }
  end
  
  # 验证阶段：检查订单是否符合要求
  def verify
    # 断言1: 必须有订单创建
    add_assertion "订单已创建", weight: 20 do
      @order = InternetOrder.order(created_at: :desc).first
      expect(@order).not_to be_nil, "未找到任何境外上网订单记录"
    end
    
    return unless @order
    
    # 断言2: 订单类型正确（WiFi）
    add_assertion "订单类型正确（WiFi）", weight: 20 do
      expect(@order.order_type).to eq('wifi'),
        "订单类型不正确。预期: wifi, 实际: #{@order.order_type}"
    end
    
    # 断言3: 地区相关（包含欧洲或多国关键词）
    add_assertion "地区正确（欧洲或多国）", weight: 20 do
      region_text = @order.region
      expect(region_text).to match(/欧洲|多国|国家/),
        "地区不符合要求。实际: #{region_text}"
    end
    
    # 断言4: 覆盖国家数量≥5（核心评分）
    add_assertion "覆盖国家数量≥5", weight: 40 do
      wifi = @order.orderable
      region_text = wifi.region
      
      # 从 region 字段解析国家数量（假设格式为"欧洲X国"或"X国通用"）
      country_count = region_text.scan(/(\d+)国/).flatten.first.to_i
      
      expect(country_count).to be >= @min_countries,
        "覆盖国家数量不足。要求: ≥#{@min_countries}, 实际: #{country_count}"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      region: @region,
      min_countries: @min_countries,
      total_wifis: @total_wifis
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @region = data['region']
    @min_countries = data['min_countries']
    @total_wifis = data['total_wifis']
  end
  
  # 模拟 AI Agent 操作：搜索欧洲多国WiFi设备并购买
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找符合条件的WiFi设备（覆盖5国以上）
    matching_wifis = InternetWifi.where(data_version: 0)
                                  .select { |wifi| 
                                    count = wifi.region.scan(/(\d+)国/).flatten.first.to_i
                                    count >= @min_countries
                                  }
    
    # 随机选择一个
    target_wifi = matching_wifis.sample
    
    # 3. 计算租赁天数和总价（假设租5天）
    rental_days = 5
    total_price = target_wifi.daily_price * rental_days + target_wifi.deposit
    
    # 4. 创建订单（固定参数）
    order = InternetOrder.create!(
      orderable: target_wifi,
      user_id: user.id,
      order_type: 'wifi',
      region: target_wifi.region,
      quantity: 1,
      rental_days: rental_days,
      total_price: total_price,
      delivery_method: 'mail',
      status: 'pending'
    )
    
    # 返回操作信息
    {
      action: 'create_internet_order',
      order_id: order.id,
      wifi_name: target_wifi.name,
      region: target_wifi.region,
      rental_days: rental_days,
      total_price: total_price,
      user_email: user.email
    }
  end
end
