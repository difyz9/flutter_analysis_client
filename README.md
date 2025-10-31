# Flutter Analysis Client

[![Dart Version](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev/)
[![Flutter Platform](https://img.shields.io/badge/Flutter-Android%20%7C%20iOS%20%7C%20Web-blue.svg)](https://flutter.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Flutter Analysis Client 是一个轻量级、高性能的 Flutter 数据分析 SDK，支持事件追踪、用户行为分析和业务数据收集。

> 🚦 **新功能**: 现已支持基于服务器状态的应用启动控制！只有状态为 `active` 的产品才能正常启动，实现维护模式、版本控制等功能。

## ✨ 特性

- 🚀 **高性能**: 异步事件上报，不影响主业务性能
- 🔒 **安全加密**: 支持 AES 加密保护数据传输
- 📊 **丰富事件**: 支持自定义事件、用户事件、设备信息等
- 🎯 **批量上报**: 支持事件批量上报，提高传输效率
- 🛡️ **错误处理**: 完善的错误处理和重试机制
- 📱 **多平台**: 支持 Android、iOS、Web 等多种平台
- 📈 **安装统计**: 自动收集安装信息和应用生命周期数据
- 🔄 **会话管理**: 自动管理用户会话和设备识别
- 🎛️ **灵活配置**: 支持批量大小、刷新间隔等灵活配置
- 🚦 **启动控制**: 基于服务器状态的应用启动权限控制

## 📦 安装

### 方法一：添加到 pubspec.yaml

```yaml
dependencies:
  flutter_analysis_client:
    git:
      url: https://github.com/difyz9/flutter_analysis_client.git
      path: flutter_analysis_client
```

### 方法二：本地路径

```yaml
dependencies:
  flutter_analysis_client:
    path: ../flutter_analysis_client
```

然后运行：

```bash
flutter pub get
```

## 🚀 快速开始

### 安装依赖

```bash
cd flutter_analysis_client
flutter pub get
```

### 方法一：单例模式使用（推荐，最方便）

单例模式让你可以在应用的任何地方访问 Analytics，无需传递客户端实例。

```dart
import 'package:flutter_analysis_client/flutter_analysis_client.dart';

void main() async {
  // 1. 在应用启动时初始化一次
  Analytics.initialize(
    serverUrl: 'http://localhost:8080',
    productName: 'MyApp',
    debug: true,
  );

  // 2. 检查应用是否可以启动（新功能）
  final canLaunch = await Analytics.instance.canLaunchApp();
  if (canLaunch.isSuccess && canLaunch.value) {
    print('✅ 应用可以启动');
    await Analytics.instance.reportLaunch();
    runApp(MyApp());
  } else {
    print('❌ 应用无法启动，显示维护页面');
    runApp(MaintenanceApp());
  }
}

// 3. 在应用的任何地方使用 - 无需传递客户端实例！
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // 使用实例方法
        Analytics.instance.track(
          name: 'button_click',
          properties: {'button': 'home'},
        );
        
        // 或使用静态方法（更简短）
        Analytics.trackStatic('button_click', properties: {'button': 'home'});
      },
      child: Text('Click Me'),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            // 在任何地方都可以直接使用，无需依赖注入
            Analytics.instance.setUserId('user_123');
            Analytics.instance.trackEvent('profile_viewed');
          },
          child: Text('View Profile'),
        ),
      ],
    );
  }
}
```

### 方法二：直接使用客户端（适合多实例场景）

如果你需要创建多个客户端实例，可以直接使用 `AnalyticsClient`：

```dart
import 'package:flutter_analysis_client/flutter_analysis_client.dart';

void main() async {
  // 1. 创建客户端
  final client = AnalyticsClient.create(
    serverUrl: 'http://localhost:8080',
    productName: 'MyApp',
    debug: true,
  );

  // 2. 检查应用启动权限（新功能）
  final canLaunch = await client.canLaunchApp();
  if (canLaunch.isSuccess && canLaunch.value) {
    print('✅ 应用可以启动');
    await client.reportLaunch();
    // 继续应用启动流程
  } else {
    print('❌ 应用被禁止启动');
    // 显示维护页面或退出
  }

  // 3. 追踪事件
  await client.trackEvent('button_click', {
    'button_name': 'login',
    'screen': 'home',
  });

  // 4. 关闭客户端
  await client.close();
}
```

## 📖 详细用法

### 🚦 应用启动检查（新功能）

Flutter Analysis Client 支持基于服务器状态的应用启动控制。只有当产品状态为 `active` 时，应用才能正常启动。

#### 基本启动检查

```dart
void main() async {
  // 初始化客户端
  Analytics.initialize(
    serverUrl: 'http://localhost:8080',
    productName: 'HelloWorldApp',
    debug: true,
  );

  // 检查是否可以启动
  final canLaunch = await Analytics.instance.canLaunchApp();
  
  if (canLaunch.isSuccess && canLaunch.value) {
    print('✅ 应用可以启动');
    await Analytics.instance.reportLaunch();
    runApp(MyApp());
  } else {
    print('❌ 应用无法启动');
    runApp(MaintenanceApp());
  }
}
```

#### 详细状态检查

```dart
void main() async {
  Analytics.initialize(/*...*/);

  // 获取详细产品状态
  final statusResult = await Analytics.instance.checkProductStatus();
  
  if (statusResult.isSuccess) {
    final response = statusResult.value;
    final productStatus = response.data;
    
    print('产品名称: ${productStatus?.name}');
    print('当前状态: ${productStatus?.status}');
    print('设备总数: ${productStatus?.totalDevices}');
    print('7天活跃设备: ${productStatus?.activeDevices7d}');
    
    if (response.canLaunch) {
      print('✅ 状态检查通过，启动应用');
      runApp(MyApp());
    } else {
      print('❌ 状态检查失败: ${productStatus?.status}');
      runApp(MaintenanceApp());
    }
  } else {
    print('⚠️ 网络错误，使用离线模式启动');
    runApp(MyApp()); // 优雅降级
  }
}
```

#### 启动管理器模式

```dart
class AppStartupManager {
  static Future<bool> checkAndLaunch() async {
    try {
      // 初始化分析客户端
      Analytics.initialize(
        serverUrl: 'http://localhost:8080',
        productName: 'HelloWorldApp',
        debug: true,
      );

      // 检查产品状态
      final result = await Analytics.instance.checkProductStatus();
      
      if (result.isFailure) {
        // 网络错误，允许启动（优雅降级）
        print('⚠️ 无法连接服务器，允许离线启动');
        return true;
      }

      final response = result.value;
      if (response.canLaunch) {
        print('✅ 服务器授权成功');
        await Analytics.instance.reportLaunch();
        return true;
      } else {
        print('❌ 服务器拒绝启动: ${response.data?.status}');
        return false;
      }
    } catch (e) {
      print('💥 启动检查异常: $e');
      return true; // 异常时允许启动
    }
  }
}

void main() async {
  final canStart = await AppStartupManager.checkAndLaunch();
  
  if (canStart) {
    runApp(MyApp());
  } else {
    runApp(MaintenanceApp());
  }
}
```

#### 状态检查 API 说明

| 方法 | 返回类型 | 说明 |
|------|----------|------|
| `canLaunchApp([productName])` | `Result<bool>` | 简单检查是否可以启动 |
| `checkProductStatus([productName])` | `Result<ProductStatusResponse>` | 获取详细产品状态 |

**服务器 API 端点**: `GET /api/products/{productName}`

**状态值说明**:
- `active`: 应用可以正常启动 ✅
- `inactive`: 应用被禁用 ❌
- `maintenance`: 维护模式 🔧
- 其他值: 应用无法启动 ❌

### 单例模式高级用法

```dart
// ===== 初始化配置 =====
void main() {
  Analytics.initialize(
    serverUrl: 'http://localhost:8080',
    productName: 'MyApp',
    deviceId: 'custom-device-id',              // 自定义设备ID（可选）
    userId: 'user-123',                        // 用户ID（可选）
    timeout: Duration(seconds: 15),            // 网络超时时间
    batchSize: 30,                             // 批量发送大小
    flushInterval: Duration(seconds: 10),      // 自动刷新间隔
    bufferSize: 2000,                          // 事件缓冲区大小
    debug: true,                               // 调试模式
    encryption: EncryptionConfig.enabled(      // AES 加密配置
      'your-32-byte-secret-key-here!!!!!'
    ),
    logger: (message) => print(message),       // 自定义日志
  );

  runApp(MyApp());
}

// ===== 在任何 Widget 中使用 =====
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        // 追踪登录事件
        await Analytics.instance.trackAction(
          category: 'user',
          action: 'login',
          label: 'email',
        );
        
        // 设置用户ID
        Analytics.instance.setUserId('user_12345');
      },
      child: Text('Login'),
    );
  }
}

// ===== 在任何普通类中使用 =====
class UserService {
  Future<void> updateProfile(String userId) async {
    // 业务逻辑...
    
    // 追踪事件 - 无需依赖注入！
    await Analytics.trackStatic('profile_updated', properties: {
      'user_id': userId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}

// ===== 检查初始化状态 =====
void someFunction() {
  if (Analytics.isInitialized) {
    Analytics.instance.trackEvent('function_called');
  } else {
    print('Analytics not initialized yet');
  }
}

// ===== 获取会话信息 =====
void showSessionInfo() {
  final sessionInfo = Analytics.instance.sessionInfo;
  print('Session ID: ${sessionInfo['session_id']}');
  print('Device ID: ${sessionInfo['device_id']}');
}

// ===== 手动刷新事件 =====
Future<void> logout() async {
  await Analytics.trackStatic('user_logout');
  
  // 确保事件在退出前发送
  await Analytics.instance.flush();
  
  // 清理...
}
```

### 直接使用客户端（多实例）

```dart
final client = AnalyticsClient.create(
  serverUrl: 'http://localhost:8080',        // 服务器地址
  productName: 'MyApp',                      // 产品名称
  deviceId: 'custom-device-id',              // 自定义设备ID（可选）
  userId: 'user-123',                        // 用户ID（可选）
  timeout: Duration(seconds: 15),            // 网络超时时间
  batchSize: 30,                             // 批量发送大小
  flushInterval: Duration(seconds: 10),      // 自动刷新间隔
  bufferSize: 2000,                          // 事件缓冲区大小
  debug: true,                               // 调试模式
  encryption: EncryptionConfig.enabled(      // AES 加密配置
    'your-32-byte-secret-key-here!!!!!'
  ),
  logger: (message) => print(message),       // 自定义日志
);
```

### 事件追踪

#### 产品状态检查

```dart
// 检查产品状态（用于应用启动控制）
final statusResult = await client.checkProductStatus();
if (statusResult.isSuccess) {
  final statusResponse = statusResult.value;
  if (statusResponse.canLaunch) {
    print('✅ 应用可以启动 - 状态为 active');
    await client.reportLaunch();
  } else {
    print('❌ 应用无法启动 - 状态为 ${statusResponse.data?.status}');
    // 显示维护页面或错误信息
  }
}

// 简单的启动检查
final canLaunchResult = await client.canLaunchApp();
if (canLaunchResult.isSuccess && canLaunchResult.value) {
  // 继续应用启动流程
} else {
  // 阻止应用启动
}

// 检查指定产品的状态
final otherProductResult = await client.checkProductStatus('AnotherApp');
```

#### 应用生命周期事件

```dart
// 上报应用安装（推荐在应用首次启动时调用）
await client.reportInstall();

// 上报应用启动
await client.reportLaunch();
```

#### 基础事件

```dart
// 简单事件
await client.trackEvent('page_view', {
  'page': 'dashboard',
  'user_type': 'premium',
});

// 带分类的事件
await client.track(
  name: 'user_action',
  category: 'engagement',
  action: 'click',
  label: 'header_button',
  value: 1.0,
  properties: {
    'button_text': 'Sign Up',
    'location': 'header',
  },
);
```

#### 用户行为分析

```dart
// Google Analytics 风格的事件
await client.trackAction(
  category: 'ecommerce',
  action: 'purchase',
  label: 'premium_plan',
  value: 99.99,
  properties: {
    'currency': 'USD',
    'payment_method': 'credit_card',
  },
);
```

#### 生命周期事件

```dart
// 应用安装
await client.reportInstall();

// 应用启动
await client.reportLaunch();

// 设置用户ID
client.setUserId('user-456');
```

### 加密传输

```dart
// 启用 AES 加密
final client = AnalyticsClient.create(
  serverUrl: 'https://secure-analytics.com',
  productName: 'SecureApp',
  encryption: EncryptionConfig.enabled(
    'my-secret-key-32-bytes-long!!!'  // 32字节密钥用于 AES-256
  ),
);

// 所有事件将自动加密传输
await client.trackEvent('sensitive_data', {
  'user_email': 'user@example.com',
  'payment_info': 'encrypted_data',
});
```

### 会话管理

```dart
// 获取会话信息
final sessionInfo = client.sessionInfo;
print('Session ID: ${sessionInfo['session_id']}');
print('Device ID: ${sessionInfo['device_id']}');
print('User ID: ${sessionInfo['user_id']}');

// 监听事件流
client.eventStream.listen((event) {
  print('Event tracked: ${event.name} at ${event.timestamp}');
});
```

### 手动控制

```dart
// 手动刷新事件到服务器
final result = await client.flush();
if (result.isSuccess) {
  print('Events sent successfully');
} else {
  print('Failed to send events: ${result.error}');
}

// 检查缓冲区状态
print('Buffer size: ${client.bufferSize} events');
print('Is closed: ${client.isClosed}');
```

## 🏗️ 高级用法

### 自定义 HTTP 客户端

```dart
import 'package:http/http.dart' as http;

class CustomHttpClient implements HttpClient {
  final http.Client _client = http.Client();

  @override
  Future<HttpResponse> post(String url, {
    Map<String, String>? headers,
    Uint8List? body,
  }) async {
    final uri = Uri.parse(url);
    final response = await _client.post(
      uri,
      headers: headers,
      body: body,
    );
    
    return HttpResponse(
      statusCode: response.statusCode,
      body: response.body,
      headers: response.headers,
    );
  }

  @override
  void close() {
    _client.close();
  }
}

// 使用自定义客户端
final client = AnalyticsClient.create(
  serverUrl: 'http://localhost:8080',
  productName: 'MyApp',
  httpClient: CustomHttpClient(),
);
```

### 错误处理

```dart
final result = await client.trackEvent('test_event', {'key': 'value'});

if (result.isFailure) {
  final error = result.error;
  
  if (error is NetworkException) {
    print('Network error: ${error.statusCode} - ${error.message}');
  } else if (error is EncryptionException) {
    print('Encryption error: ${error.message}');
  } else if (error is BufferOverflowException) {
    print('Buffer full: ${error.message}');
  }
}
```

### 批量事件处理

```dart
// 事件会自动批量发送，但你也可以手动控制
final events = [
  AnalyticsEvent.now(name: 'event1', properties: {'key': 'value1'}),
  AnalyticsEvent.now(name: 'event2', properties: {'key': 'value2'}),
  AnalyticsEvent.now(name: 'event3', properties: {'key': 'value3'}),
];

// 这些事件会被添加到缓冲区，当达到 batchSize 时自动发送
for (final event in events) {
  await client.trackEvent(event.name, event.properties);
}
```

## 🧪 测试

运行示例：

```bash
cd example
dart run main.dart
```

运行测试：

```bash
cd flutter_analysis_client
dart test
```

## 📋 API 参考

### AnalyticsClient

主要的分析客户端类。

#### 构造函数

- `AnalyticsClient.create(...)` - 创建新的分析客户端

#### 主要方法

- `track({...})` - 追踪事件（支持完整配置）
- `trackEvent(name, properties)` - 追踪简单事件
- `trackAction({...})` - 追踪用户行为
- `checkProductStatus([productName])` - 检查产品状态
- `canLaunchApp([productName])` - 检查应用是否可以启动
- `reportInstall()` - 上报安装信息
- `reportLaunch()` - 上报启动信息
- `setUserId(userId)` - 设置用户ID
- `flush()` - 手动刷新事件
- `close()` - 关闭客户端

#### 属性

- `sessionInfo` - 会话信息
- `eventStream` - 事件流
- `bufferSize` - 缓冲区大小
- `isClosed` - 是否已关闭

### AnalyticsEvent

事件数据模型。

```dart
final event = AnalyticsEvent(
  name: 'button_click',
  timestamp: DateTime.now().millisecondsSinceEpoch,
  properties: {'button': 'login'},
  category: 'ui',
  action: 'click',
  label: 'header',
  value: 1.0,
);
```

### ProductStatus

产品状态数据模型。

```dart
final status = ProductStatus(
  name: 'HelloWorldApp',
  displayName: 'HelloWorldApp',
  status: 'active',
  totalEvents: 1500,
  totalDevices: 300,
  activeDevices7d: 150,
  activeDevices30d: 280,
  // ... 其他字段
);

// 检查是否可以启动
if (status.isActive) {
  print('应用可以启动');
}
```

### ProductStatusResponse

产品状态响应包装器。

```dart
final response = ProductStatusResponse(
  code: 0,
  data: productStatus,
  message: 'success',
);

// 检查响应状态
if (response.isSuccess && response.canLaunch) {
  print('服务器授权应用启动');
}
```

### Result<T>

操作结果包装器，用于错误处理。

```dart
final result = await client.trackEvent('test');
if (result.isSuccess) {
  // 成功
} else {
  final error = result.error;
  // 处理错误
}
```

## 🔗 与服务端兼容性

本客户端与 [go-analysis-server](../go-analysis-server/) 完全兼容：

- 支持相同的事件格式
- 支持相同的加密方式
- 支持相同的API端点
- 支持相同的设备识别机制
- 支持产品状态检查和启动控制

### 服务端配置

确保服务端配置了正确的端点：

```toml
# config.toml
[server]
host = "localhost"
port = 8080

[api]
events_endpoint = "/api/events"
products_endpoint = "/api/products"  # 新增：产品状态检查端点
```

### 启动控制 API

服务端需要提供以下端点来支持应用启动控制：

```bash
# 检查产品状态
GET /api/products/{productName}

# 响应格式
{
  "code": 0,
  "data": {
    "name": "HelloWorldApp",
    "status": "active",  # active=允许启动, 其他=禁止启动
    "total_devices": 300,
    "active_devices_7d": 150
    // ... 其他字段
  },
  "message": "success"
}
```

## 🤝 贡献

欢迎贡献代码！请遵循以下步骤：

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🆘 支持

如果你遇到问题或有疑问：

1. 查看 [example](example/) 目录中的示例代码
2. 检查 [Issues](../../issues) 中是否有类似问题
3. 创建新的 Issue 描述你的问题

## 📈 版本历史

### 1.0.0

- 🎉 初始版本发布
- ✅ 基础事件追踪功能
- ✅ AES 加密支持
- ✅ 批量上报机制
- ✅ 会话管理
- ✅ 错误处理
- ✅ Flutter 多平台支持