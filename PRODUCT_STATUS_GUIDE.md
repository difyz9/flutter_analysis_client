# 产品状态检查 - 快速参考

Flutter Analysis Client 现在支持根据产品名称检查状态，用于控制应用是否可以启动。

## API 端点

```bash
curl -X GET 'http://localhost:8080/api/products/DigiBankApp' \
  -H 'accept: application/json'
```

## 响应格式

```json
{
  "code": 0,
  "data": {
    "name": "DigiBankApp",
    "display_name": "DigiBankApp", 
    "description": "",
    "icon_url": "",
    "homepage_url": "",
    "status": "active",
    "total_events": 0,
    "total_devices": 0,
    "total_licenses": 0,
    "active_devices_7d": 0,
    "active_devices_30d": 0,
    "events_today": 0,
    "last_activity": "0001-01-01 00:00:00",
    "first_seen": "0001-01-01 00:00:00", 
    "created_at": "0001-01-01 00:00:00",
    "updated_at": "0001-01-01 00:00:00"
  },
  "message": "success"
}
```

## 应用启动控制

**只有当 `status: "active"` 时，应用才能启动。**

其他状态值（如 `inactive`, `maintenance` 等）将阻止应用启动。

## 使用方法

### 方法1：简单检查

```dart
// 检查是否可以启动
final result = await client.canLaunchApp();
if (result.isSuccess && result.value) {
  // 应用可以启动
  await client.reportLaunch();
} else {
  // 显示维护页面
}
```

### 方法2：详细状态

```dart
// 获取详细产品状态
final statusResult = await client.checkProductStatus();
if (statusResult.isSuccess) {
  final response = statusResult.value;
  if (response.canLaunch) {
    print('✅ 应用可以启动');
    print('📊 设备总数: ${response.data?.totalDevices}');
    print('📈 7天活跃设备: ${response.data?.activeDevices7d}');
  } else {
    print('❌ 应用无法启动 - 状态: ${response.data?.status}');
  }
}
```

### 方法3：使用单例模式

```dart
void main() {
  Analytics.initialize(
    serverUrl: 'http://localhost:8080',
    productName: 'DigiBankApp',
  );
  
  runApp(MyApp());
}

// 在任何地方检查
final canLaunch = await Analytics.instance.canLaunchApp();
```

### 方法4：应用启动集成

```dart
class AppStartupManager {
  Future<bool> checkAppStatus() async {
    final result = await Analytics.instance.checkProductStatus();
    
    if (result.isFailure) {
      // 网络错误，允许启动（优雅降级）
      return true;
    }
    
    return result.value.canLaunch;
  }
}

void main() async {
  final manager = AppStartupManager();
  final canStart = await manager.checkAppStatus();
  
  if (canStart) {
    runApp(MyApp());
  } else {
    runApp(MaintenanceApp());
  }
}
```

## 新增 API 方法

### AnalyticsClient

- `checkProductStatus([productName])` → `Result<ProductStatusResponse>`
- `canLaunchApp([productName])` → `Result<bool>`

### Analytics 单例

- `Analytics.instance.checkProductStatus([productName])`
- `Analytics.instance.canLaunchApp([productName])`
- `Analytics.checkProductStatusStatic([productName])` 
- `Analytics.canLaunchAppStatic([productName])`

## 新增模型

### ProductStatus

```dart
class ProductStatus {
  final String name;
  final String displayName;
  final String status;
  final int totalEvents;
  final int totalDevices;
  // ... 其他字段
  
  bool get isActive => status == 'active';
}
```

### ProductStatusResponse

```dart
class ProductStatusResponse {
  final int code;
  final ProductStatus? data;
  final String message;
  
  bool get isSuccess => code == 0;
  bool get canLaunch => isSuccess && data?.isActive == true;
}
```

## 错误处理

```dart
final result = await client.checkProductStatus();

if (result.isFailure) {
  final error = result.error;
  if (error is NetworkException) {
    // 网络错误 - 可以选择允许启动
    print('网络错误: ${error.message}');
  } else {
    // 其他错误
    print('检查失败: ${error.message}');
  }
}
```

## 最佳实践

1. **优雅降级**: 在网络错误时允许应用启动
2. **缓存结果**: 避免频繁检查状态
3. **用户体验**: 提供清晰的维护/错误页面
4. **重试机制**: 允许用户手动重试状态检查
5. **超时设置**: 设置合理的网络超时时间

## 示例场景

- **维护模式**: 服务器设置 `status: "maintenance"`，阻止所有应用启动
- **版本控制**: 针对特定版本设置不同状态
- **灰度发布**: 逐步开放应用访问权限
- **紧急关停**: 快速禁用有问题的应用版本