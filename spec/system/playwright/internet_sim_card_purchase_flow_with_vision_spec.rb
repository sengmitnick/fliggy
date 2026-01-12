require 'rails_helper'
require 'playwright'
require_relative '../../support/playwright_helper'

RSpec.describe "Internet SIM Card Purchase Flow (with AI Vision Analysis)", type: :system do
  include PlaywrightHelper

  let(:base_url) { "http://localhost:3000" }
  
  it "completes full SIM card purchase flow with visual verification" do
    with_page(base_url) do |page|
      puts "\n=== 🤖 境外电话卡购买流程 - AI视觉分析测试 ==="
      puts "This test uses AI vision to find and analyze UI issues in SIM card purchase flow\n"
      
      # Step 1: Login
      puts "\n[Step 1] 登录"
      page.goto("#{base_url}/sign_in")
      sleep 0.5
      
      result = take_and_analyze_screenshot(
        page, 
        "sim_01_login_page",
        "请确认这是登录页面，是否有邮箱和密码输入框？"
      )
      
      page.fill('input[type="email"]', 'demo@fliggy.com')
      page.fill('input[type="password"]', 'password123')
      page.click('button[type="submit"], input[type="submit"]')
      sleep 1
      
      # Step 2: Navigate to SIM card page
      puts "\n[Step 2] 进入境外电话卡页面"
      page.goto("#{base_url}/internet_services?tab=sim_card")
      sleep 1
      
      result = take_and_analyze_screenshot(
        page,
        "sim_02_sim_card_page",
        "【关键检查】这是境外电话卡选择页面，请仔细分析：1) 页面顶部是否有三个标签（境外电话卡/境外流量包/随身WiFi）？2) 当前是否在'境外电话卡'标签？3) 页面是否显示了电话卡商品列表？4) 每个商品是否显示了价格、特性标签？5) 是否有筛选条件（取卡方式、天数、流量）？6) 页面布局是否正常，有没有UI错位、重叠、空白异常？请详细分析每一点。"
      )
      
      # Step 3: Check filter options
      puts "\n[Step 3] 检查筛选器功能"
      result = take_and_analyze_screenshot(
        page,
        "sim_03_filters",
        "【筛选器检查】请分析页面上的筛选条件：1) '取卡方式'选项（邮寄/自取）是否可见且布局正常？2) '天数'选项（1/2/3/4/5/7/10/15天）是否完整显示？3) '流量'选项（3GB/天、5GB/天、无限量）是否存在？4) 这些筛选按钮的样式是否一致，有无错位或样式异常？"
      )
      
      # Step 4: Check SIM card list
      puts "\n[Step 4] 检查电话卡商品列表"
      page.wait_for_selector('[data-controller="product-card"]', timeout: 5000)
      
      result = take_and_analyze_screenshot(
        page,
        "sim_04_product_cards",
        "【商品卡片检查】请详细检查电话卡商品列表：1) 是否显示了多个商品卡片？2) 第一个商品是否有'热销'标签？3) 每个商品卡片是否包含：商品名称、特性标签（虚商卡、5G网络等）、销量、价格？4) 商品卡片的布局是否整齐，图片、文字、价格位置是否对齐？5) 是否有选择框（圆圈或对勾）？6) 有没有UI显示问题，比如文字重叠、图片缺失、布局错乱？"
      )
      
      # Step 5: Select a SIM card
      puts "\n[Step 5] 选择电话卡"
      product_cards = page.query_selector_all('[data-controller="product-card"]')
      
      if product_cards.length > 1
        # Select the second card
        product_cards[1].click
        sleep 0.5
        
        result = take_and_analyze_screenshot(
          page,
          "sim_05_after_selection",
          "【选择反馈检查】选择了第二张电话卡后，请确认：1) 被选中的卡片是否有视觉高亮（黄色边框/背景色变化）？2) 是否有选中标识（对勾图标）出现？3) 底部的总价是否更新显示？4) 页面UI是否有任何异常（如选中后布局变乱）？"
        )
      else
        puts "⚠️  Found #{product_cards.length} product cards, expected at least 2"
      end
      
      # Step 6: Check booking section
      puts "\n[Step 6] 检查预订信息区域"
      result = take_and_analyze_screenshot(
        page,
        "sim_06_booking_section",
        "【预订区域检查】请检查页面下方的预订信息区域：1) 是否有'预订数量'部分，包含+/-按钮和数量显示？2) 是否有'收货地址'部分？3) 收货地址是显示'添加收货地址'链接，还是已有地址信息？4) 底部是否有固定的支付栏，显示总计价格和'立即支付'按钮？5) 这些元素的布局是否清晰，有无重叠或错位？"
      )
      
      # Step 7: Try to proceed to payment
      puts "\n[Step 7] 尝试进入支付页面"
      payment_button = page.query_selector('input[type="submit"][value="立即支付"], button:has-text("立即支付")')
      
      if payment_button
        result = take_and_analyze_screenshot(
          page,
          "sim_07_before_payment",
          "准备点击'立即支付'按钮，请确认：1) 按钮是否清晰可见且样式正常？2) 按钮位置是否在底部固定栏？3) 总价显示是否正确？"
        )
        
        payment_button.click
        sleep 2
        
        # Step 8: Check order page
        puts "\n[Step 8] 检查订单确认页面"
        result = take_and_analyze_screenshot(
          page,
          "sim_08_order_page",
          "【订单页面检查】这应该是订单确认页面，请详细分析：1) URL是否跳转到了订单页面（/internet_orders/new）？2) 是否显示了订单详情（商品名称、价格、有效期等）？3) 是否有收货地址相关信息？4) 页面是否有错误提示或缺失内容？5) 是否有'确认支付'或类似的提交按钮？6) 整体布局是否完整？如果有任何问题，请详细说明。"
        )
        
        # Check URL
        current_url = page.url
        puts "Current URL: #{current_url}"
        
        if current_url.include?('/internet_orders/new')
          # Try to submit order
          puts "\n[Step 9] 提交订单"
          submit_button = page.query_selector('input[type="submit"], button[type="submit"]')
          
          if submit_button
            result = take_and_analyze_screenshot(
              page,
              "sim_09_before_submit",
              "订单提交前最后确认：订单信息是否完整？提交按钮是否可用？"
            )
            
            submit_button.click
            sleep 2
            
            # Step 10: Check success page
            puts "\n[Step 10] 检查支付成功页面"
            result = take_and_analyze_screenshot(
              page,
              "sim_10_success_page",
              "【支付结果页面检查】请详细分析这个页面：1) 是否显示'支付成功'或类似成功提示？2) 是否有成功图标（绿色对勾等）？3) 是否显示了订单号？4) 是否有订单详情（商品名称、金额、地址等）？5) 页面布局是否友好完整？6) 如果不是成功页面，显示的是什么内容？有什么错误信息？请给出完整的页面分析。"
            )
            
            final_url = page.url
            puts "Final URL: #{final_url}"
            
            if final_url.include?('/success')
              puts "✅ Successfully reached success page"
            else
              puts "⚠️  Did not reach success page, current URL: #{final_url}"
              puts "⚠️  This may indicate a problem in the purchase flow"
            end
          else
            puts "❌ Submit button not found on order page"
            result = take_and_analyze_screenshot(
              page,
              "sim_09_no_submit_button",
              "【错误分析】订单页面找不到提交按钮，请分析：1) 页面显示的是什么内容？2) 是否有错误提示？3) 是否缺少必填信息导致无法提交？4) 页面UI是否正常？"
            )
          end
        else
          puts "❌ Did not reach order page, current URL: #{current_url}"
          result = take_and_analyze_screenshot(
            page,
            "sim_08_wrong_page",
            "【错误分析】点击'立即支付'后没有跳转到订单页面，请分析：1) 当前页面显示的是什么？2) 是否有错误提示？3) 是否还在商品选择页面？4) 页面有什么异常？请详细说明问题。"
          )
        end
      else
        puts "❌ Payment button not found"
        result = take_and_analyze_screenshot(
          page,
          "sim_07_no_payment_button",
          "【错误分析】找不到'立即支付'按钮，请分析：1) 页面底部显示的是什么？2) 是否有其他提示信息？3) 可能是什么原因导致按钮不显示？4) 页面布局是否正常？"
        )
      end
      
      puts "\n=== 境外电话卡测试完成 ==="
      puts "所有截图已保存在 tmp/screenshots/ 目录，请查看AI分析结果以发现问题"
    end
  end
  
  it "tests filter interactions with visual verification" do
    with_page(base_url) do |page|
      puts "\n=== 测试筛选器交互功能 ==="
      
      # Login
      page.goto("#{base_url}/sign_in")
      sleep 0.5
      page.fill('input[type="email"]', 'demo@fliggy.com')
      page.fill('input[type="password"]', 'password123')
      page.click('button[type="submit"], input[type="submit"]')
      sleep 1
      
      # Go to SIM card page
      page.goto("#{base_url}/internet_services?tab=sim_card")
      sleep 1
      
      # Test delivery method filter
      puts "\n测试'取卡方式'筛选"
      delivery_buttons = page.query_selector_all('[data-action="sim-card-filter#selectDelivery"]')
      if delivery_buttons.length >= 2
        delivery_buttons[1].click  # Click "自取"
        sleep 0.3
        
        result = take_and_analyze_screenshot(
          page,
          "sim_filter_delivery",
          "点击'自取'筛选后，请确认：1) '自取'按钮是否有高亮或选中状态？2) 商品列表是否更新？3) UI反馈是否清晰？"
        )
      end
      
      # Test days filter
      puts "\n测试'天数'筛选"
      days_buttons = page.query_selector_all('[data-action="sim-card-filter#selectDays"]')
      if days_buttons.length > 0
        days_buttons[2].click  # Click third day option
        sleep 0.3
        
        result = take_and_analyze_screenshot(
          page,
          "sim_filter_days",
          "点击天数筛选后，请确认：1) 被选中的天数按钮是否有视觉反馈？2) 商品列表是否根据天数筛选？3) 筛选器UI是否正常工作？"
        )
      end
      
      puts "\n=== 筛选器测试完成 ==="
    end
  end
end
