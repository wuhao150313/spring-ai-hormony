import { SessionService } from '../services/SessionService';
import { ChatSession } from '../models/ChatSession';
import { ChatMessage } from '../models/ChatMessage';
import { ResultUtil } from '../models/Result';
import { MessageItem } from '../components/MessageItem';
import { LoadingView } from '../components/LoadingView';
import { ChatService } from '../services/ChatService';
import { CategoryItem } from '../models/CategoryItem';
import router from '@ohos.router';

/**
 * 聊天页面
 */
@Entry
@Component
struct ChatPage {
  @State sessionId: number = 0;
  @State session: ChatSession | null = null;
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State selectedCategory: string = 'general'; // 消息类别，控制是否使用知识库
  categories: CategoryItem[] = [
    { key: 'general', label: '通用', useKnowledgeBase: false },
    { key: 'health', label: '健康问题', useKnowledgeBase: true }
  ];
  @State isLoading: boolean = false;
  @State isSending: boolean = false;
  @State errorMessage: string = '';

  async aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as Record<string, Object>;
    if (params && params['sessionId']) {
      const sessionIdValue = params['sessionId'];
      // 处理类型转换：可能是 number 或 string
      if (typeof sessionIdValue === 'number') {
        this.sessionId = sessionIdValue;
      } else if (typeof sessionIdValue === 'string') {
        const parsedId = parseInt(sessionIdValue, 10);
        if (!isNaN(parsedId)) {
          this.sessionId = parsedId;
        } else {
          this.errorMessage = '会话ID格式无效';
          return;
        }
      } else {
        this.errorMessage = '会话ID类型无效';
        return;
      }
      await this.loadSessionDetail();
    } else {
      this.errorMessage = '未获取到会话ID';
    }
  }

  /**
   * 加载会话详情
   */
  async loadSessionDetail() {
    if (this.sessionId <= 0) {
      this.errorMessage = '会话ID无效';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';
    try {
      console.info(`[ChatPage] 加载会话详情，sessionId: ${this.sessionId}`);
      const result = await SessionService.getSessionDetail(this.sessionId);
      if (ResultUtil.isSuccess(result)) {
        this.session = result.data;
        this.messages = result.data?.messages || [];
        console.info(`[ChatPage] 会话详情加载成功，消息数量: ${this.messages.length}`);
      } else {
        const errorMsg = ResultUtil.getErrorMessage(result);
        this.errorMessage = errorMsg || '会话信息不存在';
        console.error(`[ChatPage] 加载会话详情失败: ${errorMsg}`);
      }
    } catch (err) {
      const errorMsg = `加载失败: ${JSON.stringify(err)}`;
      this.errorMessage = errorMsg;
      console.error(`[ChatPage] 加载会话详情异常:`, err);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 发送消息
   */
  async sendMessage() {
    if (!this.inputText.trim()) {
      return;
    }

    // 如果会话信息未加载，先加载
    if (!this.session) {
      await this.loadSessionDetail();
      if (!this.session) {
        this.errorMessage = '会话信息不存在，请返回重试';
        return;
      }
    }

    const content = this.inputText;
    this.inputText = '';
    this.isSending = true;
    this.errorMessage = '';

    try {
      console.info(`[ChatPage] 开始发送消息，sessionId: ${this.sessionId}, content: ${content.substring(0, 50)}...`);
      
      // 调用聊天服务发送消息并获取AI回复
      const messagePair = await ChatService.sendMessageAndGetReply(
        this.sessionId,
        content,
        this.session?.modelName || 'qwen-max',
        this.selectedCategory === 'health'
      );

      console.info(`[ChatPage] 消息发送成功，用户消息ID: ${messagePair.userMessage.id}`);

      // 添加到消息列表（使用展开运算符创建新数组以触发UI更新）
      this.messages = [...this.messages, messagePair.userMessage, messagePair.aiMessage];

      // 更新会话的最后一条消息信息（不重新加载整个消息列表，避免覆盖）
      if (this.session) {
        this.session.lastMessage = messagePair.aiMessage.content;
        this.session.lastMessageTime = messagePair.aiMessage.createTime;
      }
      
      console.info(`[ChatPage] 消息已添加到列表，当前消息数量: ${this.messages.length}`);
    } catch (err) {
      console.error(`[ChatPage] 发送消息失败:`, err);
      let errorMsg = '发送失败';
      if (err instanceof Error) {
        errorMsg = err.message;
      } else if (typeof err === 'string') {
        errorMsg = err;
      } else {
        errorMsg = `发送失败: ${JSON.stringify(err)}`;
      }
      this.errorMessage = errorMsg;
      // 恢复输入内容
      this.inputText = content;
    } finally {
      this.isSending = false;
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Button('返回')
          .fontSize(16)
          .type(ButtonType.Normal)
          .fontColor('#007AFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            router.back();
          });
        
        Text(this.session?.title || '聊天')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center);
        
        Blank()
          .width(60);
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF');

      // 消息列表
      if (this.isLoading) {
        LoadingView({ message: '加载中...' });
      } else if (this.errorMessage) {
        Column() {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#FF0000');
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);
      } else {
        List() {
          ForEach(this.messages, (message: ChatMessage) => {
            ListItem() {
              MessageItem({ message: message });
            }
          }, (message: ChatMessage) => message.id.toString());
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ top: 8, bottom: 8 })
        .alignListItem(ListItemAlign.End)
        .scrollBar(BarState.Auto);
      }

      // 发送中提示
      if (this.isSending) {
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

      // 输入区域
      // 类别选择（决定是否走知识库）
      Row() {
        ForEach(this.categories, (item: CategoryItem) => {
          Button(item.label)
            .type(ButtonType.Normal)
            .fontSize(12)
            .fontColor(this.selectedCategory === item.key ? '#FFFFFF' : '#007AFF')
            .backgroundColor(this.selectedCategory === item.key ? '#007AFF' : '#E6F0FF')
            .borderRadius(16)
            .padding({ left: 12, right: 12 })
            .margin({ right: 8 })
            .onClick(() => {
              this.selectedCategory = item.key;
            });
        }, (item: CategoryItem) => item.key);
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8 });

      Row() {
        TextInput({ placeholder: '输入消息...' })
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
          .enabled(!this.isSending)
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

