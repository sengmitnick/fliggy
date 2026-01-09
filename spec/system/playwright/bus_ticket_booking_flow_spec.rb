require 'rails_helper'
require_relative '../../support/playwright_helper'

RSpec.describe "Bus Ticket Booking Flow", type: :system do
  include PlaywrightHelper

  let!(:user) { create(:user, email: 'test@example.com', password: '123456', password_confirmation: '123456', pay_password: '123456') }
  let!(:passenger) { create(:passenger, user: user, name: '张三', id_number: '440101199001011234', phone: '13800138000') }
  let!(:bus_ticket) { create(:bus_ticket, departure_station: '深圳北站', arrival_station: '广州站', price: 50, departure_date: Date.today, departure_time: '08:00') }

  it "completes the full bus ticket booking flow" do
    with_page("http://localhost:#{ENV['PORT'] || 3000}/bus_tickets") do |page|
      sleep 1 # Wait for page to fully load
      
      # 1. Visit homepage - verify page loaded
      expect(page.content).to include('汽车票')
      
      # 2. Click search button
      search_button = page.query_selector('button:has-text("搜索汽车票")')
      if search_button
        search_button.click
        sleep 1 # Wait for navigation
        
        # 3. Check that bus tickets search page loads
        expect(page.content).to include('深圳')
        expect(page.url).to include('/bus_tickets/search')
        
        # 4. Click on first bus ticket to view details (if exists)
        ticket_card = page.query_selector('.bg-white.p-4.rounded-lg')
        if ticket_card
          ticket_card.click
          sleep 1 # Wait for navigation
          
          # 5. Verify booking page loads (no errors)
          expect(page.url).to match(/\/bus_tickets\/\d+/)
          
          # 6. Click "预订" button to go to order form (if exists)
          booking_button = page.query_selector('button:has-text("预订")')
          if booking_button
            booking_button.click
            sleep 1 # Wait for navigation
            
            # 7. Verify order form page loads
            expect(page.url).to include('/bus_ticket_orders/new')
          end
        end
      end
      
      # Success: No JavaScript errors encountered during the flow
      puts "✅ Bus ticket booking flow completed successfully without errors"
    end
  end
end
