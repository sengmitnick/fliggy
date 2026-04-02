# frozen_string_literal: true

# FrozenTime Initializer
#
# 解决问题：
#   部署时，数据包以 Date.current 为基准生成未来 21 天的数据。
#   部署超过 21 天后，验证器 prepare 中的 Date.current + N.days 超出数据范围，
#   导致报错（如 "数据包缺少上海出发的邮轮班次"）。
#
# 解决方案：
#   在 Rails 启动时，通过 monkey-patch Time.now / Date.today / DateTime.now，
#   将服务感知到的"当前时间"冻结到基线数据生成时的日期。
#   无论实际经过多少天，验证器始终认为"今天"是部署那一天。
#
# 控制方式：
#   - 默认启用（模拟环境的核心需求）
#   - 设置 FREEZE_TIME=false 可以关闭（例如本地调试真实时间时）
#
# 锚点选取：
#   取数据库中 data_version=0 的 City 记录的 created_at，
#   作为基线数据生成时的时间戳。City 是所有数据包的基础依赖。

Rails.application.config.after_initialize do
  # 允许通过环境变量关闭（FREEZE_TIME=false 时跳过）
  next if ENV['FREEZE_TIME'] == 'false'

  # 跳过测试环境（测试自有时间控制机制）
  next if Rails.env.test?

  begin
    # 确保表存在（避免在迁移过程中出错）
    next unless ActiveRecord::Base.connection.table_exists?('cities')

    # 查找基线数据的创建时间（data_version=0 的第一条 City 记录）
    anchor_record = City.where(data_version: 0).order(:created_at).first

    unless anchor_record
      # 基线数据尚未加载（首次部署期间），跳过冻结
      # validator_baseline.rb 会在同一次 after_initialize 中加载基线数据，
      # 下次重启时 frozen_time.rb 将正常冻结
      Rails.logger.info '[FrozenTime] 基线数据尚未存在，跳过时间冻结（将在下次重启时生效）'
      next
    end

    # 计算时间偏移量：当前真实时间 - 基线数据创建时间
    real_now = Time.now
    anchor_time = anchor_record.created_at
    time_offset_seconds = (real_now - anchor_time).to_f

    frozen_date = anchor_time.to_date

    puts ''
    puts '=' * 70
    puts '🕐 FrozenTime: 动态时间冻结已启用 (长效模式)'
    puts "   基线数据生成时间: #{anchor_time.strftime('%Y-%m-%d %H:%M:%S %Z')}"
    puts '   机制: 系统长时间运行时，超过7天自动回退整周，'
    puts '         使得服务感知的"今天"永远在基线数据生成后的 0~6 天内，'
    puts '         完美保持真实的星期几（周末仍是周末），且永远不过期。'
    puts '=' * 70
    puts ''

    # == Monkey-patch 开始 ==

    # 保存基准时间到常量供 patch 使用
    ::FrozenAnchorTime = anchor_time.freeze unless defined?(::FrozenAnchorTime)

    # 1. Patch Time.now
    # 动态计算经过了多少整周（以7天为单位回拨），保证"服务器不重启"的情况下时间仍然被冻结。
    Time.class_eval do
      class << self
        alias_method :original_now_before_freeze, :now unless method_defined?(:original_now_before_freeze)

        def now
          real_now = original_now_before_freeze
          elapsed_seconds = (real_now - ::FrozenAnchorTime).to_f

          if elapsed_seconds >= 604_800 # 超过7天
            weeks_passed = (elapsed_seconds / 604_800).floor
            offset_seconds = weeks_passed * 604_800
            real_now - offset_seconds
          else
            real_now
          end
        end
      end
    end

    # 2. Patch Date.today（使 Date.today 与 patched Time.now 一致）
    Date.class_eval do
      class << self
        alias_method :original_today_before_freeze, :today unless method_defined?(:original_today_before_freeze)

        def today
          ::Time.now.to_date
        end
      end
    end

    # 3. Patch DateTime.now
    DateTime.class_eval do
      class << self
        alias_method :original_now_before_freeze, :now unless method_defined?(:original_now_before_freeze)

        def now
          ::Time.now.to_datetime
        end
      end
    end

    # 4. Patch ActiveSupport::TimeZone#now 使 Time.current / Date.current 正确工作
    #    Rails 的 Time.current 调用 Time.zone.now，Time.zone.now 是 ActiveSupport::TimeZone 的实例方法。
    #    patch 它使其调用已经 patch 过的 Time.now，再转换为时区时间。
    ActiveSupport::TimeZone.class_eval do
      unless method_defined?(:original_now_before_freeze)
        alias_method :original_now_before_freeze, :now
      end

      def now
        ::Time.now.in_time_zone(self)
      end
    end

    # == Monkey-patch 结束 ==

    Rails.logger.info "[FrozenTime] 时间已冻结到 #{frozen_date}"

  rescue StandardError => e
    # 冻结失败不应影响应用启动
    Rails.logger.error "[FrozenTime] 初始化失败: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
  end
end
