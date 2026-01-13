# frozen_string_literal: true

require 'playwright'
require 'base64'
require 'net/http'
require 'json'

# Playwright test helper module
# Provides browser lifecycle management for Playwright tests
#
# Usage:
#   RSpec.describe "Homepage", type: :system do
#     include PlaywrightHelper
#
#     it "loads without errors" do
#       visit_page("http://localhost:3000/")
#       expect(page).to be_truthy
#     end
#   end
module PlaywrightHelper
  attr_reader :browser, :page

  # Take a screenshot and save to tmp/screenshots
  def take_screenshot(page, name)
    Dir.mkdir('tmp/screenshots') unless Dir.exist?('tmp/screenshots')
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    filepath = "tmp/screenshots/#{name}_#{timestamp}.png"
    page.screenshot(path: filepath)
    puts "📸 Screenshot saved: #{filepath}"
    filepath
  end

  # Analyze screenshot using AI vision to verify visual content
  def analyze_screenshot(filepath, verification_prompt)
    return unless ENV['LLM_API_KEY'] && ENV['LLM_BASE_URL']
    
    puts "🔍 Analyzing screenshot: #{filepath}"
    puts "   Question: #{verification_prompt}"
    
    # Read and encode image with proper encoding
    image_data = File.binread(filepath)
    base64_image = Base64.strict_encode64(image_data).force_encoding('UTF-8')
    
    # Prepare API request
    uri = URI("#{ENV['LLM_BASE_URL']}/v1/chat/completions")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.read_timeout = 30
    
    request = Net::HTTP::Post.new(uri.path)
    request['Authorization'] = "Bearer #{ENV['LLM_API_KEY']}"
    request['Content-Type'] = 'application/json; charset=utf-8'
    
    payload = {
      model: ENV['LLM_MODEL'] || 'openrouter/claude-sonnet-4.5',
      max_tokens: 500,
      messages: [
        {
          role: 'user',
          content: [
            {
              type: 'image_url',
              image_url: {
                url: "data:image/png;base64,#{base64_image}"
              }
            },
            {
              type: 'text',
              text: verification_prompt
            }
          ]
        }
      ]
    }
    
    request.body = payload.to_json.force_encoding('UTF-8')
    
    # Send request and parse response
    response = http.request(request)
    
    if response.code == '200'
      # Force UTF-8 encoding for response body
      response_body = response.body.force_encoding('UTF-8')
      result = JSON.parse(response_body)
      analysis = result.dig('content', 0, 'text') || result.dig('choices', 0, 'message', 'content')
      analysis = analysis.to_s.force_encoding('UTF-8') if analysis
      puts "   ✓ Analysis: #{analysis}"
      analysis
    else
      error_body = response.body.force_encoding('UTF-8')
      puts "   ⚠️  API Error: #{response.code} - #{error_body}"
      nil
    end
  rescue => e
    puts "   ⚠️  Analysis failed: #{e.message}"
    puts "   Error class: #{e.class}"
    puts "   Backtrace: #{e.backtrace.first(3).join('\n   ')}"
    nil
  end

  # Take screenshot and analyze with AI vision
  def take_and_analyze_screenshot(page, name, verification_prompt)
    filepath = take_screenshot(page, name)
    analysis = analyze_screenshot(filepath, verification_prompt)
    { filepath: filepath, analysis: analysis }
  end

  # Check if page has errors and take screenshot if found
  def check_for_errors(page, step_name)
    page_content = page.content
    error_indicators = [
      'Something Went Wrong',
      '500 Internal Server Error',
      '404 Not Found',
      'undefined method',
      'NoMethodError',
      'ActiveRecord::RecordNotFound',
      "couldn't find",
      'Routing Error'
    ]
    
    has_error = error_indicators.any? { |indicator| page_content.downcase.include?(indicator.downcase) }
    
    if has_error
      puts "⚠️  Error detected at step: #{step_name}"
      take_screenshot(page, "error_#{step_name}")
      raise "Error found on page at step: #{step_name}"
    end
  end

  def visit_page(url)
    Playwright.create(playwright_cli_executable_path: 'npx playwright') do |playwright|
      playwright.chromium.launch(headless: true) do |browser|
        @browser = browser
        @page = browser.new_page
        @page.goto(url)
        yield if block_given?
      end
    end
  end

  def with_page(url, options = {}, &block)
    headless = options.fetch(:headless, true)
    Playwright.create(playwright_cli_executable_path: 'npx playwright') do |playwright|
      playwright.chromium.launch(headless: headless) do |browser|
        page = browser.new_page
        page.goto(url)
        yield page
      end
    end
  end
end
