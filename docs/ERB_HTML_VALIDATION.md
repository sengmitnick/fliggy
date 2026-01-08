# ERB HTML Validation Guide

## Overview

The `bin/validate_erb_html` script validates the HTML structure of all ERB template files to catch common errors early in development.

## Why ERB HTML Validation?

ERB templates mix Ruby code with HTML, which can easily lead to:
- **Unclosed tags** when ERB conditions span across HTML elements
- **Invalid nesting** when loops or conditions break HTML structure
- **Missing closing tags** that work in some branches but break in others
- **Structural issues** that pass Ruby syntax checks but produce invalid HTML

These issues often manifest as:
- Layout breaking unexpectedly
- Elements appearing in wrong places
- CSS styles not applying correctly
- Accessibility problems
- Browser parsing inconsistencies

## Installation

The validator requires `html-validate` npm package:

```bash
npm install --save-dev html-validate
```

Configuration is in `.htmlvalidate.json` at project root.

## Usage

### Validate All ERB Files

```bash
# Using rake task (recommended)
rake erb:validate

# Direct script execution
ruby bin/validate_erb_html
```

This scans all `app/views/**/*.html.erb` files and reports any HTML structure issues.

### Validate Single File

```bash
# Using rake task
rake erb:validate_file[app/views/flights/index.html.erb]

# Direct script execution
ruby bin/validate_erb_html app/views/flights/index.html.erb
```

Useful when working on a specific view and want quick feedback.

## Understanding Validation Errors

### Error Format

```
❌ Found HTML structure issues in 2 file(s):

📄 app/views/flights/index.html.erb
   Line 45:12 - Element <div> is not closed
   Line 67:8 - Element <p> cannot be child of <span>

📄 app/views/shared/_navbar.html.erb
   Line 23:5 - Element <ul> is missing required attribute "role"
```

Each error shows:
- **File path**: Which ERB file has the issue
- **Line:Column**: Exact location in the file
- **Error message**: What's wrong with the HTML

## Common ERB Patterns That Break HTML

### 1. Conditional Tag Splitting (ANTI-PATTERN)

**❌ BAD - Opens tag in one branch, closes in another:**

```erb
<div class="container">
  <% if @user.admin? %>
    <div class="admin-panel">
  <% else %>
    <div class="user-panel">
  <% end %>
  
    <p>Content here</p>
  </div>  <!-- Which div is this closing? Ambiguous! -->
</div>
```

**✅ GOOD - Complete HTML in each branch:**

```erb
<div class="container">
  <% if @user.admin? %>
    <div class="admin-panel">
      <p>Content here</p>
    </div>
  <% else %>
    <div class="user-panel">
      <p>Content here</p>
    </div>
  <% end %>
</div>
```

### 2. Loop-Generated Unclosed Tags (ANTI-PATTERN)

**❌ BAD - Loop opens tags but doesn't close:**

```erb
<ul>
  <% @items.each do |item| %>
    <li>
      <% if item.featured? %>
        <strong><%= item.name %>
      <% else %>
        <%= item.name %>
      <% end %>
    </li>  <!-- <strong> never closed when featured! -->
  <% end %>
</ul>
```

**✅ GOOD - All tags closed in all branches:**

```erb
<ul>
  <% @items.each do |item| %>
    <li>
      <% if item.featured? %>
        <strong><%= item.name %></strong>
      <% else %>
        <%= item.name %>
      <% end %>
    </li>
  <% end %>
</ul>
```

### 3. Invalid Nesting (ANTI-PATTERN)

**❌ BAD - Block element inside inline element:**

```erb
<span class="wrapper">
  <div class="content">  <!-- Invalid! div cannot be inside span -->
    <%= @text %>
  </div>
</span>
```

**✅ GOOD - Use appropriate semantic elements:**

```erb
<div class="wrapper">  <!-- Use div or other block element -->
  <div class="content">
    <%= @text %>
  </div>
</div>

<!-- OR if you need inline wrapper: -->
<span class="wrapper">
  <span class="content">  <!-- Keep everything inline -->
    <%= @text %>
  </span>
</span>
```

### 4. Partial Rendering Assumptions (ANTI-PATTERN)

**❌ BAD - Partial expects wrapper that's not always there:**

```erb
<!-- _item.html.erb partial -->
  <div class="item">  <!-- Missing opening wrapper -->
    <%= item.name %>
  </div>
</div>  <!-- Closing non-existent wrapper -->

<!-- Caller view -->
<%= render partial: 'item', collection: @items %>
<!-- No wrapper provided, breaks structure -->
```

**✅ GOOD - Partial is self-contained:**

```erb
<!-- _item.html.erb partial -->
<div class="item">
  <%= item.name %>
</div>

<!-- Caller view -->
<div class="items-container">
  <%= render partial: 'item', collection: @items %>
</div>
```

### 5. Conditional Attributes Breaking Structure

**❌ BAD - ERB logic breaks tag structure:**

```erb
<div 
  <% if @highlighted %>
    class="highlighted"
  <% end %>
>  <!-- Invalid syntax -->
```

**✅ GOOD - Proper conditional attributes:**

```erb
<div class="<%= 'highlighted' if @highlighted %>">
  <!-- OR -->
<div <%= 'class="highlighted"' if @highlighted %>>
  <!-- OR best: -->
<div class="<%= @highlighted ? 'highlighted' : '' %>">
```

## Debugging Strategy

When you see an HTML validation error, follow these steps:

### Step 1: Locate the Error

```bash
❌ app/views/flights/index.html.erb
   Line 45:12 - Element <div> is not closed
```

1. Open the file: `app/views/flights/index.html.erb`
2. Go to line 45, column 12
3. Identify the problematic HTML element

### Step 2: Understand the Context

Look at the surrounding code:
- Is there ERB logic (`<% if %>`, `<% each %>`) around this line?
- Does the element span multiple ERB branches?
- Are there any partials being rendered nearby?

### Step 3: Trace Through ALL Branches

For each ERB conditional:
```erb
<% if condition %>
  <!-- Check: Are all tags opened here also closed here? -->
<% else %>
  <!-- Check: Are all tags opened here also closed here? -->
<% end %>
```

### Step 4: Verify the Fix

After making changes:

```bash
# Re-run validation
rake erb:validate_file[app/views/flights/index.html.erb]

# Should see:
✅ All ERB files have valid HTML structure!
```

### Step 5: Test in Browser

Even after validation passes:
1. Start the app: `bin/dev`
2. Visit the page in browser
3. Verify layout renders correctly
4. Check browser console for any errors

## Integration with Development Workflow

### When to Run Validation

1. **After creating new views**: Validate immediately
2. **After modifying existing views**: Ensure changes didn't break structure
3. **Before committing**: Add to pre-commit checks
4. **In CI/CD pipeline**: Fail build on validation errors

### Adding to Git Pre-commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash

echo "🔍 Running ERB HTML validation..."
if ! rake erb:validate; then
  echo "❌ ERB HTML validation failed. Please fix errors before committing."
  exit 1
fi

echo "✅ ERB HTML validation passed"
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

## Configuration

The validator uses `.htmlvalidate.json` for configuration. Current settings:

```json
{
  "extends": ["html-validate:recommended"],
  "rules": {
    "element-permitted-content": "error",
    "element-required-attributes": "error",
    "no-missing-close": "error",
    "close-order": "error",
    "no-dup-attr": "error",
    ...
  }
}
```

### Customizing Rules

To adjust validation rules, edit `.htmlvalidate.json`:

```json
{
  "rules": {
    "void-style": ["error", { "style": "omit" }],
    "attr-quotes": ["error", { "style": "double" }]
  }
}
```

See [html-validate documentation](https://html-validate.org/rules/) for all available rules.

## Troubleshooting

### Validator Hangs or Takes Too Long

The validator processes each file through `npx html-validate`, which can be slow for large projects:

- Use single-file validation during development
- Run full validation before commits only
- Consider parallel processing for CI/CD (future enhancement)

### False Positives

If validator reports an error that's actually valid HTML:

1. **Double-check**: Is it really valid? Consult HTML5 spec
2. **Context issue**: Does ERB logic create invalid structure in some branches?
3. **Configure rule**: If truly a false positive, adjust rule in `.htmlvalidate.json`

**DO NOT disable validation entirely** - fix the root cause instead.

### Turbo Stream Templates

Turbo Stream templates (`.turbo_stream.erb`) contain `<turbo-stream>` tags that are valid in this context but might be flagged. These are configured as valid elements in `.htmlvalidate.json`.

## Best Practices

### 1. Keep ERB Logic Simple

**✅ Prefer:**
```erb
<div class="<%= user.role %>-panel">
  <%= render "#{user.role}_content" %>
</div>
```

**❌ Avoid:**
```erb
<% if user.admin? %>
  <div class="admin-panel">
<% elsif user.moderator? %>
  <div class="mod-panel">
<% else %>
  <div class="user-panel">
<% end %>
  <%= content %>
</div>
```

### 2. Use Partials for Complex Conditional Rendering

**✅ Extract to partial:**
```erb
<%= render "panels/#{user.role}_panel", user: user %>
```

Each partial contains complete, valid HTML.

### 3. Validate Early and Often

Don't wait until you have dozens of view files to run validation. Run it:
- After creating each new view
- After any significant ERB changes
- Before pushing code

### 4. Fix Root Causes, Not Symptoms

When you see validation errors, don't just patch them. Understand:
- Why is the structure invalid?
- Is there a better way to organize this ERB code?
- Can logic be moved to the controller or helper?

## Summary

The ERB HTML validator helps maintain clean, valid HTML structure in your Rails views by:
- ✅ Catching structural errors early
- ✅ Preventing layout bugs before they reach production
- ✅ Enforcing HTML best practices
- ✅ Improving code maintainability

**Remember**: Valid HTML structure is not just about passing validation - it's about creating robust, accessible, maintainable web applications.

Run `rake erb:validate` regularly and keep your views clean! 🎯
