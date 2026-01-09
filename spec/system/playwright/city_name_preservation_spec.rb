require 'rails_helper'
require 'support/playwright_helper'

RSpec.describe "City Name Preservation", type: :system do
  include PlaywrightHelper
  
  let(:hotels_url) { "http://localhost:3000/hotels" }
  
  it "preserves selected city name when switching to international tab" do
    with_page(hotels_url) do |page|
      # Wait for controllers to initialize
      page.wait_for_selector('[data-controller*="hotel-tabs"]', timeout: 5000)
      page.wait_for_selector('[data-controller*="city-selector"]', timeout: 5000)
      
      # Verify we start on domestic tab with default city
      domestic_tab = page.query_selector('[data-hotel-tabs-target="tab"][data-tab-type="domestic"]')
      expect(domestic_tab.evaluate("el => el.classList.contains('bg-white')")).to be true
      
      initial_city = page.query_selector('[data-city-selector-target="departure"]').text_content
      puts "Initial city: #{initial_city}"
      
      # Open city selector
      city_selector_button = page.query_selector('[data-action="click->city-selector#openDeparture"]')
      city_selector_button.click
      
      # Wait for modal to appear
      page.wait_for_selector('[data-city-selector-target="modal"]:not(.hidden)', timeout: 3000)
      
      # Switch to international tab in city selector
      international_tab = page.query_selector('[data-action="click->city-selector#showInternational"]')
      international_tab.click
      
      sleep 0.5
      
      # Select Macau (澳门)
      macau_button = page.query_selector('button[data-city-name="澳门"][data-international="true"]')
      expect(macau_button).not_to be_nil, "Macau button should exist in international city selector"
      
      puts "Clicking Macau button..."
      macau_button.click
      
      # Wait for page reload (hotel tab switch triggers page reload with new URL)
      sleep 2
      
      # Verify we're now on international tab
      page.wait_for_selector('[data-hotel-tabs-target="tab"][data-tab-type="international"]', timeout: 5000)
      international_hotel_tab = page.query_selector('[data-hotel-tabs-target="tab"][data-tab-type="international"]')
      expect(international_hotel_tab.evaluate("el => el.classList.contains('bg-white')")).to be true
      
      # CRITICAL: Verify city name is preserved as "澳门" (not reset to default)
      displayed_city = page.query_selector('[data-city-selector-target="departure"]').text_content
      puts "Displayed city after tab switch: #{displayed_city}"
      expect(displayed_city).to eq("澳门"), "City name should be '澳门' after switching tabs, but got '#{displayed_city}'"
      
      # Verify URL contains correct parameters
      current_url = page.url
      puts "Current URL: #{current_url}"
      expect(current_url).to include("location_type=international")
      expect(current_url).to include("city=%E6%BE%B3%E9%97%A8") # URL-encoded "澳门"
    end
  end
  
  it "preserves selected city name when switching from domestic to international tab manually" do
    with_page(hotels_url) do |page|
      page.wait_for_selector('[data-controller*="hotel-tabs"]', timeout: 5000)
      page.wait_for_selector('[data-controller*="city-selector"]', timeout: 5000)
      
      # Open city selector on domestic tab
      city_selector_button = page.query_selector('[data-action="click->city-selector#openDeparture"]')
      city_selector_button.click
      
      page.wait_for_selector('[data-city-selector-target="modal"]:not(.hidden)', timeout: 3000)
      
      # Select a domestic city first
      shenzhen_button = page.query_selector('button[data-city-name="深圳"]')
      shenzhen_button.click if shenzhen_button
      
      sleep 0.5
      
      # Now select an international city (Hong Kong)
      city_selector_button.click
      page.wait_for_selector('[data-city-selector-target="modal"]:not(.hidden)', timeout: 3000)
      
      international_tab = page.query_selector('[data-action="click->city-selector#showInternational"]')
      international_tab.click
      
      sleep 0.5
      
      hongkong_button = page.query_selector('button[data-city-name="香港"][data-international="true"]')
      expect(hongkong_button).not_to be_nil
      
      hongkong_button.click
      
      sleep 2
      
      # Verify city is Hong Kong after automatic tab switch
      displayed_city = page.query_selector('[data-city-selector-target="departure"]').text_content
      expect(displayed_city).to eq("香港"), "City name should be '香港' after switching tabs"
    end
  end
end
