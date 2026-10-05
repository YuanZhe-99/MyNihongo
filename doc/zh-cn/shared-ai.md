# 共享 AI

## 所有权

MyApps-AI v0.2.1 固定于 `packages/myapps_ai`。全新检出先执行
`git submodule update --init --recursive`，再执行 `flutter pub get`。
共享插件注册 com.yuanzhe.myapps_ai/genai，负责 Android Prompt、日语键盘校对及
原生取消。应用后端适配器保留既有能力枚举、诊断、失败类型和公开签名。

## 兼容

Prompt 和校对仍独立报告可用性及下载。Explain 映射至共享 generate，使用空指令、
temperature 0.2 和 topK 16。核心信息映射至共享 info。应用门控仍只支持 Android，
迁移不增加 Apple AI 功能。既有练习调度、提示词、输出解析、评分、进度及生成题
排除规则仍由应用负责。既有失败枚举以外的失败映射为 failed，取消和长度失败保留
原义。原生桥接现在在发布成功前检查取消，并保留忙碌位置直到已取消任务退出。

## 验证

运行时更新固定 v0.2.1，两个能力使用 AiExecutionGate。共享门控在等待状态前
占用执行位置，超时请求取消并拒绝过期回复。关闭后刷新和下载不再查询。
练习层交互顺序和有次数上限的后台重试仍由应用负责。

共享 CI 验证 Android release 和 Apple 构建及弱链接。消费者后端测试覆盖更新后的
generate/info 协议和能力报告；应用测试保留能力独立及教学行为。
消费者 release 构建和真机推理仍是独立验证。
