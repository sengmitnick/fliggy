require 'rails_helper'
require 'playwright'
require_relative '../../../support/playwright_helper'

RSpec.describe "Internet Data Plan Purchase Flow (with AI Vision Analysis)", type: :system do
  include PlaywrightHelper

  let(:base_url) { "http://localhost:3000" }
  
  it "completes full purchase flow with visual verification at each step" do
    with_page(base_url) do |page|
      puts "\n=== 🤖 Starting AI-Enhanced E2E Test ==="
      puts "This test uses AI vision to analyze screenshots and verify UI states\n"
      
      # Step 1: Login page visual verification
      puts "\n[Step 1] Login Page - Visual Verification"
      page.goto("#{base_url}/sign_in")
      sleep 0.5
      
      result = take_and_analyze_screenshot(
        page, 
        "01_login_page_vision",
        "请分析这个登录页面截图，确认：1) 是否有邮箱和密码输入框？2) 是否有登录按钮？3) 页面是否有任何错误信息？请简短回答。"
      )
      
      # Step 2: Fill form and login
      puts "\n[Step 2] Performing Login"
      page.fill('input[type="email"]', 'demo@fliggy.com')
      page.fill('input[type="password"]', 'password123')
      page.click('button[type="submit"], input[type="submit"]')
      sleep 1
      
      result = take_and_analyze_screenshot(
        page,
        "02_after_login_vision",
        "登录后的页面，请确认：1) 是否成功跳转离开登录页？2) 页面上是否显示用户已登录的状态？3) 有没有错误提示？"
      )
      
      expect(page.url).not_to include('/sign_in')
      
      # Step 3: Navigate to data plan page with visual check
      puts "\n[Step 3] Data Plan Page - Visual Analysis"
      page.goto("#{base_url}/internet_services?tab=data_plan")
      sleep 1
      
      result = take_and_analyze_screenshot(
        page,
        "03_data_plan_page_vision",
        "这是流量包选择页面，请分析：1) 页面上是否显示了多个流量套餐选项？2) 每个套餐是否显示了价格？3) 是否有手机号显示（13800138000）？4) 界面布局是否正常，没有错位？"
      )
      
      # Step 4: Select plan with visual verification
      puts "\n[Step 4] Selecting Data Plan"
      page.wait_for_selector('[data-plan-id]', timeout: 5000)
      
      plan_cards = page.query_selector_all('[data-plan-id]')
      selected_plan = plan_cards[1]
      
      # Before selection
      take_and_analyze_screenshot(
        page,
        "04_before_plan_selection",
        "选择套餐前的状态，套餐卡片的背景色是什么？"
      )
      
      # Select plan
      selected_plan.click
      sleep 0.5
      
      # After selection - verify visual feedback
      result = take_and_analyze_screenshot(
        page,
        "05_after_plan_selection",
        "选择套餐后，请确认：1) 被选中的套餐卡片是否有高亮显示（比如黄色背景）？2) 底部总价是否显示正确？3) '立即支付'按钮是否可见？"
      )
      
      # Step 5: Navigate to order page
      puts "\n[Step 5] Order Confirmation Page"
      payment_button = page.query_selector('a:has-text("立即支付")')
      payment_button.click
      sleep 1
      
      result = take_and_analyze_screenshot(
        page,
        "06_order_page_vision",
        "这是订单确认页面，请分析：1) 是否显示了订单详情（套餐名称、价格）？2) 是否显示了手机号13800138000？3) 是否有提交订单按钮？4) 页面布局是否完整？"
      )
      
      expect(page.url).to include('/internet_orders/new')
      
      # Step 6: Submit order
      puts "\n[Step 6] Submitting Order"
      submit_button = page.query_selector('input[type="submit"], button[type="submit"]')
      
      take_and_analyze_screenshot(
        page,
        "07_before_submit",
        "提交订单前，确认提交按钮是否清晰可见？按钮文字是什么？"
      )
      
      submit_button.click
      sleep 2
      
      # Step 7: Success page visual verification
      puts "\n[Step 7] Payment Success Page - Comprehensive Analysis"
      result = take_and_analyze_screenshot(
        page,
        "08_success_page_vision",
        "这是支付成功页面，请详细分析：1) 是否有明确的成功标识（比如绿色对勾图标）？2) 是否显示'支付成功'或类似文字？3) 是否显示了订单号？4) 是否有订单详情（商品名称、金额等）？5) 页面整体视觉效果是否友好？请给出综合评价。"
      )
      
      expect(page.url).to include('/success')
      
      # Verify success indicators
      page_content = page.content
      success_indicators = ['支付成功', '订单成功', '购买成功', '订单号']
      has_success = success_indicators.any? { |indicator| page_content.include?(indicator) }
      
      expect(has_success).to be true
      
      puts "\n=== ✅ Test Completed Successfully with AI Vision Analysis ==="
      puts "All screenshots have been analyzed by AI for visual verification"
      puts "Screenshots saved in tmp/screenshots/"
    end
  end
  
  it "analyzes UI consistency across different plan selections" do
    with_page(base_url) do |page|
      puts "\n=== Testing UI Consistency with Visual Analysis ==="
      
      # Login
      page.goto("#{base_url}/sign_in")
      sleep 0.5
      page.fill('input[type="email"]', 'demo@fliggy.com')
      page.fill('input[type="password"]', 'password123')
      page.click('button[type="submit"], input[type="submit"]')  # Fixed selector
      sleep 1
      
      # Go to data plan page
      page.goto("#{base_url}/internet_services?tab=data_plan")
      sleep 1
      
      page.wait_for_selector('[data-plan-id]', timeout: 5000)
      plan_cards = page.query_selector_all('[data-plan-id]')
      
      # Test first 3 plans with visual analysis
      [0, 1, 2].each do |index|
        plan_cards[index].click
        sleep 0.3
        
        result = take_and_analyze_screenshot(
          page,
          "plan_#{index + 1}_visual_check",
          "套餐#{index + 1}被选中后，请分析：1) 该套餐卡片是否有明显的视觉反馈（高亮/边框/背景色）？2) 底部价格显示是否更新？3) UI是否有任何错位或显示异常？简短回答。"
        )
      end
      
      puts "\n=== UI Consistency Check Completed ==="
    end
  end
end
