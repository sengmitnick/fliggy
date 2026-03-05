# Train Booking Passenger Pre-selection from Homepage

## Feature Overview
This document describes the implementation of automatic passenger pre-selection in the train booking module, matching the behavior of the flight booking module.

## User Flow

### 1. Homepage Passenger Selection
Users select passengers on the trains search page (`trains/index.html.erb`):
- Open passenger selector modal
- Select specific passengers (adults, children, infants)
- Confirm selection

### 2. Data Persistence
Selected passenger information is stored in `localStorage`:
```javascript
localStorage.setItem('passenger_selection', JSON.stringify({
  passengerIds: [1, 2, 3],  // Array of passenger IDs
  adults: 2,
  children: 1,
  infants: 0
}))
```

### 3. Booking Page Auto-selection
When user navigates to booking page (`/train_bookings/new`):
- Controller reads `passenger_selection` from localStorage
- Automatically selects matching passengers
- Updates UI to show yellow checkmarks
- Auto-fills contact phone from first adult passenger

## Implementation Details

### Controller Method: `loadPassengersFromLocalStorage()`

Located in: `app/javascript/controllers/train_booking_controller.ts`

**Execution Flow:**
```typescript
connect() {
  // ... other initialization
  this.loadPassengersFromLocalStorage()  // Called automatically on page load
}

private loadPassengersFromLocalStorage(): void {
  // 1. Read from localStorage
  const savedState = localStorage.getItem('passenger_selection')
  if (!savedState) return
  
  // 2. Parse JSON data
  const state = JSON.parse(savedState)
  const passengerIds = state.passengerIds || []
  
  // 3. Only apply if passenger names mode was used
  if (passengerIds.length === 0) return
  
  // 4. Find and select each passenger
  passengerIds.forEach((passengerId: number) => {
    const passengerElement = document.querySelector(`[data-passenger-id="${passengerId}"]`)
    if (passengerElement) {
      // Add to selected passengers Map
      this.selectedPassengers.set(passengerId.toString(), { ... })
      
      // Update UI (yellow checkmark)
      this.updatePassengerUI(passengerElement, true)
      
      // Store first adult's phone
      if (passengerType === 'adult' && passengerPhone) {
        firstAdultPhone = passengerPhone
      }
    }
  })
  
  // 5. Auto-fill contact phone
  if (firstAdultPhone) {
    contactPhoneField.value = firstAdultPhone
  }
  
  // 6. Update UI displays
  this.updatePassengerCountDisplay()  // "已选X人"
  this.updateHiddenField()            // Hidden form field
}
```

## Visual Behavior

### Before Auto-selection
- All passengers show **gray** checkmark icon
- Passenger count displays: "已选0人"
- Contact phone field is empty

### After Auto-selection
- Pre-selected passengers show **yellow** checkmark icon
- Passenger count displays: "已选X人" (X = number of selected passengers)
- Contact phone auto-filled with first adult passenger's phone number
- Hidden field `train_booking_passenger_ids` contains comma-separated IDs

## Data Flow Diagram

```
┌─────────────────┐
│  Search Page    │
│  (Homepage)     │
└────────┬────────┘
         │ User selects passengers
         │ Clicks "确定"
         ↓
┌─────────────────┐
│  localStorage   │
│  'passenger_    │
│   selection'    │
└────────┬────────┘
         │ User clicks train → booking
         ↓
┌─────────────────┐
│  Booking Page   │
│  connect()      │
└────────┬────────┘
         │ loadPassengersFromLocalStorage()
         ↓
┌─────────────────┐
│  Auto-select    │
│  Passengers     │
│  - Yellow ✓     │
│  - Count update │
│  - Phone fill   │
└─────────────────┘
```

## Code References

### View Template
**File:** `app/views/train_bookings/new.html.erb`

Passenger items have required data attributes:
```erb
<div data-action="click->train-booking#togglePassenger"
     data-passenger-id="<%= passenger.id %>"
     data-passenger-name="<%= passenger.name %>"
     data-passenger-id-number="<%= passenger.id_number %>"
     data-passenger-phone="<%= passenger.phone %>"
     data-passenger-type="<%= passenger.child_ticket? ? 'child' : 'adult' %>">
  <!-- Passenger info -->
  <div data-train-booking-target="checkIcon">
    <!-- Checkmark SVG -->
  </div>
</div>
```

### Controller Targets
```typescript
static targets = [
  "passengerCount",  // Display: "已选X人"
  "checkIcon"        // Visual indicator (gray/yellow)
]
```

### Hidden Form Field
```erb
<%= f.hidden_field :passenger_ids, 
      id: "train_booking_passenger_ids", 
      value: "", 
      name: 'train_booking[passenger_ids]' %>
```

This field is automatically populated with comma-separated passenger IDs.

## Comparison with Flight Module

| Feature | Flight Module | Train Module | Status |
|---------|--------------|--------------|--------|
| Read from localStorage | ✅ | ✅ | Same |
| Auto-select passengers | ✅ | ✅ | Same |
| Yellow checkmark UI | ✅ | ✅ | Same |
| Auto-fill contact phone | ✅ | ✅ | Same |
| Update passenger count | ✅ | ✅ | Same |
| Update hidden field | ✅ | ✅ | Same |

Both modules now have **identical behavior** for passenger pre-selection.

## Testing

### Manual Test Steps
1. Go to trains search page (homepage)
2. Click passenger selector
3. Select 2 adults and 1 child
4. Click "确定"
5. Search for a train
6. Click on a train to view details
7. Click "立即预订" to go to booking page
8. **Expected Result:**
   - 3 passengers automatically selected (yellow checkmarks)
   - "已选3人" displayed
   - Contact phone auto-filled
   - Can toggle passengers on/off by clicking

### Automated Tests
```bash
bundle exec rspec spec/requests/train_bookings_spec.rb
# All tests pass ✅
```

## Error Handling

The implementation includes robust error handling:

```typescript
try {
  const state = JSON.parse(savedState)
  // ... processing
} catch (e) {
  console.error('Failed to load passengers from localStorage:', e)
  // Silently fail - user can still manually select passengers
}
```

**Graceful degradation:**
- Invalid JSON → Ignore, no error shown to user
- Missing passenger IDs → No pre-selection, normal flow
- Passenger not found in DB → Skip that passenger, select others

## Benefits

1. **Better UX**: Users don't need to re-select passengers
2. **Consistency**: Matches flight module behavior
3. **Time-saving**: Reduces booking form friction
4. **Error prevention**: Pre-fills phone from passenger data
5. **Flexibility**: Users can still modify selection if needed

## Future Enhancements

Potential improvements (not yet implemented):
- Clear localStorage after booking submission
- Add expiration time to localStorage data
- Show notification "已为您自动选择X位乘客"
- Sync with passenger count from URL parameter

## Related Files

- Controller: `app/javascript/controllers/train_booking_controller.ts`
- View: `app/views/train_bookings/new.html.erb`
- Reference: `app/javascript/controllers/booking_controller.ts` (flight module)
- Passenger Selector: `app/javascript/controllers/passenger_selector_controller.ts`
- Modal: `app/views/shared/_passenger_selector_modal.html.erb`
