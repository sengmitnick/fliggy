# 管理员登录后跳转功能

## 功能说明

当管理员访问需要认证的后台页面时（如 `/admin/validation_tasks/v006_book_morning_bus_validator`），如果未登录或会话失效，系统会：

1. 记录当前访问的路径到 session
2. 跳转到登录页面 `/admin/login`
3. 登录成功后，自动跳转回原来访问的页面

## 实现细节

### 1. 路径记录 (`Admin::BaseController`)

```ruby
def authenticate_admin!
  if current_admin.blank?
    store_location_for_admin
    redirect_to admin_login_path
    return
  end

  if current_admin.password_digest != session[:current_admin_token]
    store_location_for_admin
    redirect_to admin_login_path, alert: 'Password was changed, please log in again'
    return
  end
end

def store_location_for_admin
  # 只记录 GET 请求且非 AJAX 请求的路径
  session[:admin_return_to] = request.fullpath if request.get? && !request.xhr?
end
```

### 2. 登录后跳转 (`Admin::SessionsController`)

```ruby
def create
  create_first_admin_or_reset_password!
  admin = Administrator.find_by(name: params[:name])
  if admin && admin.authenticate(params[:password])
    admin_sign_in(admin)
    AdminOplogService.log_login(admin, request)
    redirect_to redirect_path_after_login  # 使用新方法
  else
    flash.now[:alert] = 'Username or password is wrong'
    render 'new', status: :unprocessable_entity
  end
end

private

def redirect_path_after_login
  return_to = session.delete(:admin_return_to)  # 获取并清除记录的路径
  return_to || admin_root_path                   # 如果没有记录，跳转到首页
end
```

## 使用场景

### 场景 1：访问受保护页面被拦截

```
用户访问：/admin/validation_tasks/v006_book_morning_bus_validator
        ↓ (未登录)
系统记录：session[:admin_return_to] = "/admin/validation_tasks/v006_book_morning_bus_validator"
        ↓
跳转到：/admin/login
        ↓ (登录成功)
跳转回：/admin/validation_tasks/v006_book_morning_bus_validator
```

### 场景 2：密码被修改导致会话失效

```
用户在页面 A：/admin/validation_tasks
        ↓
密码在其他地方被修改
        ↓
刷新页面或访问其他页面
        ↓ (会话失效)
系统记录：session[:admin_return_to] = "/admin/validation_tasks"
        ↓
跳转到：/admin/login (显示提示：Password was changed, please log in again)
        ↓ (重新登录)
跳转回：/admin/validation_tasks
```

### 场景 3：直接访问登录页面

```
用户直接访问：/admin/login
        ↓ (登录成功)
跳转到：/admin (首页)
```

## 限制条件

只有以下情况会记录返回路径：

- ✅ GET 请求（如：访问页面）
- ✅ 非 AJAX 请求（如：普通页面访问）

不会记录返回路径的情况：

- ❌ POST/PUT/DELETE 请求（如：表单提交）
- ❌ AJAX/XHR 请求（如：异步数据请求）

## 测试覆盖

测试文件：`spec/requests/admin/sessions_redirect_spec.rb`

测试场景：
1. ✅ 访问受保护页面被拦截后登录，跳转回原页面
2. ✅ 访问特定验证任务页面被拦截后登录，跳转回该页面
3. ✅ 直接登录（无记录路径），跳转到首页
4. ✅ 密码修改导致会话失效，记录当前路径
5. ✅ AJAX 请求不记录返回路径

## 安全考虑

- 使用 `session` 存储返回路径，避免 URL 参数被篡改
- 登录成功后立即删除 `session[:admin_return_to]`，防止重复使用
- 只记录 GET 请求，避免表单重复提交问题
- 使用 `request.fullpath` 记录完整路径（包括查询参数）
