// Maintenance App Example
// 
// This file provides an example implementation of a maintenance screen
// that can be shown when the app cannot launch due to server status.

import 'package:flutter/material.dart';
import '../lib/flutter_analysis_client.dart';

/// Maintenance app to show when the main app cannot launch
class MaintenanceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '应用维护中',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MaintenanceScreen(),
    );
  }
}

class MaintenanceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 维护图标
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.build_circle_outlined,
                  size: 64,
                  color: Colors.orange[700],
                ),
              ),
              
              SizedBox(height: 32),
              
              // 标题
              Text(
                '🔧 应用维护中',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 16),
              
              // 描述
              Text(
                '我们正在对应用进行维护升级\n为您带来更好的使用体验',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.orange[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 48),
              
              // 重试按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _retryLaunch(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    '重试启动',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // 状态检查按钮
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _checkStatus(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange[700],
                    side: BorderSide(color: Colors.orange),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '检查状态',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 32),
              
              // 底部信息
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '维护期间您的数据是安全的\n完成后将自动恢复服务',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange[700],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 重试启动应用
  Future<void> _retryLaunch(BuildContext context) async {
    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('检查中...'),
          ],
        ),
      ),
    );

    try {
      // 检查应用状态
      final canLaunch = await Analytics.instance.canLaunchApp();
      
      // 关闭加载对话框
      Navigator.of(context).pop();
      
      if (canLaunch.isSuccess && canLaunch.value) {
        // 可以启动，重新启动应用
        _showSuccessAndRestart(context);
      } else {
        // 仍然无法启动
        _showStillMaintenanceMessage(context);
      }
    } catch (e) {
      // 关闭加载对话框
      Navigator.of(context).pop();
      
      // 显示错误信息
      _showErrorMessage(context, e.toString());
    }
  }

  /// 检查详细状态
  Future<void> _checkStatus(BuildContext context) async {
    try {
      final result = await Analytics.instance.checkProductStatus();
      
      if (result.isSuccess) {
        final response = result.value;
        final status = response.data;
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('产品状态'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusRow('产品名称', status?.name ?? '未知'),
                _buildStatusRow('当前状态', status?.status ?? '未知'),
     
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: response.canLaunch ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        response.canLaunch ? Icons.check_circle : Icons.cancel,
                        color: response.canLaunch ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          response.canLaunch ? '可以启动' : '暂时无法启动',
                          style: TextStyle(
                            color: response.canLaunch ? Colors.green[800] : Colors.red[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('关闭'),
              ),
            ],
          ),
        );
      } else {
        _showErrorMessage(context, '无法获取状态信息');
      }
    } catch (e) {
      _showErrorMessage(context, e.toString());
    }
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(': '),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessAndRestart(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('成功'),
          ],
        ),
        content: Text('应用现在可以正常启动了！'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 这里应该重新启动主应用
              // 在实际应用中，你可能需要重新初始化整个应用
            },
            child: Text('重新启动'),
          ),
        ],
      ),
    );
  }

  void _showStillMaintenanceMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('应用仍在维护中，请稍后再试'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('检查失败: $error'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}