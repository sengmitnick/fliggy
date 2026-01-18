require 'rails_helper'
require 'playwright'
require_relative '../../../support/playwright_helper'

RSpec.describe "Internet WiFi Device Purchase Flow (with AI Vision Analysis)", type: :system do
  include PlaywrightHelper

  let(:base_url) { "http://localhost:3000" }
  
  it "completes full WiFi device rental flow with visual verification" do
    with_page(base_url) do |page|
      puts "\n=== 🤖 随身WiFi租赁流程 - AI视觉分析测试 ==="
      puts "This test uses AI vision to find and analyze UI issues in WiFi rental flow\n"
      
      # Step 1: Login
      puts "\n[Step 1] 登录"
      page.goto("#{base_url}/sign_in")
      sleep 0.5
      
      result = take_and_analyze_screenshot(
        page, 
        "wifi_01_login_page",
        "确认登录页面是否正常显示"
      )
      
      page.fill('input[type="email"]', 'demo@fliggy.com')
      page.fill('input[type="password"]', 'password123')
      page.click('button[type="submit"], input[type="submit"]')
      sleep 1
      
      # Step 2: Navigate to WiFi page
      puts "\n[Step 2] 进入随身WiFi页面"
      page.goto("#{base_url}/internet_services?tab=wifi")
      sleep 1
      
      result = take_and_analyze_screenshot(
        page,
        "wifi_02_wifi_page",
        "【关键检查】这是随身WiFi租赁页面，请仔细分析：1) 页面顶部是否有三个标签（境外电话卡/境外流量包/随身WiFi）？2) 当前是否在'随身WiFi'标签？3) 页面是否显示了WiFi设备商品列表？4) 每个商品是否显示了设备名称、网络类型（4G/5G）、流量限制、每日价格？5) 是否显示了押金信息？6) 页面布局是否正常，有没有UI错位、内容重叠、空白异常？请详细分析每一点。"
      )
      
      # Step 3: Check filter options
      puts "\n[Step 3] 检查筛选器功能"
      result = take_and_analyze_screenshot(
        page,
        "wifi_03_filters",
        "【筛选器检查】请检查页面上的筛选条件：1) 是否有'取WiFi方式'选项（邮寄到家/门店自取）？2) 是否有'网络类型'选项（4G/5G）？3) 是否有'流量'选项（无限量/限量）？4) 这些筛选按钮是否清晰可见且布局合理？5) 筛选器样式是否一致？"
      )
      
      # Step 4: Check WiFi device list
      puts "\n[Step 4] 检查WiFi设备商品列表"
      page.wait_for_selector('[data-wifi-id]', timeout: 5000)
      
      result = take_and_analyze_screenshot(
        page,
        "wifi_04_product_cards",
        "【商品卡片检查】请详细检查WiFi设备商品列表：1) 是否显示了多个设备选项？2) 第一个商品是否有'热销'标签？3) 每个商品卡片是否包含：设备名称、网络类型标签、流量限制、特性标签（多网覆盖、信号稳定等）、销量、每日价格？4) 是否显示了押金金额（如¥500押金）？5) 商品卡片布局是否整齐？6) 是否有选择框（圆圈或对勾）？7) 有没有UI显示问题，比如价格显示错误、文字重叠、图标缺失？"
      )
      
      # Step 5: Select a WiFi device
      puts "\n[Step 5] 选择WiFi设备"
      product_cards = page.query_selector_all('[data-wifi-id]')
      
      if product_cards.length > 1
        # Select the second card
        product_cards[1].click
        sleep 0.5
        
        result = take_and_analyze_screenshot(
          page,
          "wifi_05_after_selection",
          "【选择反馈检查】选择了第二个WiFi设备后，请确认：1) 被选中的设备卡片是否有视觉高亮（边框/背景色变化）？2) 是否有选中标识（对勾图标）？3) 底部的总价是否更新（包括设备租金和押金）？4) 页面UI是否有任何异常？"
        )
      else
        puts "⚠️  Found #{product_cards.length} product cards, expected at least 2"
      end
      
      # Step 6: Check rental details section
      puts "\n[Step 6] 检查租赁详情区域"
      result = take_and_analyze_screenshot(
        page,
        "wifi_06_rental_details",
        "【租赁详情检查】请检查页面下方的租赁信息区域：1) 是否有租赁天数选择（+/-按钮）？2) 是否显示了租赁总价计算？3) 是否显示了押金金额？4) 是否有取还设备信息（取设备地点、还设备地点）？5) 取还地点是显示'选择地点'链接，还是已有具体地址？6) 底部是否有支付栏，显示总计（租金+押金）和'立即支付'按钮？7) 这些元素布局是否清晰？"
      )
      
      # Step 7: Adjust rental days
      puts "\n[Step 7] 调整租赁天数"
      increase_button = page.query_selector('[data-action*="increase"]')
      if increase_button
        increase_button.click
        sleep 0.3
        
        result = take_and_analyze_screenshot(
          page,
          "wifi_07_after_increase_days",
          "调整租赁天数后，请确认：1) 天数显示是否更新？2) 租金总价是否重新计算？3) 底部总计金额是否更新（租金+押金）？4) UI反馈是否及时清晰？"
        )
      end
      
      # Step 8: Try to proceed to payment
      puts "\n[Step 8] 尝试进入支付页面"
      payment_button = page.query_selector('input[type="submit"][value="立即支付"], button:has-text("立即支付"), a:has-text("立即支付")')
      
      if payment_button
        result = take_and_analyze_screenshot(
          page,
          "wifi_08_before_payment",
          "准备点击'立即支付'按钮，请确认：1) 按钮是否清晰可见？2) 总计金额是否包含租金和押金？3) 所有必填信息是否完整（取还地点等）？"
        )
        
        # Check link href before clicking
        tag_name = payment_button.evaluate('el => el.tagName.toLowerCase()')
        puts "💡 Payment button tag: #{tag_name}"
        if tag_name == 'a'
          href = payment_button.evaluate('el => el.href')
          puts "💡 Payment link href: #{href}"
        end
        
        # Force remove error status bar if it exists
        page.evaluate("() => { const bar = document.querySelector('#js-error-status-bar'); if (bar) bar.style.display = 'none'; }")
        sleep 0.3
        
        # Click and wait for navigation
        payment_button.click
        page.wait_for_url('**/internet_orders/new**', timeout: 5000) rescue nil
        sleep 1
        
        # Step 9: Check order page
        puts "\n[Step 9] 检查订单确认页面"
        result = take_and_analyze_screenshot(
          page,
          "wifi_09_order_page",
          "【订单页面检查】这应该是订单确认页面，请详细分析：1) URL是否跳转到了订单页面（/internet_orders/new）？2) 是否显示了设备信息（设备名称、网络类型）？3) 是否显示了租赁天数和价格？4) 是否显示了押金信息？5) 是否有取还设备地点信息？6) 页面是否有错误提示？7) 是否有'确认支付'按钮？8) 整体布局是否完整？如果有任何问题，请详细说明。"
        )
        
        # Check URL
        current_url = page.url
        puts "Current URL: #{current_url}"
        
        if current_url.include?('/internet_orders/new')
          # Try to submit order
          puts "\n[Step 10] 提交订单"
          submit_button = page.query_selector('input[type="submit"], button[type="submit"]')
          
          if submit_button
            result = take_and_analyze_screenshot(
              page,
              "wifi_10_before_submit",
              "订单提交前最后确认：设备信息、租赁天数、价格、押金、取还地点是否完整？提交按钮是否可用？"
            )
            
            submit_button.click
            sleep 2
            
            # Step 11: Check success page
            puts "\n[Step 11] 检查支付成功页面"
            result = take_and_analyze_screenshot(
              page,
              "wifi_11_success_page",
              "【支付结果页面检查】请详细分析这个页面：1) 是否显示'支付成功'或类似成功提示？2) 是否有成功图标？3) 是否显示了订单号？4) 是否有租赁详情（设备名称、租赁天数、金额、押金）？5) 是否有取还设备信息？6) 页面布局是否友好？7) 如果不是成功页面，显示的是什么内容？有什么错误信息？请给出完整分析。"
            )
            
            final_url = page.url
            puts "Final URL: #{final_url}"
            
            if final_url.include?('/success')
              puts "✅ Successfully reached success page"
            else
              puts "⚠️  Did not reach success page, current URL: #{final_url}"
              puts "⚠️  This may indicate a problem in the rental flow"
            end
          else
            puts "❌ Submit button not found on order page"
            result = take_and_analyze_screenshot(
              page,
              "wifi_10_no_submit_button",
              "【错误分析】订单页面找不到提交按钮，请分析：1) 页面显示什么内容？2) 是否有错误提示？3) 是否缺少必填信息？4) 页面UI是否正常？"
            )
          end
        else
          puts "❌ Did not reach order page, current URL: #{current_url}"
          result = take_and_analyze_screenshot(
            page,
            "wifi_09_wrong_page",
            "【错误分析】点击'立即支付'后没有跳转到订单页面，请分析：1) 当前页面显示什么？2) 是否有错误提示？3) 是否还在设备选择页面？4) 页面有什么异常？请详细说明问题。"
          )
        end
      else
        puts "❌ Payment button not found"
        result = take_and_analyze_screenshot(
          page,
          "wifi_08_no_payment_button",
          "【错误分析】找不到'立即支付'按钮，请分析：1) 页面底部显示什么？2) 是否有其他提示信息？3) 可能是什么原因导致按钮不显示？4) 页面布局是否正常？"
        )
      end
      
      puts "\n=== 随身WiFi测试完成 ==="
      puts "所有截图已保存在 tmp/screenshots/ 目录，请查看AI分析结果以发现问题"
    end
  end
  
  it "tests network type filter with visual verification" do
    with_page(base_url) do |page|
      puts "\n=== 测试网络类型筛选功能 ==="
      
      # Login
      page.goto("#{base_url}/sign_in")
      sleep 0.5
      page.fill('input[type="email"]', 'demo@fliggy.com')
      page.fill('input[type="password"]', 'password123')
      page.click('button[type="submit"], input[type="submit"]')
      sleep 1
      
      # Go to WiFi page
      page.goto("#{base_url}/internet_services?tab=wifi")
      sleep 1
      
      # Test before any filter
      result = take_and_analyze_screenshot(
        page,
        "wifi_filter_initial",
        "筛选前的初始状态，请记录显示了多少个WiFi设备，它们的网络类型和价格"
      )
      
      # Try to find and test network type filter
      puts "\n测试'网络类型'筛选（如果存在）"
      network_buttons = page.query_selector_all('[data-action*="network"], button:has-text("4G"), button:has-text("5G")')
      if network_buttons.length > 0
        # Try clicking 5G filter
        five_g_button = page.query_selector('button:has-text("5G")')
        if five_g_button
          five_g_button.click
          sleep 0.5
          
          result = take_and_analyze_screenshot(
            page,
            "wifi_filter_5g",
            "点击'5G'筛选后，请确认：1) '5G'按钮是否有选中状态？2) 商品列表是否只显示5G设备？3) 筛选结果是否正确？"
          )
        end
      else
        puts "未找到网络类型筛选器，可能该功能未实现"
        result = take_and_analyze_screenshot(
          page,
          "wifi_no_network_filter",
          "请确认页面上是否有网络类型筛选功能？如果没有，页面显示的筛选选项有哪些？"
        )
      end
      
      puts "\n=== 筛选器测试完成 ==="
    end
  end
end
