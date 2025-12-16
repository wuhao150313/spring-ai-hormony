import { AIService } from '../services/AIService';
import { StorageUtil } from '../utils/StorageUtil';
import { ResultUtil } from '../models/Result';
import { MessageItem } from '../models/MessageItem';
import { AuthService } from '../services/AuthService';
import { SessionService } from '../services/SessionService';
import { ChatSession } from '../models/ChatSession';
import { DateUtil } from '../utils/DateUtil';
import { MarkdownText } from '../components/MarkdownText';
import { OssService } from '../services/OssService';
import { KnowledgeBaseService } from '../services/KnowledgeBaseService';
import { Constants } from '../utils/Constants';
import { ChatService } from '../services/ChatService';
import { ChatMessage } from '../models/ChatMessage';
import { Toast } from '../components/Toast';
import router from '@ohos.router';
import picker from '@ohos.file.picker';

/**
 * AI 对话页面（Agent）- 启动页
 */
@Component
export struct AIChatPage {
  @State userId: string = '';
  @State threadId: string = '';
  @State messages: MessageItem[] = [];
  @State inputText: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State isLoggedIn: boolean = false; // 登录状态
  @State currentSessionId: number = 0; // 当前选中的会话ID
  @State currentSessionTitle: string = '新会话'; // 当前会话标题
  @State newSessionTitle: string = ''; // 新建会话标题

  @State historyDialogVisible: boolean = false; // 历史对话弹窗
  @State sessions: ChatSession[] = []; // 会话列表
  @State isLoadingSessions: boolean = false; // 加载会话列表状态
  @State sessionTitle: string = '新会话'; // 会话标题
  @State selectedModel: string = 'default'; // 当前选中的模型

  historyDialogController: CustomDialogController | null = null;

  async aboutToAppear() {
    await this.checkLoginStatus();
  }

  /**
   * 检查并更新登录状态
   */
  async checkLoginStatus() {
    const loggedIn = await AuthService.isLoggedIn();
    this.isLoggedIn = loggedIn;

    if (this.isLoggedIn) {
      const storedUserId = await StorageUtil.getUserId();
      if (storedUserId) {
        this.userId = storedUserId;
      }
    } else {
      this.userId = `guest_${Date.now()}`;
    }

    let threadId = await StorageUtil.getThreadId();
    if (!threadId) {
      threadId = `thread_${Date.now()}`;
      await StorageUtil.saveThreadId(threadId);
    }
    this.threadId = threadId;
  }

  async onPageShow() {
    await this.checkLoginStatus();
  }

  // ========== ✅ 关键：统一用"新数组赋值"的方式更新 messages ==========
  private appendMessage(msg: MessageItem) {
    const newMessages: MessageItem[] = [];
    for (let i = 0; i < this.messages.length; i++) {
      newMessages.push(this.messages[i]);
    }
    newMessages.push(msg);
    this.messages = newMessages;
  }

  /**
   * 更新指定索引的消息内容
   * 
   * SDK20关键点：
   * 1. 必须创建全新的数组和对象，才能触发@State更新
   * 2. 不能直接修改原数组元素，必须创建新对象
   * 3. 赋值新数组后，ArkUI会在JS调用栈结束后统一刷新UI
   */
  private updateMessageContent(index: number, newContent: string) {
    if (index < 0 || index >= this.messages.length) {
      console.warn(`[AIChatPage] updateMessageContent: invalid index ${index}, messages.length=${this.messages.length}`);
      return;
    }
    
    // SDK20: 创建全新的数组和对象，确保状态更新被正确触发
    const newMessages: MessageItem[] = [];
    for (let i = 0; i < this.messages.length; i++) {
      if (i === index) {
        // 更新指定索引的消息内容（创建新对象）
        // ⚠️ 关键：同时更新time字段，确保ForEach的key会变化，触发UI重新渲染
        newMessages.push({
          role: this.messages[i].role,
          content: newContent,
          time: new Date().toISOString()  // 更新time，确保key变化
        });
        console.info(`[AIChatPage] updateMessageContent: updated message at index ${index}, content length=${newContent.length}`);
      } else {
        // 保持其他消息不变
        newMessages.push(this.messages[i]);
      }
    }
    
    // ⚠️ 关键：赋值新数组，触发@State变化检测
    // ArkUI会在JS调用栈结束后统一刷新UI
    this.messages = newMessages;
    console.info(`[AIChatPage] updateMessageContent: messages array updated, total messages=${this.messages.length}`);
  }

  private removeMessageAt(index: number) {
    if (index < 0 || index >= this.messages.length) return;
    const arr = this.messages.slice();
    arr.splice(index, 1);
    this.messages = arr;
  }

  private updateSessionTitleNow() {
    const now = new Date();
    const year = now.getFullYear();
    const month = (now.getMonth() + 1).toString().padStart(2, '0');
    const day = now.getDate().toString().padStart(2, '0');
    const hours = now.getHours().toString().padStart(2, '0');
    const minutes = now.getMinutes().toString().padStart(2, '0');
    this.sessionTitle = `新会话 ${year}/${month}/${day} ${hours}:${minutes}`;
  }

  /**
   * 发送消息（使用普通接口）
   * 
   * 说明：使用 HttpUtil 调用普通问答接口 /ai/qna/ask
   * 在SDK20中，http.request会阻塞等待整个响应完成，然后一次性返回结果。
   */
  async sendMessage() {
    const text = (this.inputText || '').trim();
    if (!text) return;

    // 防重入：上一轮没结束就不让点
    if (this.isLoading) {
      console.warn('[AIChatPage] send blocked: isLoading=true');
      return;
    }

    const userMessage = text;

    // 检查是否为特殊问题（本地应答）
    if (KnowledgeBaseService.isSpecialQuestion(userMessage)) {
      this.appendMessage({
        role: 'user',
        content: userMessage,
        time: new Date().toISOString()
      });
      this.inputText = '';
      this.appendMessage({
        role: 'assistant',
        content: KnowledgeBaseService.getSpecialAnswer(),
        time: new Date().toISOString()
      });
      return;
    }

    // 若还未选择会话，先创建一个新会话
    if (this.currentSessionId <= 0) {
      try {
        const createResult = await SessionService.createSession(this.sessionTitle, this.selectedModel);
        if (ResultUtil.isSuccess(createResult) && createResult.data && createResult.data.id) {
          this.currentSessionId = createResult.data.id;
          this.currentSessionTitle = createResult.data.title || this.sessionTitle;
          this.sessionTitle = this.currentSessionTitle;
          Toast.showSuccess('会话创建成功');
        } else {
          const errorMsg = ResultUtil.getErrorMessage(createResult);
          console.warn('[AIChatPage] 创建会话失败:', errorMsg);
          Toast.showError(`创建会话失败: ${errorMsg}`);
          // 仍继续，但会话ID无效将导致后续发送失败
        }
      } catch (err) {
        const errorMsg = err instanceof Error ? err.message : JSON.stringify(err);
        console.error('[AIChatPage] 创建会话异常:', err);
        Toast.showError(`创建会话失败: ${errorMsg}`);
      }
    }

    // 发送并保存消息（绑定 currentSessionId）
    this.inputText = '';
    this.isLoading = true;
    this.errorMessage = '';

    try {
      if (this.currentSessionId <= 0) {
        this.errorMessage = '会话创建失败，请重试';
        this.isLoading = false;
        return;
      }

      // 先立即添加用户消息到UI（用户点击发送后立即显示）
      const userMsgItem: MessageItem = {
        role: 'user',
        content: userMessage,
        time: new Date().toISOString()
      };
      this.appendMessage(userMsgItem);

      const useKB = false; // 当前页面未配置类别，默认不使用知识库
      console.info(`[AIChatPage] 发送问题: ${userMessage}, sessionId=${this.currentSessionId}, model=${this.selectedModel}`);
      
      // 调用AI服务获取回复（这会保存用户消息和AI消息到后端）
      const pair = await ChatService.sendMessageAndGetReply(
        this.currentSessionId,
        userMessage,
        this.selectedModel,
        useKB
      );

      // 映射AI消息到前端 MessageItem
      const aiMsgItem: MessageItem = {
        role: pair.aiMessage.role || 'assistant',
        content: pair.aiMessage.content || '',
        time: pair.aiMessage.createTime || new Date().toISOString()
      };

      // 追加AI消息到UI（AI回复后显示）
      this.appendMessage(aiMsgItem);
      this.isLoading = false;

      // 检测是否为第一条消息（用户消息 + AI消息 = 2条）
      const isFirstMessage = this.messages.length === 2;

      // 如果是第一条消息，自动更新会话标题
      if (isFirstMessage && this.currentSessionId > 0) {
        try {
          console.info(`[AIChatPage] 第一条消息，自动更新会话标题，sessionId=${this.currentSessionId}`);
          const updateResult = await SessionService.updateSessionTitleByContent(this.currentSessionId);
          if (ResultUtil.isSuccess(updateResult) && updateResult.data) {
            const newTitle = updateResult.data.title || this.currentSessionTitle;
            this.currentSessionTitle = newTitle;
            this.sessionTitle = newTitle;
            console.info(`[AIChatPage] 会话标题已自动更新为: ${newTitle}`);
          } else {
            console.warn(`[AIChatPage] 自动更新会话标题失败: ${ResultUtil.getErrorMessage(updateResult)}`);
          }
        } catch (err) {
          console.error('[AIChatPage] 自动更新会话标题异常:', err);
        }
      }
      
      // 发送消息成功提示
      Toast.showSuccess('消息发送成功');
    } catch (err) {
      console.error('[AIChatPage] 发送消息异常:', err);
      const errorMsg = err instanceof Error ? err.message : JSON.stringify(err);
      this.errorMessage = `发送失败: ${errorMsg}`;
      Toast.showError(`发送失败: ${errorMsg}`);
      
      // 如果用户消息已显示，添加错误消息作为AI回复
      if (this.messages.length > 0 && this.messages[this.messages.length - 1].role === 'user') {
        const errorAiMsg: MessageItem = {
          role: 'assistant',
          content: `抱歉，发送失败：${errorMsg}`,
          time: new Date().toISOString()
        };
        this.appendMessage(errorAiMsg);
      }
      
      this.isLoading = false;
    }
  }

  /**
   * 打开历史对话
   */
  async openHistoryDialog() {
    console.info('[AIChatPage] 点击历史对话按钮');
    // 检查登录状态
    const loggedIn = await AuthService.isLoggedIn();
    console.info('[AIChatPage] 登录状态:', loggedIn);
    if (!loggedIn) {
      // 未登录，跳转到登录页
      console.info('[AIChatPage] 未登录，跳转到登录页');
      router.pushUrl({
        url: 'pages/LoginPage'
      }).catch((err: Error) => {
        console.error('Failed to navigate to login:', JSON.stringify(err));
      });
      return;
    }

    // 已登录，打开历史对话弹窗
    console.info('[AIChatPage] 已登录，加载会话列表');
    this.isLoggedIn = true;
    await this.loadSessions();
    console.info('[AIChatPage] 会话列表加载完成，数量:', this.sessions.length);
    this.showHistoryDialog();
  }

  /**
   * 加载会话列表
   */
  async loadSessions() {
    this.isLoadingSessions = true;
    try {
      const result = await SessionService.getSessionList();
      if (ResultUtil.isSuccess(result)) {
        this.sessions = result.data || [];
      } else {
        this.sessions = [];
        console.error('加载会话列表失败:', ResultUtil.getErrorMessage(result));
      }
    } catch (err) {
      this.sessions = [];
      console.error('加载会话列表异常:', err);
    } finally {
      this.isLoadingSessions = false;
    }
  }

  /**
   * 刷新历史对话弹窗：关闭 -> 重新拉取 -> 再打开（仅在弹窗已打开时）
   */
  async refreshHistoryDialog() {
    const wasOpen = this.historyDialogVisible;
    if (wasOpen) {
      this.closeHistoryDialog();
    }
    await this.loadSessions();
    if (wasOpen) {
      this.showHistoryDialog();
    }
  }

  /**
   * 根据当前会话ID加载会话详情（包含消息）
   */
  async loadSessionDetail() {
    if (this.currentSessionId <= 0) {
      return;
    }
    this.isLoading = true;
    try {
      const result = await SessionService.getSessionDetail(this.currentSessionId);
      if (ResultUtil.isSuccess(result) && result.data) {
        const chatMessages: ChatMessage[] = (result.data.messages || []) as ChatMessage[];
        const msgs: MessageItem[] = chatMessages.map((m: ChatMessage): MessageItem => ({
          role: m.role ?? 'assistant',
          content: m.content ?? '',
          time: m.createTime ?? new Date().toISOString()
        }));
        this.messages = msgs;
        this.currentSessionTitle = result.data.title || this.currentSessionTitle;
        this.sessionTitle = this.currentSessionTitle;
      } else {
        console.warn('[AIChatPage] 加载会话详情失败:', ResultUtil.getErrorMessage(result));
      }
    } catch (err) {
      console.error('[AIChatPage] 加载会话详情异常:', err);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 构建历史对话弹窗内容
   */
  @Builder
  historyDialogBuilder(controller: CustomDialogController) {
    HistoryDialog({
      controller: controller,
      sessions: this.sessions,
      isLoading: this.isLoadingSessions,
      newSessionTitle: this.newSessionTitle,
      onNewSessionTitleChange: (title: string) => {
        this.newSessionTitle = title;
      },
      onCreateSession: async () => {
        if (this.isLoadingSessions) {
          return; // 避免重复点击导致多次创建
        }
        const title = (this.newSessionTitle || '').trim() || '新会话';
        this.isLoadingSessions = true;
        try {
          const createResult = await SessionService.createSession(title, this.selectedModel);
          if (ResultUtil.isSuccess(createResult) && createResult.data) {
            this.currentSessionId = createResult.data.id;
            this.currentSessionTitle = createResult.data.title || title;
            this.sessionTitle = this.currentSessionTitle;
            this.newSessionTitle = '';
            await this.loadSessions();
            await this.loadSessionDetail();
            Toast.showSuccess('会话创建成功');
            // 创建成功后关闭弹窗，避免用户误以为无响应
            this.closeHistoryDialog();
          } else {
            const errorMsg = ResultUtil.getErrorMessage(createResult);
            console.warn('[AIChatPage] 创建会话失败:', errorMsg);
            Toast.showError(`创建会话失败: ${errorMsg}`);
          }
        } catch (err) {
          const errorMsg = err instanceof Error ? err.message : JSON.stringify(err);
          console.error('[AIChatPage] 创建会话异常:', err);
          Toast.showError(`创建会话失败: ${errorMsg}`);
        } finally {
          this.isLoadingSessions = false;
        }
      },
      onSessionClick: (session: ChatSession) => {
        this.onSessionClick(session);
      },
      onDeleteSession: async (session: ChatSession) => {
        if (this.isLoadingSessions) {
          return; // 避免重复删除请求
        }
        this.isLoadingSessions = true;
        try {
          const delResult = await SessionService.deleteSession(session.id);
          if (ResultUtil.isSuccess(delResult)) {
            Toast.showSuccess('会话删除成功');
            // 如果删除的是当前会话，清空当前状态
            if (this.currentSessionId === session.id) {
              this.currentSessionId = 0;
              this.currentSessionTitle = '新会话';
              this.sessionTitle = this.currentSessionTitle;
              this.messages = [];
            }
          } else {
            const errorMsg = ResultUtil.getErrorMessage(delResult);
            console.warn('[AIChatPage] 删除会话失败:', errorMsg);
            Toast.showError(`删除会话失败: ${errorMsg}`);
          }
          // 执行完删除操作后，重建弹窗，确保实时更新
          await this.refreshHistoryDialog();
        } catch (err) {
          const errorMsg = err instanceof Error ? err.message : JSON.stringify(err);
          console.error('[AIChatPage] 删除会话异常:', err);
          Toast.showError(`删除会话失败: ${errorMsg}`);
          // 异常也刷新弹窗
          await this.refreshHistoryDialog();
        } finally {
          this.isLoadingSessions = false;
        }
      },
      onToggleStar: async (session: ChatSession, star: boolean) => {
        if (this.isLoadingSessions) {
          return;
        }
        this.isLoadingSessions = true;
        // 本地先更新，立即反馈高亮/置灰
        const newSessions: ChatSession[] = [];
        for (let i = 0; i < this.sessions.length; i++) {
          const s = this.sessions[i];
          if (s.id === session.id) {
            const updated: ChatSession = {
              id: s.id,
              title: s.title,
              userId: s.userId,
              modelName: s.modelName,
              status: s.status,
              lastMessage: s.lastMessage,
              lastMessageTime: s.lastMessageTime,
              createTime: s.createTime,
              updateTime: s.updateTime,
              star: star,
              messages: s.messages
            };
            newSessions.push(updated);
          } else {
            newSessions.push(s);
          }
        }
        this.sessions = newSessions;

        try {
          const starResult = await SessionService.updateSessionStar(session.id, star);
          if (ResultUtil.isSuccess(starResult)) {
            Toast.showSuccess(star ? '已收藏' : '已取消收藏');
          } else {
            const errorMsg = ResultUtil.getErrorMessage(starResult);
            console.warn('[AIChatPage] 收藏操作失败:', errorMsg);
            Toast.showError(`收藏操作失败: ${errorMsg}`);
          }
          // 执行完收藏操作后，重建弹窗，确保实时更新和正确排序
          await this.refreshHistoryDialog();
        } catch (err) {
          const errorMsg = err instanceof Error ? err.message : JSON.stringify(err);
          console.error('[AIChatPage] 收藏操作异常:', err);
          Toast.showError(`收藏操作失败: ${errorMsg}`);
          // 异常也刷新弹窗
          await this.refreshHistoryDialog();
        } finally {
          this.isLoadingSessions = false;
        }
      },
      onClose: () => {
        this.closeHistoryDialog();
      }
    });
  }

  /**
   * 显示历史对话弹窗
   */
  showHistoryDialog() {
    console.info('[AIChatPage] 显示历史对话弹窗');
    if (this.historyDialogController) {
      try {
        this.historyDialogController.close();
      } catch (err) {
        console.warn('关闭旧对话框失败:', err);
      }
      this.historyDialogController = null;
    }
    
    let dialogController: CustomDialogController | null = null;
    dialogController = new CustomDialogController({
      builder: () => {
        this.historyDialogBuilder(dialogController!);
      },
      cancel: () => {
        this.closeHistoryDialog();
      },
      autoCancel: true,
      alignment: DialogAlignment.Bottom,
      customStyle: true
    });
    this.historyDialogController = dialogController;
    
    try {
      dialogController.open();
      console.info('[AIChatPage] 历史对话弹窗已打开');
      this.historyDialogVisible = true;
    } catch (err) {
      console.error('打开历史对话弹窗失败:', err);
    }
  }

  /**
   * 关闭历史对话弹窗
   */
  closeHistoryDialog() {
    if (this.historyDialogController) {
      try {
        this.historyDialogController.close();
      } catch (err) {
        console.warn('关闭历史对话弹窗失败:', err);
      }
      this.historyDialogController = null;
    }
    this.historyDialogVisible = false;
  }

  /**
   * 点击会话项
   */
  async onSessionClick(session: ChatSession) {
    this.closeHistoryDialog();
    // 留在当前页面，直接加载该会话消息
    try {
      this.isLoading = true;
      const result = await SessionService.getSessionDetail(session.id);
      if (ResultUtil.isSuccess(result) && result.data) {
        const chatMessages: ChatMessage[] = (result.data.messages || []) as ChatMessage[];
        const msgs: MessageItem[] = chatMessages.map((m: ChatMessage): MessageItem => ({
          role: m.role ?? 'assistant',
          content: m.content ?? '',
          time: m.createTime ?? new Date().toISOString()
        }));
        this.messages = msgs;
        this.currentSessionId = session.id;
        this.currentSessionTitle = session.title || '新会话';
        this.sessionTitle = this.currentSessionTitle;
      } else {
        console.warn('[AIChatPage] 加载会话详情失败:', ResultUtil.getErrorMessage(result));
      }
    } catch (err) {
      console.error('[AIChatPage] 加载历史会话失败:', err);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 处理切换模型
   */
  async handleSwitchModel() {
    const models = ['default', 'qwen-max', 'qwen-plus', 'qwen-turbo'];
    const currentIndex = models.indexOf(this.selectedModel);
    const nextModel = models[(currentIndex + 1) % models.length];
    this.selectedModel = nextModel;
    
    try {
      const result = await AIService.switchModel(nextModel);
      this.appendMessage({
        role: 'assistant',
        content: `已切换到模型: ${nextModel}\n${result}`,
        time: new Date().toISOString()
      });
    } catch (err) {
      this.errorMessage = `切换模型失败: ${err instanceof Error ? err.message : JSON.stringify(err)}`;
    }
  }

  /**
   * 处理联网搜索
   */
  async handleWebSearch() {
    if (!this.inputText.trim()) {
      this.errorMessage = '请先输入要搜索的问题';
      return;
    }
    
    this.isLoading = true;
    this.errorMessage = '';
    
    const userMessage = this.inputText;
    this.inputText = '';
    
    this.appendMessage({
      role: 'user',
      content: `[联网搜索] ${userMessage}`,
      time: new Date().toISOString()
    });
    
    this.appendMessage({
      role: 'assistant',
      content: '',
      time: new Date().toISOString()
    });
    const aiMsgIndex = this.messages.length - 1;
    
    try {
      const result = await AIService.webSearch(userMessage);
      this.updateMessageContent(aiMsgIndex, result);
      this.isLoading = false;
    } catch (err) {
      this.errorMessage = `联网搜索失败: ${err instanceof Error ? err.message : JSON.stringify(err)}`;
      this.removeMessageAt(aiMsgIndex);
      this.isLoading = false;
    }
  }

  /**
   * 处理图片分析
   */
  async handleImageAnalyze() {
    try {
      // 打开文件选择器
      const photoPicker = new picker.PhotoViewPicker();
      const photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;
      
      const photoSelectResult = await photoPicker.select(photoSelectOptions);
      
      if (photoSelectResult && photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
        const fileUri = photoSelectResult.photoUris[0];
        console.info(`[AIChatPage] 选择的图片URI: ${fileUri}`);
        
        this.isLoading = true;
        this.errorMessage = '';
        
        // 添加用户消息
        const prompt = this.inputText.trim() || '请分析这张图片';
        this.appendMessage({
          role: 'user',
          content: `[图片分析] ${prompt}`,
          time: new Date().toISOString()
        });
        
        this.inputText = '';
        
        // 添加AI占位消息
        this.appendMessage({
          role: 'assistant',
          content: '',
          time: new Date().toISOString()
        });
        const aiMsgIndex = this.messages.length - 1;
        
        try {
          // 上传文件到OSS
          const uploadResult = await OssService.uploadFile(fileUri);
          if (!ResultUtil.isSuccess(uploadResult) || !uploadResult.data) {
            const errorMsg = ResultUtil.getErrorMessage(uploadResult);
            this.errorMessage = `文件上传失败: ${errorMsg}`;
            Toast.showError(`文件上传失败: ${errorMsg}`);
            this.removeMessageAt(aiMsgIndex);
            this.isLoading = false;
            return;
          }
          
          const ossUrl = uploadResult.data;
          console.info(`[AIChatPage] OSS上传成功，URL: ${ossUrl}`);
          Toast.showSuccess('文件上传成功');
          
          // 调用图片分析接口
          const analyzeResult = await AIService.analyzeImageByUrl(prompt, ossUrl);
          this.updateMessageContent(aiMsgIndex, analyzeResult);
          this.isLoading = false;
        } catch (err) {
          const errorMsg = err instanceof Error ? err.message : JSON.stringify(err);
          this.errorMessage = `图片分析失败: ${errorMsg}`;
          Toast.showError(`图片分析失败: ${errorMsg}`);
          this.removeMessageAt(aiMsgIndex);
          this.isLoading = false;
        }
      } else {
        console.info('[AIChatPage] 用户取消了图片选择');
      }
    } catch (err) {
      console.error('[AIChatPage] 打开文件选择器失败:', err);
      this.errorMessage = `打开文件选择器失败: ${err instanceof Error ? err.message : JSON.stringify(err)}`;
    }
  }

  /**
   * 处理课程推荐
   */
  async handleCourseRecommend() {
    if (!this.inputText.trim()) {
      this.errorMessage = '请输入您的学习水平和已完成的课程（格式：学习水平|已完成课程，逗号分隔）';
      return;
    }
    
    const parts = this.inputText.split('|');
    if (parts.length < 2) {
      this.errorMessage = '请输入格式：学习水平|已完成课程（逗号分隔）';
      return;
    }
    
    const userLevel = parts[0].trim();
    const completedCourses = parts[1].split(',').map(c => c.trim()).filter(c => c);
    
    this.isLoading = true;
    this.errorMessage = '';
    
    this.appendMessage({
      role: 'user',
      content: `[课程推荐] 水平: ${userLevel}, 已完成: ${completedCourses.join(', ')}`,
      time: new Date().toISOString()
    });
    
    this.inputText = '';
    
    this.appendMessage({
      role: 'assistant',
      content: '',
      time: new Date().toISOString()
    });
    const aiMsgIndex = this.messages.length - 1;
    
    try {
      const result = await AIService.recommendCourses(userLevel, completedCourses);
      if (ResultUtil.isSuccess(result) && result.data) {
        const courses = result.data.join('\n');
        this.updateMessageContent(aiMsgIndex, `推荐课程：\n${courses}`);
      } else {
        this.errorMessage = ResultUtil.getErrorMessage(result) || '课程推荐失败';
        this.removeMessageAt(aiMsgIndex);
      }
      this.isLoading = false;
    } catch (err) {
      this.errorMessage = `课程推荐失败: ${err instanceof Error ? err.message : JSON.stringify(err)}`;
      this.removeMessageAt(aiMsgIndex);
      this.isLoading = false;
    }
  }

  /**
   * 处理作业批改
   */
  async handleHomeworkReview() {
    if (!this.inputText.trim()) {
      this.errorMessage = '请输入作业题目和答案（格式：题目|答案）';
      return;
    }
    
    const parts = this.inputText.split('|');
    if (parts.length < 2) {
      this.errorMessage = '请输入格式：作业题目|学生答案';
      return;
    }
    
    const taskDescription = parts[0].trim();
    const studentAnswer = parts[1].trim();
    
    this.isLoading = true;
    this.errorMessage = '';
    
    this.appendMessage({
      role: 'user',
      content: `[作业批改] 题目: ${taskDescription}`,
      time: new Date().toISOString()
    });
    
    this.inputText = '';
    
    this.appendMessage({
      role: 'assistant',
      content: '',
      time: new Date().toISOString()
    });
    const aiMsgIndex = this.messages.length - 1;
    
    try {
      const result = await AIService.reviewHomework(taskDescription, studentAnswer);
      if (ResultUtil.isSuccess(result) && result.data) {
        const review = result.data;
        const reviewText = `评分: ${review.score || 'N/A'}\n总结: ${review.summary || 'N/A'}\n优点: ${review.strengths || 'N/A'}\n不足: ${review.weaknesses || 'N/A'}\n建议: ${review.suggestions || 'N/A'}`;
        this.updateMessageContent(aiMsgIndex, reviewText);
      } else {
        this.errorMessage = ResultUtil.getErrorMessage(result) || '作业批改失败';
        this.removeMessageAt(aiMsgIndex);
      }
      this.isLoading = false;
    } catch (err) {
      this.errorMessage = `作业批改失败: ${err instanceof Error ? err.message : JSON.stringify(err)}`;
      this.removeMessageAt(aiMsgIndex);
      this.isLoading = false;
    }
  }

  /**
   * 处理课程总结
   */
  async handleCourseSummary() {
    if (!this.inputText.trim()) {
      this.errorMessage = '请输入课程内容';
      return;
    }
    
    const courseContent = this.inputText.trim();
    
    this.isLoading = true;
    this.errorMessage = '';
    
    this.appendMessage({
      role: 'user',
      content: `[课程总结] ${courseContent.substring(0, 50)}...`,
      time: new Date().toISOString()
    });
    
    this.inputText = '';
    
    this.appendMessage({
      role: 'assistant',
      content: '',
      time: new Date().toISOString()
    });
    const aiMsgIndex = this.messages.length - 1;
    
    try {
      const result = await AIService.summarizeCourse(courseContent);
      if (ResultUtil.isSuccess(result) && result.data) {
        this.updateMessageContent(aiMsgIndex, result.data);
      } else {
        this.errorMessage = ResultUtil.getErrorMessage(result) || '课程总结失败';
        this.removeMessageAt(aiMsgIndex);
      }
      this.isLoading = false;
    } catch (err) {
      this.errorMessage = `课程总结失败: ${err instanceof Error ? err.message : JSON.stringify(err)}`;
      this.removeMessageAt(aiMsgIndex);
      this.isLoading = false;
    }
  }

  /**
   * 处理生成思维导图
   */
  async handleGenerateMindMap() {
    if (!this.inputText.trim()) {
      this.errorMessage = '请输入课程内容';
      return;
    }
    
    const courseContent = this.inputText.trim();
    
    this.isLoading = true;
    this.errorMessage = '';
    
    this.appendMessage({
      role: 'user',
      content: `[生成思维导图] ${courseContent.substring(0, 50)}...`,
      time: new Date().toISOString()
    });
    
    this.inputText = '';
    
    this.appendMessage({
      role: 'assistant',
      content: '',
      time: new Date().toISOString()
    });
    const aiMsgIndex = this.messages.length - 1;
    
    try {
      const result = await AIService.generateMindMap(courseContent);
      if (ResultUtil.isSuccess(result) && result.data) {
        this.updateMessageContent(aiMsgIndex, result.data);
      } else {
        this.errorMessage = ResultUtil.getErrorMessage(result) || '生成思维导图失败';
        this.removeMessageAt(aiMsgIndex);
      }
      this.isLoading = false;
    } catch (err) {
      this.errorMessage = `生成思维导图失败: ${err instanceof Error ? err.message : JSON.stringify(err)}`;
      this.removeMessageAt(aiMsgIndex);
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        // 左侧显示会话标题
        Text(this.sessionTitle)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1);
        
        // 右侧历史对话按钮
        Button('历史对话')
          .fontSize(14)
          .type(ButtonType.Normal)
          .fontColor('#FF3B30')
          .backgroundColor(Color.Transparent)
          .onClick(async () => {
            await this.openHistoryDialog();
          });
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center);

      // 消息列表
      List() {
        ForEach(this.messages, (message: MessageItem, index: number) => {
          ListItem() {
            Row() {
              if (message.role === 'user') {
                Blank()
                  .layoutWeight(1);
                
                Column() {
                  // SDK20: 确保Text组件能够正确响应状态变化
                  Text(message.content || '')
                    .fontSize(14)
                    .fontColor('#FFFFFF')
                    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                    .backgroundColor('#007AFF')
                    .borderRadius(8);
                }
                .alignItems(HorizontalAlign.End)
                .margin({ right: 16, top: 8, bottom: 8 });
              } else {
                Column() {
                  // 使用MarkdownText组件渲染AI回答的markdown内容
                  Column() {
                    MarkdownText({
                      content: message.content || '',
                      fontSize: 14,
                      fontColor: '#333333'
                    })
                  }
                  .width('100%')
                  .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                  .backgroundColor('#F5F5F5')
                  .borderRadius(8);
                }
                .alignItems(HorizontalAlign.Start)
                .margin({ left: 16, top: 8, bottom: 8 });
                
                Blank()
                  .layoutWeight(1);
              }
            }
            .width('100%');
          }
        }, (message: MessageItem, index: number) => `${index}_${message.time}`);
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ top: 8, bottom: 8 });

      // 加载提示
      if (this.isLoading) {
        Text('思考中...')
          .fontSize(12)
          .fontColor('#999999')
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 8, bottom: 8 });
      }

      // 错误提示
      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(12)
          .fontColor('#FF0000')
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ left: 16, right: 16, top: 4, bottom: 4 });
      }

      // 功能按钮区域
      Scroll() {
        Row() {
          Button('切换模型')
            .fontSize(12)
            .height(32)
            .padding({ left: 12, right: 12 })
            .backgroundColor('#F0F0F0')
            .fontColor('#333333')
            .borderRadius(16)
            .margin({ right: 8 })
            .onClick(() => {
              this.handleSwitchModel();
            });
          
          Button('联网搜索')
            .fontSize(12)
            .height(32)
            .padding({ left: 12, right: 12 })
            .backgroundColor('#F0F0F0')
            .fontColor('#333333')
            .borderRadius(16)
            .margin({ right: 8 })
            .onClick(() => {
              this.handleWebSearch();
            });
          
          Button('图片分析')
            .fontSize(12)
            .height(32)
            .padding({ left: 12, right: 12 })
            .backgroundColor('#F0F0F0')
            .fontColor('#333333')
            .borderRadius(16)
            .margin({ right: 8 })
            .onClick(() => {
              this.handleImageAnalyze();
            });
          
          Button('课程推荐')
            .fontSize(12)
            .height(32)
            .padding({ left: 12, right: 12 })
            .backgroundColor('#F0F0F0')
            .fontColor('#333333')
            .borderRadius(16)
            .margin({ right: 8 })
            .onClick(() => {
              this.handleCourseRecommend();
            });
          
          Button('作业批改')
            .fontSize(12)
            .height(32)
            .padding({ left: 12, right: 12 })
            .backgroundColor('#F0F0F0')
            .fontColor('#333333')
            .borderRadius(16)
            .margin({ right: 8 })
            .onClick(() => {
              this.handleHomeworkReview();
            });
          
          Button('课程总结')
            .fontSize(12)
            .height(32)
            .padding({ left: 12, right: 12 })
            .backgroundColor('#F0F0F0')
            .fontColor('#333333')
            .borderRadius(16)
            .margin({ right: 8 })
            .onClick(() => {
              this.handleCourseSummary();
            });
          
          Button('生成思维导图')
            .fontSize(12)
            .height(32)
            .padding({ left: 12, right: 12 })
            .backgroundColor('#F0F0F0')
            .fontColor('#333333')
            .borderRadius(16)
            .onClick(() => {
              this.handleGenerateMindMap();
            });
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .justifyContent(FlexAlign.Start);
      }
      .width('100%')
      .height(56)
      .scrollBar(BarState.Off)
      .backgroundColor('#FFFFFF');

      // 输入区域
      Row() {
        TextInput({ placeholder: '输入消息...', text: this.inputText })
          .layoutWeight(1)
          .height(40)
          .backgroundColor('#F5F5F5')
          .borderRadius(20)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.inputText = value;
          });
        
        Button('发送')
          .width(60)
          .height(40)
          .margin({ left: 8 })
          .enabled(!this.isLoading)
          .onClick(() => {
            this.sendMessage();
          });
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor('#FFFFFF');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5');
  }
}

/**
 * 历史对话弹窗组件
 */
@CustomDialog
struct HistoryDialog {
  controller: CustomDialogController;
  sessions: ChatSession[] = [];
  isLoading: boolean = false;
  newSessionTitle: string = '';
  onNewSessionTitleChange: (title: string) => void = () => {};
  onCreateSession: () => void = () => {};
  onRefresh: () => void = () => {};
  onSessionClick: (session: ChatSession) => void = () => {};
  onDeleteSession: (session: ChatSession) => void = () => {};
  onToggleStar: (session: ChatSession, star: boolean) => void = () => {};
  onClose: () => void = () => {};

  /**
   * 左滑动作（历史列表）- 收藏 / 删除
   */
  @Builder
  swipeActionBuilder(session: ChatSession) {
    Row() {
      Button((!!session.star) ? '取消收藏' : '收藏')
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor('#FF9F0A')
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          this.onToggleStar(session, !(!!session.star));
        });

      Button('删除')
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor('#FF3B30')
        .padding({ left: 20, right: 20 })
        .onClick(() => {
          this.onDeleteSession(session);
        });
    }
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('历史对话')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1);
        
        Button('关闭')
          .fontSize(14)
          .type(ButtonType.Normal)
          .fontColor('#007AFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.controller.close();
            this.onClose();
          });
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .border({ width: { bottom: 1 }, color: '#E5E5E5' });

      // 新建会话输入与按钮
      Column() {
        TextInput({ placeholder: '输入会话名称（可选）', text: this.newSessionTitle })
          .width('100%')
          .height(40)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 12, right: 12 })
          .margin({ left: 16, right: 16, top: 8 })
          .onChange((value: string) => {
            this.onNewSessionTitleChange(value);
          });

        Button('新建会话')
          .width('100%')
          .height(40)
          .margin({ left: 16, right: 16, top: 8 })
          .onClick(() => {
            this.onCreateSession();
          });
      }

      // 内容区域
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#007AFF');
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 12 });
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);
      } else if (this.sessions.length === 0) {
        Column() {
          Text('暂无历史对话')
            .fontSize(16)
            .fontColor('#999999');
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);
      } else {
        List() {
          ForEach(this.sessions, (session: ChatSession) => {
            ListItem() {
              HistorySessionItem({
                session: session,
                onItemClick: () => {
                  this.onSessionClick(session);
                },
                onDelete: () => {
                  this.onDeleteSession(session);
                }
              });
            }
            .swipeAction({
              end: () => this.swipeActionBuilder(session)
            })
          }, (session: ChatSession) => session.id.toString());
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 8 });
      }

    }
    .width('100%')
    .height(600)
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 16, topRight: 16 });
  }
}

/**
 * 历史会话项组件
 */
@Component
struct HistorySessionItem {
  @Prop session: ChatSession;
  onItemClick: () => void = () => {};
  onDelete: () => void = () => {};

  build() {
    Row() {
      Column() {
        Text(this.session.title || '新会话')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Start);

        if (this.session.lastMessage) {
          Text(this.session.lastMessage)
            .fontSize(14)
            .fontColor('#999999')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .textAlign(TextAlign.Start)
            .margin({ top: 4 });
        }

        if (this.session.lastMessageTime) {
          Text(DateUtil.formatRelativeTime(this.session.lastMessageTime))
            .fontSize(12)
            .fontColor('#CCCCCC')
            .margin({ top: 4 })
            .width('100%')
            .textAlign(TextAlign.Start);
        }
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .layoutWeight(1);
    }
    .width('100%')
    .backgroundColor(this.session.star ? '#FFF4E5' : '#F5F5F5')
    .borderRadius(8)
    .margin({ bottom: 8 })
    .onClick(() => {
      this.onItemClick();
    });
  }
}
