require 'rails_helper'
require_relative '../../../support/playwright_helper'

RSpec.describe 'Transfers Payment Flow', type: :system do
  include PlaywrightHelper

  let!(:user) do
    User.create!(
      email: 'test@example.com',
      password: 'password123',
      pay_password: '123456',
      balance: 1000.0
    )
  end

  let!(:flight) do
    Flight.create!(
      flight_number: 'HU4390',
      airline: '海南航空',
      departure_city: '北京',
      destination_city: '上海',
      departure_airport: '首都国际机场',
      arrival_airport: '虹桥国际机场',
      departure_time: 1.day.from_now.change(hour: 10, min: 35),
      arrival_time: 1.day.from_now.change(hour: 13, min: 45),
      flight_date: 1.day.from_now.to_date,
      price: 680,
      available_seats: 80
    )
  end

  let!(:transfer_package) do
    TransferPackage.create!(
      name: '经济5座',
      vehicle_category: 'comfort_5',
      seats: 4,
      luggage: 2,
      provider: '阳光出行',
      price: 80,
      original_price: 100,
      wait_time: 60,
      refund_policy: '条件退',
      features: ['准时接送', '司机5年驾龄'],
      priority: 1,
      is_active: true
    )
  end

  describe 'Payment Modal Auto-Trigger Flow' do
    it 'successfully creates transfer order and auto-opens payment modal', :aggregate_failures do
      with_authenticated_page("http://localhost:3000/transfers", user, headless: false) do |page|
        screenshots_dir = Rails.root.join('tmp', 'screenshots', 'transfers_payment')
        FileUtils.mkdir_p(screenshots_dir)

        # === STEP 1: Navigate to packages page ===
        puts "\n🔹 Step 1: Navigate to packages page"
        
        page.goto("http://localhost:3000/transfers/packages?transfer_type=airport_pickup&service_type=from_airport&location_to=土地堂东站&location_from=虹桥T2&flight_id=#{flight.id}")
        page.wait_for_timeout(1000)
        
        check_for_errors(page, 'packages_page')
        
        screenshot_path = screenshots_dir.join('01_packages_page.png')
        page.screenshot(path: screenshot_path.to_s)
        
        puts "   ✓ Packages page loaded"

        # === STEP 2: Click "立刻预约" button ===
        puts "\n🔹 Step 2: Click booking button to trigger modal"
        
        # Wait for the booking button to be available
        booking_button = page.wait_for_selector('text=立刻预约', state: 'visible', timeout: 5000)
        expect(booking_button).not_to be_nil
        
        booking_button.click
        page.wait_for_timeout(500)
        
        screenshot_path = screenshots_dir.join('02_booking_modal_opened.png')
        page.screenshot(path: screenshot_path.to_s)
        
        puts "   ✓ Booking modal opened"

        # === STEP 3: Fill booking form ===
        puts "\n🔹 Step 3: Fill booking form"
        
        # Check if modal is visible
        modal = page.query_selector('[data-booking-modal-target="modal"]')
        expect(modal).not_to be_nil
        
        # Fill passenger name
        name_input = page.query_selector('input[name="transfer[passenger_name]"]')
        name_input.fill('Demo User') if name_input
        
        # Fill phone number
        phone_input = page.query_selector('input[name="transfer[passenger_phone]"]')
        phone_input.fill('13800138000') if phone_input
        
        page.wait_for_timeout(500)
        
        screenshot_path = screenshots_dir.join('03_form_filled.png')
        page.screenshot(path: screenshot_path.to_s)
        
        puts "   ✓ Form filled"

        # === STEP 4: Submit booking ===
        puts "\n🔹 Step 4: Submit booking form"
        
        submit_button = page.query_selector('button[type="submit"]:has-text("确认预订")')
        expect(submit_button).not_to be_nil
        
        submit_button.click
        
        # Wait for navigation and page load
        page.wait_for_url(/\/transfers\/\d+\?pay_now=true/, timeout: 5000)
        page.wait_for_timeout(1500) # Wait for turbo:load and setTimeout
        
        check_for_errors(page, 'transfer_show_with_pay_now')
        
        screenshot_path = screenshots_dir.join('04_redirected_to_show.png')
        page.screenshot(path: screenshot_path.to_s)
        
        expect(page.url).to include('pay_now=true')
        puts "   ✓ Redirected to transfer show page with pay_now=true"

        # === STEP 5: Verify payment modal auto-opened ===
        puts "\n🔹 Step 5: Verify payment modal auto-opened"
        
        # Check if password modal is visible (auto-triggered)
        password_modal = page.wait_for_selector('[data-payment-confirmation-target="passwordModal"]', state: 'visible', timeout: 3000)
        expect(password_modal).not_to be_nil
        
        # Verify modal content
        modal_title = page.query_selector('text=请输入支付密码')
        expect(modal_title).not_to be_nil
        
        # Verify amount display
        amount_element = page.query_selector('[data-payment-confirmation-target="passwordAmount"]')
        expect(amount_element).not_to be_nil
        expect(amount_element.text_content).to eq('80')
        
        screenshot_path = screenshots_dir.join('05_payment_modal_auto_opened.png')
        page.screenshot(path: screenshot_path.to_s)
        
        puts "   ✓ Payment modal auto-opened successfully"
        puts "   ✓ Amount displayed: ¥80"

        # === STEP 6: Verify no console errors ===
        puts "\n🔹 Step 6: Verify no console errors"
        
        # Check console for errors
        console_errors = page.evaluate('() => window.__consoleErrors || []')
        password_modal_errors = console_errors.select { |e| e.include?('Password modal target not found') }
        
        expect(password_modal_errors).to be_empty, "Found 'Password modal target not found' errors: #{password_modal_errors.join(', ')}"
        
        puts "   ✓ No 'Password modal target not found' errors"

        # === FINAL SUMMARY ===
        puts "\n✅ Payment flow PASSED"
        puts "   Screenshots saved to: #{screenshots_dir}"
        puts "   ✓ Packages page loaded"
        puts "   ✓ Booking modal opened"
        puts "   ✓ Form submitted successfully"
        puts "   ✓ Redirected with pay_now=true"
        puts "   ✓ Payment modal auto-triggered without errors"
        puts "   ✓ No 'Password modal target not found' console errors"
      end
    end
  end

  describe 'Manual Payment Modal Trigger' do
    it 'opens payment modal when clicking pay button manually' do
      # Create a pending transfer order
      transfer = Transfer.create!(
        user: user,
        transfer_type: 'airport_pickup',
        service_type: 'from_airport',
        location_from: '虹桥T2',
        location_to: '土地堂东站',
        pickup_datetime: 1.day.from_now,
        flight_number: 'HU4390',
        passenger_name: 'Test User',
        passenger_phone: '13800138000',
        vehicle_type: '经济5座',
        provider_name: '阳光出行',
        total_price: 80.0,
        status: 'pending',
        transfer_package_id: transfer_package.id
      )

      with_authenticated_page("http://localhost:3000/transfers/#{transfer.id}", user, headless: false) do |page|
        screenshots_dir = Rails.root.join('tmp', 'screenshots', 'transfers_payment_manual')
        FileUtils.mkdir_p(screenshots_dir)

        puts "\n🔹 Manual Payment Modal Test"
        
        page.wait_for_timeout(1000)
        check_for_errors(page, 'transfer_show')
        
        screenshot_path = screenshots_dir.join('01_show_page.png')
        page.screenshot(path: screenshot_path.to_s)

        # Click payment button
        pay_button = page.wait_for_selector('text=立即支付', state: 'visible', timeout: 5000)
        expect(pay_button).not_to be_nil
        
        pay_button.click
        page.wait_for_timeout(500)
        
        # Verify modal opened
        password_modal = page.wait_for_selector('[data-payment-confirmation-target="passwordModal"]', state: 'visible', timeout: 3000)
        expect(password_modal).not_to be_nil
        
        screenshot_path = screenshots_dir.join('02_payment_modal_manual.png')
        page.screenshot(path: screenshot_path.to_s)
        
        puts "   ✓ Payment modal opened manually"
        puts "   ✓ Test PASSED"
      end
    end
  end
end
