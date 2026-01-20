# frozen_string_literal: true

# Validator Baseline Data Initializer
# 
# 在项目启动时加载所有验证器基线数据（data_version=0）
# 这些数据将被所有验证器共享，作为只读的基础数据
# 
# 工作流程：
# 1. 系统启动时检查是否存在基线数据（data_version=0）
# 2. 如果不存在，设置 app.data_version='0' 并加载所有数据包
# 3. 所有创建的数据自动标记为 data_version=0（DataVersionable before_create 钩子）

Rails.application.config.after_initialize do
  # 在所有环境中自动加载基线数据（首次启动时）
  unless Rails.env.test?
    begin
      # 检查是否已存在基线数据（使用City作为标志，因为所有数据包都依赖它）
      # 如果 City 表中不存在 data_version=0 的数据，说明需要初始化
      if City.where(data_version: 0).count == 0
        puts "\n" + "=" * 80
        puts "🚀 首次启动：正在初始化验证器基线数据 (data_version=0)"
        puts "=" * 80
        
        # 设置 PostgreSQL 会话变量 app.data_version='0'
        # 这样 DataVersionable 的 before_create 钩子会自动读取并设置 data_version=0
        ActiveRecord::Base.connection.execute("SET SESSION app.data_version = '0'")
        
        # 获取数据包目录
        data_packs_dir = Rails.root.join('app/validators/support/data_packs/v1')
        
        if Dir.exist?(data_packs_dir)
          # 获取所有 .rb 文件并按文件名排序
          data_pack_files = Dir.glob(data_packs_dir.join('*.rb')).sort
          
          # 确保 base.rb 优先加载（如果存在）
          base_file = data_packs_dir.join('base.rb')
          if File.exist?(base_file)
            data_pack_files.delete(base_file.to_s)
            data_pack_files.unshift(base_file.to_s)
          end
          
          # 加载所有数据包
          data_pack_files.each do |file|
            filename = File.basename(file)
            puts "  → 加载 #{filename}"
            begin
              load file
            rescue StandardError => e
              puts "  ✗ 加载失败: #{filename}"
              puts "    错误: #{e.message}"
              puts "    #{e.backtrace.first(3).join("\n    ")}"
            end
          end
          
          puts "=" * 80
          puts "✓ 基线数据初始化完成 (data_version=0)"
          puts "  - 共加载 #{data_pack_files.size} 个数据包"
          puts "  - City 数量: #{City.where(data_version: 0).count}"
          puts "  - Destination 数量: #{Destination.where(data_version: 0).count}"
          puts "=" * 80
          puts ""
        else
          puts "⚠️  数据包目录不存在: #{data_packs_dir}"
        end
      else
        # 基线数据已存在，跳过初始化
        # puts "✓ 验证器基线数据已存在 (data_version=0)"
      end
    rescue StandardError => e
      puts "\n⚠️  加载验证器基线数据时出错:"
      puts "   #{e.message}"
      puts "   #{e.backtrace.first(5).join("\n   ")}"
    end
  end
end
