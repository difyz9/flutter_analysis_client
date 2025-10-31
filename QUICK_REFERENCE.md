# Analytics 单例快速参考

## 🚀 快速开始

```dart
// 1. 在 main() 中初始化
void main() {
  Analytics.initialize(
    serverUrl: 'http://localhost:8080',
    productName: 'MyApp',
    debug: true,
  );
  runApp(MyApp());
}

// 2. 在任何地方使用
Analytics.instance.track(name: 'button_click');
Analytics.trackStatic('page_view');
```

## 📌 常用方法

### 追踪事件
```dart
// 实例方法
await Analytics.instance.track(
  name: 'event_name',
  properties: {'key': 'value'},
  category: 'category',
  action: 'action',
  label: 'label',
  value: 1.0,
);

// 静态方法（简化）
await Analytics.trackStatic('event_name', properties: {'key': 'value'});
await Analytics.trackEventStatic('event_name', {'key': 'value'});
```

### 追踪用户操作
```dart
// 实例方法
await Analytics.instance.trackAction(
  category: 'user',
  action: 'login',
  label: 'email',
);

// 静态方法
await Analytics.trackActionStatic(
  category: 'user',
  action: 'login',
);
```

### 设置用户ID
```dart
// 实例方法
Analytics.instance.setUserId('user_123');

// 静态方法
Analytics.setUserIdStatic('user_123');
```

### 应用生命周期
```dart
await Analytics.instance.reportInstall();
await Analytics.instance.reportLaunch();
```

### 手动刷新
```dart
// 实例方法
await Analytics.instance.flush();

// 静态方法
await Analytics.flushStatic();
```

### 关闭客户端
```dart
await Analytics.instance.close();
```

## 🔍 信息查询

```dart
// 检查初始化状态
bool isInit = Analytics.isInitialized;

// 获取会话信息
Map<String, dynamic> info = Analytics.instance.sessionInfo;

// 获取缓冲区大小
int size = Analytics.instance.bufferSize;

// 监听事件流
Analytics.instance.eventStream.listen((event) {
  print('Event: ${event.name}');
});

// 访问底层客户端
AnalyticsClient client = Analytics.instance.client;
```

## ⚙️ 完整配置

```dart
Analytics.initialize(
  serverUrl: 'http://localhost:8080',
  productName: 'MyApp',
  deviceId: 'device-123',                // 可选
  userId: 'user-123',                    // 可选
  timeout: Duration(seconds: 15),        // 可选
  batchSize: 30,                         // 可选
  flushInterval: Duration(seconds: 10),  // 可选
  bufferSize: 2000,                      // 可选
  debug: true,                           // 可选
  encryption: EncryptionConfig.enabled(  // 可选
    'your-32-byte-key'
  ),
  logger: (msg) => print(msg),           // 可选
  forceReinitialize: false,              // 可选
);
```

## 💡 最佳实践

### ✅ 推荐做法
```dart
// 1. 在 main() 中初始化
void main() {
  Analytics.initialize(...);
  runApp(MyApp());
}

// 2. 使用有意义的事件名
Analytics.trackStatic('checkout_completed', properties: {
  'order_id': '12345',
  'total': 99.99,
});

// 3. 在关键时刻刷新
Future<void> logout() async {
  await Analytics.instance.trackEvent('user_logout');
  await Analytics.instance.flush();  // 确保事件发送
  // ... 登出逻辑
}

// 4. 检查初始化状态
if (Analytics.isInitialized) {
  Analytics.instance.trackEvent('event');
}
```

### ❌ 避免做法
```dart
// 不要在 Widget 的 build 方法中初始化
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Analytics.initialize(...);  // ❌ 错误！
    return Container();
  }
}

// 不要使用模糊的事件名
Analytics.trackStatic('click');  // ❌ 不好

// 推荐使用清晰的事件名
Analytics.trackStatic('product_add_to_cart');  // ✅ 好
```

## 🎯 典型场景

### 页面追踪
```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Analytics.trackStatic('page_view', properties: {
      'page': 'home',
      'timestamp': DateTime.now().toIso8601String(),
    });
    return Scaffold(...);
  }
}
```

### 按钮点击
```dart
ElevatedButton(
  onPressed: () {
    Analytics.instance.trackAction(
      category: 'button',
      action: 'click',
      label: 'login',
    );
    // ... 处理点击
  },
  child: Text('Login'),
)
```

### 错误追踪
```dart
try {
  await api.fetchData();
} catch (e) {
  Analytics.trackStatic('error', properties: {
    'error_type': e.runtimeType.toString(),
    'error_message': e.toString(),
    'screen': 'data_fetch',
  });
}
```

### 用户登录
```dart
Future<void> login(String username) async {
  // ... 登录逻辑
  final userId = await performLogin(username);
  
  Analytics.instance.setUserId(userId);
  Analytics.trackStatic('user_login', properties: {
    'method': 'email',
    'timestamp': DateTime.now().toIso8601String(),
  });
}
```

## 📦 导入

```dart
import 'package:flutter_analysis_client/flutter_analysis_client.dart';
```

## 🔗 相关文档

- `SINGLETON_GUIDE.md` - 详细使用指南
- `README.md` - 完整文档
- `example/singleton_example.dart` - 示例代码
