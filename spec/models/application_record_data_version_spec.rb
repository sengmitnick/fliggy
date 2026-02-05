# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationRecord, type: :model do
  describe 'Global DataVersionable Middleware' do
    # 排除列表：这些模型不需要 data_version 字段
    # 1. 系统/管理模型（非业务数据）
    # 2. ActiveStorage 内部模型
    let(:excluded_models) do
      [
        'Administrator',           # 管理员账号（系统模型）
        'Session',                 # 用户会话（系统模型）
        'AdminOplog',              # 管理员操作日志（系统模型）
        'ValidatorExecution',      # 验证器执行记录（系统模型）
        'ActiveStorage::Blob',     # ActiveStorage 内部模型
        'ActiveStorage::Attachment', # ActiveStorage 内部模型
        'ActiveStorage::VariantRecord' # ActiveStorage 内部模型
      ]
    end

    it '所有 ApplicationRecord 子类都有 data_version 字段' do
      # 获取所有继承 ApplicationRecord 的模型
      all_models = ApplicationRecord.descendants.reject(&:abstract_class?)
      
      # 过滤掉排除列表中的模型
      business_models = all_models.reject { |model| excluded_models.include?(model.name) }
      
      # 检查每个模型是否有 data_version 字段
      missing_column_models = []
      
      business_models.each do |model|
        # 检查表是否存在（避免在迁移过程中出错）
        next unless ActiveRecord::Base.connection.table_exists?(model.table_name)
        
        # 检查是否有 data_version 字段
        unless model.column_names.include?('data_version')
          missing_column_models << {
            model: model.name,
            table: model.table_name
          }
        end
      end

      # 生成详细的错误信息
      if missing_column_models.any?
        error_lines = []
        error_lines << ""
        error_lines << "=" * 80
        error_lines << "以下模型缺少 data_version 字段:"
        error_lines << "=" * 80
        error_lines << ""
        
        missing_column_models.each do |info|
          error_lines << "  模型: #{info[:model]}"
          error_lines << "  表名: #{info[:table]}"
          error_lines << "  修复命令:"
          error_lines << "  rails g migration AddDataVersionTo#{info[:model].pluralize} data_version:string:default='0':limit=50"
          error_lines << "  rails db:migrate"
          error_lines << ""
        end
        
        error_lines << "=" * 80
        error_lines << "为什么需要 data_version 字段？"
        error_lines << "=" * 80
        error_lines << "ApplicationRecord 已全局启用 DataVersionable 中间件。"
        error_lines << "所有业务模型都需要 data_version 字段来支持："
        error_lines << "1. 验证器会话隔离（每个验证器看到独立的数据）"
        error_lines << "2. 基线数据共享（data_version='0' 的数据全局可见）"
        error_lines << "3. 自动清理测试数据（通过 data_version 批量删除）"
        error_lines << "=" * 80
        
        error_message = error_lines.join("\n")
      end

      expect(missing_column_models).to be_empty, error_message
    end

    it 'ApplicationRecord 已全局包含 DataVersionable' do
      expect(ApplicationRecord.ancestors).to include(DataVersionable),
        "ApplicationRecord 缺少 DataVersionable concern！\n\n" \
        "修复方法: 在 app/models/application_record.rb 添加:\n" \
        "class ApplicationRecord < ActiveRecord::Base\n" \
        "  primary_abstract_class\n" \
        "  include DataVersionable\n" \
        "  ...\n" \
        "end"
    end

    it '所有业务模型自动继承 DataVersionable 功能' do
      # 测试一个示例模型
      expect(InsuranceOrder.ancestors).to include(DataVersionable),
        "InsuranceOrder 应该自动继承 DataVersionable（通过 ApplicationRecord）"
      
      expect(User.ancestors).to include(DataVersionable),
        "User 应该自动继承 DataVersionable（通过 ApplicationRecord）"
    end

    it '排除的系统模型不应该有 data_version 字段' do
      excluded_models.each do |model_name|
        # 跳过 ActiveStorage 模型（它们不继承 ApplicationRecord，且需要 storage.yml 配置）
        next if model_name.start_with?('ActiveStorage::')
        
        begin
          model = model_name.constantize
          
          # 检查表是否存在
          next unless ActiveRecord::Base.connection.table_exists?(model.table_name)
          
          # 这些模型虽然继承 ApplicationRecord，但不应该有 data_version
          # （它们是系统模型，不是业务数据）
          if model.column_names.include?('data_version')
            fail "#{model_name} 是系统模型，不应该有 data_version 字段！\n" \
                 "系统模型应该排除在 DataVersionable 机制之外。\n" \
                 "请运行迁移移除该字段。"
          end
        rescue NameError
          # 模型不存在，跳过
        end
      end
    end
  end

  describe 'DataVersionable 中间件功能验证' do
    it '创建记录时自动设置 data_version' do
      # 设置测试会话
      ActiveRecord::Base.connection.execute("SET app.data_version = 'test-middleware-123'")
      
      # 创建测试用户和产品
      user = User.unscoped.first || User.create!(
        email: 'test@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        verified: true,
        data_version: '0'
      )
      
      product = InsuranceProduct.unscoped.where(data_version: '0').first || InsuranceProduct.create!(
        name: 'Test Insurance',
        company: 'Test Company',
        product_type: 'domestic',
        code: 'TEST001',
        price_per_day: 30.0,
        min_days: 1,
        max_days: 365,
        active: true,
        data_version: '0'
      )
      
      # 创建测试记录
      order = InsuranceOrder.create!(
        user: user,
        insurance_product: product,
        start_date: Date.today,
        end_date: Date.today + 3,
        days: 3,
        unit_price: 30.0,
        quantity: 1,
        total_price: 90.0,
        status: 'pending'
      )
      
      # 验证 data_version 自动设置
      expect(order.data_version).to eq('test-middleware-123')
      
      # 清理
      order.delete
    end

    it '查询时自动过滤 data_version' do
      # 准备测试数据
      ActiveRecord::Base.connection.execute("SET app.data_version = '0'")
      
      user = User.unscoped.first || User.create!(
        email: 'test@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        verified: true,
        data_version: '0'
      )
      
      product = InsuranceProduct.unscoped.where(data_version: '0').first || InsuranceProduct.create!(
        name: 'Test Insurance',
        company: 'Test Company',
        product_type: 'domestic',
        code: 'TEST001',
        price_per_day: 30.0,
        min_days: 1,
        max_days: 365,
        active: true,
        data_version: '0'
      )
      
      # 创建两个不同 data_version 的记录
      ActiveRecord::Base.connection.execute("SET app.data_version = 'session-X'")
      order_x = InsuranceOrder.create!(
        user: user,
        insurance_product: product,
        start_date: Date.today,
        end_date: Date.today + 3,
        days: 3,
        unit_price: 30.0,
        quantity: 1,
        total_price: 90.0,
        status: 'pending'
      )
      
      ActiveRecord::Base.connection.execute("SET app.data_version = 'session-Y'")
      order_y = InsuranceOrder.create!(
        user: user,
        insurance_product: product,
        start_date: Date.today,
        end_date: Date.today + 3,
        days: 3,
        unit_price: 30.0,
        quantity: 1,
        total_price: 90.0,
        status: 'pending'
      )
      
      # 在 session-X 上下文查询
      ActiveRecord::Base.connection.execute("SET app.data_version = 'session-X'")
      found_in_x = InsuranceOrder.where(id: [order_x.id, order_y.id]).pluck(:id)
      expect(found_in_x).to contain_exactly(order_x.id)
      expect(found_in_x).not_to include(order_y.id)
      
      # 在 session-Y 上下文查询
      ActiveRecord::Base.connection.execute("SET app.data_version = 'session-Y'")
      found_in_y = InsuranceOrder.where(id: [order_x.id, order_y.id]).pluck(:id)
      expect(found_in_y).to contain_exactly(order_y.id)
      expect(found_in_y).not_to include(order_x.id)
      
      # 清理
      InsuranceOrder.unscoped.where(id: [order_x.id, order_y.id]).delete_all
    end

    it '基线数据（data_version=0）在所有会话中可见' do
      # 准备基线产品
      ActiveRecord::Base.connection.execute("SET app.data_version = '0'")
      
      baseline_product = InsuranceProduct.unscoped.where(data_version: '0').first || InsuranceProduct.create!(
        name: 'Baseline Insurance',
        company: 'Baseline Company',
        product_type: 'domestic',
        code: 'BASELINE001',
        price_per_day: 30.0,
        min_days: 1,
        max_days: 365,
        active: true,
        data_version: '0'
      )
      
      expect(baseline_product.data_version).to eq('0')
      
      # 在不同会话中查询基线数据
      ActiveRecord::Base.connection.execute("SET app.data_version = 'session-test-1'")
      found_in_session1 = InsuranceProduct.find_by(id: baseline_product.id)
      expect(found_in_session1).not_to be_nil
      
      ActiveRecord::Base.connection.execute("SET app.data_version = 'session-test-2'")
      found_in_session2 = InsuranceProduct.find_by(id: baseline_product.id)
      expect(found_in_session2).not_to be_nil
    end
  end
end
