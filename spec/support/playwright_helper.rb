# frozen_string_literal: true

require 'playwright'

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

  def with_page(url, &block)
    Playwright.create(playwright_cli_executable_path: 'npx playwright') do |playwright|
      playwright.chromium.launch(headless: true) do |browser|
        page = browser.new_page
        page.goto(url)
        yield page
      end
    end
  end
end
