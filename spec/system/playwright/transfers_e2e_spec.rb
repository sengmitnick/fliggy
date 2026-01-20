# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Transfers End-to-End Flow', type: :system do
  include PlaywrightHelper

  let(:user) { User.create!(email: 'transfer_test@example.com', password: 'password123', payment_password: '123456') }
  let!(:flight) do
    Flight.create!(
      flight_number: 'CA1357',
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
    TransferPackage.create!(
      name: '经济型',
      vehicle_category: 'economy_5',
      seats: 4,
      luggage: 2,
      provider: '专车',
      price: 120,
      original_price: 150,
      wait_time: 60,
      refund_policy: '条件退',
      features: ['准时接送', '司机5年驾龄'],
      priority: 1,
      is_active: true
    )
    
    TransferPackage.create!(
      name: '舒适型',
      vehicle_category: 'comfort_5',
      seats: 4,
      luggage: 2,
      provider: '专车',
      price: 180,
      original_price: 220,
      wait_time: 90,
      refund_policy: '随时退',
      features: ['准时接送', '司机8年驾龄', '免费等待30分钟'],
      priority: 2,
      is_active: true
    )
  end

  describe 'Complete Airport Transfer Booking Flow' do
    it 'completes full flow from homepage to success page', :aggregate_failures do
      with_page("#{Capybara.app_host}/", headless: true) do |page|
        # === STEP 1: Navigate from homepage to transfers ===
        puts "\n🔹 Step 1: Navigate from homepage to transfers"
        
        # Check if homepage has transfers button
        transfer_link = page.query_selector('a[href*="transfers"]')
        if transfer_link
          transfer_link.click
          page.wait_for_load_state('networkidle')
        else
          # Directly go to transfers
          page.goto("#{Capybara.app_host}/transfers")
        end
        
        check_for_errors(page, 'navigate_to_transfers')
        expect(page.url).to include('/transfers')
        puts "   ✓ Navigated to transfers page"
        
        # === STEP 2: Select airport pickup service ===
        puts "\n🔹 Step 2: Verify transfers index page"
        
        # Check page has key elements
        page_content = page.content
        expect(page_content.include?('接送机') || page_content.include?('接送火车')).to be true
        expect(page_content.include?('到机场接我') || page_content.include?('送我到机场')).to be true
        
        # Select "到机场接我" if not already selected
        if page.query_selector('text=到机场接我')
          pickup_btn = page.query_selector('text=到机场接我')
          pickup_btn.click if pickup_btn
          page.wait_for_timeout(300)
        end
        
        puts "   ✓ Transfers index page loaded correctly"
        
        # === STEP 3: Navigate to flight search page ===
        puts "\n🔹 Step 3: Navigate to flight search page"
        
        # Click "请选择机场" button to go to search_flights page
        airport_selector = page.query_selector('text=请选择机场')
        expect(airport_selector).not_to be_nil, "Airport selector button not found"
        airport_selector.click
        page.wait_for_load_state('networkidle')
        
        check_for_errors(page, 'flight_search_page')
        expect(page.url).to include('search_flights')
        puts "   ✓ Navigated to flight search page"
        
        # === STEP 4: Search flights by city ===
        puts "\n🔹 Step 4: Search flights by city"
        
        # Select departure city (北京)
        departure_btn = page.query_selector('[data-action="click->city-selector#openDeparture"]')
        if departure_btn
          departure_btn.click
          page.wait_for_timeout(300)
          
          # Wait for city modal to open
          modal = page.query_selector('[data-city-selector-target="modal"]')
          expect(modal).not_to be_nil
          
          # Select 北京 from popular cities
          beijing_btn = page.query_selector('button:has-text("北京")')
          beijing_btn.click if beijing_btn
          page.wait_for_timeout(200)
          
          # Click confirm button
          confirm_btn = page.query_selector('button:has-text("确认")')
          confirm_btn.click if confirm_btn
          page.wait_for_timeout(300)
        end
        
        # Select arrival city (上海)
        destination_btn = page.query_selector('[data-action="click->city-selector#openDestination"]')
        if destination_btn
          destination_btn.click
          page.wait_for_timeout(300)
          
          # Select 上海
          shanghai_btn = page.query_selector('button:has-text("上海")')
          shanghai_btn.click if shanghai_btn
          page.wait_for_timeout(200)
          
          # Confirm
          confirm_btn = page.query_selector('button:has-text("确认")')
          confirm_btn.click if confirm_btn
          page.wait_for_timeout(300)
        end
        
        # Submit search
        search_btn = page.query_selector('input[value="查询"], button:has-text("查询")')
        expect(search_btn).not_to be_nil, "Search button not found"
        search_btn.click
        page.wait_for_load_state('networkidle')
        
        check_for_errors(page, 'flight_search_results')
        puts "   ✓ Searched flights successfully"
        
        # === STEP 5: Select flight from results ===
        puts "\n🔹 Step 5: Select flight from results"
        
        # Verify flight appears in results
        page_content = page.content
        expect(page_content.include?(flight.flight_number) || page_content.include?('搜索结果')).to be true
        
        # Click first flight to return to index with flight_id
        flight_card = page.query_selector("a[href*='flight_id=#{flight.id}']")
        if flight_card.nil?
          # Try any flight link
          flight_card = page.query_selector('a[href*="flight_id="]')
        end
        
        expect(flight_card).not_to be_nil, "No flight card found in results"
        flight_card.click
        page.wait_for_load_state('networkidle')
        
        check_for_errors(page, 'return_to_index_with_flight')
        expect(page.url).to include('/transfers')
        page_url = page.url
        page_content = page.content
        expect(page_url.include?('flight_id=') || page_content.include?(flight.arrival_airport)).to be true
        puts "   ✓ Selected flight and returned to index page"
        
        # === STEP 6: Select location via modal ===
        puts "\n🔹 Step 6: Select dropoff location via modal"
        
        # Click location selector button to open modal (NOT navigate to page)
        location_btn = page.query_selector('[data-action="click->location-selector#openModal"]')
        expect(location_btn).not_to be_nil, "Location selector button not found"
        location_btn.click
        page.wait_for_timeout(500)
        
        # Verify modal opened (not page navigation)
        location_modal = page.query_selector('[data-location-selector-target="modal"]')
        expect(location_modal).not_to be_nil, "Location modal did not open"
        
        # Check modal has visible class removed
        modal_classes = location_modal.get_attribute('class')
        expect(modal_classes).not_to include('hidden'), "Modal is still hidden"
        
        # Select a popular location
        popular_location = page.query_selector('[data-location-name]')
        if popular_location
          popular_location.click
          page.wait_for_timeout(200)
          
          # Click confirm button in modal
          modal_confirm = page.query_selector('[data-action*="location-selector#confirm"]')
          modal_confirm.click if modal_confirm
          page.wait_for_timeout(300)
        end
        
        puts "   ✓ Selected location via modal"
        
        # === STEP 7: Navigate to packages page ===
        puts "\n🔹 Step 7: Navigate to packages selection"
        
        # Click "搜索接送机" button
        search_transfer_btn = page.query_selector('a:has-text("搜索接送机")')
        expect(search_transfer_btn).not_to be_nil, "Search transfer button not found"
        search_transfer_btn.click
        page.wait_for_load_state('networkidle')
        
        check_for_errors(page, 'packages_page')
        expect(page.url).to include('packages')
        puts "   ✓ Navigated to packages page"
        
        # === STEP 8: Verify packages displayed ===
        puts "\n🔹 Step 8: Verify packages are displayed"
        
        # Check packages exist
        page_content = page.content
        expect(page_content.include?('经济型') || page_content.include?('舒适型') || page_content.include?('套餐')).to be true
        
        package_cards = page.query_selector_all('.package-card, [data-package-id], a[href*="transfer_package_id"]')
        expect(package_cards.length).to be > 0, "No transfer packages found"
        puts "   ✓ Found #{package_cards.length} transfer packages"
        
        # === FINAL: Verify complete flow ===
        puts "\n✅ Complete transfers E2E flow verified successfully"
        puts "   - Homepage → Transfers index"
        puts "   - Index → Flight search page"
        puts "   - Search flights → Return to index with flight_id"
        puts "   - Select location via MODAL (not page navigation)"
        puts "   - Navigate to packages page"
        puts "   - Packages displayed correctly"
      end
    end
  end

  describe 'Location Modal Architecture' do
    it 'uses modal for location selection instead of page navigation' do
      with_page("#{Capybara.app_host}/transfers", headless: true) do |page|
        puts "\n🔹 Verify location selection uses modal, not page"
        
        check_for_errors(page, 'transfers_index')
        
        # Find location selector button
        location_btn = page.query_selector('[data-action*="location-selector#openModal"]')
        expect(location_btn).not_to be_nil, "Location selector button not found"
        
        # Click button
        current_url = page.url
        location_btn.click
        page.wait_for_timeout(500)
        
        # Verify URL did NOT change (modal opened, not page navigation)
        expect(page.url).to eq(current_url), "URL changed - location selection navigated to page instead of opening modal"
        
        # Verify modal is visible
        modal = page.query_selector('[data-location-selector-target="modal"]')
        expect(modal).not_to be_nil, "Location modal does not exist"
        
        modal_classes = modal.get_attribute('class')
        expect(modal_classes).not_to include('hidden'), "Modal should be visible but has 'hidden' class"
        
        # Verify modal has location options
        location_buttons = page.query_selector_all('[data-location-name]')
        expect(location_buttons.length).to be > 0, "No location options found in modal"
        
        puts "   ✓ Location selection correctly uses modal (not page navigation)"
        puts "   ✓ Modal contains #{location_buttons.length} location options"
      end
    end
  end

  describe 'Flight Search Return Flow' do
    it 'returns to index page after selecting flight' do
      with_page("#{Capybara.app_host}/transfers/search_flights?transfer_type=airport_pickup&service_type=from_airport", headless: true) do |page|
        puts "\n🔹 Verify flight selection returns to index"
        
        check_for_errors(page, 'flight_search_page')
        
        # Submit search to get results
        search_btn = page.query_selector('input[value="查询"]')
        if search_btn
          search_btn.click
          page.wait_for_load_state('networkidle')
        end
        
        # Find flight link
        flight_link = page.query_selector('a[href*="transfers?"]')
        if flight_link
          href = flight_link.get_attribute('href')
          
          # Verify link goes to transfers path (index), not select_location
          expect(href).to include('/transfers?')
          expect(href).not_to include('select_location'), "Flight link should return to index, not navigate to select_location page"
          expect(href).to include('flight_id='), "Flight link should include flight_id parameter"
          
          puts "   ✓ Flight link correctly points to transfers index"
          puts "   ✓ Link includes flight_id parameter"
        end
      end
    end
  end

  describe 'Airport Selection Architecture' do
    it 'uses page navigation for airport selection' do
      with_page("#{Capybara.app_host}/transfers", headless: true) do |page|
        puts "\n🔹 Verify airport selection uses page navigation"
        
        check_for_errors(page, 'transfers_index')
        
        # Find airport selector link (should be <a> tag, not button)
        airport_link = page.query_selector('a[href*="search_flights"]')
        expect(airport_link).not_to be_nil, "Airport selector should be a link to search_flights page"
        
        href = airport_link.get_attribute('href')
        expect(href).to include('search_flights'), "Airport link should navigate to search_flights page"
        
        puts "   ✓ Airport selection correctly uses page navigation (not modal)"
      end
    end
  end
end
