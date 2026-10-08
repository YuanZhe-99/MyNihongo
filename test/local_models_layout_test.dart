import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapps_ai_local_ui/myapps_ai_local_ui.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';
import 'package:my_nihongo/features/ai/services/ai_source_backend.dart';

void main() {
  for (final size in [
    const Size(933, 704),
    const Size(704, 933),
    const Size(791, 820),
    const Size(659, 791),
    const Size(1024, 768),
    const Size(768, 1024),
    const Size(412, 915),
    const Size(915, 412),
    const Size(1000, 720),
  ]) {
    testWidgets('local model management fits $size in Chinese', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      final controller = createAiSourceRouter();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: MyAppsLocalModelList(
                controller: controller,
                groups: const [
                  MyAppsLocalModelGroup(capability: 'llm', title: '本地模型'),
                ],
                formatBytes: (b) => '$b B',
                labels: MyAppsLocalModelLabels(
                  modelName: (e) =>
                      controller.sourceName(e.modelId) ?? e.modelId,
                  state: (_) => '未安装',
                  action: (_) => '下载',
                  failure: (_) => '失败',
                  progress: (_, _) => '正在下载',
                  systemManaged: '系统管理',
                  removeTitle: (_) => '移除',
                  removeBody: '仅移除模型文件，保留历史',
                  removeConfirm: '移除',
                  storage: (_, _) => '存储',
                  empty: '无模型',
                  actionFailed: '操作失败',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Qwen: Qwen3.5 0.8B (Q4_K_M)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
