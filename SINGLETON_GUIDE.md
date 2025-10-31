# Analytics Singleton 使用指南

## 概述

`Analytics` 单例类提供了一个方便的方式来从应用程序的任何地方访问分析客户端，无需传递实例或使用依赖注入。

## 为什么使用单例模式？

### 优势

1. **无需传递实例** - 不需要通过构造函数传递客户端实例
2. **全局访问** - 可以在任何文件中直接使用，无需导入客户端实例
3. **代码更清晰** - 减少样板代码，提高代码可读性
4. **线程安全** - 单例实现确保线程安全
5. **状态管理简单** - 自动管理初始化状态和错误处理

### 适用场景

- ✅ 大多数应用程序（推荐）
- ✅ 只需要一个分析客户端实例
- ✅ 希望简化代码结构
- ✅ 不需要在运行时切换多个分析配置

### 不适用场景

- ❌ 需要多个独立的分析客户端实例
- ❌ 需要为不同环境使用不同配置
- ❌ 需要精细控制客户端生命周期

## 基本用法

### 1. 初始化（在应用启动时）

```dart
import 'package:flutter_analysis_client/flutter_analysis_client.dart';

void main() {
  // 初始化 Analytics 单例
  Analytics.initialize(
    serverUrl: 'http://localhost:8080',
    productName: 'MyApp',
    debug: true,
  );
  
  runApp(MyApp());
}
```

### 2. 在任何地方使用

#### 在 Widget 中使用

```dart
class MyButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // 直接使用 - 无需传递客户端实例！
        Analytics.instance.track(
          name: 'button_clicked',
          properties: {
            'button_id': 'login_button',
            'screen': 'home',
          },
        );
      },
      child: Text('Login'),
    );
  }
}
```

#### 在普通类中使用

```dart
class UserService {
  Future<void> updateProfile(String userId, Map<String, dynamic> updates) async {
    // 执行业务逻辑...
    
    // 追踪事件 - 无需依赖注入！
    await Analytics.instance.trackEvent('profile_updated', {
      'user_id': userId,
      'fields': updates.keys.toList(),
    });
  }
  
  Future<void> login(String username) async {
    // 登录逻辑...
    
    // 设置用户ID
    Analytics.instance.setUserId(username);
    
    // 追踪登录
    await Analytics.trackStatic('user_login', properties: {
      'method': 'password',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
```

#### 在异步函数中使用

```dart
Future<void> fetchData() async {
  try {
    final data = await api.fetchData();
    
    // 追踪成功
    Analytics.instance.trackEvent('data_fetched', {
      'count': data.length,
      'timestamp': DateTime.now().toIso8601String(),
    });
  } catch (e) {
    // 追踪错误
    Analytics.instance.trackEvent('fetch_error', {
      'error': e.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
```

## 高级用法

### 完整配置选项

```dart
Analytics.initialize(
  serverUrl: 'http://localhost:8080',
  productName: 'MyApp',
  deviceId: 'custom-device-id',           // 可选：自定义设备ID
  userId: 'user-123',                     // 可选：初始用户ID
  timeout: Duration(seconds: 15),         // 可选：网络超时
  batchSize: 30,                          // 可选：批量大小
  flushInterval: Duration(seconds: 10),   // 可选：自动刷新间隔
  bufferSize: 2000,                       // 可选：缓冲区大小
  debug: true,                            // 可选：调试模式
  encryption: EncryptionConfig.enabled(   // 可选：加密配置
    'your-32-byte-secret-key-here!!!!!'
  ),
  logger: (message) => print(message),    // 可选：自定义日志
);
```

### 使用静态方法（更简洁的语法）

```dart
// 追踪简单事件
await Analytics.trackStatic('page_view', properties: {
  'page': 'home',
  'referrer': 'dashboard',
});

// 追踪用户操作
await Analytics.trackActionStatic(
  category: 'user',
  action: 'signup',
  label: 'email',
  value: 1.0,
);

// 设置用户ID
Analytics.setUserIdStatic('user_456');

// 手动刷新事件
await Analytics.flushStatic();
```

### 检查初始化状态

```dart
// 在使用前检查是否已初始化
if (Analytics.isInitialized) {
  await Analytics.instance.track(name: 'event');
} else {
  print('Analytics not initialized');
}

// 或者在可选功能中使用
void trackOptionalEvent() {
  if (!Analytics.isInitialized) {
    return; // 静默失败
  }
  
  Analytics.instance.trackEvent('optional_event');
}
```

### 访问会话信息

```dart
final sessionInfo = Analytics.instance.sessionInfo;
print('Session ID: ${sessionInfo['session_id']}');
print('Device ID: ${sessionInfo['device_id']}');
print('User ID: ${sessionInfo['user_id']}');
```

### 监听事件流

```dart
Analytics.instance.eventStream.listen((event) {
  print('Event tracked: ${event.name}');
  print('Properties: ${event.properties}');
});
```

### 手动刷新事件

```dart
// 在关键时刻确保事件被发送（如应用退出前）
Future<void> logout() async {
  await Analytics.instance.trackEvent('user_logout');
  
  // 确保事件在退出前发送
  await Analytics.instance.flush();
  
  // 执行登出逻辑...
}
```

### 重新初始化（高级场景）

```dart
// 场景：切换用户或环境
Future<void> switchUser(String newUserId) async {
  // 关闭当前实例
  await Analytics.instance.close();
  
  // 重新初始化新配置
  Analytics.initialize(
    serverUrl: 'http://localhost:8080',
    productName: 'MyApp',
    userId: newUserId,
    forceReinitialize: true,  // 允许重新初始化
  );
}
```

### 访问底层客户端

如果需要使用单例不提供的高级功能：

```dart
final client = Analytics.instance.client;

// 使用客户端的任何方法
await client.reportInstall();
await client.reportLaunch();
```

## 实际应用示例

### Flutter 应用完整示例

```dart
import 'package:flutter/material.dart';
import 'package:flutter_analysis_client/flutter_analysis_client.dart';

void main() {
  // 1. 初始化 Analytics
  Analytics.initialize(
    serverUrl: 'http://localhost:8080',
    productName: 'MyFlutterApp',
    debug: true,
  );
  
  // 2. 报告应用启动
  Analytics.instance.reportLaunch();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
      // 全局导航观察器
      navigatorObservers: [AnalyticsNavigatorObserver()],
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 追踪页面查看
    Analytics.trackStatic('page_view', properties: {
      'page': 'home',
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _handleLogin(context),
              child: Text('Login'),
            ),
            ElevatedButton(
              onPressed: () => _handleSignup(context),
              child: Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _handleLogin(BuildContext context) async {
    // 追踪按钮点击
    Analytics.instance.trackAction(
      category: 'user',
      action: 'click',
      label: 'login_button',
    );
    
    // 执行登录...
    final userId = await performLogin();
    
    // 设置用户ID
    Analytics.instance.setUserId(userId);
    
    // 追踪登录成功
    Analytics.trackStatic('user_login', properties: {
      'method': 'email',
      'success': true,
    });
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfilePage()),
    );
  }
  
  Future<void> _handleSignup(BuildContext context) async {
    Analytics.trackActionStatic(
      category: 'user',
      action: 'click',
      label: 'signup_button',
    );
    // ... 注册逻辑
  }
  
  Future<String> performLogin() async {
    // 模拟登录
    await Future.delayed(Duration(seconds: 1));
    return 'user_12345';
  }
}

// 自定义导航观察器
class AnalyticsNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    
    if (route.settings.name != null) {
      Analytics.trackStatic('screen_view', properties: {
        'screen_name': route.settings.name,
        'previous_screen': previousRoute?.settings.name,
      });
    }
  }
}
```

## 最佳实践

### 1. 在 main() 中初始化

```dart
void main() {
  // ✅ 好：在应用启动时初始化
  Analytics.initialize(...);
  
  runApp(MyApp());
}
```

### 2. 使用有意义的事件名称

```dart
// ✅ 好：清晰的事件名称
Analytics.trackStatic('button_clicked', properties: {
  'button_id': 'checkout_button',
  'screen': 'cart',
});

// ❌ 差：模糊的事件名称
Analytics.trackStatic('click');
```

### 3. 包含上下文信息

```dart
// ✅ 好：包含丰富的上下文
Analytics.trackStatic('product_viewed', properties: {
  'product_id': '12345',
  'category': 'electronics',
  'price': 99.99,
  'source': 'search_results',
  'position': 3,
});

// ❌ 差：信息不足
Analytics.trackStatic('view');
```

### 4. 处理错误情况

```dart
Future<void> trackEvent() async {
  if (!Analytics.isInitialized) {
    print('Warning: Analytics not initialized');
    return;
  }
  
  try {
    await Analytics.instance.trackEvent('my_event');
  } catch (e) {
    print('Error tracking event: $e');
  }
}
```

### 5. 在关键时刻刷新事件

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // 应用进入后台时刷新事件
      Analytics.instance.flush();
    }
  }
  
  // ...
}
```

## 故障排除

### 问题：初始化失败

```dart
// 检查是否已经初始化
if (Analytics.isInitialized) {
  print('Already initialized');
} else {
  Analytics.initialize(...);
}
```

### 问题：事件未发送

```dart
// 手动刷新
await Analytics.instance.flush();

// 检查缓冲区
print('Buffer size: ${Analytics.instance.bufferSize}');
```

### 问题：需要重新初始化

```dart
// 关闭并重新初始化
await Analytics.instance.close();
Analytics.initialize(..., forceReinitialize: true);
```

## 与直接使用客户端的对比

### 单例模式（推荐）

```dart
// 初始化一次
Analytics.initialize(serverUrl: '...', productName: '...');

// 在任何地方使用
Analytics.instance.trackEvent('event');
```

### 直接使用客户端

```dart
// 每次都需要传递客户端实例
final client = AnalyticsClient.create(serverUrl: '...', productName: '...');

class MyWidget extends StatelessWidget {
  final AnalyticsClient analytics;
  
  MyWidget({required this.analytics});
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => analytics.trackEvent('event'),
      child: Text('Click'),
    );
  }
}
```

## 总结

单例模式提供了一种简单、便捷的方式来在整个应用中使用分析功能，无需繁琐的实例传递或依赖注入。对于大多数应用场景，这是推荐的使用方式。
