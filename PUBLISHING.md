# 📦 发布到 pub.dev 指南

本文档说明如何将 `flutter_analysis_client` 包发布到 pub.dev。

## ✅ 发布前检查清单

已完成的准备工作：

- [x] ✅ **pubspec.yaml 完整配置**
  - 包含 `name`, `description`, `version`
  - 添加了 `homepage`, `repository`, `issue_tracker`
  - 描述精简到 180 字符以内
  
- [x] ✅ **CHANGELOG.md 更新**
  - 包含所有版本的变更记录
  - 当前版本: 1.2.1
  - 遵循 Keep a Changelog 格式

- [x] ✅ **LICENSE 文件**
  - MIT 许可证已就绪

- [x] ✅ **README.md 完善**
  - 详细的功能说明
  - 安装和使用示例
  - API 文档
  - 示例代码

- [x] ✅ **.pubignore 配置**
  - 排除了 build 目录
  - 排除了测试文件
  - 排除了开发文档
  - 包大小从 13 MB 优化到 47 KB

- [x] ✅ **验证通过**
  - `flutter pub publish --dry-run` 通过
  - 0 warnings, 0 errors

## 🚀 发布步骤

### 1. 确认 Git 状态干净

```bash
git status
# 确保所有更改都已提交
```

### 2. 执行发布前验证（可选）

```bash
flutter pub publish --dry-run
```

应该看到：
```
✓ Package has 0 warnings.
```

### 3. 登录 pub.dev（首次发布必须）

**⚠️ 重要：首次发布前必须先登录 pub.dev！**

执行登录命令：

```bash
dart pub token add https://pub.dev
```

或者使用 Flutter 命令：

```bash
flutter pub token add https://pub.dev
```

系统会：
1. 🌐 **自动打开浏览器**，跳转到 pub.dev 授权页面
2. 🔐 **提示你使用 Google 账号登录** pub.dev
3. ✅ **授权 dart 工具访问你的 pub.dev 账号**
4. 💾 **自动保存授权令牌**到本地（`~/.pub-cache/credentials.json`）

授权成功后，你会看到：
```
✓ Successfully authenticated.
```

**注意事项：**
- 需要一个 Google 账号
- 授权令牌会保存在本地，之后发布不需要重复登录
- 如果授权过期，会自动提示重新登录

### 4. 执行真正的发布

```bash
flutter pub publish
```

你会看到类似的提示：
```
Publishing flutter_analysis_client 1.2.1 to https://pub.dev:
...
Do you want to publish flutter_analysis_client 1.2.1 (y/N)?
```

输入 `y` 确认发布。

### 5. 确认发布信息

系统会显示将要发布的文件列表和大小，仔细检查后输入 `y` 确认。

如果之前没有登录，这时会自动触发登录流程（同步骤 3）。

### 6. 验证发布成功

发布成功后，你会看到：
```
Successfully uploaded package.
```

然后访问：
- **包主页**: https://pub.dev/packages/flutter_analysis_client
- **文档**: https://pub.dev/documentation/flutter_analysis_client/latest/

### 🔑 关于授权令牌

- **令牌位置**: `~/.pub-cache/credentials.json`
- **有效期**: 长期有效（除非手动撤销）
- **查看已登录账号**: `cat ~/.pub-cache/credentials.json`
- **撤销授权**: 删除 credentials.json 文件或在 pub.dev 网站撤销
- **切换账号**: 先撤销当前授权，再重新登录

## 📊 包信息总结

```yaml
名称: flutter_analysis_client
版本: 1.2.1
大小: 47 KB
依赖: 6 个包
平台支持: Android, iOS, Web, Windows, macOS, Linux
Dart SDK: >=3.0.0 <4.0.0
Flutter SDK: >=3.0.0
```

## 🎯 主要特性

- 🚀 高性能事件追踪
- 🔒 AES 加密支持
- 📊 批量上报机制
- 🚦 应用启动控制
- 🌐 网络优雅降级
- 📱 设备唯一标识（flutter_udid + MD5）
- 🎛️ 单例模式便捷使用
- 🛡️ 完善的错误处理

## 🔄 后续版本发布流程

当需要发布新版本时：

1. 更新代码
2. 更新 `pubspec.yaml` 中的 `version`
3. 在 `CHANGELOG.md` 中添加新版本的变更记录
4. 提交更改：`git commit -am "chore: bump version to x.x.x"`
5. 打标签：`git tag vx.x.x`
6. 推送：`git push && git push --tags`
7. 发布：`flutter pub publish`

## 📝 版本号规范

遵循语义化版本（Semantic Versioning）：

- **主版本号（Major）**: 不兼容的 API 变更
- **次版本号（Minor）**: 向后兼容的功能新增
- **修订号（Patch）**: 向后兼容的问题修复

示例：
- `1.0.0` → `1.0.1`: Bug 修复
- `1.0.0` → `1.1.0`: 新功能
- `1.0.0` → `2.0.0`: 破坏性变更

## 🆘 常见问题

### Q: 发布失败，提示包名已存在？

A: pub.dev 上的包名是全局唯一的。如果名称已被占用，需要修改 `pubspec.yaml` 中的 `name` 字段。

### Q: 如何撤回已发布的版本？

A: pub.dev 不支持删除已发布的版本，但可以：
- 标记版本为 "retracted"（撤回）
- 发布新的修复版本

### Q: 如何更新包的说明或文档？

A: 修改 `README.md` 和相关文档，然后发布新的修订版本。

### Q: 包的评分是如何计算的？

A: pub.dev 会根据以下因素评分：
- 文档完整性
- 平台支持
- 依赖的健康度
- 维护频率
- 测试覆盖率

## 📞 支持

如果发布过程中遇到问题：

1. 查看 pub.dev 官方文档：https://dart.dev/tools/pub/publishing
2. 检查 pub.dev 状态页面：https://status.pub.dev/
3. 在 GitHub 上提交 issue：https://github.com/difyz9/flutter_analysis_client/issues

---

**准备好了吗？执行 `flutter pub publish` 开始发布！** 🚀
