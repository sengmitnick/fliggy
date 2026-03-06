# Train Booking Passenger Selector Fix

## Issue
Frontend error reported on `/train_bookings/new` page:
- Error: `Action "click->train-booking#togglePassenger" references undefined method "togglePassenger"`
- Users were clicking passenger items but the method was missing in the controller

## Root Cause
The view template (`app/views/train_bookings/new.html.erb`) had passenger selection UI with `data-action="click->train-booking#togglePassenger"` binding, but the `train_booking_controller.ts` was missing the `togglePassenger` method and related passenger management logic.

## Solution

### Changes Made

#### 1. Updated `app/javascript/controllers/train_booking_controller.ts`

**Added targets:**
- `passengerCount` - Display for showing selected passenger count
- `checkIcon` - Visual indicator for selected passengers

**Added properties:**
- `selectedPassengers: Map<string, any>` - Stores selected passenger data
- `maxPassengers: number` - Maximum passengers allowed (from URL parameter)

**Added methods:**
- `togglePassenger(event: Event)` - Main method to handle passenger selection/deselection
  - Reads passenger data from dataset attributes
  - Checks if already selected (toggle off if yes)
  - Validates against max passenger limit
  - Updates UI and hidden field
  
- `updatePassengerUI(element: HTMLElement, selected: boolean)` - Updates visual state
  - Changes checkIcon color (gray → yellow when selected)
  
- `updatePassengerCountDisplay()` - Updates passenger count display
  - Shows "已选X人" text
  - Updates max seats for seat selection
  
- `updateHiddenField()` - Updates hidden form field
  - Writes comma-separated passenger IDs to `train_booking_passenger_ids` field

**Updated connect() method:**
- Now reads `passenger_count` from URL parameters
- Sets `maxPassengers` and `maxSeats` accordingly

**Updated validation:**
- Changed from checking radio button to checking hidden field value
- Both `handleSubmit()` and `handleNormalBooking()` now validate passenger IDs

#### 2. View Template (`app/views/train_bookings/new.html.erb`)
No changes needed - already had correct structure:
- Passenger items with `data-action="click->train-booking#togglePassenger"`
- Dataset attributes for passenger data
- Hidden field `train_booking_passenger_ids`
- Display targets for UI updates

## Technical Details

### Data Flow
1. User clicks passenger item
2. `togglePassenger()` method triggered via Stimulus action
3. Method reads passenger data from dataset attributes
4. Updates `selectedPassengers` Map
5. Calls `updatePassengerUI()` to change visual state
6. Calls `updatePassengerCountDisplay()` to update counter
7. Calls `updateHiddenField()` to write IDs to form field

### Dynamic Passenger Limit
- Homepage selection sets `passenger_count` URL parameter
- Booking page reads this parameter in `connect()` method
- Sets `maxPassengers` limit for validation
- Also updates `maxSeats` for seat selection logic

### Visual Feedback
- Unselected: Gray checkmark icon (`text-gray-300`)
- Selected: Yellow checkmark icon (`text-yellow-400`)
- Count display: "已选X人" (X = number of selected passengers)

## Testing

### Unit Tests
All existing RSpec tests pass:
```bash
bundle exec rspec spec/requests/train_bookings_spec.rb
# 3 examples, 0 failures
```

### Manual Testing
Test scenarios:
1. ✅ Click passenger item - selects passenger and shows yellow checkmark
2. ✅ Click again - deselects passenger and reverts to gray
3. ✅ Select multiple passengers - updates count correctly
4. ✅ Exceed max limit - shows toast notification
5. ✅ Submit without passengers - shows validation error
6. ✅ Dynamic limit from homepage - respects passenger_count parameter

## Files Modified
- `app/javascript/controllers/train_booking_controller.ts` - Added passenger selection logic
- No view changes needed

## Compiled Assets
- TypeScript compiled successfully with `npm run build`
- Only warnings (no errors)
- Generated JavaScript bundles updated

## Related Features
- Flight booking passenger selector (reference implementation in `booking_controller.ts`)
- Homepage passenger count selector (sets URL parameter)
- Seat selection (max seats now tied to passenger count)

## Error Resolution
The frontend errors are now resolved:
- ❌ Before: `method "togglePassenger" does not exist`
- ✅ After: Method implemented and fully functional

Users can now:
- Select passengers by clicking on passenger items
- See visual feedback (yellow checkmark)
- Respect dynamic passenger limits from homepage
- Successfully submit bookings with selected passengers
