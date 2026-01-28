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
      
      Rails.logger.info "[ValidatorSessionBinder] Detected session_id=#{session_id} from URL param"
      
      # Call the next middleware/app first
      status, headers, body = @app.call(env)
      
      # Set independent cookie for this session_id
      # ⚠️ CRITICAL: Use separate cookie instead of Rails session
      # This allows multiple tabs with different session_ids to coexist
      Rack::Utils.set_cookie_header!(headers, COOKIE_NAME, {
        value: session_id,
        path: '/',
        http_only: true,
        same_site: :lax,
        expires: Time.now + 24.hours  # Valid for 24 hours
      })
      
      Rails.logger.info "[ValidatorSessionBinder] Set cookie #{COOKIE_NAME}=#{session_id}"
      
      return [status, headers, body]
    end
    
    # No session_id in URL params, proceed normally
    @app.call(env)
  end
end
