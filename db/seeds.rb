# frozen_string_literal: true

# ============================================================================
# Seeds 入口文件
# ============================================================================
# 
# 本项目采用按需加载的数据管理策略：
# 
# 1. 初始状态：数据库为空，无任何预置数据
# 2. 数据来源：所有数据统一存放在 app/validators/support/data_packs/
# 3. 加载时机：
#    - 验证器运行时自动加载所需的 data_pack
#    - BaseValidator#ensure_checkpoint 会在需要时加载基础数据
#    - 用户可以手动运行 `rails runner "load Rails.root.join('app/validators/support/data_packs/v1/base.rb')"`
# 
# ============================================================================
# 数据包结构
# ============================================================================
# 
# app/validators/support/data_packs/v1/
# ├── base.rb          # 基础数据：City, Destination（验证器依赖）
# ├── flights.rb       # 航班测试数据
# ├── hotels.rb        # 酒店测试数据
# ├── hotels_seed.rb   # 酒店种子数据（待迁移到 hotels.rb）
# ├── trains.rb        # 火车测试数据
# └── ...              # 其他业务数据包
# 
# ============================================================================
# 使用方式
# ============================================================================
# 
# 方式1: 通过验证器自动加载（推荐）
#   validator = BookFlightValidator.new
#   validator.execute_prepare  # 自动加载 base.rb + flights.rb
# 
# 方式2: 手动加载基础数据
#   rails runner "load Rails.root.join('app/validators/support/data_packs/v1/base.rb')"
# 
# 方式3: 手动加载完整数据（用于开发/演示）
#   rails runner "load Rails.root.join('app/validators/support/data_packs/v1/base.rb')"
#   rails runner "load Rails.root.join('app/validators/support/data_packs/v1/flights.rb')"
#   rails runner "load Rails.root.join('app/validators/support/data_packs/v1/hotels_seed.rb')"
# 
# ============================================================================

puts "================================"
puts "数据包管理系统"
puts "================================"
puts ""
puts "✓ 本项目采用按需加载策略，初始数据库为空"
puts ""
puts "数据包位置: app/validators/support/data_packs/v1/"
puts ""
puts "如需加载基础数据，请运行："
puts "  rails runner \"load Rails.root.join('app/validators/support/data_packs/v1/base.rb')\""
puts ""
puts "如需加载完整演示数据，请运行："
puts "  rails runner \"load Rails.root.join('app/validators/support/data_packs/v1/base.rb')\""
puts "  rails runner \"load Rails.root.join('app/validators/support/data_packs/v1/flights.rb')\""
puts "  rails runner \"load Rails.root.join('app/validators/support/data_packs/v1/hotels_seed.rb')\""
puts ""
puts "================================"
