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
#
# 家庭关系说明：
# ┌─────────────────────────────────────────────────────────────┐
# │ 家庭1：张三一家（三口之家 + 爷爷）                           │
# │   - 张建国（男，65岁，1959年生）- 爷爷（张三的父亲）         │
# │   - 张三（男，34岁，1990年生）- 丈夫/父亲                    │
# │   - 王芳（女，39岁，1985年生）- 妻子/母亲                    │
# │   - 小明（男，9岁，2015年生）- 儿子                          │
# ├─────────────────────────────────────────────────────────────┤
# │ 家庭2：刘强一家（三口之家）                                  │
# │   - 刘强（男，36岁，1988年生）- 丈夫/父亲                    │
# │   - 陈静（女，35岁，1989年生）- 妻子/母亲                    │
# │   - 小红（女，6岁，2018年生）- 女儿                          │
# ├─────────────────────────────────────────────────────────────┤
# │ 其他关系：                                                   │
# │   - 李四（男，34岁，1990年生）- 张三的弟弟                   │
# └─────────────────────────────────────────────────────────────┘


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
  
  # 设置会员里程（足够支持高价商品兑换，包括Arc'teryx冲锋衣35000积分和机票次卡50000积分）
  if demo_user.membership.nil?
    demo_user.create_membership!(
      level: 'F1',
      points: 60000,
      experience: 0,
      data_version: 0
    )
    puts "     ✓ 设置会员里程: 60000"
  elsif demo_user.membership.points < 60000
    demo_user.membership.update!(points: 60000)
    puts "     ✓ 更新会员里程: 60000"
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
        name: '张建国',
        id_type: '身份证',
        id_number: '110101195912155555',  # 1959年出生 - 老人（65岁）- 小明的爷爷
        phone: '13200132000',
        data_version: 0
      },
      {
        name: '李四',
        id_type: '身份证',
        id_number: '110101199001012345',  # 1990年出生 - 成人（34岁）
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
      },
      {
        name: '陈静',
        id_type: '身份证',
        id_number: '110101198904158901',  # 1989年出生 - 成人（35岁）
        phone: '13300133001',
        data_version: 0
      },
      {
        name: '吴勇',
        id_type: '身份证',
        id_number: '110101199205107890',  # 1992年出生 - 成人（32岁）
        phone: '13100131001',
        data_version: 0
      }
    ])
    puts "     ✓ 添加默认乘机人: 张三, 张建国(爷爷), 李四, 王芳, 刘强, 小明, 小红, 陈静, 吴勇"
  end
  
  # 添加联系人（与出行人数据对应）
  if demo_user.contacts.where(name: '张三').none?
    demo_user.contacts.create!([
      {
        name: '张三',
        phone: '13800138000',
        email: 'zhangsan@example.com',
        is_default: true,
        data_version: 0
      },
      {
        name: '张建国',
        phone: '13200132000',
        email: 'zhangjianguo@example.com',
        data_version: 0
      },
      {
        name: '李四',
        phone: '13900139000',
        email: 'lisi@example.com',
        data_version: 0
      },
      {
        name: '王芳',
        phone: '13700137001',
        email: 'wangfang@example.com',
        data_version: 0
      },
      {
        name: '刘强',
        phone: '13600136001',
        email: 'liuqiang@example.com',
        data_version: 0
      },
      {
        name: '小明',
        phone: '13500135001',
        email: 'xiaoming@example.com',
        data_version: 0
      },
      {
        name: '小红',
        phone: '13400134001',
        email: 'xiaohong@example.com',
        data_version: 0
      },
      {
        name: '陈静',
        phone: '13300133001',
        email: 'chenjing@example.com',
        data_version: 0
      },
      {
        name: '吴勇',
        phone: '13100131001',
        email: 'wuyong@example.com',
        data_version: 0
      },
      {
        name: '王五',
        phone: '13700137000',
        email: 'wangwu@example.com',
        data_version: 0
      }
    ])
    puts "     ✓ 添加联系人: 张三, 张建国, 李四, 王芳, 刘强, 小明, 小红, 陈静, 吴勇, 王五"
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
      },
      {
        name: '王芳',
        phone: '13700137001',
        province: '广东省',
        city: '广州',
        district: '天河区',
        detail: '珠江新城花城大道85号',
        address_type: 'delivery',
        data_version: 0
      },
      {
        name: '刘强',
        phone: '13600136001',
        province: '广东省',
        city: '深圳',
        district: '南山区',
        detail: '科技园南区深圳湾科技生态园',
        address_type: 'delivery',
        data_version: 0
      },
      {
        name: '小明',
        phone: '13500135001',
        province: '四川省',
        city: '成都',
        district: '高新区',
        detail: '天府大道中段天府软件园',
        address_type: 'delivery',
        data_version: 0
      },
      {
        name: '陈静',
        phone: '13300133001',
        province: '浙江省',
        city: '杭州',
        district: '西湖区',
        detail: '文三路123号西湖国际科技大厦',
        address_type: 'delivery',
        data_version: 0
      },
      {
        name: '吴勇',
        phone: '13100131001',
        province: '山东省',
        city: '青岛',
        district: '市南区',
        detail: '香港中路68号五四广场',
        address_type: 'delivery',
        data_version: 0
      }
    ])
    puts "     ✓ 添加收货地址: 北京SOHO, 上海陆家嘴, 广州天河, 深圳南山, 成都高新, 杭州西湖, 青岛市南"
  end
  
  puts "     ✓ Demo用户: demo@travel01.com (密码: password123, 支付密码: 222222, 余额: ¥10,000, 里程: 60000)"
end

