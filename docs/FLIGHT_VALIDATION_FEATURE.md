# 机票搜索表单验证功能

## 功能说明

当用户在机票搜索页面选择出发地和目的地时，如果两者相同，在提交表单时会弹出提示"出发地与目的地不能相同"，阻止表单提交。

## 实现细节

### 1. 前端验证逻辑

**文件**: `app/javascript/controllers/flight_search_controller.ts`

- 创建了 `flight_search_controller.ts` Stimulus 控制器
- 定义了两个 target：`departureInput` 和 `destinationInput`
- 实现了 `validateForm` 方法，在表单提交时检查：
  - 出发地和目的地的值是否存在
  - 两个值是否相同
  - 如果相同，调用 `event.preventDefault()` 阻止提交并弹出 alert 提示

### 2. HTML 集成

**文件**: `app/views/flights/index.html.erb`

在单程/往返机票搜索表单中：

```erb
<%= form_with url: search_flights_path, method: :get, local: true, 
  data: { turbo: false, controller: 'flight-search', action: 'submit->flight-search#validateForm' } do |f| %>
  
  <%= f.hidden_field :departure_city, value: '北京', 
    data: { 'city-selector-target': 'departureCityInput', 'flight-search-target': 'departureInput' } %>
  
  <%= f.hidden_field :destination_city, value: '杭州', 
    data: { 'city-selector-target': 'destinationCityInput', 'flight-search-target': 'destinationInput' } %>
  
  <!-- 其他表单字段 -->
  
  <button type="submit">搜索机票</button>
<% end %>
```

**关键配置**:
- 表单添加了 `data-controller="flight-search"` 
- 表单添加了 `data-action="submit->flight-search#validateForm"`
- 两个隐藏字段添加了 `data-flight-search-target` 属性

## 用户体验流程

1. 用户进入机票搜索页面 `/flights`
2. 用户选择出发地（例如：北京）
3. 用户选择目的地（如果也选择：北京）
4. 用户点击"搜索机票"按钮
5. **系统弹出提示**："出发地与目的地不能相同"
6. 表单提交被阻止，用户需要修改城市选择

## 技术要点

- 使用 Stimulus 框架进行前端交互
- 验证在客户端执行，无需服务器往返
- 使用 `event.preventDefault()` 阻止表单提交
- 支持与现有的 `city-selector` 控制器协同工作

## 测试验证

访问页面：`http://localhost:3000/flights`

测试步骤：
1. 点击出发地，选择一个城市（如北京）
2. 点击目的地，选择同一个城市（北京）
3. 点击"搜索机票"按钮
4. 应该看到提示：「出发地与目的地不能相同」

## 注意事项

- 多程搜索表单（multi-city）暂未添加此验证
- 验证仅在单程/往返搜索表单中生效
- 如需为多程搜索添加类似验证，需要在 `multi_city_controller` 中实现相应逻辑
