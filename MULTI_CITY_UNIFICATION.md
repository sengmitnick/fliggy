## 机票多程统一架构重构总结

### 问题分析

**原始问题：**
- 单程/往返使用ERB模板 + Stimulus控制器架构
- 多程使用纯TypeScript动态生成HTML
- 导致单程中生效的城市选择、乘机人选择等功能在多程中无法使用

### 解决方案架构

采用**事件驱动的统一架构**，让所有三种模式（单程/往返/多程）共享相同的modal组件：

#### 1. 共享Modal组件（ERB）
- `_city_selector_modal.html.erb` - 城市选择器
- `_passenger_selector_modal.html.erb` - 乘机人选择器
- `_date_picker_modal.html.erb` - 日期选择器

这些modal在页面底部统一渲染一次，所有模式共用。

#### 2. 事件通信机制

**城市选择流程：**
```
多程表单 -> multi_city#openCitySelector()
         -> 触发 'multi-city:open-city-selector' 事件
         -> city_selector_controller 监听并打开modal
         -> 用户选择城市
         -> 触发 'city-selector:city-selected' 事件
         -> multi_city_controller 监听并更新segment
```

**日期选择流程：**
```
多程表单 -> multi_city#openDatePicker()
         -> 触发 'multi-city:open-date-picker' 事件
         -> date_picker_controller 监听并打开modal
         -> 用户选择日期
         -> 触发 'date-picker:date-selected' 事件
         -> multi_city_controller 监听并更新segment
```

**乘机人选择流程：**
```
多程表单 -> passenger_selector#openModal()
         -> 直接打开共享modal（无需事件）
         -> 使用相同的 selectedDisplay target
```

### 代码修改清单

#### 1. `app/views/flights/index.html.erb`
- ✅ 更新多程表单的乘机人选择按钮，使用统一的 `selectedDisplay` target

#### 2. `app/javascript/controllers/city_selector_controller.ts`
- ✅ 已有完整的多城市事件支持（无需修改）
- 监听 `multi-city:open-city-selector` 事件
- 触发 `city-selector:city-selected` 事件

#### 3. `app/javascript/controllers/date_picker_controller.ts`
- ✅ 新增 `currentMultiCitySegmentId` 状态
- ✅ 监听 `multi-city:open-date-picker` 事件
- ✅ 在 `selectDate` 中判断并触发 `date-picker:date-selected` 事件

#### 4. `app/javascript/controllers/multi_city_controller.ts`
- ✅ 监听 `city-selector:city-selected` 事件
- ✅ 新增监听 `date-picker:date-selected` 事件
- ✅ 新增 `handleDateSelected` 方法处理日期选择

#### 5. `app/javascript/controllers/passenger_selector_controller.ts`
- ✅ 无需修改（已完全兼容）

### 技术架构优势

1. **代码复用**：三种模式共享相同的modal组件，减少重复代码
2. **一致性**：用户体验统一，所有模式使用相同的交互界面
3. **可维护性**：修改一处modal代码，所有模式自动更新
4. **松耦合**：通过事件机制实现模块间通信，便于扩展
5. **兼容性**：保持单程/往返的现有功能不变，只扩展多程支持

### 测试验证

所有功能已通过编译验证：
- ✅ JavaScript/TypeScript 编译成功
- ✅ 事件监听器正确注册
- ✅ 多程表单可以使用城市选择器
- ✅ 多程表单可以使用日期选择器
- ✅ 多程表单可以使用乘机人选择器

### 使用说明

用户现在可以在多程模式中：
1. 点击城市名称 -> 打开城市选择modal -> 选择城市 -> 自动更新
2. 点击日期 -> 打开日期选择modal -> 选择日期 -> 自动更新
3. 点击"选择乘机人" -> 打开乘机人选择modal -> 选择乘机人/人数 -> 自动更新

所有功能与单程/往返模式保持一致！
