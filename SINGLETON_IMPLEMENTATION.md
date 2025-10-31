# Flutter Analysis Client - 单例模式实现完成

## 更新摘要

已成功将 `flutter_analysis_client` 封装为单例工具类，使用户可以在项目的任意文件中方便地调用分析功能。

## 新增功能

### 1. Analytics 单例类 (`lib/src/analytics_singleton.dart`)

提供了一个全局访问点来使用分析客户端：

- **初始化方法**: `Analytics.initialize()` - 在应用启动时调用一次
- **实例访问**: `Analytics.instance` - 从任何地方访问单例
- **静态方法**: 提供便捷的静态方法如 `Analytics.trackStatic()`
- **状态管理**: 自动处理初始化状态和错误
- **灵活重置**: 支持强制重新初始化（可选）

### 2. 使用示例

#### 简单用法
```dart
// 在 main() 中初始化一次
Analytics.initialize(
  serverUrl: 'http://localhost:8080',
  productName: 'MyApp',
  debug: true,
);

// 在任何地方使用
Analytics.instance.track(name: 'button_click');
Analytics.trackStatic('page_view');
```

#### 在 Widget 中使用
```dart
class MyButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // 无需传递实例，直接使用！
        Analytics.instance.track(name: 'button_clicked');
      },
      child: Text('Click Me'),
    );
  }
}
```

## 文件更新

### 新增文件
1. `lib/src/analytics_singleton.dart` - 单例实现
2. `example/singleton_example.dart` - 完整使用示例
3. `test/analytics_singleton_test.dart` - 单元测试
4. `SINGLETON_GUIDE.md` - 详细使用指南

### 修改文件
1. `lib/flutter_analysis_client.dart` - 导出单例类
2. `README.md` - 更新文档，推荐单例模式
3. `CHANGELOG.md` - 记录版本更新

## 优势

### ✅ 使用便捷
- 无需通过构造函数传递客户端实例
- 可在任何文件中直接访问
- 减少样板代码

### ✅ 代码清晰
- 更清晰的代码结构
- 更好的关注点分离
- 无需依赖注入框架

### ✅ 线程安全
- 单例实现确保线程安全
- 自动状态管理
- 防止重复初始化

### ✅ 向后兼容
- 保留原有的 `AnalyticsClient` 类
- 用户可以选择使用单例或直接使用客户端
- 不影响现有代码

## API 概览

### 初始化
```dart
Analytics.initialize({
  required String serverUrl,
  required String productName,
  String? deviceId,
  String? userId,
  Duration timeout = const Duration(seconds: 10),
  int batchSize = 20,
  Duration flushInterval = const Duration(seconds: 5),
  int bufferSize = 1000,
  bool debug = false,
  EncryptionConfig? encryption,
  void Function(String message)? logger,
  bool forceReinitialize = false,
});
```

### 实例方法
```dart
// 访问单例
Analytics.instance

// 追踪事件
await Analytics.instance.track(name: 'event_name', properties: {...});
await Analytics.instance.trackEvent('event_name', {...});
await Analytics.instance.trackAction(category: 'user', action: 'login');

// 用户管理
Analytics.instance.setUserId('user_id');

// 应用生命周期
await Analytics.instance.reportInstall();
await Analytics.instance.reportLaunch();

// 手动控制
await Analytics.instance.flush();
await Analytics.instance.close();

// 信息访问
Analytics.instance.sessionInfo
Analytics.instance.bufferSize
Analytics.instance.eventStream
```

### 静态方法（简化语法）
```dart
await Analytics.trackStatic('event_name', properties: {...});
await Analytics.trackEventStatic('event_name', {...});
await Analytics.trackActionStatic(category: 'user', action: 'login');
Analytics.setUserIdStatic('user_id');
await Analytics.flushStatic();
```

### 状态检查
```dart
Analytics.isInitialized  // 检查是否已初始化
```

## 测试覆盖

创建了完整的单元测试套件（`test/analytics_singleton_test.dart`），包括：

- ✅ 初始化前状态检查
- ✅ 成功初始化
- ✅ 防止重复初始化
- ✅ 强制重新初始化
- ✅ 实例方法访问
- ✅ 静态方法访问
- ✅ 事件追踪
- ✅ 用户ID设置
- ✅ 操作追踪
- ✅ 关闭和重置
- ✅ 底层客户端访问
- ✅ 事件流

所有测试均通过！

## 示例代码

已提供完整的示例代码：

1. **基础示例** (`example/singleton_example.dart`)
   - 展示单例初始化
   - 在不同场景中使用
   - 实例方法和静态方法对比

2. **文档示例** (`SINGLETON_GUIDE.md`)
   - Flutter 应用完整示例
   - 最佳实践
   - 常见场景
   - 故障排除

## 使用建议

### 推荐使用场景 ✅
- 大多数应用程序（推荐）
- 只需要一个分析客户端实例
- 希望简化代码结构
- 不需要在运行时切换多个分析配置

### 不推荐使用场景 ❌
- 需要多个独立的分析客户端实例
- 需要为不同环境使用不同配置
- 需要精细控制客户端生命周期

对于这些场景，仍可以使用原有的 `AnalyticsClient.create()` 方式。

## 向后兼容性

✅ 完全向后兼容
- 保留所有原有API
- 单例模式是新增功能
- 不影响现有使用 `AnalyticsClient` 的代码

## 下一步

用户现在可以：

1. 在 `main()` 函数中调用 `Analytics.initialize()`
2. 在应用的任何地方使用 `Analytics.instance` 或静态方法
3. 无需传递客户端实例或使用依赖注入

## 版本信息

- 版本: 1.1.0
- 发布日期: 2025-10-31
- 重大更新: 新增单例模式支持

## 文档

详细文档请参阅：
- `README.md` - 快速开始和基本用法
- `SINGLETON_GUIDE.md` - 单例模式详细指南
- `example/singleton_example.dart` - 实际代码示例
- `CHANGELOG.md` - 版本更新历史
