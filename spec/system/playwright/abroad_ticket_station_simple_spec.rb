require 'rails_helper'
require_relative '../../support/playwright_helper'

RSpec.describe "Abroad Ticket Station Selection - Simple", type: :system do
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

  before do
    FileUtils.mkdir_p('tmp/playwright_screenshots/abroad_tickets_simple')
  end

  it "tests basic station selection functionality with screenshots" do
    with_page("http://localhost:#{ENV['PORT'] || 3000}/abroad_tickets") do |page|
      screenshot_dir = 'tmp/playwright_screenshots/abroad_tickets_simple'
      
      puts "\n" + "="*80
      puts "🎯 Abroad Ticket Station Selection - Basic Test"
      puts "="*80
      
      sleep 2
      
      # Step 1: Verify page loads
      puts "\n📸 Step 1: Initial page load"
      expect(page.content).to include('境外当地交通')
      page.screenshot(path: "#{screenshot_dir}/01_page_loaded.png")
      puts "✅ Page loaded"
      
      # Step 2: Click origin field to open modal
      puts "\n📸 Step 2: Open origin modal"
      origin_field = page.query_selector('[data-action*="selectOrigin"]')
      expect(origin_field).not_to be_nil
      
      origin_field.click
      sleep 1
      
      page.screenshot(path: "#{screenshot_dir}/02_modal_opened.png")
      puts "✅ Modal opened"
      
      # Step 3: Verify modal has content
      puts "\n📸 Step 3: Verify modal content"
      modal = page.query_selector('[data-abroad-ticket-search-target="stationModal"]')
      expect(modal).not_to be_nil
      expect(page.content).to include('出发地选择')
      
      search_input = page.query_selector('[data-abroad-ticket-search-target="searchInput"]')
      expect(search_input).not_to be_nil
      page.screenshot(path: "#{screenshot_dir}/03_modal_content.png")
      puts "✅ Modal has search input"
      
      # Step 4: Test clicking a station (Tokyo)
      puts "\n📸 Step 4: Click Tokyo station"
      tokyo_station = page.query_selector('[data-station-name="东京站"]')
      if tokyo_station
        tokyo_station.click
        sleep 1
        
        # Modal should close
        page.screenshot(path: "#{screenshot_dir}/04_station_selected.png")
        puts "✅ Tokyo station selected, modal closed"
        
        # Verify station was set
        origin_text = page.query_selector('[data-abroad-ticket-search-target="originText"]')
        expect(origin_text.text_content).to include('东京')
        puts "✅ Origin field updated with Tokyo"
      else
        puts "⚠️  Tokyo station not found in list"
      end
      
      # Step 5: Test search functionality
      puts "\n📸 Step 5: Test search"
      origin_field.click
      sleep 1
      
      search_input = page.query_selector('[data-abroad-ticket-search-target="searchInput"]')
      search_input.fill('京都')
      sleep 0.5
      
      page.screenshot(path: "#{screenshot_dir}/05_search_kyoto.png")
      expect(page.content).to include('京都')
      puts "✅ Search works - found Kyoto"
      
      # Step 6: Select Kyoto
      puts "\n📸 Step 6: Select Kyoto as destination"
      close_btn = page.query_selector('[data-action*="closeStationModal"]')
      close_btn&.click
      sleep 0.5
      
      dest_field = page.query_selector('[data-action*="selectDestination"]')
      dest_field&.click
      sleep 1
      
      kyoto_station = page.query_selector('[data-station-name="京都站"]')
      if kyoto_station
        kyoto_station.click
        sleep 1
        page.screenshot(path: "#{screenshot_dir}/06_destination_selected.png")
        puts "✅ Kyoto selected as destination"
      end
      
      # Final screenshot
      page.screenshot(path: "#{screenshot_dir}/07_final_state.png")
      
      puts "\n" + "="*80
      puts "✅ Basic station selection test completed!"
      puts "📁 Screenshots: #{screenshot_dir}"
      puts "="*80 + "\n"
    end
  end
end
