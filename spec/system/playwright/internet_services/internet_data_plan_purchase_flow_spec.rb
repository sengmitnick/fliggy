# frozen_string_literal: true

require 'rails_helper'
require 'playwright'
require_relative '../../../support/playwright_helper'

RSpec.describe "Internet Data Plan Purchase Flow", type: :system do
  include PlaywrightHelper

  let(:base_url) { "http://localhost:3000" }
  
  before(:all) do
    # Use development environment data - no need to create test user
    # The tests will use the existing user in development database
  end

  it "completes full data plan purchase flow from homepage to payment success" do
    with_page(base_url) do |page|
      puts "\n=== Starting Internet Data Plan Purchase Flow Test ==="
      
      # Step 1: Login
      puts "\n[Step 1] Logging in..."
      page.goto("#{base_url}/sign_in")
      sleep 0.5
      take_screenshot(page, "01_login_page")
      check_for_errors(page, "login_page")
      
      page.fill('input[type="email"]', 'demo@travel01.com')
      page.fill('input[type="password"]', 'password123')
      page.click('button[type="submit"], input[type="submit"]')
      sleep 1
      
      take_screenshot(page, "02_after_login")
      expect(page.url).not_to include('/sign_in')
      puts "✓ Login successful"
      
      # Step 2: Navigate to Internet Services
      puts "\n[Step 2] Navigating to Internet Services..."
      page.goto("#{base_url}/internet_services?tab=data_plan")
      sleep 1
      
      take_screenshot(page, "04_data_plan_page")
      check_for_errors(page, "data_plan_page")
      
      expect(page.url).to include('/internet_services')
      expect(page.url).to include('tab=data_plan')
      puts "✓ Reached data plan page"
      
      # Step 3: Select a data plan
      puts "\n[Step 3] Selecting data plan..."
      
      # Wait for data plans to load
      page.wait_for_selector('[data-plan-id]', timeout: 5000)
      
      # Click the second plan (香港3天漫游包)
      plan_cards = page.query_selector_all('[data-plan-id]')
      expect(plan_cards.length).to be > 1
      
      selected_plan = plan_cards[1] # Second plan
      selected_plan.click
      sleep 0.5
      
      take_screenshot(page, "05_plan_selected")
      
      # Verify plan is selected (should have yellow background)
      expect(selected_plan.evaluate('el => el.classList.contains("bg-[#FFF9E6]")')).to be true
      puts "✓ Data plan selected"
      
      # Step 4: Click payment button
      puts "\n[Step 4] Proceeding to order..."
      payment_button = page.query_selector('a:has-text("立即支付")')
      expect(payment_button).not_to be_nil
      
      payment_button.click
      sleep 1
      
      take_screenshot(page, "06_order_page")
      check_for_errors(page, "order_page")
      
      expect(page.url).to include('/internet_orders/new')
      puts "✓ Reached order confirmation page"
      
      # Step 5: Verify order details
      puts "\n[Step 5] Verifying order details..."
      
      # Check phone number is displayed
      expect(page.content).to include('13800138000')
      
      # Check plan name
      expect(page.content).to include('香港')
      expect(page.content).to include('漫游包')
      
      # Check total price is displayed
      total_price = page.query_selector('[data-internet-order-form-target="totalPrice"]')
      expect(total_price).not_to be_nil
      expect(total_price.text_content.to_i).to be > 0
      
      puts "✓ Order details verified"
      
      # Step 6: Submit order
      puts "\n[Step 6] Submitting order..."
      submit_button = page.query_selector('input[type="submit"], button[type="submit"]')
      expect(submit_button).not_to be_nil
      
      take_screenshot(page, "07_before_submit")
      
      submit_button.click
      sleep 2
      
      take_screenshot(page, "08_after_submit")
      check_for_errors(page, "after_submit")
      
      # Should redirect to success page
      expect(page.url).to include('/internet_orders/')
      expect(page.url).to include('/success')
      puts "✓ Order submitted successfully"
      
      # Step 7: Verify success page
      puts "\n[Step 7] Verifying payment success..."
      
      take_screenshot(page, "09_success_page")
      
      # Check for success message or order number
      page_content = page.content
      success_indicators = [
        '支付成功',
        '订单成功',
        '购买成功',
        '订单号'
      ]
      
      has_success_indicator = success_indicators.any? { |indicator| page_content.include?(indicator) }
      expect(has_success_indicator).to be true
      
      puts "✓ Payment success page displayed"
      puts "\n=== Test Completed Successfully ==="
      puts "\n📸 All screenshots saved in tmp/screenshots/"
    end
  end
  
  it "can select different data plans and price updates correctly" do
    with_page(base_url) do |page|
      puts "\n=== Testing Data Plan Selection ==="
      
      # Login first
      page.goto("#{base_url}/sign_in")
      sleep 0.5
      page.fill('input[type="email"]', 'demo@travel01.com')
      page.fill('input[type="password"]', 'password123')
      page.click('button[type="submit"], input[type="submit"]')
      sleep 1
      
      # Navigate to data plan page
      page.goto("#{base_url}/internet_services?tab=data_plan")
      sleep 1
      
      take_screenshot(page, "plan_selection_test_start")
      check_for_errors(page, "plan_selection_start")
      
      # Wait for plans to load
      page.wait_for_selector('[data-plan-id]', timeout: 5000)
      
      plan_cards = page.query_selector_all('[data-plan-id]')
      total_price_element = page.query_selector('[data-data-plan-target="totalPrice"]')
      
      # Test each plan
      plan_cards.each_with_index do |plan_card, index|
        puts "\nTesting plan #{index + 1}..."
        
        # Get expected price
        expected_price = plan_card.get_attribute('data-plan-price').to_f.to_i
        
        # Click plan
        plan_card.click
        sleep 0.3
        
        take_screenshot(page, "plan_#{index + 1}_selected")
        
        # Verify selection visual feedback
        expect(plan_card.evaluate('el => el.classList.contains("bg-[#FFF9E6]")')).to be true
        
        # Verify price updated
        actual_price = total_price_element.text_content.to_i
        expect(actual_price).to eq(expected_price)
        
        puts "✓ Plan #{index + 1}: Price correctly updated to ¥#{expected_price}"
      end
      
      puts "\n=== Plan Selection Test Completed ==="
      puts "📸 Screenshots saved in tmp/screenshots/"
    end
  end
  
  it "displays correct phone number from user data" do
    with_page(base_url) do |page|
      puts "\n=== Testing Phone Number Display ==="
      
      # Login
      page.goto("#{base_url}/sign_in")
      sleep 0.5
      page.fill('input[type="email"]', 'demo@travel01.com')
      page.fill('input[type="password"]', 'password123')
      page.click('button[type="submit"], input[type="submit"]')
      sleep 1
      
      # Navigate to data plan page
      page.goto("#{base_url}/internet_services?tab=data_plan")
      sleep 1
      
      take_screenshot(page, "phone_number_test_data_plan")
      check_for_errors(page, "phone_number_data_plan")
      
      # Check phone number display
      page_content = page.content
      expect(page_content).to include('13800138000')
      
      puts "✓ Phone number displayed correctly on data plan page"
      
      # Navigate to order page
      payment_button = page.query_selector('a:has-text("立即支付")')
      payment_button.click if payment_button
      sleep 1
      
      # Check phone number on order page
      if page.url.include?('/internet_orders/new')
        take_screenshot(page, "phone_number_test_order_page")
        check_for_errors(page, "phone_number_order_page")
        
        page_content = page.content
        expect(page_content).to include('13800138000')
        puts "✓ Phone number displayed correctly on order page"
      end
      
      puts "\n=== Phone Number Test Completed ==="
      puts "📸 Screenshots saved in tmp/screenshots/"
    end
  end
end
