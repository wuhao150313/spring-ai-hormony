# HarmonyOS AI 智能助手应用

基于 HarmonyOS 开发的 AI 智能助手应用，对接后端 Spring Boot API。

## 项目结构

```
entry/src/main/ets/
├── models/              # 数据模型
│   ├── Result.ets
│   ├── ChatSession.ets
│   ├── ChatMessage.ets
│   ├── AIModel.ets
│   ├── ReviewResult.ets
│   └── AssistantResponse.ets
├── services/            # 服务层
│   ├── SessionService.ets
│   ├── AIService.ets
│   └── ModelService.ets
├── utils/               # 工具类
│   ├── HttpUtil.ets
│   ├── StorageUtil.ets
│   ├── DateUtil.ets
│   └── Constants.ets
├── components/          # 自定义组件
│   ├── SessionItem.ets
│   ├── MessageItem.ets
│   ├── LoadingView.ets
│   └── EmptyView.ets
└── pages/               # 页面
    ├── IndexPage.ets          # 首页（会话列表）
    ├── SessionCreatePage.ets  # 创建会话
    ├── ChatPage.ets           # 聊天页面
    └── AIChatPage.ets         # AI 对话页面（Agent）
```

## 配置说明

### 1. 修改后端 API 地址

在 `entry/src/main/ets/utils/Constants.ets` 文件中，修改 `BASE_URL` 为你的后端服务器地址：

```typescript
static readonly BASE_URL = 'http://your-server:8081/api-template';
```

**注意**：
- 如果使用模拟器，可以使用 `http://10.0.2.2:8081/api-template`（10.0.2.2 是模拟器访问本机的特殊地址）
- 如果使用真机，需要确保手机和电脑在同一网络，使用电脑的局域网 IP 地址
- 生产环境请使用 HTTPS

### 2. 网络权限

项目已配置网络权限，在 `entry/src/main/module.json5` 中：

```json5
"requestPermissions": [
  {
    "name": "ohos.permission.INTERNET",
    "reason": "$string:internet_permission_reason",
    "usedScene": {
      "abilities": ["EntryAbility"],
      "when": "inuse"
    }
  }
]
```

## 功能说明

### 已实现功能

1. **会话列表**（IndexPage）
   - 显示所有聊天会话
   - 创建新会话
   - 删除会话
   - 点击会话进入聊天页面

2. **创建会话**（SessionCreatePage）
   - 输入会话标题
   - 选择 AI 模型
   - 创建新会话

3. **聊天页面**（ChatPage）
   - 显示会话消息列表
   - 发送消息
   - 接收 AI 回复（需要实现实际的发送消息接口）

4. **AI 对话页面**（AIChatPage）
   - Agent 智能对话
   - 支持多轮对话（有上下文记忆）
   - 自动保存 threadId

### 待完善功能

1. **ChatPage 中的发送消息功能**
   - 当前只是占位实现，需要调用实际的发送消息接口
   - 需要实现流式响应显示

2. **其他 AI 功能页面**
   - QnAPage（AI 问答）
   - CourseRecommendPage（课程推荐）
   - HomeworkReviewPage（作业批改）
   - KnowledgeSummaryPage（知识总结）
   - ModelSelectPage（模型选择）

3. **流式响应**
   - HarmonyOS 的 http 模块可能不支持真正的流式响应
   - 需要根据实际情况调整实现方式

## 使用说明

### 1. 开发环境

- DevEco Studio 4.0+
- HarmonyOS SDK API 9+
- Node.js 14+

### 2. 运行项目

1. 打开 DevEco Studio
2. 导入项目
3. 修改 `Constants.ets` 中的 `BASE_URL`
4. 连接设备或启动模拟器
5. 点击运行

### 3. 测试

1. 启动后端服务（确保后端服务正常运行）
2. 运行应用
3. 测试各个功能

## API 接口说明

### Agent 智能对话

- **简单对话**：`GET /api/v1/chat?question=xxx`
- **高级对话**：`POST /api/v2/chat`（支持多轮对话）

### 会话管理

- **创建会话**：`POST /api/chat/session/create`
- **获取会话列表**：`GET /api/chat/session/list`
- **获取会话详情**：`GET /api/chat/session/{id}`
- **更新会话标题**：`PUT /api/chat/session/{id}/title`
- **删除会话**：`DELETE /api/chat/session/{id}`

### AI 功能

- **AI 问答**：`GET /ai/qna/ask?question=xxx`
- **课程推荐**：`POST /ai/recommend/courses`
- **作业批改**：`POST /ai/homework/review`
- **知识总结**：`POST /ai/summary/course`
- **思维导图**：`POST /ai/summary/mindmap`

### 模型管理

- **获取模型列表**：`GET /api/ai/model/list`
- **获取当前模型**：`GET /api/ai/model/current`
- **切换模型**：`POST /api/ai/model/switch`

详细接口文档请参考 `鸿蒙端项目规划书.md`。

## 注意事项

1. **网络请求**
   - 确保设备有网络连接
   - 确保后端服务正常运行
   - 注意跨域问题（后端已配置 CORS）

2. **数据存储**
   - 使用 `@ohos.data.preferences` 存储用户ID、Token等
   - 数据存储在应用沙箱中

3. **错误处理**
   - 所有网络请求都有错误处理
   - 建议在生产环境中添加更详细的错误日志

4. **性能优化**
   - 使用 List 组件的缓存机制
   - 避免在主线程进行耗时操作
   - 图片懒加载（如果后续添加图片功能）

## 后续开发建议

1. **完善 ChatPage**
   - 实现实际的发送消息接口调用
   - 实现流式响应显示
   - 添加消息发送状态提示

2. **添加其他功能页面**
   - 参考规划书实现其他 AI 功能页面
   - 统一页面风格和交互

3. **优化用户体验**
   - 添加加载动画
   - 优化错误提示
   - 添加操作反馈

4. **功能扩展**
   - 支持语音输入
   - 支持图片上传
   - 支持文件分享

## 问题排查

### 1. 网络请求失败

- 检查 `BASE_URL` 是否正确
- 检查设备网络连接
- 检查后端服务是否运行
- 查看控制台错误日志

### 2. 页面无法跳转

- 检查 `main_pages.json` 中是否添加了页面路径
- 检查路由路径是否正确

### 3. 数据无法保存

- 检查 `StorageUtil.init()` 是否在 `EntryAbility.onCreate()` 中调用
- 检查权限配置

## 联系与支持

如有问题，请参考：
- 后端 API 文档
- 鸿蒙端项目规划书
- HarmonyOS 官方文档

