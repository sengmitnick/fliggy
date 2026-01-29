# frozen_string_literal: true

# ValidatorSessionBinder Middleware
#
# Purpose: Bind validator session_id from URL parameters to independent cookie
#
# Flow:
# 1. APK passes session_id via Deeplink: ai.clacky.trip01://?session_id=xxx
# 2. WebView loads: http://SERVER/?session_id=xxx
# 3. This middleware extracts session_id from URL params
# 4. Stores it in INDEPENDENT cookie: validator_session_id (NOT in Rails session)
# 5. ApplicationController#restore_validator_context reads from cookie
#
# WHY INDEPENDENT COOKIE?
# - Rails session cookie is SHARED across all tabs in the same browser
# - If we use session[:validator_execution_id], opening multiple session_id URLs
#   in different tabs will cause them to overwrite each other
# - Using an independent cookie allows true multi-tab parallel validation
#
# Benefits:
# - Explicit session binding (users know which session they're operating in)
# - Supports multi-tab parallel testing (different tabs = different session_ids)
# - No APK modifications needed (already supports Deeplink params)
# - Backward compatible (falls back to "latest session" if no session_id param)
#
# Example Usage:
#   # Create session
#   POST /api/tasks/book_flight_sz_to_bj/start
#   # Response: {"session_id": "abc-123", ...}
#
#   # Launch APK with session_id
#   adb shell am start -a android.intent.action.VIEW \
#     -d "ai.clacky.trip01://?session_id=abc-123"
#
#   # WebView loads: http://192.168.1.10:5010/?session_id=abc-123
#   # Middleware sets cookie: validator_session_id = "abc-123"
#   # All subsequent operations in this tab use this session
#
class ValidatorSessionBinder
  COOKIE_NAME = 'validator_session_id'
  
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    response = nil
    
    # Extract session_id from URL parameters
    if request.params['session_id'].present?
      session_id = request.params['session_id']
      old_cookie_value = request.cookies[COOKIE_NAME]
      
      Rails.logger.info "[ValidatorSessionBinder] Detected session_id=#{session_id} from URL param"
      Rails.logger.info "[ValidatorSessionBinder] Old cookie value: #{old_cookie_value.inspect}"
      
      # Call the next middleware/app first
      status, headers, body = @app.call(env)
      
      # CRITICAL FIX: Clear ALL existing Set-Cookie headers for validator_session_id
      # Why: ApplicationController may have added a delete cookie directive if the old
      # cookie value was invalid. We need to remove ALL cookie directives before setting
      # the new one, otherwise the delete directive will override our new cookie.
      #
      # Strategy:
      # 1. Remove ALL Set-Cookie headers for validator_session_id from response
      # 2. Add a single delete directive (to clear browser's old cookie)
      # 3. Add the new cookie value
      
      # Step 1: Remove all existing Set-Cookie headers for validator_session_id
      # Note: Rack stores Set-Cookie as an array in Rack::Utils::HeaderHash
      if headers['Set-Cookie']
        set_cookie_value = headers['Set-Cookie']
        
        # DEBUG: Log the actual type and content
        Rails.logger.info "[ValidatorSessionBinder DEBUG] Set-Cookie type: #{set_cookie_value.class}"
        Rails.logger.info "[ValidatorSessionBinder DEBUG] Set-Cookie value: #{set_cookie_value.inspect}"
        
        # Handle both array and string formats
        cookie_lines = if set_cookie_value.is_a?(Array)
                         set_cookie_value
                       else
                         set_cookie_value.split("\n")
                       end
        
        Rails.logger.info "[ValidatorSessionBinder DEBUG] cookie_lines (#{cookie_lines.size} total): #{cookie_lines.inspect}"
        
        # Filter out all lines containing validator_session_id
        remaining_cookies = cookie_lines.reject { |line| line.include?("#{COOKIE_NAME}=") }
        
        Rails.logger.info "[ValidatorSessionBinder DEBUG] remaining_cookies (#{remaining_cookies.size} left): #{remaining_cookies.inspect}"
        
        if remaining_cookies.empty?
          headers.delete('Set-Cookie')
        else
          # Preserve array format if input was array
          headers['Set-Cookie'] = set_cookie_value.is_a?(Array) ? remaining_cookies : remaining_cookies.join("\n")
        end
        
        Rails.logger.info "[ValidatorSessionBinder] Filtered out existing #{COOKIE_NAME} cookies (found #{cookie_lines.size - remaining_cookies.size})"
      end
      
      # Step 2: Add delete directive to clear browser's old cookie
      Rack::Utils.delete_cookie_header!(headers, COOKIE_NAME, { path: '/' })
      
      # Step 3: Set new cookie value
      # ⚠️ CRITICAL: Use separate cookie instead of Rails session
      # This allows multiple tabs with different session_ids to coexist
      Rack::Utils.set_cookie_header!(headers, COOKIE_NAME, {
        value: session_id,
        path: '/',
        http_only: true,
        same_site: :lax,
        expires: Time.now + 24.hours  # Valid for 24 hours
      })
      
      Rails.logger.info "[ValidatorSessionBinder] Deleted old cookie (if exists), set new cookie #{COOKIE_NAME}=#{session_id}"
      
      return [status, headers, body]
    end
    
    # No session_id in URL params, proceed normally
    @app.call(env)
  end
end
