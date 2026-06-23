import 'package:flutter/material.dart';

import 'config/app_theme.dart';
import 'screens/home_screen.dart';

/// 程序入口。Dart 应用从 main() 开始执行。
void main() {
  // 在使用任何 Flutter 插件（如 path_provider）之前必须先初始化绑定
  WidgetsFlutterBinding.ensureInitialized();
  // runApp：把根 Widget 挂载到屏幕，启动 Flutter 渲染引擎
  runApp(const ImoodApp());
}

/// StatelessWidget：无内部可变状态的组件。
/// 当父组件传入的参数不变时，build 结果也不变。
class ImoodApp extends StatelessWidget {
  // super.key：Flutter 3 推荐写法，用于 Widget 树中唯一标识此节点
  const ImoodApp({super.key});

  /// build：描述 UI 长什么样。context 包含主题、屏幕尺寸等信息。
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Imood',
      debugShowCheckedModeBanner: false, // 隐藏右上角 DEBUG 条
      theme: AppTheme.dark(), // 全局暗色主题
      home: const HomeScreen(), // 第一个显示的页面
    );
  }
}
