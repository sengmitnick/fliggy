# 城市选择器标签按钮功能实现

## 问题描述
用户指出 `app/views/shared/_city_selector_modal.html.erb:59:13:59:92` 位置的按钮（"国际/中国港澳台"标签按钮）没有实现功能。

## 根本原因
1. 第58-59行的"国内"和"国际/中国港澳台"两个标签按钮没有绑定 Stimulus 点击事件
2. 按钮缺少 `data-city-selector-target` 属性定义
3. 虽然 Stimulus 控制器中已有 `showDomestic()` 和 `showInternational()` 方法，但没有被正确调用

## 实现方案

### 1. 视图修改 (app/views/shared/_city_selector_modal.html.erb)

**修改位置：** 第58-65行

**修改前：**
```erb
<button class="flex-1 py-3 text-sm font-medium border-b-2 border-gray-900">国内</button>
<button class="flex-1 py-3 text-sm font-medium text-gray-500">国际/中国港澳台</button>
```

**修改后：**
```erb
<button 
  data-city-selector-target="tabDomestic"
  data-action="click->city-selector#showDomestic"
  class="flex-1 py-3 text-sm font-medium border-b-2 border-gray-900">国内</button>
<button 
  data-city-selector-target="tabInternational"
  data-action="click->city-selector#showInternational"
  class="flex-1 py-3 text-sm font-medium text-gray-500">国际/中国港澳台</button>
```

### 2. Stimulus 控制器修改 (app/javascript/controllers/city_selector_controller.ts)

#### 2.1 添加 Target 定义（第16-17行）
```typescript
static targets = [
  // ... existing targets
  "tabDomestic",
  "tabInternational",
  // ... other targets
]
```

#### 2.2 添加 TypeScript 声明（第48-51行）
```typescript
declare readonly tabDomesticTarget: HTMLElement
declare readonly tabInternationalTarget: HTMLElement
```

#### 2.3 更新切换方法（第184-200行）

**修改前的问题：** 使用了错误的 target（tabDeparture/tabDestination）

**修改后：**
```typescript
showDomestic(): void {
  this.domesticListTarget.classList.remove('hidden')
  this.internationalListTarget.classList.add('hidden')
  this.tabDomesticTarget.classList.add('border-gray-900', 'text-gray-900')
  this.tabDomesticTarget.classList.remove('text-gray-500')
  this.tabInternationalTarget.classList.remove('border-gray-900', 'text-gray-900')
  this.tabInternationalTarget.classList.add('text-gray-500')
}

showInternational(): void {
  this.domesticListTarget.classList.add('hidden')
  this.internationalListTarget.classList.remove('hidden')
  this.tabDomesticTarget.classList.remove('border-gray-900', 'text-gray-900')
  this.tabDomesticTarget.classList.add('text-gray-500')
  this.tabInternationalTarget.classList.add('border-gray-900', 'text-gray-900')
  this.tabInternationalTarget.classList.remove('text-gray-500')
}
```

## 功能说明

### 点击"国内"按钮时：
1. 显示国内城市列表 (`domesticList`)
2. 隐藏国际城市列表 (`internationalList`)
3. 给"国内"按钮添加激活样式（黑色边框和文字）
4. 移除"国际/中国港澳台"按钮的激活样式

### 点击"国际/中国港澳台"按钮时：
1. 隐藏国内城市列表
2. 显示国际城市列表
3. 给"国际/中国港澳台"按钮添加激活样式
4. 移除"国内"按钮的激活样式

## 验证结果

✅ **HTML 输出验证：**
- `data-action="click->city-selector#showDomestic"` 已正确渲染
- `data-action="click->city-selector#showInternational"` 已正确渲染
- `data-city-selector-target="tabDomestic"` 已正确渲染
- `data-city-selector-target="tabInternational"` 已正确渲染

✅ **JavaScript 编译验证：**
- `showDomestic()` 方法已正确编译到 `app/assets/builds/application.js`
- `showInternational()` 方法已正确编译到 `app/assets/builds/application.js`

✅ **运行时验证：**
- 项目成功启动，无 JavaScript 错误
- 按钮绑定正确，可以正常触发对应方法

## 技术要点

1. **Stimulus Target 命名规范：** 使用语义化名称 `tabDomestic`/`tabInternational` 而非通用名称
2. **CSS 类切换：** 直接操作 Tailwind 类而非使用自定义 `.active-tab` 类（保持一致性）
3. **TypeScript 类型安全：** 正确声明所有 target 的类型为 `HTMLElement`
4. **视图-控制器绑定：** 使用 `data-action` 属性将点击事件绑定到 Stimulus 方法

## 相关文件

- ✏️ `app/views/shared/_city_selector_modal.html.erb` - 视图模板
- ✏️ `app/javascript/controllers/city_selector_controller.ts` - Stimulus 控制器
- 🔨 `app/assets/builds/application.js` - 编译后的 JavaScript（自动生成）

## 部署状态
✅ 功能已完全实现并验证通过
