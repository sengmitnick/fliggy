# frozen_string_literal: true

# 为送机服务套餐添加具体车型信息
puts "正在更新 TransferPackage 车型信息..."

# 定义不同车型类别的常见车型
vehicle_models = {
  'economy_5' => [
    { brand: '大众', model: '帕萨特' },
    { brand: '日产', model: '天籁' },
    { brand: '丰田', model: '凯美瑞' },
    { brand: '本田', model: '雅阁' }
  ],
  'comfort_5' => [
    { brand: '奥迪', model: 'A6L' },
    { brand: '宝马', model: '5系' },
    { brand: '奔驰', model: 'E级' },
    { brand: '沃尔沃', model: 'S90' }
  ],
  'economy_7' => [
    { brand: '别克', model: 'GL8' },
    { brand: '本田', model: '奥德赛' },
    { brand: '丰田', model: '塞纳' }
  ],
  'comfort_7' => [
    { brand: '别克', model: 'GL8 ES' },
    { brand: '奔驰', model: 'V级' },
    { brand: '丰田', model: '埃尔法' }
  ],
  'luxury_5' => [
    { brand: '奥迪', model: 'A8L' },
    { brand: '宝马', model: '7系' },
    { brand: '奔驰', model: 'S级' }
  ],
  'luxury_7' => [
    { brand: '奔驰', model: 'V级尊贵版' },
    { brand: '丰田', model: '埃尔法双擎' },
    { brand: '雷克萨斯', model: 'LM' }
  ]
}

TransferPackage.find_each do |package|
  category = package.vehicle_category
  available_models = vehicle_models[category]
  
  if available_models && available_models.any?
    # 根据 priority 分配不同车型
    model_index = (package.priority - 1) % available_models.length
    vehicle = available_models[model_index]
    
    package.update!(
      vehicle_brand: vehicle[:brand],
      vehicle_model: vehicle[:model]
    )
    
    puts "✓ 更新 #{package.provider} (#{package.category_name}): #{vehicle[:brand]} #{vehicle[:model]}"
  end
end

puts "✓ 车型信息更新完成"
