# Ticket Product Logic Fix - Summary

## Issue Description

The ticket product logic had an inconsistency between the list page and selection page:

- **Index page** (`tickets/index.html.erb`): Showed 3 product types - 成人票 (adult), 家庭票 (family), 儿童票 (child)
- **Select page** (`tickets/select.html.erb`): Only showed adult and child tickets in separate sections, missing family ticket and lacking the ability to switch between ticket types

## User Requirements

1. Remove family tickets (家庭套票) from the system
2. Keep only adult tickets (成人票) and child tickets (儿童票)
3. Allow users to switch between adult and child tickets on the selection page using tabs
4. Maintain consistency between the product list and selection pages

## Changes Made

### 1. Data Layer - Remove Family Tickets
**File**: `app/validators/support/data_packs/v1/attractions.rb`

- Removed all `ticket_type: "family"` entries from the tickets data
- Removed the following family tickets:
  - 深圳欢乐港湾家庭套票 (¥450)
  - 广州长隆家庭套票 (¥720)

**Result**: Database now contains only adult and child tickets (14 tickets total: 7 adult + 6 child + 1 student)

### 2. View Layer - Refactor Selection Page
**File**: `app/views/tickets/select.html.erb`

**Before**: Separate sections for adult and child tickets
```erb
<!-- Adult Tickets Section -->
<% if @adult_tickets.any? %>
  <div class="bg-surface p-4">
    <h3>成人票</h3>
    ...
  </div>
<% end %>

<!-- Child Tickets Section -->
<% if @child_tickets.any? %>
  <div class="bg-surface p-4">
    <h3>儿童票</h3>
    ...
  </div>
<% end %>
```

**After**: Single section with tab navigation
```erb
<div class="bg-surface p-4" data-controller="ticket-selector">
  <h3>门票类型</h3>
  
  <!-- Tab Navigation -->
  <div class="flex gap-2 mb-4">
    <button data-ticket-type="adult" data-action="ticket-selector#switchType">成人票</button>
    <button data-ticket-type="child" data-action="ticket-selector#switchType">儿童票</button>
  </div>

  <!-- Adult Tickets Panel -->
  <div data-ticket-selector-target="panel" data-ticket-type="adult">...</div>

  <!-- Child Tickets Panel -->
  <div data-ticket-selector-target="panel" data-ticket-type="child">...</div>
</div>
```

### 3. Controller Layer - Tab Switching Logic
**File**: `app/javascript/controllers/ticket_selector_controller.ts`

Created a new Stimulus controller to handle tab switching:

```typescript
export default class extends Controller {
  static targets = ["tab", "panel"]

  switchType(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const targetType = button.dataset.ticketType

    // Update tab styles (active/inactive)
    this.tabTargets.forEach((tab) => {
      const isActive = tab.dataset.ticketType === targetType
      // Toggle bg-primary/text-white vs bg-gray-100/text-gray-700
    })

    // Update panel visibility (show/hide)
    this.panelTargets.forEach((panel) => {
      const isActive = panel.dataset.ticketType === targetType
      panel.classList.toggle("hidden", !isActive)
    })
  }
}
```

### 4. Registration
**File**: `app/javascript/controllers/index.ts`

Registered the new controller:
```typescript
import TicketSelectorController from "./ticket_selector_controller"
application.register("ticket-selector", TicketSelectorController)
```

## Testing Results

### Database Verification
```bash
$ rails runner "puts Ticket.where(ticket_type: 'family').count"
=> 0  # ✓ No family tickets

$ rails runner "puts Ticket.where(ticket_type: 'adult').count"
=> 7  # ✓ Adult tickets exist

$ rails runner "puts Ticket.where(ticket_type: 'child').count"
=> 6  # ✓ Child tickets exist
```

### UI Verification
```bash
$ curl http://localhost:3000/tickets/82/select | grep -o 'ticket-selector'
=> ticket-selector  # ✓ Controller attached

$ curl http://localhost:3000/tickets/82/select | grep -o 'data-ticket-type="adult"'
=> data-ticket-type="adult"  # ✓ Adult tab exists

$ curl http://localhost:3000/tickets/82/select | grep -o 'data-ticket-type="child"'
=> data-ticket-type="child"  # ✓ Child tab exists

$ curl http://localhost:3000/tickets | grep -i '家庭'
=> (no output)  # ✓ No family tickets in index page
```

## User Experience Flow

### Before Fix
1. User sees 3 ticket types on index page: Adult, Child, Family
2. User clicks "立即预订" (Book Now)
3. User arrives at select page and sees only Adult OR Child sections
4. **Problem**: Disconnected experience, cannot switch ticket types, family ticket missing

### After Fix
1. User sees 2 ticket types on index page: Adult, Child (no family)
2. User clicks "立即预订" (Book Now)
3. User arrives at select page with tabs: 成人票 | 儿童票
4. User can switch between adult and child tickets using tabs
5. **Result**: Consistent experience, flexible selection, unified product offering

## Benefits

1. **Consistency**: Index and select pages now show the same ticket types
2. **Flexibility**: Users can switch between adult and child tickets without going back
3. **Simplicity**: Removed unnecessary family ticket product, reducing complexity
4. **Better UX**: Tab-based interface is more intuitive than separate sections

## Files Modified

1. `app/validators/support/data_packs/v1/attractions.rb` - Data cleanup
2. `app/views/tickets/select.html.erb` - View refactor
3. `app/javascript/controllers/ticket_selector_controller.ts` - New controller
4. `app/javascript/controllers/index.ts` - Controller registration

## Migration Notes

If there are existing family tickets in the production database, run this migration:

```ruby
# Remove family tickets from production
rails runner "Ticket.where(ticket_type: 'family').destroy_all"
```
