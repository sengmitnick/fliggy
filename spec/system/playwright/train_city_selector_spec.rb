require 'rails_helper'
require 'playwright'

RSpec.describe 'Train City Selector', type: :system do
  include PlaywrightHelper

  it 'opens city selector modal when clicking departure city' do
    with_page('http://localhost:3000/trains') do |page|
      # Wait for page to load
      page.wait_for_selector('[data-controller~="train-city-selector"]', timeout: 5000)
      
      # Verify modal is initially hidden
      modal = page.query_selector('[data-train-city-selector-target="modal"]')
      expect(modal).not_to be_nil
      expect(modal.evaluate('el => el.classList.contains("hidden")')).to be true
      
      # Debug: Check modal's parent structure
      modal_info = page.evaluate('() => {
        const modal = document.querySelector("[data-train-city-selector-target=\"modal\"]");
        const controller = document.querySelector("[data-controller~=\"train-city-selector\"]");
        if (!modal || !controller) return { modal: !!modal, controller: !!controller };
        return {
          modal: true,
          controller: true,
          modalInside: controller.contains(modal),
          modalAttribute: modal.getAttribute("data-train-city-selector-target"),
          controllerEl: controller.tagName
        };
      }')
      puts "🔍 Modal info: #{modal_info.inspect}"
      
      # Click on departure city button
      departure_button = page.query_selector('[data-action*="train-city-selector#openDeparture"]')
      expect(departure_button).not_to be_nil
      puts "🔍 Clicking departure button..."
      departure_button.click
      
      # Wait a moment for modal to open
      page.wait_for_timeout(500)
      
      # Debug: Check if controller is connected
      has_modal_target = page.evaluate('() => {
        const el = document.querySelector("[data-controller~=\"train-city-selector\"]");
        if (!el) return "no controller";
        const controller = window.Stimulus.controllers.find(c => c.element === el);
        return controller ? controller.hasModalTarget : "no controller instance";
      }')
      puts "🔍 Controller hasModalTarget: #{has_modal_target}"
      
      # Debug: Check modal classes
      modal_classes = modal.evaluate('el => el.className')
      puts "🔍 Modal classes after click: #{modal_classes}"
      
      # Verify modal is now visible
      expect(modal.evaluate('el => el.classList.contains("hidden")')).to be false
      
      # Verify modal title shows correct text
      modal_title = page.query_selector('[data-modal-title]')
      expect(modal_title).not_to be_nil
      expect(modal_title.text_content).to include('单选出发地')
      
      # Click on a hot city (e.g., 上海)
      shanghai_button = page.query_selector('[data-city-name="上海"]')
      expect(shanghai_button).not_to be_nil
      shanghai_button.click
      
      # Wait a moment for modal to close
      page.wait_for_timeout(500)
      
      # Verify modal is now hidden again
      expect(modal.evaluate('el => el.classList.contains("hidden")')).to be true
      
      # Verify departure city text updated to 上海
      departure_text = page.query_selector('[data-train-city-selector-target="departure"]')
      expect(departure_text).not_to be_nil
      expect(departure_text.text_content).to eq('上海')
    end
  end

  it 'opens city selector modal when clicking destination city' do
    with_page('http://localhost:3000/trains') do |page|
      # Wait for page to load
      page.wait_for_selector('[data-controller~="train-city-selector"]', timeout: 5000)
      
      # Verify modal is initially hidden
      modal = page.query_selector('[data-train-city-selector-target="modal"]')
      expect(modal).not_to be_nil
      expect(modal.evaluate('el => el.classList.contains("hidden")')).to be true
      
      # Click on destination city button
      destination_button = page.query_selector('[data-action*="train-city-selector#openDestination"]')
      expect(destination_button).not_to be_nil
      destination_button.click
      
      # Wait a moment for modal to open
      page.wait_for_timeout(500)
      
      # Verify modal is now visible
      expect(modal.evaluate('el => el.classList.contains("hidden")')).to be false
      
      # Verify modal title shows correct text
      modal_title = page.query_selector('[data-modal-title]')
      expect(modal_title).not_to be_nil
      expect(modal_title.text_content).to include('单选目的地')
    end
  end
end
