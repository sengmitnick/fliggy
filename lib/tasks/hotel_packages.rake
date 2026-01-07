namespace :hotel_packages do
  desc "Generate package options for hotel packages that don't have any"
  task generate_missing_options: :environment do
    puts "正在检查缺少套餐选项的酒店套票..."
    
    missing_count = 0
    generated_count = 0
    
    HotelPackage.find_each do |package|
      if package.package_options.count == 0
        missing_count += 1
        puts "  生成选项: #{package.title}"
        package.generate_options
        generated_count += package.package_options.count
      end
    end
    
    puts "\n✅ 完成！"
    puts "   - 缺少选项的套票: #{missing_count} 个"
    puts "   - 生成的选项数: #{generated_count} 个"
    puts "   - 总套票数: #{HotelPackage.count}"
    puts "   - 总选项数: #{PackageOption.count}"
  end
  
  desc "Regenerate all package options (destructive)"
  task regenerate_all_options: :environment do
    puts "正在重新生成所有套餐选项..."
    
    PackageOption.destroy_all
    puts "  已删除所有现有选项"
    
    HotelPackage.find_each do |package|
      puts "  生成选项: #{package.title}"
      package.generate_options
    end
    
    puts "\n✅ 完成！"
    puts "   - 总套票数: #{HotelPackage.count}"
    puts "   - 总选项数: #{PackageOption.count}"
  end
  
  desc "Show hotel packages statistics"
  task stats: :environment do
    puts "酒店套票统计信息"
    puts "=" * 50
    puts "总套票数: #{HotelPackage.count}"
    puts "总选项数: #{PackageOption.count}"
    puts ""
    puts "按类型分类:"
    puts "  - VIP: #{HotelPackage.by_type('vip').count}"
    puts "  - Standard: #{HotelPackage.by_type('standard').count}"
    puts "  - Limited: #{HotelPackage.by_type('limited').count}"
    puts ""
    puts "特色套票: #{HotelPackage.featured.count}"
    puts ""
    
    packages_without_options = HotelPackage.select { |p| p.package_options.count == 0 }
    if packages_without_options.any?
      puts "⚠️  缺少套餐选项的套票 (#{packages_without_options.count}):"
      packages_without_options.each do |pkg|
        puts "  - #{pkg.title}"
      end
    else
      puts "✅ 所有套票都有套餐选项"
    end
  end
end
