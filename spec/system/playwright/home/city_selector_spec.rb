# frozen_string_literal: true

require "rails_helper"

RSpec.describe "City Selector", type: :system do
  include PlaywrightHelper

  let(:hotels_url) { "http://localhost:3000/hotels" }

  it "automatically switches to international hotel tab when international city is selected" do
    with_page(hotels_url) do |page|
      # Wait for page load
      page.wait_for_selector('[data-controller*="hotel-tabs"]', timeout: 5000)
      
      # Verify we're on domestic tab initially
      domestic_tab = page.query_selector('[data-hotel-tabs-target="tab"][data-tab-type="domestic"]')
      expect(domestic_tab.evaluate("el => el.classList.contains('bg-white')")).to be true
      
      # Open city selector by clicking the departure city button
      city_selector_button = page.query_selector('[data-action="click->city-selector#openDeparture"]')
      expect(city_selector_button).not_to be_nil
      city_selector_button.click
      
      # Wait for modal to open
      page.wait_for_selector('[data-city-selector-target="modal"]:not(.hidden)', timeout: 3000)
      
      # Switch to international tab in city selector
      international_tab = page.query_selector('[data-action="click->city-selector#showInternational"]')
      expect(international_tab).not_to be_nil
      international_tab.click
      
      # Wait for international content
      page.wait_for_selector('[data-region-section="japan-korea"]', timeout: 3000)
      
      # Click an international city (e.g., Tokyo)
      tokyo_button = page.query_selector('button[data-city-name="东京"][data-international="true"]')
      expect(tokyo_button).not_to be_nil
      tokyo_button.click
      
      # Wait a bit for the event to propagate and modal to close
      sleep 1
      
      # Verify hotel tab switched to international
      international_hotel_tab = page.query_selector('[data-hotel-tabs-target="tab"][data-tab-type="international"]')
      expect(international_hotel_tab.evaluate("el => el.classList.contains('bg-white')")).to be true
    end
  end

  it "allows clicking sidebar region tabs to scroll to content sections" do
    with_page(hotels_url) do |page|
      # Open city selector
      city_selector_button = page.query_selector('[data-action="click->city-selector#openDeparture"]')
      expect(city_selector_button).not_to be_nil
      city_selector_button.click
      
      # Wait for modal
      page.wait_for_selector('[data-city-selector-target="modal"]:not(.hidden)', timeout: 3000)
      
      # Switch to international tab
      international_tab = page.query_selector('[data-action="click->city-selector#showInternational"]')
      expect(international_tab).not_to be_nil
      international_tab.click
      
      # Wait for international content
      page.wait_for_selector('[data-region-section="japan-korea"]', timeout: 3000)
      
      # Click the Japan-Korea region tab
      japan_korea_tab = page.query_selector('button[data-action="click->city-selector#scrollToRegion"][data-region="japan-korea"]')
      expect(japan_korea_tab).not_to be_nil
      japan_korea_tab.click
      
      # Wait a moment for styling to apply
      sleep 0.5
      
      # Verify tab styling changed (active state)
      expect(japan_korea_tab.evaluate("el => el.classList.contains('bg-white')")).to be true
      expect(japan_korea_tab.evaluate("el => el.classList.contains('font-bold')")).to be true
      
      # Click Southeast Asia tab
      southeast_asia_tab = page.query_selector('button[data-region="southeast-asia"]')
      expect(southeast_asia_tab).not_to be_nil
      southeast_asia_tab.click
      
      sleep 0.5
      
      # Verify it became active
      expect(southeast_asia_tab.evaluate("el => el.classList.contains('bg-white')")).to be true
    end
  end

  it "displays all expanded international cities organized by regions" do
    with_page(hotels_url) do |page|
      # Open city selector
      city_selector_button = page.query_selector('[data-action="click->city-selector#openDeparture"]')
      expect(city_selector_button).not_to be_nil
      city_selector_button.click
      
      # Switch to international tab
      international_tab = page.query_selector('[data-action="click->city-selector#showInternational"]')
      expect(international_tab).not_to be_nil
      international_tab.click
      
      # Wait for content
      page.wait_for_selector('[data-region-section="japan-korea"]', timeout: 3000)
      
      # Verify different region sections exist
      expect(page.query_selector('[data-region-section="hkmo"]')).not_to be_nil
      expect(page.query_selector('[data-region-section="japan-korea"]')).not_to be_nil
      expect(page.query_selector('[data-region-section="southeast-asia"]')).not_to be_nil
      expect(page.query_selector('[data-region-section="europe"]')).not_to be_nil
      expect(page.query_selector('[data-region-section="america"]')).not_to be_nil
      expect(page.query_selector('[data-region-section="oceania"]')).not_to be_nil
      
      # Verify some cities have data-international="true"
      tokyo = page.query_selector('button[data-city-name="东京"][data-international="true"]')
      expect(tokyo).not_to be_nil
      
      seoul = page.query_selector('button[data-city-name="首尔"][data-international="true"]')
      expect(seoul).not_to be_nil
    end
  end
end
