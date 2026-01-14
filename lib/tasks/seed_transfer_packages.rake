namespace :db do
  desc "Seed transfer packages data"
  task seed_transfer_packages: :environment do
    puts "正在创建接送机套餐数据..."
    
    if TransferPackage.any?
      puts "接送机套餐数据已存在，跳过创建"
      puts "当前数量: #{TransferPackage.count}"
    else
      TransferPackage.generate_default_packages
      puts "✓ 成功创建了 #{TransferPackage.count} 个接送机套餐"
      
      TransferPackage.all.each do |package|
        puts "  - #{package.category_name}: #{package.name} (¥#{package.price})"
      end
    end
  end
end
