# frozen_string_literal: true

# ============================================================================
# Seeds 入口文件
# ============================================================================
# 
# 本项目采用按需加载的数据管理策略：
# 
# 1. 初始状态：数据库为空，无任何预置数据
# 2. 数据来源：所有数据统一存放在 app/validators/support/data_packs/v1/
# 3. 加载时机：
#    - 验证器 prepare 阶段自动加载 v1 目录下的所有数据包
#    - 验证完成后自动清空所有数据，恢复到初始空状态
#    - 用户可以手动运行 `rails runner "Dir.glob(Rails.root.join('app/validators/support/data_packs/v1/*.rb')).sort.each { |f| load f }"`
# 
# ============================================================================
# 数据包结构
# ============================================================================
# 
# app/validators/support/data_packs/v1/
# ├── base.rb                    # 基础数据（City, Destination, Demo用户）
# ├── flights.rb                 # 航班数据
# ├── hotels.rb / hotels_seed.rb # 酒店数据
# ├── cars.rb                    # 汽车租赁数据
# ├── bus_tickets.rb             # 巴士票数据
# ├── tour_group_products.rb     # 跟团游数据
# ├── abroad_tickets.rb          # 境外票务数据
# ├── abroad_shopping.rb         # 境外购物数据
# ├── deep_travel.rb             # 深度游数据
# ├── hotel_packages.rb          # 酒店套餐数据
# └── internet_services.rb       # 互联网服务数据
# 
# 共 12 个数据包文件，prepare 阶段会自动全量加载
# 
# ============================================================================
# 使用方式
# ============================================================================
# 
# 方式1: 通过验证器自动加载（推荐）
#   validator = BookFlightValidator.new
#   validator.execute_prepare  # 自动加载 v1 目录下所有数据包
# 
# 方式2: 手动加载所有数据包（用于开发/演示）
#   rails runner "Dir.glob(Rails.root.join('app/validators/support/data_packs/v1/*.rb')).sort.each { |f| load f }"
# 
# 方式3: 手动加载单个数据包
#   rails runner "load Rails.root.join('app/validators/support/data_packs/v1/base.rb')"
#   rails runner "load Rails.root.join('app/validators/support/data_packs/v1/flights.rb')"
# 
# ============================================================================

puts "================================"
puts "数据包管理系统"
puts "================================"
puts ""
puts "✓ 本项目采用按需加载策略，初始数据库为空"
puts ""
puts "数据包位置: app/validators/support/data_packs/v1/"
puts "  - base.rb: 基础数据（City + Destination + Demo用户）"
puts "  - flights.rb: 航班测试数据"
puts "  - hotels.rb / hotels_seed.rb: 酒店测试数据"
puts "  - cars.rb / bus_tickets.rb / ...: 其他业务数据包"
puts "  - 共 12 个数据包文件"
puts ""
puts "手动加载示例："
puts "  # 加载所有数据包（推荐）"
puts "  rails runner \"Dir.glob(Rails.root.join('app/validators/support/data_packs/v1/*.rb')).sort.each { |f| load f }\""
puts ""
puts "  # 加载单个数据包"
puts "  rails runner \"load Rails.root.join('app/validators/support/data_packs/v1/base.rb')\""
puts "  rails runner \"load Rails.root.join('app/validators/support/data_packs/v1/flights.rb')\""
puts ""
puts "================================"
