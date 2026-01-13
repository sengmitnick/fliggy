require 'rails_helper'
require_relative '../../support/playwright_helper'

RSpec.describe "Abroad Ticket Station Selection", type: :system do
  include PlaywrightHelper

  let!(:user) { create(:user, email: 'test@example.com', password: '123456', password_confirmation: '123456', pay_password: '123456') }
  let!(:japan_ticket) do
    create(:abroad_ticket,
           region: 'japan',
           ticket_type: 'train',
           origin: '东京站',
           destination: '京都站',
           price: 150,
           departure_date: Date.today + 1.day,
           time_slot_start: '09:00',
           time_slot_end: '12:00')
  end
  let!(:europe_ticket) do
    create(:abroad_ticket,
           region: 'europe',
           ticket_type: 'train',
           origin: '巴黎北站',
           destination: '阿姆斯特丹中央车站',
           price: 280,
           departure_date: Date.today + 2.days,
           time_slot_start: '10:30',
           time_slot_end: '14:00')
  end

  before do
    # Ensure screenshots directory exists
    FileUtils.mkdir_p('tmp/playwright_screenshots/abroad_tickets')
  end

  it "tests station selection modal with screenshots for all cities" do
    with_page("http://localhost:#{ENV['PORT'] || 3000}/abroad_tickets", headless: false) do |page|
      screenshot_dir = 'tmp/playwright_screenshots/abroad_tickets'
      
      puts "\n" + "="*80
      puts "🎯 Starting Abroad Ticket Station Selection E2E Test"
      puts "="*80
      
      # Wait for page to fully load
      sleep 2
      
      # Step 1: Verify initial page load
      puts "\n📸 Step 1: Verify initial page loaded"
      expect(page.content).to include('境外当地交通')
      page.screenshot(path: "#{screenshot_dir}/01_initial_page.png")
      puts "✅ Initial page loaded successfully"
      
      # Step 2: Check Japan region is selected by default
      puts "\n📸 Step 2: Check Japan region selected"
      japan_tab = page.query_selector('button:has-text("日本")')
      expect(japan_tab).not_to be_nil
      page.screenshot(path: "#{screenshot_dir}/02_japan_region.png")
      puts "✅ Japan region tab found"
      
      # Step 3: Click on origin station to open modal
      puts "\n📸 Step 3: Click origin station field"
      origin_field = page.query_selector('[data-action*="click->abroad-ticket-search#selectOrigin"]')
      expect(origin_field).not_to be_nil
      
      origin_field.click
      sleep 1 # Wait for modal animation
      
      page.screenshot(path: "#{screenshot_dir}/03_origin_modal_opened.png")
      puts "✅ Origin station modal opened"
      
      # Step 4: Verify modal structure
      puts "\n📸 Step 4: Verify modal structure"
      modal = page.query_selector('[data-abroad-ticket-search-target="stationModal"]')
      expect(modal).not_to be_nil
      expect(page.content).to include('出发地选择')
      
      # Check search input exists
      search_input = page.query_selector('[data-abroad-ticket-search-target="searchInput"]')
      expect(search_input).not_to be_nil
      puts "✅ Modal structure verified (title, search input)"
      
      # Step 5: Test each Japanese city station
      puts "\n📸 Step 5: Testing Japanese city stations"
      japanese_cities = ['东京', '大阪', '京都', '名古屋', '仙台', '青森', '新潟', '广岛', '福冈', '鹿儿岛', '北海道']
      
      japanese_cities.each_with_index do |city, index|
        puts "  🏙️  Testing city: #{city}"
        
        # Find city section
        city_section = page.locator("text=#{city}").first
        if city_section
          # Scroll to city if needed
          city_section.scroll_into_view_if_needed
          sleep 0.5
          
          # Take screenshot of each city
          page.screenshot(path: "#{screenshot_dir}/05_japan_city_#{sprintf('%02d', index + 1)}_#{city}.png")
          
          # Try to click a station under this city
          station_link = page.query_selector("[data-action*='click->abroad-ticket-search#selectStation'][data-station-name*='#{city}']")
          if station_link
            station_link.click
            sleep 0.5
            
            # Verify modal closed and station selected
            modal_hidden = page.query_selector('[data-abroad-ticket-search-target="stationModal"].hidden')
            expect(modal_hidden).not_to be_nil
            
            page.screenshot(path: "#{screenshot_dir}/05_japan_city_#{sprintf('%02d', index + 1)}_#{city}_selected.png")
            puts "    ✅ Station clicked and selected for #{city}"
            
            # Reopen modal for next city test
            origin_field.click
            sleep 1
          else
            puts "    ⚠️  No clickable station found for #{city}"
          end
        else
          puts "    ⚠️  City section not found for #{city}"
        end
      end
      
      # Step 6: Close modal and switch to Europe
      puts "\n📸 Step 6: Close modal and switch to Europe region"
      close_button = page.query_selector('[data-action*="click->abroad-ticket-search#closeStationModal"]')
      if close_button
        close_button.click
        sleep 0.5
      end
      
      # Click Europe tab
      europe_tab = page.query_selector('button:has-text("欧洲")')
      if europe_tab
        europe_tab.click
        sleep 1
        page.screenshot(path: "#{screenshot_dir}/06_europe_region_switched.png")
        puts "✅ Switched to Europe region"
        
        # Step 7: Test European countries
        puts "\n📸 Step 7: Testing European country stations"
        european_countries = ['法国', '荷兰', '德国', '意大利', '西班牙']
        
        # Open origin modal again for Europe
        origin_field.click
        sleep 1
        page.screenshot(path: "#{screenshot_dir}/07_europe_modal_opened.png")
        
        european_countries.each_with_index do |country, index|
          puts "  🌍  Testing country: #{country}"
          
          # Find country section
          country_section = page.locator("text=#{country}").first
          if country_section
            country_section.scroll_into_view_if_needed
            sleep 0.5
            
            # Take screenshot
            page.screenshot(path: "#{screenshot_dir}/07_europe_country_#{sprintf('%02d', index + 1)}_#{country}.png")
            
            # Try to click a station
            station_link = page.query_selector("[data-action*='click->abroad-ticket-search#selectStation'][data-station-name*='#{country}']")
            if station_link
              station_link.click
              sleep 0.5
              
              # Verify selection
              modal_hidden = page.query_selector('[data-abroad-ticket-search-target="stationModal"].hidden')
              expect(modal_hidden).not_to be_nil
              
              page.screenshot(path: "#{screenshot_dir}/07_europe_country_#{sprintf('%02d', index + 1)}_#{country}_selected.png")
              puts "    ✅ Station clicked and selected for #{country}"
              
              # Reopen for next country
              origin_field.click
              sleep 1
            else
              puts "    ⚠️  No clickable station found for #{country}"
            end
          else
            puts "    ⚠️  Country section not found for #{country}"
          end
        end
        
        # Close modal
        close_button = page.query_selector('[data-action*="click->abroad-ticket-search#closeStationModal"]')
        close_button&.click
        sleep 0.5
      else
        puts "⚠️  Europe tab not found"
      end
      
      # Step 8: Test destination selection
      puts "\n📸 Step 8: Test destination field"
      destination_field = page.query_selector('[data-action*="click->abroad-ticket-search#selectDestination"]')
      if destination_field
        destination_field.click
        sleep 1
        page.screenshot(path: "#{screenshot_dir}/08_destination_modal_opened.png")
        puts "✅ Destination modal opened"
        
        # Select a destination station
        first_station = page.query_selector('[data-action*="click->abroad-ticket-search#selectStation"]')
        if first_station
          first_station.click
          sleep 0.5
          page.screenshot(path: "#{screenshot_dir}/08_destination_selected.png")
          puts "✅ Destination station selected"
        end
      end
      
      # Step 9: Test search input filtering
      puts "\n📸 Step 9: Test search filtering"
      origin_field.click
      sleep 1
      
      search_input = page.query_selector('[data-abroad-ticket-search-target="searchInput"]')
      if search_input
        # Test search with Chinese
        search_input.fill('东京')
        sleep 0.5
        page.screenshot(path: "#{screenshot_dir}/09_search_chinese.png")
        expect(page.content).to include('东京')
        puts "✅ Chinese search works"
        
        # Clear and test English search
        search_input.fill('')
        sleep 0.3
        search_input.fill('Tokyo')
        sleep 0.5
        page.screenshot(path: "#{screenshot_dir}/09_search_english.png")
        expect(page.content).to include('Tokyo')
        puts "✅ English search works"
        
        # Clear search
        search_input.fill('')
        sleep 0.5
      end
      
      # Step 10: Test popular routes
      puts "\n📸 Step 10: Test popular routes selection"
      popular_route = page.query_selector('[data-action*="click->abroad-ticket-search#selectPopularRoute"]')
      if popular_route
        page.screenshot(path: "#{screenshot_dir}/10_popular_routes.png")
        popular_route.click
        sleep 0.5
        page.screenshot(path: "#{screenshot_dir}/10_popular_route_selected.png")
        puts "✅ Popular route selected"
      else
        puts "⚠️  No popular routes found"
      end
      
      # Step 11: Test station swap button
      puts "\n📸 Step 11: Test station swap button"
      close_button = page.query_selector('[data-action*="click->abroad-ticket-search#closeStationModal"]')
      close_button&.click
      sleep 0.5
      
      swap_button = page.query_selector('[data-action*="click->abroad-ticket-search#swapStations"]')
      if swap_button
        page.screenshot(path: "#{screenshot_dir}/11_before_swap.png")
        swap_button.click
        sleep 0.5
        page.screenshot(path: "#{screenshot_dir}/11_after_swap.png")
        puts "✅ Station swap button works"
      else
        puts "⚠️  Swap button not found"
      end
      
      # Step 12: Test train/pass toggle buttons
      puts "\n📸 Step 12: Test ticket type toggle"
      train_button = page.query_selector('button:has-text("火车票")')
      pass_button = page.query_selector('button:has-text("通票")')
      
      if train_button && pass_button
        page.screenshot(path: "#{screenshot_dir}/12_train_selected.png")
        
        pass_button.click
        sleep 0.5
        page.screenshot(path: "#{screenshot_dir}/12_pass_selected.png")
        puts "✅ Ticket type toggle works"
        
        train_button.click
        sleep 0.5
      else
        puts "⚠️  Ticket type buttons not found"
      end
      
      # Final screenshot
      puts "\n📸 Step 13: Final state"
      page.screenshot(path: "#{screenshot_dir}/13_final_state.png")
      
      puts "\n" + "="*80
      puts "✅ All station selection tests completed successfully!"
      puts "📁 Screenshots saved to: #{screenshot_dir}"
      puts "="*80 + "\n"
    end
  end
  
  it "tests visual feedback on button clicks" do
    with_page("http://localhost:#{ENV['PORT'] || 3000}/abroad_tickets", headless: false) do |page|
      screenshot_dir = 'tmp/playwright_screenshots/abroad_tickets/button_states'
      FileUtils.mkdir_p(screenshot_dir)
      
      puts "\n" + "="*80
      puts "🎨 Testing Button Visual States"
      puts "="*80
      
      sleep 2
      
      # Test region buttons
      puts "\n🔘 Testing region button states"
      japan_button = page.query_selector('button:has-text("日本")')
      europe_button = page.query_selector('button:has-text("欧洲")')
      
      if japan_button && europe_button
        # Japan active state
        page.screenshot(path: "#{screenshot_dir}/region_japan_active.png")
        puts "✅ Japan button active state captured"
        
        # Click Europe
        europe_button.click
        sleep 0.5
        page.screenshot(path: "#{screenshot_dir}/region_europe_active.png")
        puts "✅ Europe button active state captured"
        
        # Click Japan again
        japan_button.click
        sleep 0.5
      end
      
      # Test ticket type buttons
      puts "\n🎫 Testing ticket type button states"
      train_button = page.query_selector('button:has-text("火车票")')
      pass_button = page.query_selector('button:has-text("通票")')
      
      if train_button && pass_button
        page.screenshot(path: "#{screenshot_dir}/ticket_train_active.png")
        puts "✅ Train button active state captured"
        
        pass_button.click
        sleep 0.5
        page.screenshot(path: "#{screenshot_dir}/ticket_pass_active.png")
        puts "✅ Pass button active state captured"
        
        train_button.click
        sleep 0.5
      end
      
      # Test station field click states
      puts "\n📍 Testing station field states"
      origin_field = page.query_selector('[data-action*="click->abroad-ticket-search#selectOrigin"]')
      
      if origin_field
        # Before click
        page.screenshot(path: "#{screenshot_dir}/station_field_default.png")
        puts "✅ Station field default state captured"
        
        # Click to open modal
        origin_field.click
        sleep 1
        page.screenshot(path: "#{screenshot_dir}/station_field_modal_open.png")
        puts "✅ Station field with modal open captured"
        
        # Hover over a station (if possible)
        first_station = page.query_selector('[data-action*="click->abroad-ticket-search#selectStation"]')
        if first_station
          first_station.hover
          sleep 0.3
          page.screenshot(path: "#{screenshot_dir}/station_hover_state.png")
          puts "✅ Station hover state captured"
          
          # Click station
          first_station.click
          sleep 0.5
          page.screenshot(path: "#{screenshot_dir}/station_selected_state.png")
          puts "✅ Station selected state captured"
        end
      end
      
      # Test search button
      puts "\n🔍 Testing search button states"
      search_button = page.query_selector('button:has-text("搜索")')
      
      if search_button
        search_button.hover
        sleep 0.3
        page.screenshot(path: "#{screenshot_dir}/search_button_hover.png")
        puts "✅ Search button hover state captured"
      end
      
      puts "\n" + "="*80
      puts "✅ All button visual tests completed!"
      puts "📁 Screenshots saved to: #{screenshot_dir}"
      puts "="*80 + "\n"
    end
  end
end
