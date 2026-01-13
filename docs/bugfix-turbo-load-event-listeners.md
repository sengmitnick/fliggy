# Bug Fix: Turbo Load Event Listener Accumulation

## Issue

**Problem**: `Password modal target not found` error occurred when clicking "立即支付" (Pay Now) button on `/transfers/:id` page.

**Root Cause**: The `turbo:load` event listener in the auto-trigger script was not being removed after execution. This caused multiple event listeners to accumulate when:
- The page was loaded/reloaded multiple times
- Turbo Drive cached and restored the page
- Any Turbo navigation occurred on the page

When the user manually clicked the payment button, if it triggered any navigation (even a failed one), the accumulated event listeners would fire, attempting to click the button again before Stimulus controllers had fully connected and registered their targets.

## Stack Trace

```
Time: 2026/1/13 18:31:46
Page Path: /transfers/10
Last User Action: click button.w-full.bg-gradient-to-r.from-[#FF9B00] "立即支付" (3.1s ago)

Error: Password modal target not found
at Binding.invokeWithEvent (node_modules/@hotwired/stimulus/dist/stimulus.js:385:24)
at https://3000-bde2ef632f56-web.clackypaas.com/transfers/10?pay_now=true:443:21
```

## Solution

Added named function references and explicit `removeEventListener` calls after first execution to prevent duplicate event listener registrations.

### Files Fixed

1. **app/views/transfers/show.html.erb** (lines 287-299)
2. **app/views/transfers/packages.html.erb** (lines 151-225)

### Code Pattern

**Before (BROKEN)**:
```javascript
document.addEventListener('turbo:load', function() {
  // ... code ...
});
```

**After (FIXED)**:
```javascript
document.addEventListener('turbo:load', function namedFunction() {
  // ... code ...
  
  // Remove event listener after first execution
  document.removeEventListener('turbo:load', namedFunction);
});
```

## Key Points

1. **Named Functions**: Event listener functions must be named to enable proper removal
2. **Cleanup**: Always remove one-time event listeners to prevent accumulation
3. **Turbo Drive**: `turbo:load` fires on every navigation, not just initial page load
4. **Timing**: The 100ms setTimeout is still needed to allow Stimulus controllers to fully connect

## Testing

To verify the fix:
1. Load `/transfers/:id?pay_now=true` multiple times
2. Click the "立即支付" button manually
3. Verify no "Password modal target not found" errors occur
4. Check that the payment modal opens correctly

## Date

2026-01-13
