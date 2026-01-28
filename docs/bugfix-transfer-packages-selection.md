# Bugfix: Transfer Packages Multiple Selection Issue

## Issue Description

**Problem:** Multiple transfer package options were incorrectly highlighted with yellow background when viewing the packages list page.

**URL:** `/transfers/packages?transfer_type=airport_pickup&service_type=from_airport&location_to=上海虹桥站南广场接送中心&location_from=浦东T2&flight_id=56`

**Root Cause:** 
The view logic was applying the yellow highlight (`bg-[#FFFBF0] border-yellow-300`) to the FIRST package in EACH category, rather than only the FIRST package globally across all categories.

## Before Fix

```erb
<% packages_in_category.each_with_index do |package, index| %>
  <div class="package-card ... <%= index == 0 ? 'bg-[#FFFBF0] border border-yellow-300' : 'bg-transparent' %> ...">
```

**Behavior:**
- Package ID 1 (economy_5 category, first): ✅ Highlighted
- Package ID 2 (economy_5 category, second): ❌ Not highlighted  
- Package ID 3 (economy_5 category, third): ❌ Not highlighted
- Package ID 4 (economy_5 category, fourth): ❌ Not highlighted
- Package ID 5 (comfort_5 category, **first**): ✅ **Highlighted** (BUG)
- Package ID 6 (comfort_5 category, second): ❌ Not highlighted
- Package ID 7 (economy_7 category, **first**): ✅ **Highlighted** (BUG)
- Package ID 8 (economy_7 category, second): ❌ Not highlighted

**Result:** 3 packages highlighted (IDs 1, 5, 7) - one per category

## After Fix

```erb
<% global_index = 0 %>
<% packages_in_category.each_with_index do |package, index| %>
  <% is_first_overall = (global_index == 0) %>
  <% global_index += 1 %>
  <div class="package-card ... <%= is_first_overall ? 'bg-[#FFFBF0] border border-yellow-300' : 'bg-transparent' %> ...">
```

**Behavior:**
- Package ID 1 (first globally): ✅ Highlighted
- Package ID 2-8: ❌ Not highlighted

**Result:** Only 1 package highlighted (ID 1) ✅

## JavaScript Fix

Also updated the click handler to remove selection from ALL cards, not just cards in the same category:

```javascript
// Before
document.querySelectorAll(`.package-card[data-category="${category}"]`).forEach(c => {

// After
document.querySelectorAll('.package-card').forEach(c => {
```

This ensures when a user clicks any package, ALL other highlights are removed first.

## Testing

### Manual Testing
```bash
# Check total packages
curl -s -H 'Authorization: Bearer 2' 'http://localhost:3000/transfers/packages?...' | grep -c 'class="package-card'
# Result: 8 packages

# Check highlighted packages
curl -s -H 'Authorization: Bearer 2' 'http://localhost:3000/transfers/packages?...' | grep 'class="package-card' | grep -c 'bg-\[#FFFBF0\]'
# Result: 1 (was 3 before fix)

# Check which package is highlighted
curl -s -H 'Authorization: Bearer 2' 'http://localhost:3000/transfers/packages?...' | grep 'package-card.*bg-\[#FFFBF0\]' | grep -oP 'data-package-id="\d+"'
# Result: data-package-id="1"
```

### Automated Tests
```bash
bundle exec rspec spec/requests/transfers_spec.rb --format documentation
# All tests pass ✅
```

## Files Changed

1. **app/views/transfers/packages.html.erb**
   - Added `global_index` variable to track position across all categories
   - Changed highlighting condition from `index == 0` to `is_first_overall`
   - Updated JavaScript to remove selection from ALL cards when clicking

## Impact

- **User Experience:** Users now see only ONE highlighted package (the cheapest/first option) instead of multiple confusing highlights
- **Visual Clarity:** Clear visual hierarchy showing the default selected option
- **Interaction:** Clicking any package correctly removes all other highlights and shows only the clicked one

## Related Code

- **Model:** `app/models/transfer_package.rb`
- **Controller:** `app/controllers/transfers_controller.rb#packages`
- **View:** `app/views/transfers/packages.html.erb`
- **Routes:** `config/routes.rb` (GET /transfers/packages)
