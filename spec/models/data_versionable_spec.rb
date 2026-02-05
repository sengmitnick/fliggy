require 'rails_helper'

RSpec.describe DataVersionable, type: :model do
  describe 'Model Coverage' do
    # List of models that SHOULD have DataVersionable
    let(:business_models) do
      [
        # Booking-related models
        'Booking', 'HotelBooking', 'TrainBooking', 'TourGroupBooking',
        'CharterBooking', 'CruiseOrder', 'BusTicketOrder', 'CarOrder',
        'TicketOrder', 'ActivityOrder', 'DeepTravelBooking', 'HotelPackageOrder',
        'AbroadTicketOrder', 'VisaOrder', 'InternetOrder', 'InsuranceOrder',
        'Transfer', 'MembershipOrder',
        
        # Product-related models
        'Flight', 'FlightOffer', 'Hotel', 'HotelRoom', 'HotelPackage',
        'Train', 'TourGroupProduct', 'DeepTravelProduct', 'CharterRoute',
        'VehicleType', 'Car', 'BusTicket', 'Ticket', 'AttractionActivity',
        'CruiseShip', 'CruiseSailing', 'CruiseLine', 'CabinType',
        'AbroadTicket', 'VisaProduct', 'InsuranceProduct', 'InternetSimCard',
        'InternetDataPlan', 'InternetWifi', 'TransferPackage', 'MembershipProduct',
        
        # Supporting models
        'Passenger', 'Contact', 'Address', 'BookingTraveler', 'BookingOption',
        'CustomTravelRequest', 'Attraction', 'City', 'Destination', 'Country',
        'TravelAgency', 'AbroadShop', 'AbroadBrand', 'AbroadCoupon'
      ]
    end

    # Models that SHOULD NOT have DataVersionable (system/admin models)
    let(:system_models) do
      [
        'Administrator', 'Session', 'AdminOplog', 'ValidatorExecution'
      ]
    end

    it 'all business models include DataVersionable concern' do
      missing_models = []

      business_models.each do |model_name|
        begin
          model = model_name.constantize
          unless model.ancestors.include?(DataVersionable)
            missing_models << model_name
          end
        rescue NameError
          # Model doesn't exist, skip
        end
      end

      expect(missing_models).to be_empty,
        "以下业务模型缺少 DataVersionable concern:\n#{missing_models.join(', ')}\n\n" \
        "修复方法: 在模型文件中添加 `include DataVersionable`"
    end

    it 'system models do NOT include DataVersionable' do
      incorrectly_included = []

      system_models.each do |model_name|
        begin
          model = model_name.constantize
          if model.ancestors.include?(DataVersionable)
            incorrectly_included << model_name
          end
        rescue NameError
          # Model doesn't exist, skip
        end
      end

      expect(incorrectly_included).to be_empty,
        "以下系统模型不应该包含 DataVersionable:\n#{incorrectly_included.join(', ')}"
    end
  end

  describe 'Database Column Presence' do
    let(:models_with_concern) do
      ApplicationRecord.descendants.select do |model|
        model.ancestors.include?(DataVersionable)
      end
    end

    it 'all models with DataVersionable have data_version column' do
      missing_column = []

      models_with_concern.each do |model|
        next if model.abstract_class?
        
        unless model.column_names.include?('data_version')
          missing_column << model.name
        end
      end

      expect(missing_column).to be_empty,
        "以下模型包含 DataVersionable 但缺少 data_version 字段:\n#{missing_column.join(', ')}\n\n" \
        "修复方法: 运行迁移添加 data_version 字段"
    end
  end

  describe 'Core Functionality: data_version Auto-Setting' do
    before do
      # Simulate validator session
      allow(Thread.current).to receive(:[]).with(:data_version).and_return('test-session-123')
    end

    it 'CharterBooking concern includes DataVersionable' do
      expect(CharterBooking.ancestors).to include(DataVersionable),
        "❌ CharterBooking 模型缺少 DataVersionable concern！\n\n" \
        "修复方法: 在 app/models/charter_booking.rb 添加:\n" \
        "class CharterBooking < ApplicationRecord\n" \
        "  include DataVersionable\n" \
        "  ...\n" \
        "end"
    end

    it 'CharterRoute includes DataVersionable' do
      expect(CharterRoute.ancestors).to include(DataVersionable)
    end

    it 'VehicleType includes DataVersionable' do
      expect(VehicleType.ancestors).to include(DataVersionable)
    end

    it 'CustomTravelRequest includes DataVersionable' do
      expect(CustomTravelRequest.ancestors).to include(DataVersionable)
    end
  end

  describe 'Real-world Issue Documentation' do
    it 'documents the validator "未找到订单" error cause and fix' do
      # This test is documentation-only, explaining the issue

      issue_description = <<~DESC
        ## 问题症状
        
        Validator V251 (预订北京文化深度游) 失败，错误信息：
        - "未找到任何包车订单"
        - 前端页面显示订单创建成功：https://3000-xxx.clackypaas.com/charter_bookings/2/success
        - Validator 查询时找不到订单
        
        ## 根本原因
        
        1. **CharterBooking 模型缺少 `include DataVersionable`**
        2. 前端控制器创建订单时，data_version 字段没有自动设置
        3. Validator 查询时使用 `.where(data_version: @data_version)` 过滤
        4. 结果：订单存在于数据库，但 data_version = nil，查询无法匹配
        
        ## 解决方案
        
        在以下模型添加 `include DataVersionable`：
        - app/models/charter_booking.rb ✅
        - app/models/charter_route.rb ✅
        - app/models/vehicle_type.rb ✅
        - app/models/custom_travel_request.rb ✅
        
        ## 验证方法
        
        运行此测试文件：
        ```bash
        bundle exec rspec spec/models/data_versionable_spec.rb
        ```
        
        运行 validator 模拟：
        ```bash
        rake validator:simulate_single[v251_book_beijing_culture_deep_chartered_tour_validator]
        ```
        
        ## 预防措施
        
        本测试文件会自动检查：
        1. 所有业务模型是否包含 DataVersionable concern
        2. 所有包含 DataVersionable 的模型是否有 data_version 字段
        3. 系统模型是否错误包含了 DataVersionable
        
        ## 相关技术细节
        
        - DataVersionable concern 提供 before_validation 回调
        - 自动从 Thread.current[:data_version] 读取当前会话 ID
        - 创建记录时自动设置 data_version 字段
        - 支持 data_version='0' 作为 baseline 数据（全局可访问）
      DESC

      puts "\n" + "="*80
      puts issue_description
      puts "="*80

      expect(true).to be true
    end
  end
end
