# 酒店筛选条件持久化功能测试指南

## 功能说明
当用户在酒店页面设置了筛选条件后，点击返回按钮回到首页，再次点击酒店按钮进入酒店页面时，之前设置的筛选条件将自动恢复。

## 实现方式
- 使用 `sessionStorage` 保存筛选状态
- 在离开页面时（`beforeunload` 事件）自动保存当前筛选条件
- 进入页面时自动检查并恢复之前的筛选条件
- 保存的数据24小时后自动过期

## 保存的筛选条件
- 城市 (city)
- 入住日期 (check_in)
- 离店日期 (check_out)
- 房间数 (rooms)
- 成人数 (adults)
- 儿童数 (children)
- 最低价格 (price_min)
- 最高价格 (price_max)
- 星级 (star_level)
- 搜索关键词 (query)

## 测试步骤

### 1. 访问酒店页面
打开浏览器，访问：
```
http://localhost:3000/hotels
```

### 2. 修改筛选条件
在酒店页面上进行以下操作：
- 点击城市选择器，选择不同的城市（如"北京"）
- 点击日期选择器，修改入住和离店日期
- 点击房间/客人选择器，修改房间数、成人数、儿童数
- 点击价格/星级筛选，设置价格范围和星级
- 点击搜索按钮提交筛选

### 3. 返回首页
点击页面左上角的返回按钮（"返回.png"图标），回到首页

### 4. 再次进入酒店页面
在首页点击"酒店"按钮，再次进入酒店页面

### 5. 验证筛选条件
检查以下内容是否与步骤2中设置的一致：
- ✅ 城市显示正确
- ✅ 入住/离店日期显示正确
- ✅ 房间数/成人数/儿童数显示正确
- ✅ 价格/星级筛选显示正确
- ✅ 酒店列表根据筛选条件显示

## 浏览器控制台日志
打开浏览器开发者工具（F12），在控制台中应该看到以下日志：

**页面加载时：**
```javascript
HotelFilterPersistence connected
No saved hotel filters found  // 第一次访问
// 或
Restoring hotel filters from sessionStorage: {...}  // 恢复筛选条件
Redirecting with restored filters: http://localhost:3000/hotels?city=...
```

**离开页面时：**
```javascript
Hotel filters saved to sessionStorage: {...}
```

## 测试 sessionStorage
在浏览器控制台中执行：
```javascript
// 查看保存的筛选条件
JSON.parse(sessionStorage.getItem('hotel_filters_state'))

// 手动清除筛选条件
sessionStorage.removeItem('hotel_filters_state')
```

## 预期行为

### ✅ 正常流程
1. 用户设置筛选条件
2. 离开页面时自动保存
3. 返回页面时自动恢复
4. 筛选条件完全一致

### ✅ 边界情况
1. **直接通过URL带参数访问**：不会覆盖URL参数
2. **24小时后**：自动过期，不再恢复
3. **清除浏览器数据**：筛选条件丢失（正常行为）
4. **首次访问**：使用默认筛选条件

## 技术实现文件
- Controller: `app/javascript/controllers/hotel_filter_persistence_controller.ts`
- View: `app/views/hotels/index.html.erb` (添加了 `hotel-filter-persistence` controller)
- Storage Key: `hotel_filters_state`
- Expiry Time: 24小时

## 注意事项
1. 使用 `sessionStorage`，关闭浏览器标签页后数据会清除
2. 不会影响搜索结果页面（search action）
3. 只在首次无参数访问时恢复筛选条件
4. 与现有筛选功能完全兼容，不会相互干扰
