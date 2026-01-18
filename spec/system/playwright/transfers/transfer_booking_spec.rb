require 'rails_helper'
require 'playwright'

RSpec.describe 'Transfer Booking Flow', type: :system do
  include PlaywrightHelper

  let(:user) { User.create!(email: 'test@example.com', password: 'password', payment_password: '123456') }
  let(:flight) do
    Flight.create!(
      flight_number: 'CA1234',
      departure_city: '北京',
      arrival_city: '上海',
      departure_airport: '首都国际机场',
      arrival_airport: '虹桥机场',
      departure_time: 2.days.from_now.change(hour: 10, min: 0),
      arrival_time: 2.days.from_now.change(hour: 12, min: 30),
      flight_date: 2.days.from_now.to_date,
      price: 800,
      available_seats: 50
    )
  end
  let(:train) do
    Train.create!(
      train_number: 'G1234',
      departure_station: '北京南',
      arrival_station: '上海虹桥',
      departure_time: 3.days.from_now.change(hour: 9, min: 0),
      arrival_time: 3.days.from_now.change(hour: 14, min: 30),
      train_date: 3.days.from_now.to_date,
      price: 550,
      available_seats: 100
    )
  end

  before do
    # Create transfer packages
    TransferPackage.generate_default_packages
    
    # Create flights and trains
    flight
    train
    
    # Set up test environment
    setup_playwright
  end

  after do
    teardown_playwright
  end

  describe 'Airport Transfer Flow' do
    it 'completes full booking from homepage to order details' do
      # Step 1: Login
      page.goto("#{Capybara.app_host}/login")
      page.fill('input[name="session[email]"]', user.email)
      page.fill('input[name="session[password]"]', user.password)
      page.click('button[type="submit"]')
      expect(page).to have_text('登录成功')

      # Step 2: Navigate to transfers homepage
      page.goto("#{Capybara.app_host}/transfers")
      expect(page).to have_text('接送机')
      expect(page).to have_text('接送火车')

      # Step 3: Select airport pickup service
      page.click('text=机场接送')
      page.click('text=到机场接我')

      # Step 4: Search flights by city
      page.click('text=按城市选航班')
      page.fill('input[placeholder*="出发城市"]', '北京')
      page.fill('input[placeholder*="到达城市"]', '上海')
      page.click('button:has-text("搜索航班")')

      # Step 5: Select flight from list
      expect(page).to have_text(flight.flight_number)
      page.click(".flight-card:has-text('#{flight.flight_number}')")

      # Step 6: Select pickup location
      expect(page).to have_text('选择上车地点')
      expect(page).to have_text('下车地点')
      
      # Fill location from
      page.fill('input[name="location_from"]', '虹桥机场T2航站楼')
      
      # Fill location to
      page.fill('input[name="location_to"]', '静安区南京西路1000号')
      
      page.click('button:has-text("确认位置")')

      # Step 7: Select transfer package
      expect(page).to have_text('选择套餐')
      
      # Wait for packages to load
      page.wait_for_selector('.package-card')
      
      # Select first package
      first_package = page.query_selector('.package-card')
      first_package.click
      
      # Click book button
      page.click('button:has-text("立即预约")')

      # Step 8: Payment modal - enter password
      expect(page).to have_text('支付密码')
      page.fill('input[type="password"]', user.payment_password)
      page.click('button:has-text("确认支付")')

      # Step 9: Verify success page
      expect(page).to have_text('支付成功')
      expect(page).to have_text('实付金额')

      # Step 10: Go to order details
      page.click('text=订单详情')

      # Step 11: Verify order details page
      expect(page).to have_text('司机')
      expect(page).to have_text('接单')
      expect(page).to have_text(flight.flight_number)
      expect(page).to have_text('虹桥机场T2航站楼')
      expect(page).to have_text('静安区南京西路1000号')

      # Step 12: Verify order appears in bookings list
      page.goto("#{Capybara.app_host}/bookings")
      expect(page).to have_text('机场接机')
      expect(page).to have_text('虹桥机场T2航站楼')
    end

    it 'allows selecting flight by flight number' do
      # Login
      page.goto("#{Capybara.app_host}/login")
      page.fill('input[name="session[email]"]', user.email)
      page.fill('input[name="session[password]"]', user.password)
      page.click('button[type="submit"]')

      # Navigate to transfers
      page.goto("#{Capybara.app_host}/transfers")
      page.click('text=机场接送')

      # Search by flight number
      page.click('text=按航班号')
      page.fill('input[placeholder*="航班号"]', flight.flight_number)
      page.click('button:has-text("搜索")')

      # Verify flight found
      expect(page).to have_text(flight.flight_number)
      expect(page).to have_text(flight.departure_city)
      expect(page).to have_text(flight.arrival_city)
    end
  end

  describe 'Train Station Transfer Flow' do
    it 'completes train station pickup booking' do
      # Login
      page.goto("#{Capybara.app_host}/login")
      page.fill('input[name="session[email]"]', user.email)
      page.fill('input[name="session[password]"]', user.password)
      page.click('button[type="submit"]')

      # Navigate to transfers
      page.goto("#{Capybara.app_host}/transfers")
      page.click('text=接送火车')
      page.click('text=到车站接我')

      # Search trains by station
      page.click('text=按车站选')
      page.fill('input[placeholder*="出发站"]', '北京南')
      page.fill('input[placeholder*="到达站"]', '上海虹桥')
      page.click('button:has-text("搜索车次")')

      # Select train
      expect(page).to have_text(train.train_number)
      page.click(".train-card:has-text('#{train.train_number}')")

      # Select locations
      page.fill('input[name="location_from"]', '上海虹桥站南广场')
      page.fill('input[name="location_to"]', '徐汇区漕溪北路1000号')
      page.click('button:has-text("确认位置")')

      # Select package
      page.wait_for_selector('.package-card')
      first_package = page.query_selector('.package-card')
      first_package.click
      page.click('button:has-text("立即预约")')

      # Payment
      page.fill('input[type="password"]', user.payment_password)
      page.click('button:has-text("确认支付")')

      # Verify success
      expect(page).to have_text('支付成功')
      
      # Check details
      page.click('text=订单详情')
      expect(page).to have_text(train.train_number)
      expect(page).to have_text('上海虹桥站南广场')
    end
  end

  describe 'Order Management' do
    it 'allows canceling transfer order before payment' do
      # Create pending transfer
      transfer = Transfer.create!(
        user: user,
        transfer_type: 'airport_transfer',
        service_type: 'from_airport',
        location_from: '虹桥机场',
        location_to: '市区酒店',
        pickup_datetime: 2.days.from_now,
        passenger_name: '测试用户',
        passenger_phone: '13800138000',
        total_price: 120,
        status: 'pending'
      )

      # Login
      page.goto("#{Capybara.app_host}/login")
      page.fill('input[name="session[email]"]', user.email)
      page.fill('input[name="session[password]"]', user.password)
      page.click('button[type="submit"]')

      # Go to bookings
      page.goto("#{Capybara.app_host}/bookings")
      
      # Verify transfer appears
      expect(page).to have_text('机场接机')
      
      # Click order details
      page.click('text=查看详情')
      
      # Cancel order
      page.click('text=取消订单')
      page.on('dialog', ->(dialog) { dialog.accept })
      
      # Verify cancellation
      expect(page).to have_text('已取消')
    end

    it 'shows driver acceptance status after payment' do
      # Create paid transfer
      transfer = Transfer.create!(
        user: user,
        transfer_type: 'airport_transfer',
        service_type: 'from_airport',
        location_from: '虹桥机场',
        location_to: '市区酒店',
        pickup_datetime: 2.days.from_now,
        passenger_name: '测试用户',
        passenger_phone: '13800138000',
        total_price: 120,
        status: 'paid',
        driver_status: 'pending'
      )

      # Login
      page.goto("#{Capybara.app_host}/login")
      page.fill('input[name="session[email]"]', user.email)
      page.fill('input[name="session[password]"]', user.password)
      page.click('button[type="submit"]')

      # View order
      page.goto("#{Capybara.app_host}/transfers/#{transfer.id}")
      
      # Check initial status
      expect(page).to have_text('司机未接单').or(have_text('司机正在确认'))
      
      # Simulate driver acceptance
      transfer.update!(driver_status: 'accepted')
      page.reload
      
      # Verify updated status
      expect(page).to have_text('司机已接单')
    end
  end

  describe 'Integration with Bookings List' do
    it 'displays transfer orders alongside other order types' do
      # Create multiple order types
      flight_booking = Booking.create!(
        user: user,
        flight: flight,
        trip_type: 'one_way',
        total_price: 800,
        status: 'paid',
        passenger_name: '测试用户',
        passenger_phone: '13800138000'
      )
      
      transfer = Transfer.create!(
        user: user,
        transfer_type: 'airport_transfer',
        service_type: 'from_airport',
        location_from: '虹桥机场',
        location_to: '市区酒店',
        pickup_datetime: 2.days.from_now,
        passenger_name: '测试用户',
        passenger_phone: '13800138000',
        total_price: 120,
        status: 'paid'
      )

      # Login
      page.goto("#{Capybara.app_host}/login")
      page.fill('input[name="session[email]"]', user.email)
      page.fill('input[name="session[password]"]', user.password)
      page.click('button[type="submit"]')

      # View all orders
      page.goto("#{Capybara.app_host}/bookings")
      
      # Verify both orders appear
      expect(page).to have_text(flight.flight_number)
      expect(page).to have_text('机场接机')
      
      # Filter by upcoming
      page.click('text=未出行')
      expect(page).to have_text('机场接机')
    end
  end
end
