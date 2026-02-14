# 刷题助手 v2.0 更新说明

## 版本概述

v2.0 版本重点完善了 AI 导入功能，引入分块并发处理机制，大幅提升大文档处理能力和导入速度。

---

## 核心特性

### 1. 滑动窗口分块 + 智能丢弃

针对大型题库文档（几百页级别），采用 **带重叠的滑动窗口（Sliding Window with Overlap）** 策略：

- **分块切片**：将超长文本按 Token 限制切分为多个块
- **10% 重叠区**：相邻块之间保留重叠，确保边界处题目不遗漏
- **Prompt 指令**：要求 AI 丢弃首尾不完整的题目片段，避免断句错误

技术细节见 `concurrency_logic.md`。

### 2. 并发请求加速

- Chat 模型支持多块并行处理（默认并发数 3，可在设置中调整）
- Reasoner 模型自动降级为单线程，避免触发 API 限流

### 3. 流式响应 + 活动超时

- 所有请求启用 SSE 流式输出
- **活动超时机制**：只要持续收到数据就不会断开，解决 Reasoner 模型 10 分钟超时问题

### 4. 多进度条 UI

- 进度对话框显示每个分块的独立进度条
- 紧凑行布局：`块1: ████████ 1234/5678`
- ETA 预估优化：单块处理时使用 token 接收百分比计算剩余时间

### 5. 模型设置记忆

切换模型时自动保存/恢复对应的参数配置（最大 Token、温度、并发数）。

---

## TODO（有生之年）

1. 其余模型与平台的支持，测试魔塔平台
2. 带图题目的支持
3. 给 Reasoner 模型增加并发功能
4. 给每个题库增加导出功能

---

## 原始需求文档

记下来将为该项目增加ai自动整理试题格式功能。

1. 在题库主页面的右下角，除了"导入题库"外增加一个“ai导入”选项卡
2. 在设置页面增加“api设置”选项页。该页面提供以下设置项：
3. 选择模型供应商（暂时只提供deepseek、魔塔和自定义，openai格式的）。
4. URL：选择deepseek时自动填入<https://api.deepseek.com。（只在切换时重置，可自己修改）>
  选择魔塔则自动填入“<https://api-inference.modelscope.cn/v1/”>
  选择自定义则空着。
5. api key，在api key下方增加一个超链接（蓝色文字显示：“获取api key”）deepseek和魔塔分别对应：<https://platform.deepseek.com/usage> 和 <https://www.modelscope.cn/my/myaccesstoken>
 不用显示完整网站，点击可跳转即可。
6. 模型选择：deepseek可选择deepseek-chat 和deepseek-reasoner模型，可也自己填写。
  选项下方提示：
   选择deepseek厂商时：模型ID见“官方文档”（<https://api-docs.deepseek.com/zh-cn/quick_start/pricing）>
   选择魔塔时：请在“网站”（<https://modelscope.cn/models?name=deepseek&page=1&tabKey=task）中复制需要的模型ID。>

7. 最大输出token：同样可自由设置，默认值8k。
  下方提示文字：
  deepseek-chat 模型：默认4k最大8k
  deepseek-reasoner模型：默认 32K，最大 64K
8. ai功能：
9. 先计算自定义提示词的token，假设为N_custom。
 （token计算：1 个英文字符 ≈ 0.3 个 token。
1 个中文字符 ≈ 0.6 个 token）
10. 计算

---

## 2026-01-13 本轮对话修改记录

### 1. AI 响应格式修复

- 统一所有模型（包括 Reasoner）的 prompt，强制要求 JSON 格式输出
- 明确禁止 markdown 代码块（\`\`\`）
- 输出格式：`{ "formatted": "..." }`

### 2. 流式响应实现

- 为所有请求启用流式输出（SSE），包括单块和多块处理
- **活动超时机制**：初始连接超时 60 秒，数据接收期间无超时（只要持续收到数据就不会断开）
- 解决了 Reasoner 模型 10 分钟超时问题

### 3. 多进度条 UI

- 进度对话框显示每个分块的独立进度条
- 紧凑行布局：`块1: ████████ 1234/5678`
- 限制最大高度 80px，超出可滚动

### 4. 进度更新节流

- 多块处理：每 1 秒更新一次
- 单块处理（Reasoner）：每 5 秒更新一次
- 空消息不添加日志，避免刷屏

### 5. ETA 预估优化

- 单块处理时使用 token 接收百分比计算剩余时间
- 公式：`剩余时间 = 已用时间 / 进度百分比 - 已用时间`

### 6. API 设置页面添加模型说明

新增说明卡片：

- **Chat 模型**：可以切分更多的块、并行处理以提升速度，但可能存在拼接错误
- **Reasoner 模型**：单轮耗时更久，但可感知到更多的上下文，能处理题目后面追加补充的情况
- **推荐**：Chat 模型更快、更稳定、更不容易漏题

### 涉及文件

- `lib/services/ai_service.dart` - 流式请求、活动超时、进度回调
- `lib/screens/bank_manage_tab.dart` - 多进度条 UI、ETA 计算
- `lib/providers/question_bank_provider.dart` - 空消息过滤
- `lib/screens/api_settings_screen.dart` - 模型选择说明卡片

---

### 7. 模型设置记忆功能

**功能**：记忆不同模型的特定设置，切换模型时自动恢复对应的参数配置。

**记忆的设置项**：

- 最大输出 Token
- 温度 (Temperature)
- 并发请求数

**实现方式**：

- 使用 SharedPreferences 按模型名存储设置
- 存储 key 格式：`model_[模型名]_maxTokens`, `model_[模型名]_temperature`, `model_[模型名]_concurrency`
- 切换模型时自动保存当前模型设置，加载新模型设置
- 离开设置页面时保存当前模型设置

**涉及文件**：

- `lib/providers/settings_provider.dart` - 添加 `_saveModelSettings()`, `_loadModelSettings()`, `saveCurrentModelSettings()`
- `lib/screens/api_settings_screen.dart` - 模型切换时调用 `_saveSettings(modelChanged: true)`，dispose 时保存设置
