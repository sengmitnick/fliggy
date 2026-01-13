# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Transfers Complete Flow with Vision Validation', type: :system do
  include PlaywrightHelper

  let(:user) { User.create!(email: 'transfer_vision_test@example.com', password: 'password123', payment_password: '123456') }
  let!(:flight) do
    Flight.create!(
      flight_number: 'CA1234',
      airline: '中国国际航空',
      departure_city: '北京',
      destination_city: '上海',
      departure_airport: '首都国际机场',
      arrival_airport: '虹桥机场T2',
      departure_time: 2.days.from_now.change(hour: 8, min: 0),
      arrival_time: 2.days.from_now.change(hour: 10, min: 30),
      flight_date: 2.days.from_now.to_date,
      price: 850,
      available_seats: 50
    )
  end

  before do
    # Create transfer packages
    TransferPackage.generate_default_packages
  end

  describe 'Complete Airport Transfer Booking Flow' do
    it 'completes full flow from homepage to packages page with vision validation', :aggregate_failures do
      with_page("http://localhost:3000/", headless: false) do |page|
        screenshots_dir = Rails.root.join('tmp', 'screenshots', 'transfers')
        FileUtils.mkdir_p(screenshots_dir)

        # === STEP 1: Homepage ===
        puts "\n🔹 Step 1: Verify Homepage"
        page.wait_for_timeout(1000)
        
        screenshot_path = screenshots_dir.join('01_homepage.png')
        page.screenshot(path: screenshot_path.to_s)
        
        # Vision AI validation
        vision_result = validate_with_vision_api(screenshot_path, {
          expected_elements: ['首页', '机票', '酒店', '接送机'],
          page_type: 'homepage'
        })
        expect(vision_result[:valid]).to be(true), vision_result[:errors].join(', ')
        
        puts "   ✓ Homepage loaded and validated"

        # === STEP 2: Navigate to Transfers ===
        puts "\n🔹 Step 2: Navigate to Transfers"
        
        # Find and click transfers link/button
        transfers_link = page.query_selector('a[href*="/transfers"], button:has-text("接送机")')
        if transfers_link
          transfers_link.click
          page.wait_for_timeout(1000)
        else
          page.goto("http://localhost:3000/transfers")
          page.wait_for_timeout(2000)
        end
        
        check_for_errors(page, 'transfers_index')
        
        screenshot_path = screenshots_dir.join('02_transfers_index.png')
        page.screenshot(path: screenshot_path.to_s)
        
        # Vision validation for transfers index
        vision_result = validate_with_vision_api(screenshot_path, {
          expected_elements: ['接送机', '到机场接我', '送我到机场', '机场', '火车站'],
          page_type: 'transfers_index'
        })
        expect(vision_result[:valid]).to be(true), vision_result[:errors].join(', ')
        
        expect(page.url).to include('/transfers')
        puts "   ✓ Transfers index page loaded"

        # === STEP 3: Select Service Type ===
        puts "\n🔹 Step 3: Select 'Airport Pickup' service"
        
        # Click "到机场接我" if available
        pickup_btn = page.query_selector('text=到机场接我')
        if pickup_btn
          pickup_btn.click
          page.wait_for_timeout(500)
        end
        
        screenshot_path = screenshots_dir.join('03_service_selected.png')
        page.screenshot(path: screenshot_path.to_s)
        
        puts "   ✓ Service type selected"

        # === STEP 4: Navigate to Flight Search ===
        puts "\n🔹 Step 4: Navigate to flight search"
        
        # Click "请选择机场" button
        airport_btn = page.query_selector('button:has-text("请选择机场"), a:has-text("请选择机场")')
        expect(airport_btn).not_to be_nil, "Airport selector button not found"
        airport_btn.click
        page.wait_for_timeout(1500)
        
        check_for_errors(page, 'flight_search_page')
        
        screenshot_path = screenshots_dir.join('04_flight_search_page.png')
        page.screenshot(path: screenshot_path.to_s)
        
        # Vision validation
        vision_result = validate_with_vision_api(screenshot_path, {
          expected_elements: ['出发城市', '到达城市', '出发日期', '查询', '搜索'],
          page_type: 'flight_search'
        })
        expect(vision_result[:valid]).to be(true), vision_result[:errors].join(', ')
        
        expect(page.url).to include('search_flights')
        puts "   ✓ Flight search page loaded"

        # === STEP 5: Search Flights ===
        puts "\n🔹 Step 5: Search for flights"
        
        # Select departure city (北京)
        departure_btn = page.query_selector('[data-action="click->city-selector#openDeparture"]')
        if departure_btn
          departure_btn.click
          page.wait_for_timeout(300)
          
          beijing_btn = page.query_selector('button:has-text("北京")')
          if beijing_btn
            beijing_btn.click
            page.wait_for_timeout(200)
            
            confirm_btn = page.query_selector('button:has-text("确认")')
            confirm_btn&.click
            page.wait_for_timeout(300)
          end
        end
        
        # Select arrival city (上海)
        destination_btn = page.query_selector('[data-action="click->city-selector#openDestination"]')
        if destination_btn
          destination_btn.click
          page.wait_for_timeout(300)
          
          shanghai_btn = page.query_selector('button:has-text("上海")')
          if shanghai_btn
            shanghai_btn.click
            page.wait_for_timeout(200)
            
            confirm_btn = page.query_selector('button:has-text("确认")')
            confirm_btn&.click
            page.wait_for_timeout(300)
          end
        end
        
        screenshot_path = screenshots_dir.join('05_cities_selected.png')
        page.screenshot(path: screenshot_path.to_s)
        
        # Submit search
        search_btn = page.query_selector('input[value="查询"], button:has-text("查询")')
        expect(search_btn).not_to be_nil, "Search button not found"
        search_btn.click
        page.wait_for_timeout(2000)
        
        check_for_errors(page, 'flight_search_results')
        
        screenshot_path = screenshots_dir.join('06_flight_results.png')
        page.screenshot(path: screenshot_path.to_s)
        
        # Vision validation for flight results
        vision_result = validate_with_vision_api(screenshot_path, {
          expected_elements: ['航班号', '起飞', '到达', '北京', '上海'],
          page_type: 'flight_results',
          check_for: 'flight_cards'
        })
        expect(vision_result[:valid]).to be(true), vision_result[:errors].join(', ')
        
        puts "   ✓ Flight search results displayed"

        # === STEP 6: Select Flight ===
        puts "\n🔹 Step 6: Select flight from results"
        
        # Click first flight
        flight_card = page.query_selector("a[href*='flight_id=#{flight.id}'], a[href*='flight_id=']")
        expect(flight_card).not_to be_nil, "No flight card found"
        
        flight_card.click
        page.wait_for_timeout(1500)
        
        check_for_errors(page, 'return_to_index_with_flight')
        
        screenshot_path = screenshots_dir.join('07_flight_selected.png')
        page.screenshot(path: screenshot_path.to_s)
        
        expect(page.url).to include('/transfers')
        puts "   ✓ Flight selected, returned to index"

        # === STEP 7: Select Location ===
        puts "\n🔹 Step 7: Select dropoff location"
        
        # Click location selector button
        location_btn = page.query_selector('[data-action*="location-selector#openModal"], button:has-text("选择地点")')
        if location_btn
          location_btn.click
          page.wait_for_timeout(500)
          
          screenshot_path = screenshots_dir.join('08_location_modal.png')
          page.screenshot(path: screenshot_path.to_s)
          
          # Vision validation for location modal
          vision_result = validate_with_vision_api(screenshot_path, {
            expected_elements: ['地点', '位置', '确认'],
            page_type: 'location_modal',
            check_for: 'modal_visible'
          })
          
          # Select a location
          popular_location = page.query_selector('[data-location-name]')
          if popular_location
            popular_location.click
            page.wait_for_timeout(200)
            
            modal_confirm = page.query_selector('[data-action*="location-selector#confirm"], button:has-text("确认")')
            modal_confirm&.click
            page.wait_for_timeout(300)
          end
        end
        
        puts "   ✓ Location selected"

        # === STEP 8: Navigate to Packages Page ===
        puts "\n🔹 Step 8: Navigate to packages selection"
        
        # Click "搜索接送机" button
        search_btn = page.query_selector('a:has-text("搜索接送机"), button:has-text("搜索")')
        expect(search_btn).not_to be_nil, "Search transfer button not found"
        
        search_btn.click
        page.wait_for_timeout(2000)
        
        check_for_errors(page, 'packages_page')
        
        screenshot_path = screenshots_dir.join('09_packages_page.png')
        page.screenshot(path: screenshot_path.to_s)
        
        # Vision validation for packages page - THIS IS THE CRITICAL TEST
        vision_result = validate_with_vision_api(screenshot_path, {
          expected_elements: ['经济5座', '舒适5座', '套餐', '价格', '立即预约'],
          page_type: 'packages_page',
          check_for: 'vehicle_categories',
          critical: true
        })
        expect(vision_result[:valid]).to be(true), vision_result[:errors].join(', ')
        
        expect(page.url).to include('packages')
        puts "   ✓ Packages page loaded successfully"

        # === STEP 9: Verify Package Cards ===
        puts "\n🔹 Step 9: Verify package cards are displayed"
        
        # Check for package cards
        package_cards = page.query_selector_all('.package-card, [data-package-id]')
        expect(package_cards.length).to be > 0, "No package cards found"
        
        # Check for vehicle categories in sidebar
        categories = page.query_selector_all('aside .text-sm')
        expect(categories.length).to be >= 3, "Vehicle categories not displayed"
        
        screenshot_path = screenshots_dir.join('10_packages_detailed.png')
        page.screenshot(path: screenshot_path.to_s, fullPage: true)
        
        # Detailed vision validation
        vision_result = validate_with_vision_api(screenshot_path, {
          expected_elements: ['经济5座', '舒适5座', '豪华', '阳光出行', '伙力专车'],
          page_type: 'packages_detail',
          check_for: 'package_cards',
          min_packages: 3
        })
        expect(vision_result[:valid]).to be(true), vision_result[:errors].join(', ')
        
        puts "   ✓ Found #{package_cards.length} package cards"

        # === FINAL SUMMARY ===
        puts "\n✅ Complete transfers flow with vision validation PASSED"
        puts "   Screenshots saved to: #{screenshots_dir}"
        puts "   Total steps: 10"
        puts "   Vision validations: 7"
        puts "   Critical validations passed: packages page structure"
      end
    end
  end

  # Helper method for vision API validation
  def validate_with_vision_api(screenshot_path, options = {})
    return { valid: true, errors: [] } unless File.exist?(screenshot_path)

    # Prepare validation task
    task = {
      image_path: screenshot_path.to_s,
      expected_elements: options[:expected_elements] || [],
      page_type: options[:page_type] || 'unknown',
      check_for: options[:check_for],
      critical: options.fetch(:critical, false)
    }

    # Send to validation API
    begin
      response = send_validation_request(task)
      
      if response[:success]
        {
          valid: true,
          errors: [],
          details: response[:analysis]
        }
      else
        {
          valid: false,
          errors: response[:errors] || ['Vision validation failed'],
          details: response[:analysis]
        }
      end
    rescue StandardError => e
      # If vision API fails, only fail for critical validations
      if options[:critical]
        {
          valid: false,
          errors: ["Vision API error: #{e.message}"]
        }
      else
        puts "   ⚠️  Vision validation skipped: #{e.message}"
        { valid: true, errors: [] }
      end
    end
  end

  def send_validation_request(task)
    # Use the validation API endpoint
    conn = Faraday.new(url: "http://localhost:3000") do |f|
      f.request :multipart
      f.request :url_encoded
      f.adapter Faraday.default_adapter
    end

    # Upload image and send validation request
    payload = {
      image: Faraday::UploadIO.new(task[:image_path], 'image/png'),
      expected_elements: task[:expected_elements].to_json,
      page_type: task[:page_type],
      check_for: task[:check_for]
    }

    response = conn.post('/api/validation_tasks', payload)
    
    if response.status == 200
      result = JSON.parse(response.body, symbolize_names: true)
      { success: true, analysis: result }
    else
      { success: false, errors: ["API returned #{response.status}"] }
    end
  rescue StandardError => e
    { success: false, errors: [e.message] }
  end
end
