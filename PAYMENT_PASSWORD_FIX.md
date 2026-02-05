# Payment Password Verification Fix

## Problem Description

**Error Message:**
```
验证支付密码失败: Unexpected token '<', "<!DOCTYPE "... is not valid JSON
```

**Error Location:** `/hotel_package_orders/1` page when clicking "立即支付" button

## Root Cause

The route `/profile/verify_pay_password` was incorrectly defined as a **member** route in `config/routes.rb`:

```ruby
resource :profile do
  member do
    post :verify_pay_password  # ❌ WRONG - requires ID: /profile/:id/verify_pay_password
  end
end
```

This caused:
1. JavaScript calls `/profile/verify_pay_password` (no ID)
2. Rails returns 404 HTML error page (not JSON)
3. JavaScript tries to parse HTML as JSON → syntax error

## Fix Applied

Changed from `member` to `collection` in `config/routes.rb`:

```ruby
resource :profile do
  collection do
    post :verify_pay_password  # ✅ CORRECT - no ID needed: /profile/verify_pay_password
  end
end
```

## Why Collection vs Member?

- **Member routes** require an ID: `/resource/:id/action` (for actions on specific records)
- **Collection routes** don't need ID: `/resource/action` (for actions on the collection or current context)

Since `verify_pay_password` verifies the **current user's** password (from session), not a specific profile by ID, it should be a collection route.

## Files Modified

1. `config/routes.rb` - Changed `member` to `collection`

## Testing

After server restart, the payment password verification should work correctly:

```bash
# Test the endpoint (requires authentication):
curl -X POST http://localhost:3000/profile/verify_pay_password \
  -H 'Content-Type: application/json' \
  -H 'Cookie: session_id=...' \
  -d '{"pay_password": "123456"}' \
  -s

# Expected response:
{"success": true}  # or {"success": false, "message": "支付密码错误"}
```

## Impact

This fix affects ALL payment confirmation flows using the same modal:
- Hotel package orders
- Flight bookings
- Train bookings
- Cruise orders
- And all other payment pages using `payment_confirmation_controller.ts`

All should now work correctly after the route fix.
