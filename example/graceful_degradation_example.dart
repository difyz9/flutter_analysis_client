import '../lib/flutter_analysis_client.dart';

/// Example showing graceful degradation when network fails
void main() async {
  print('=== 网络优雅降级示例 ===\n');

  // 创建客户端
  final client = AnalyticsClient.create(
    serverUrl: 'http://localhost:8080',
    productName: 'DigiBankApp',
    debug: true,
  );

  await demonstrateGracefulDegradation(client);
  await client.close();
}

/// 演示网络优雅降级功能
Future<void> demonstrateGracefulDegradation(AnalyticsClient client) async {
  print('📱 检查应用启动权限...\n');

  // 方法1: 使用 canLaunchApp - 网络失败时会允许启动
  print('1️⃣ 使用 canLaunchApp (推荐用于启动检查):');
  final canLaunchResult = await client.canLaunchApp();
  
  if (canLaunchResult.isSuccess) {
    if (canLaunchResult.value) {
      print('✅ 应用可以启动');
      print('   - 可能原因: 服务器授权 或 网络连接失败(优雅降级)');
      
      // 继续应用启动流程
      await client.reportLaunch();
      print('📊 应用启动事件已记录\n');
    } else {
      print('❌ 应用被禁止启动');
      print('   - 原因: 服务器明确返回非active状态\n');
    }
  } else {
    print('💥 启动检查失败: ${canLaunchResult.error}\n');
  }

  // 方法2: 使用 checkProductStatus - 获取详细信息
  print('2️⃣ 使用 checkProductStatus (用于获取详细状态):');
  final statusResult = await client.checkProductStatus();
  
  if (statusResult.isSuccess) {
    final response = statusResult.value;
    final status = response.data;
    
    print('✅ 成功获取产品状态:');
    print('   - 产品名称: ${status?.name}');
    print('   - 当前状态: ${status?.status}');
    print('   - 设备总数: ${status?.totalDevices}');
    print('   - 7天活跃: ${status?.activeDevices7d}');
    print('   - 可以启动: ${response.canLaunch}\n');
  } else {
    print('❌ 无法获取产品状态: ${statusResult.error}');
    print('   - 这种情况下，canLaunchApp 会允许启动(优雅降级)\n');
  }

  // 方法3: 实际项目中的使用模式
  print('3️⃣ 实际项目中的使用模式:');
  await demonstrateRealWorldUsage(client);
}

/// 演示实际项目中的使用方式
Future<void> demonstrateRealWorldUsage(AnalyticsClient client) async {
  print('🚀 应用启动流程开始...');

  try {
    // 第一步: 检查是否可以启动 (带优雅降级)
    final canLaunch = await client.canLaunchApp();
    
    if (canLaunch.isSuccess && canLaunch.value) {
      print('✅ 启动检查通过');
      
      // 第二步: 尝试获取详细状态 (可选)
      final detailedStatus = await client.checkProductStatus();
      if (detailedStatus.isSuccess) {
        print('📊 获取到详细状态: ${detailedStatus.value.data?.status}');
      } else {
        print('⚠️  无法获取详细状态，但应用仍可启动 (离线模式)');
      }
      
      // 第三步: 报告启动
      await client.reportLaunch();
      print('📱 应用启动成功');
      
    } else {
      print('🚫 应用被禁止启动');
      print('   显示维护页面...');
    }
    
  } catch (e) {
    print('💥 启动过程中发生异常: $e');
    print('   使用离线模式启动...');
  }
}

/// 启动管理器示例 - 处理各种网络情况
class AppStartupManager {
  final AnalyticsClient _client;
  
  AppStartupManager(this._client);
  
  /// 智能启动检查 - 处理网络问题
  Future<StartupResult> checkStartup() async {
    print('🔍 执行智能启动检查...');
    
    try {
      // 使用 canLaunchApp 进行启动检查
      final launchResult = await _client.canLaunchApp();
      
      if (launchResult.isSuccess) {
        if (launchResult.value) {
          // 尝试获取详细信息来判断是在线还是离线模式
          final statusResult = await _client.checkProductStatus();
          
          if (statusResult.isSuccess) {
            // 在线模式 - 服务器正常响应
            return StartupResult.online(
              canLaunch: true,
              productStatus: statusResult.value.data,
            );
          } else {
            // 离线模式 - 网络问题但允许启动
            return StartupResult.offline(canLaunch: true);
          }
        } else {
          // 服务器明确禁止启动
          return StartupResult.denied();
        }
      } else {
        // 启动检查本身失败 (不应该发生，因为有优雅降级)
        return StartupResult.error(launchResult.error.toString());
      }
    } catch (e) {
      // 异常情况 - 允许启动
      print('⚠️  启动检查异常，允许离线启动: $e');
      return StartupResult.offline(canLaunch: true);
    }
  }
}

/// 启动结果枚举
class StartupResult {
  final StartupMode mode;
  final bool canLaunch;
  final ProductStatus? productStatus;
  final String? errorMessage;
  
  StartupResult._(this.mode, this.canLaunch, {this.productStatus, this.errorMessage});
  
  factory StartupResult.online({required bool canLaunch, ProductStatus? productStatus}) {
    return StartupResult._(StartupMode.online, canLaunch, productStatus: productStatus);
  }
  
  factory StartupResult.offline({required bool canLaunch}) {
    return StartupResult._(StartupMode.offline, canLaunch);
  }
  
  factory StartupResult.denied() {
    return StartupResult._(StartupMode.denied, false);
  }
  
  factory StartupResult.error(String message) {
    return StartupResult._(StartupMode.error, false, errorMessage: message);
  }
  
  bool get isOnline => mode == StartupMode.online;
  bool get isOffline => mode == StartupMode.offline;
  bool get isDenied => mode == StartupMode.denied;
  bool get hasError => mode == StartupMode.error;
  
  @override
  String toString() {
    switch (mode) {
      case StartupMode.online:
        return '🌐 在线模式 - 可启动: $canLaunch';
      case StartupMode.offline:
        return '📱 离线模式 - 可启动: $canLaunch';
      case StartupMode.denied:
        return '🚫 被拒绝 - 服务器禁止启动';
      case StartupMode.error:
        return '💥 错误 - $errorMessage';
    }
  }
}

enum StartupMode { online, offline, denied, error }

/// 使用启动管理器的示例
void exampleWithStartupManager() async {
  final client = AnalyticsClient.create(
    serverUrl: 'http://localhost:8080',
    productName: 'DigiBankApp',
    debug: true,
  );
  
  final manager = AppStartupManager(client);
  final result = await manager.checkStartup();
  
  print('\n📋 启动检查结果: $result');
  
  if (result.canLaunch) {
    if (result.isOnline) {
      print('🎉 在线启动 - 所有功能可用');
    } else if (result.isOffline) {
      print('🔄 离线启动 - 基础功能可用');
    }
    
    // 继续应用启动...
    await client.reportLaunch();
  } else {
    print('🛑 无法启动应用');
    // 显示错误页面或维护页面...
  }
  
  await client.close();
}