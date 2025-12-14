import { AIService } from '../services/AIService';
import { StorageUtil } from '../utils/StorageUtil';
import { ResultUtil } from '../models/Result';
import { MessageItem } from '../models/MessageItem';
import { AuthService } from '../services/AuthService';
import { SessionService } from '../services/SessionService';
import { ChatSession } from '../models/ChatSession';
import { DateUtil } from '../utils/DateUtil';
import { MarkdownText } from '../components/MarkdownText';
import router from '@ohos.router';

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

  @State historyDialogVisible: boolean = false; // 历史对话弹窗
  @State sessions: ChatSession[] = []; // 会话列表
  @State isLoadingSessions: boolean = false; // 加载会话列表状态
  @State sessionTitle: string = '新会话'; // 会话标题

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

    // 1) 添加用户消息到列表
    this.appendMessage({
      role: 'user',
      content: userMessage,
      time: new Date().toISOString()
    });

    // 2) 清空输入 + 打开 loading
    this.inputText = '';
    this.isLoading = true;
    this.errorMessage = '';
    this.updateSessionTitleNow();

    // 3) 插入 assistant 占位气泡（确保 UI 一定出现）
    this.appendMessage({
      role: 'assistant',
      content: '',
      time: new Date().toISOString()
    });
    const aiMsgIndex = this.messages.length - 1;

    // 4) 调用普通问答接口
    try {
      console.info(`[AIChatPage] 发送问题: ${userMessage}`);
      const answer = await AIService.askQuestion(userMessage);
      
      // 检查响应是否为空
      if (!answer || answer.trim() === '') {
        console.warn('[AIChatPage] AI响应为空');
        this.errorMessage = 'AI响应为空，请重试';
              this.removeMessageAt(aiMsgIndex);
              this.isLoading = false;
            return;
          }
          
      // 更新AI消息内容
      console.info(`[AIChatPage] 收到回答，长度: ${answer.length}`);
      console.info(`[AIChatPage] 回答预览: ${answer.substring(0, 100)}...`);
              this.updateMessageContent(aiMsgIndex, answer);
              this.isLoading = false;
    } catch (err) {
      console.error('[AIChatPage] 发送消息异常:', err);
      this.errorMessage = `发送失败: ${err instanceof Error ? err.message : JSON.stringify(err)}`;
        // 移除空的AI消息
        if (this.messages[aiMsgIndex]?.content === '') {
          this.removeMessageAt(aiMsgIndex);
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
   * 构建历史对话弹窗内容
   */
  @Builder
  historyDialogBuilder(controller: CustomDialogController) {
    HistoryDialog({
      controller: controller,
      sessions: this.sessions,
      isLoading: this.isLoadingSessions,
      onRefresh: () => {
        this.loadSessions();
      },
      onSessionClick: (session: ChatSession) => {
        this.onSessionClick(session);
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
  }

  /**
   * 点击会话项
   */
  onSessionClick(session: ChatSession) {
    this.closeHistoryDialog();
    router.pushUrl({
      url: 'pages/ChatPage',
      params: {
        sessionId: session.id
      }
    }).catch((err: Error) => {
      console.error('Failed to navigate:', JSON.stringify(err));
    });
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
        Row() {
          LoadingProgress()
            .width(20)
            .height(20)
            .color('#007AFF');
          
          Text('AI 正在思考...')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ left: 8 });
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
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
  onRefresh: () => void = () => {};
  onSessionClick: (session: ChatSession) => void = () => {};
  onClose: () => void = () => {};

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
                }
              });
            }
          }, (session: ChatSession) => session.id.toString());
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 8 });
      }

      // 刷新按钮
      Button('刷新')
        .width('100%')
        .height(44)
        .margin({ left: 16, right: 16, bottom: 16 })
        .onClick(() => {
          this.onRefresh();
        });
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
    .backgroundColor('#F5F5F5')
    .borderRadius(8)
    .margin({ bottom: 8 })
    .onClick(() => {
      this.onItemClick();
    });
  }
}
