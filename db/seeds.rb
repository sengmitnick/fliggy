# frozen_string_literal: true

# ============================================================================
# Seeds 入口文件
# ============================================================================
# 
# 本项目采用数据包管理策略：
#
# 1. 初始状态：通过 rake validator:reset_baseline 加载全部数据包作为基线数据
# 2. 数据来源：所有数据统一存放在 app/validators/support/data_packs/v1/
# 3. 基线数据：data_version=0 的数据，所有验证器共享
# 4. 会话数据：验证器执行时创建的临时数据，使用唯一的 data_version 隔离
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
# 推荐方式: 使用 rake 任务加载（生产环境）
#   rake validator:reset_baseline  # 清空数据库并加载全部数据包
#
# 手动加载方式（仅用于开发/调试）：
#   rails runner "Dir.glob(Rails.root.join('app/validators/support/data_packs/v1/*.rb')).sort.each { |f| load f }"
# 
# ============================================================================

puts "================================"
puts "数据包管理系统"
puts "================================"
puts ""
puts "✓ 使用 rake validator:reset_baseline 加载全部数据包作为基线数据"
puts ""
puts "数据包位置: app/validators/support/data_packs/v1/"
puts "  - base.rb: 基础数据（City + Destination + Demo用户）"
puts "  - flights.rb: 航班测试数据"
puts "  - hotels.rb / hotels_seed.rb: 酒店测试数据"
puts "  - cars.rb / bus_tickets.rb / ...: 其他业务数据包"
puts "  - 共 12 个数据包文件"
puts ""
puts "加载基线数据："
puts "  rake validator:reset_baseline  # 清空数据库并加载全部数据包（推荐）"
puts ""
puts "================================"
