# ERB HTML Validation - Quick Reference

## 🚀 Quick Commands

```bash
# Validate all ERB files
rake erb:validate

# Validate single file
rake erb:validate_file[app/views/home/index.html.erb]

# Direct script execution
ruby bin/validate_erb_html
ruby bin/validate_erb_html app/views/specific_file.html.erb
```

## 🎯 When to Validate

| Situation | Action |
|-----------|--------|
| ✏️ Created new view | Run validation immediately |
| 🔧 Modified existing view | Validate after changes |
| 💾 Before commit | Full validation `rake erb:validate` |
| 🐛 Layout issues in browser | Check validation errors |

## ⚠️ Common Error Types

### 1. Stray End Tag (多余结束标签)

```
Line 46:14 - Stray end tag '</tbody>'
```

**原因：** ERB 条件分支中标签配对不一致

**修复：** 检查 if/else 分支，确保每个分支独立产生完整 HTML

### 2. Unclosed Element (未关闭元素)

```
Line 45:12 - Element <div> is not closed
```

**原因：** 标签打开但未关闭

**修复：** 添加对应的关闭标签，或检查是否被 ERB 逻辑打断

### 3. Invalid Nesting (无效嵌套)

```
Line 23:5 - <div> cannot be child of <span>
```

**原因：** 块级元素嵌套在行内元素中

**修复：** 使用正确的语义 HTML 元素

## 🔍 Debugging Workflow

```
┌─────────────────────────────────────┐
│  1. Read Error Message              │
│     - What line?                    │
│     - What error type?              │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  2. Open File & Locate Line         │
│     vim app/views/file.html.erb:45  │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  3. Check ERB Logic                 │
│     - Is there if/else nearby?      │
│     - Does loop affect structure?   │
│     - Are partials involved?        │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  4. Trace ALL Branches              │
│     - Does each branch close tags?  │
│     - Are tags in correct order?    │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  5. Fix & Re-validate               │
│     rake erb:validate_file[file]    │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  6. Test in Browser                 │
│     Ensure layout works correctly   │
└─────────────────────────────────────┘
```

## ❌ DON'T DO THIS

```erb
<!-- ❌ Conditional tag splitting -->
<% if admin? %>
  <div class="admin-panel">
<% else %>
  <div class="user-panel">
<% end %>
  <p>Content</p>
</div>  <!-- Which div is this closing??? -->

<!-- ❌ Loop with unclosed tags -->
<% @items.each do |item| %>
  <% if item.featured? %>
    <strong><%= item.name %>  <!-- Never closed! -->
  <% else %>
    <%= item.name %>
  <% end %>
<% end %>

<!-- ❌ Invalid nesting -->
<span class="wrapper">
  <div>Block inside inline!</div>  <!-- Invalid! -->
</span>
```

## ✅ DO THIS INSTEAD

```erb
<!-- ✅ Complete HTML in each branch -->
<% if admin? %>
  <div class="admin-panel">
    <p>Content</p>
  </div>
<% else %>
  <div class="user-panel">
    <p>Content</p>
  </div>
<% end %>

<!-- ✅ Proper tag closure -->
<% @items.each do |item| %>
  <% if item.featured? %>
    <strong><%= item.name %></strong>
  <% else %>
    <%= item.name %>
  <% end %>
<% end %>

<!-- ✅ Proper nesting -->
<div class="wrapper">
  <div class="content">Block inside block OK</div>
</div>
```

## 🧩 Common Patterns

### Pattern 1: Conditional Wrapper

```erb
<!-- Instead of splitting tags across branches -->
<div class="<%= admin? ? 'admin-panel' : 'user-panel' %>">
  <p>Content</p>
</div>
```

### Pattern 2: Conditional Content

```erb
<!-- Keep structure, vary content -->
<div class="panel">
  <% if admin? %>
    <%= render 'admin_content' %>
  <% else %>
    <%= render 'user_content' %>
  <% end %>
</div>
```

### Pattern 3: Collection with Empty State

```erb
<!-- Proper structure for both cases -->
<div class="list-container">
  <% if @items.any? %>
    <ul>
      <% @items.each do |item| %>
        <li><%= item.name %></li>
      <% end %>
    </ul>
  <% else %>
    <p class="empty-state">No items found</p>
  <% end %>
</div>
```

## 📊 Success Example

```
🔍 Validating app/views/home/index.html.erb...

✅ All ERB files have valid HTML structure!
```

## 🚨 Error Example

```
🔍 Validating app/views/admin/oplogs/index.html.erb...

❌ Found HTML structure issues in 1 file(s):

📄 app/views/admin/oplogs/index.html.erb
   Line 46:14 - Stray end tag '</tbody>'
   Line 47:12 - Stray end tag '</table>'
   Line 48:10 - Stray end tag '</div>'
```

**Action Required:** Fix structural issue, re-validate, test in browser.

## 💡 Pro Tips

1. **Validate early, validate often** - Don't wait until you have 100 errors
2. **One file at a time** - During development, validate the file you're working on
3. **Understand, don't patch** - Fix root cause, not symptoms
4. **Each branch must be complete** - Every if/else/elsif should produce valid, complete HTML
5. **Use partials for complex cases** - Extract complex conditional rendering to partials

## 📚 More Info

- Full guide: `docs/ERB_HTML_VALIDATION.md`
- Integration summary: `ERB_VALIDATION_INTEGRATION_SUMMARY.md`
- Project rules: `.clackyrules` (search for "ERB HTML Validation")

---

**Remember:** Valid HTML = Better UX + Fewer Bugs + Easier Maintenance 🎯
