# frozen_string_literal: true

namespace :frozen_time do
  desc "验证 FrozenTime 时间冻结机制在未来多天是否正常工作"
  task validate: :environment do
    puts ""
    puts "=" * 80
    puts "🕐 FrozenTime 机制验证测试"
    puts "=" * 80
    puts ""

    # 获取基线数据生成时间
    anchor_record = City.where(data_version: 0).order(:created_at).first
    unless anchor_record
      puts "❌ 错误: 找不到基线数据（data_version=0 的 City 记录）"
      puts "   请先运行: rake validator:reset_baseline"
      exit 1
    end

    anchor_time = anchor_record.created_at
    anchor_date = anchor_time.to_date

    puts "📅 基线数据生成时间: #{anchor_time.strftime('%Y-%m-%d %H:%M:%S %Z')}"
    puts "📅 基线日期: #{anchor_date} (#{anchor_date.strftime('%A')})"
    puts ""

    # 数据包设置（基于 flights.rb 实际配置）
    # 航班数据包生成范围：Date.current 到 Date.current + 40.days (41天)
    data_range_days = 40  # 航班数据包的天数范围
    data_start = anchor_date
    data_end = anchor_date + data_range_days.days

    # 验证器查询范围（基于实际验证器代码分析）
    # 航班验证器最大查询：Date.current + 20.days
    # 通过 grep 确认：grep -r 'Date.current.*+.*days' app/validators/ | grep -i flight | grep -oP 'Date\.current \+ \K\d+' | sort -n | tail -1
    max_query_offset = 20  # 验证器查询的最大未来天数

    puts "📦 数据包设置:"
    puts "   日期范围: #{data_start} 至 #{data_end} (共 #{data_range_days + 1} 天)"
    puts ""
    puts "🔍 验证器查询模式:"
    puts "   最大查询偏移: Date.current + #{max_query_offset}.days"
    puts ""

    # 模拟未来多天的情况
    test_days = [0, 1, 3, 6, 7, 8, 10, 14, 15, 20, 21, 28, 30, 35, 40]

    puts "🧪 测试场景: 模拟未来 #{test_days.max} 天内的时间冻结表现"
    puts ""
    puts "-" * 80
    puts "天数 | 真实日期     | 冻结后日期   | 星期   | 最大查询日期 | 数据可用性"
    puts "-" * 80

    results = []
    test_days.each do |days_offset|
      # 模拟未来的真实时间
      simulated_real_time = anchor_time + days_offset.days
      simulated_real_date = simulated_real_time.to_date

      # 计算经过的秒数
      elapsed_seconds = (simulated_real_time - anchor_time).to_f

      # 应用 FrozenTime 的回拨逻辑
      if elapsed_seconds >= 604_800 # 超过7天
        weeks_passed = (elapsed_seconds / 604_800).floor
        offset_seconds = weeks_passed * 604_800
        frozen_time = simulated_real_time - offset_seconds
      else
        frozen_time = simulated_real_time
      end

      frozen_date = frozen_time.to_date
      weekday_cn = %w[周日 周一 周二 周三 周四 周五 周六][frozen_date.wday]

      # 验证器会查询 frozen_date 到 frozen_date + 20.days
      query_range_start = frozen_date
      query_range_end = frozen_date + max_query_offset.days

      data_available = (query_range_start >= data_start && query_range_end <= data_end)
      status = data_available ? "✅ 充足" : "❌ 不足"

      result = {
        days: days_offset,
        real_date: simulated_real_date,
        frozen_date: frozen_date,
        weekday: weekday_cn,
        query_end: query_range_end,
        data_available: data_available,
        status: status
      }
      results << result

      printf("%4d | %s | %s | %-4s | %s | %s\n",
             days_offset,
             simulated_real_date.strftime('%Y-%m-%d'),
             frozen_date.strftime('%Y-%m-%d'),
             weekday_cn,
             query_range_end.strftime('%Y-%m-%d'),
             status)
    end

    puts "-" * 80
    puts ""

    # 统计结果
    available_count = results.count { |r| r[:data_available] }
    unavailable_count = results.size - available_count

    puts "📊 测试结果统计:"
    puts "   总测试场景: #{results.size} 个"
    puts "   ✅ 数据充足: #{available_count} 个"
    puts "   ❌ 数据不足: #{unavailable_count} 个"
    puts ""

    # 计算所需的数据范围
    required_days = 6 + max_query_offset
    puts "💡 数据需求分析:"
    puts "   FrozenTime 最坏情况: Day 6 (frozen_date = anchor + 6.days)"
    puts "   验证器最大查询: frozen_date + #{max_query_offset}.days"
    puts "   所需数据范围: anchor 到 anchor + #{required_days}.days (#{required_days + 1}天)"
    puts "   当前数据范围: anchor 到 anchor + #{data_range_days}.days (#{data_range_days + 1}天)"
    puts ""

    if unavailable_count > 0
      puts "⚠️  警告: 检测到数据覆盖不足的情况！"
      puts ""
      puts "问题分析:"
      puts "  当前数据包生成范围: #{data_start} 到 #{data_end} (共 #{data_range_days + 1} 天)"
      puts "  验证器查询模式: Date.current 到 Date.current + #{max_query_offset}.days"
      puts ""
      
      # 找出最大查询日期
      max_query_end = results.map { |r| r[:query_end] }.max
      puts "  最大查询日期: #{max_query_end}"
      puts "  需要的数据结束日期: #{max_query_end}"
      puts ""
      
      puts "💡 建议修改数据包日期范围:"
      recommended_end = (max_query_end - data_start).to_i
      puts "   将 flights.rb / trains.rb 等数据包中的 end_date 修改为："
      puts "   start_date = Date.current           # 保持不变"
      puts "   end_date = Date.current + #{recommended_end}.days   # 建议修改（当前: +#{data_range_days}.days）"
      puts ""
    else
      puts "✅ 成功: 所有测试场景的数据覆盖都充足！"
      puts ""
      puts "🎯 验证结论:"
      puts "  1. FrozenTime 的7天回拨机制正常工作"
      puts "  2. 数据包日期范围设置合理（#{data_start} ~ #{data_end}）"
      puts "  3. 航班验证器最大查询 +#{max_query_offset} 天，数据包 #{data_range_days + 1} 天完全覆盖（最坏情况需要 #{required_days + 1} 天）"
      puts "  4. 系统可以长期运行而不会出现数据过期问题"
      puts ""
    end

    # 额外检查：验证实际数据库中的数据范围
    puts "=" * 80
    puts "🔍 实际数据库数据范围检查"
    puts "=" * 80
    puts ""

    models_to_check = [
      { model: Flight, date_field: :flight_date, name: "航班" },
      { model: Train, date_field: :departure_time, name: "火车", is_datetime: true }
    ]

    models_to_check.each do |config|
      model = config[:model]
      date_field = config[:date_field]
      name = config[:name]

      records = model.where(data_version: 0)
      next if records.empty?

      if config[:is_datetime]
        min_date = records.minimum(date_field)&.to_date
        max_date = records.maximum(date_field)&.to_date
      else
        min_date = records.minimum(date_field)
        max_date = records.maximum(date_field)
      end

      days_coverage = (max_date - min_date).to_i + 1 if min_date && max_date

      puts "#{name}数据:"
      puts "  日期范围: #{min_date} ~ #{max_date} (共 #{days_coverage} 天)"
      puts "  记录总数: #{records.count} 条"
      
      # 检查是否覆盖了冻结后的查询范围
      if min_date && max_date
        # 最坏情况：frozen_date = anchor_date + 6.days (第7天回拨前)
        # 验证器可能查询 frozen_date 到 frozen_date + max_query_offset.days
        worst_case_frozen = anchor_date + 6.days
        worst_case_query_end = worst_case_frozen + max_query_offset.days
        
        coverage_ok = (min_date <= anchor_date) && (max_date >= worst_case_query_end)
        status = coverage_ok ? "✅ 覆盖充足" : "⚠️  可能不足"
        puts "  覆盖评估: #{status}"
        
        unless coverage_ok
          puts "    期望最小日期: #{anchor_date} (实际: #{min_date})"
          puts "    期望最大日期: #{worst_case_query_end} (实际: #{max_date})"
        end
      end
      puts ""
    end

    puts "=" * 80
    puts "✅ FrozenTime 验证测试完成"
    puts "=" * 80
    puts ""
  end

  desc "查看当前 FrozenTime 状态"
  task status: :environment do
    puts ""
    puts "=" * 80
    puts "🕐 FrozenTime 当前状态"
    puts "=" * 80
    puts ""

    # 检查 FrozenAnchorTime 是否已定义
    if defined?(::FrozenAnchorTime)
      anchor_time = ::FrozenAnchorTime
      puts "✅ FrozenTime 已启用"
      puts ""
      puts "📅 基线数据生成时间: #{anchor_time.strftime('%Y-%m-%d %H:%M:%S %Z')}"
      puts ""

      # 显示当前时间信息
      real_now = Time.original_now_before_freeze
      frozen_now = Time.now
      frozen_today = Date.today
      frozen_current = Date.current

      elapsed_seconds = (real_now - anchor_time).to_f
      elapsed_days = (elapsed_seconds / 86400).to_f

      puts "🕒 真实当前时间: #{real_now.strftime('%Y-%m-%d %H:%M:%S %Z')}"
      puts "🕒 冻结后时间:   #{frozen_now.strftime('%Y-%m-%d %H:%M:%S %Z')}"
      puts ""
      puts "📅 Date.today:    #{Date.today} (#{Date.today.strftime('%A')})"
      puts "📅 Date.current:  #{Date.current} (#{Date.current.strftime('%A')})"
      puts ""
      puts "⏱️  距离基线时间: #{elapsed_days.round(2)} 天"

      if elapsed_seconds >= 604_800
        weeks_passed = (elapsed_seconds / 604_800).floor
        puts "🔄 时间已回拨:   #{weeks_passed} 周 (#{weeks_passed * 7} 天)"
      else
        puts "⏳ 未回拨 (距离首次回拨还有 #{(7 - elapsed_days).round(2)} 天)"
      end
    else
      puts "❌ FrozenTime 未启用"
      puts ""
      puts "可能的原因:"
      puts "  1. FREEZE_TIME=false 环境变量已设置"
      puts "  2. 当前为测试环境"
      puts "  3. 基线数据尚未加载"
      puts ""
      puts "💡 解决方法:"
      puts "  运行: rake validator:reset_baseline"
    end

    puts ""
    puts "=" * 80
    puts ""
  end
end
