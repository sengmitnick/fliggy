# frozen_string_literal: true

# demo_user_v1 数据包
# Demo 用户：demo@fliggy.com
# 
# 用途：
# - 为验证器提供默认测试用户
# - 包含默认乘机人数据
# 
# 加载时机：
# - 系统启动时自动加载（config/initializers/validator_baseline.rb）

puts "  → 正在设置 Demo 用户..."

demo_user = User.find_or_create_by(email: 'demo@fliggy.com') do |u|
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.name = 'Demo用户'
  u.verified = true
end

if demo_user.persisted?
  # 设置支付密码
  demo_user.pay_password = '222222'
  demo_user.pay_password_confirmation = '222222'
  demo_user.save!
  
  # 添加默认乘机人
  if demo_user.passengers.where(name: '张三').none?
    demo_user.passengers.create!(
      name: '张三',
      id_type: '身份证',
      id_number: '110101199001011234',
      phone: '13800138000'
    )
    puts "     ✓ 添加默认乘机人: 张三"
  end
  
  puts "     ✓ Demo用户: demo@fliggy.com (密码: password123, 支付密码: 222222)"
end

puts "✓ demo_user_v1 数据包加载完成"
