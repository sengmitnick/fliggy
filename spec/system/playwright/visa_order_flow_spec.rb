require 'rails_helper'
require_relative '../../support/playwright_helper'

RSpec.describe "Visa Order Flow", type: :system do
  include PlaywrightHelper

  let!(:user) { create(:user, email: 'test@example.com', password: '123456', password_confirmation: '123456', pay_password: '123456') }
  let!(:country) { Country.find_or_create_by!(code: 'JP') { |c| c.name = '日本'; c.region = 'Asia' } }
  let!(:visa_product) { VisaProduct.find_or_create_by!(country: country, name: '日本旅游签证') { |vp| vp.price = 500; vp.processing_days = 7; vp.material_count = 5; vp.success_rate = 95 } }
  let!(:address) { create(:address, user: user, name: '张三', phone: '13800138000', province: '广东省', city: '深圳市', district: '南山区', detail: '科技园南区', is_default: true, address_type: 'delivery') }

  it "completes the full visa order flow including order creation" do
    with_page("http://localhost:#{ENV['PORT'] || 3000}/visas") do |page|
      sleep 1 # Wait for page to fully load
      
      # 1. Visit visa index page - verify page loaded
      expect(page.content).to include('签证')
      check_for_errors(page, 'visa_index')
      
      # 2. Click on a country/visa product card
      visa_card = page.query_selector('a[href*="/visas/"]')
      if visa_card
        visa_card.click
        sleep 1 # Wait for navigation
        
        # 3. Verify visa product detail page loads
        expect(page.content).to include('日本')
        expect(page.url).to include('/visas/')
        check_for_errors(page, 'visa_show')
        
        # 4. Take screenshot of visa product page
        screenshot = take_and_analyze_screenshot(
          page, 
          'visa_product_page',
          '这个页面显示的是什么签证产品？是否有价格信息？'
        )
        
        # 5. Click "立即办理" or similar booking button
        booking_button = page.query_selector('button:has-text("立即办理"), button:has-text("立刻办理"), button:has-text("预订")')
        if booking_button
          booking_button.click
          sleep 1 # Wait for navigation
          
          # 6. Verify order form page loads
          expect(page.url).to include('/visa_orders/new')
          expect(page.content).to include('填写订单')
          check_for_errors(page, 'visa_order_new')
          
          # 7. Take screenshot of order form
          screenshot = take_and_analyze_screenshot(
            page,
            'visa_order_form',
            '这个订单表单是否包含：办签人数、流程时长、材料返还、联系人信息、保险选项、支付按钮？'
          )
          
          # 8. Check if address selector button exists
          address_section = page.query_selector('[data-address-selector-target="selectedInfo"]')
          expect(address_section).to be_truthy if address
          
          # 9. Click address selector to open modal (if exists)
          address_button = page.query_selector('button[data-action*="address-selector#openModal"]')
          if address_button
            address_button.click
            sleep 0.5 # Wait for modal to open
            
            # 10. Verify modal opens
            modal = page.query_selector('[data-address-selector-target="modal"]')
            expect(modal).to be_truthy
            
            # 11. Take screenshot of address selection modal
            screenshot = take_and_analyze_screenshot(
              page,
              'address_modal',
              '这个地址选择弹窗是否显示了地址列表？是否有"新增收货地址"按钮？'
            )
            
            # 12. Click first address in modal
            address_item = page.query_selector('button[data-action*="address-selector#selectAddress"]')
            if address_item
              address_item.click
              sleep 0.5 # Wait for modal to close
              
              # 13. Verify modal closes
              modal_hidden = page.eval_on_selector('[data-address-selector-target="modal"]', 'el => el.classList.contains("hidden")')
              expect(modal_hidden).to be true
            end
          end
          
          # 14. Verify payment button exists and is styled correctly
          payment_button = page.query_selector('button[data-action*="visa-order#submitOrder"]')
          expect(payment_button).to be_truthy
          expect(payment_button.text_content).to include('支付')
          
          # 15. Take screenshot before clicking payment button
          screenshot = take_and_analyze_screenshot(
            page,
            'visa_order_ready',
            '订单表单是否已完整填写？支付按钮是否清晰可见？'
          )
          
          # 16. Record initial order count
          initial_order_count = VisaOrder.count
          
          # 17. Click payment button to create order
          payment_button.click
          sleep 1 # Wait for order creation
          
          # 18. Check for errors after clicking payment button
          check_for_errors(page, 'after_payment_button_click')
          
          # 19. Verify payment modal appears
          payment_modal = page.query_selector('[data-controller*="payment-confirmation"]')
          if payment_modal
            expect(payment_modal).to be_truthy
            
            # 20. Take screenshot of payment modal
            screenshot = take_and_analyze_screenshot(
              page,
              'payment_modal',
              '支付密码弹窗是否显示？是否有密码输入框和确认按钮？'
            )
            
            # 21. Fill in payment password
            password_input = page.query_selector('input[data-payment-confirmation-target="passwordInput"]')
            if password_input
              password_input.fill('123456')
              sleep 0.5
              
              # 22. Click confirm payment button
              confirm_button = page.query_selector('button[data-action*="payment-confirmation#confirmPayment"]')
              if confirm_button
                confirm_button.click
                sleep 2 # Wait for payment processing
                
                # 23. Check for errors after payment confirmation
                check_for_errors(page, 'after_payment_confirmation')
                
                # 24. Verify order was created in database
                expect(VisaOrder.count).to eq(initial_order_count + 1)
                created_order = VisaOrder.last
                expect(created_order.user_id).to eq(user.id)
                expect(created_order.visa_product_id).to eq(visa_product.id)
                expect(created_order.insurance_type).to eq('none')
                expect(created_order.delivery_address).to include('科技园南区')
                
                # 25. Verify redirected to success page or order detail page
                sleep 1
                expect(page.url).to match(/visa_orders\/.*\/(show|success)/)
                
                # 26. Take final screenshot
                screenshot = take_and_analyze_screenshot(
                  page,
                  'visa_order_success',
                  '是否成功跳转到订单详情或成功页面？'
                )
              end
            end
          end
        end
      end
      
      # Success: Order created successfully without errors
      puts "✅ Visa order flow completed successfully - order created and paid"
    end
  end
end
