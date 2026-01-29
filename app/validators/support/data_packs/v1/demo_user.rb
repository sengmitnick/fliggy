# frozen_string_literal: true

# demo_user_v1 数据包
# Demo 用户：demo@travel01.com
# 
# 用途：
# - 为验证器提供默认测试用户
# - 包含默认乘机人数据
# 
# 加载时机：
# - 系统启动时自动加载（config/initializers/validator_baseline.rb）


demo_user = User.find_or_create_by(email: 'demo@travel01.com') do |u|
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
  
  # 设置钱包余额（默认 1w）
  if demo_user.balance.to_f.zero?
    demo_user.update!(balance: 10000.0)
    puts "     ✓ 设置钱包余额: ¥10,000.00"
  end
  
  # 设置会员里程
  if demo_user.membership.nil?
    demo_user.create_membership!(
      level: 'F1',
      points: 50,
      experience: 0,
      data_version: 0
    )
    puts "     ✓ 设置会员里程: 50"
  elsif demo_user.membership.points.zero?
    demo_user.membership.update!(points: 50)
    puts "     ✓ 更新会员里程: 50"
  end
  
  # 添加默认乘机人
  if demo_user.passengers.where(name: '张三').none?
    demo_user.passengers.create!([
      {
        name: '张三',
        id_type: '身份证',
        id_number: '110101199001011234',  # 1990年出生 - 成人（34岁）
        phone: '13800138000',
        is_self: true,
        data_version: 0
      },
      {
        name: '李四',
        id_type: '身份证',
        id_number: '110101199002022345',  # 1990年出生 - 成人（34岁）
        phone: '13900139000',
        data_version: 0
      },
      {
        name: '王芳',
        id_type: '身份证',
        id_number: '110101198506153456',  # 1985年出生 - 成人（39岁）
        phone: '13700137001',
        data_version: 0
      },
      {
        name: '刘强',
        id_type: '身份证',
        id_number: '110101198803214567',  # 1988年出生 - 成人（36岁）
        phone: '13600136001',
        data_version: 0
      },
      {
        name: '小明',
        id_type: '身份证',
        id_number: '110101201507085678',  # 2015年出生 - 儿童（9岁）
        phone: '13500135001',
        data_version: 0
      },
      {
        name: '小红',
        id_type: '身份证',
        id_number: '110101201808126789',  # 2018年出生 - 儿童（6岁）
        phone: '13400134001',
        data_version: 0
      }
    ])
    puts "     ✓ 添加默认乘机人: 张三, 李四, 王芳, 刘强, 小明, 小红"
  end
  
  # 添加联系人
  if demo_user.contacts.where(name: '王五').none?
    demo_user.contacts.create!([
      {
        name: '王五',
        phone: '13700137000',
        email: 'wangwu@example.com',
        is_default: true,
        data_version: 0
      },
      {
        name: '赵六',
        phone: '13600136000',
        email: 'zhaoliu@example.com',
        data_version: 0
      }
    ])
    puts "     ✓ 添加联系人: 王五, 赵六"
  end
  
  # 添加收货地址
  if demo_user.addresses.where(name: '张三').none?
    demo_user.addresses.create!([
      {
        name: '张三',
        phone: '13800138000',
        province: '北京市',
        city: '北京',
        district: '朝阳区',
        detail: '建国路88号SOHO现代城',
        address_type: 'delivery',
        is_default: true,
        data_version: 0
      },
      {
        name: '李四',
        phone: '13900139000',
        province: '上海市',
        city: '上海',
        district: '浦东新区',
        detail: '陆家嘴环路1000号',
        address_type: 'delivery',
        data_version: 0
      }
    ])
    puts "     ✓ 添加收货地址: 北京SOHO, 上海陆家嘴"
  end
  
  puts "     ✓ Demo用户: demo@travel01.com (密码: password123, 支付密码: 222222, 余额: ¥10,000, 里程: 50)"
end

