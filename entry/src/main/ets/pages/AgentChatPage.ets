import { KnowledgeBaseService } from '../services/KnowledgeBaseService';
import { ResultUtil } from '../models/Result';
import { MarkdownText } from '../components/MarkdownText';
import router from '@ohos.router';

/**
 * 智能体对话页面
 */
interface ChatMessage {
  role: 'user' | 'assistant';
  content: string;
  time: string;
}

@Entry
@Component
export struct AgentChatPage {
  @State agentId: number = 0;
  @State agentName: string = '';
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';

  async aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as Record<string, Object>;
    if (params) {
      if (params['agentId']) {
        this.agentId = Number(params['agentId']);
      }
      if (params['agentName']) {
        this.agentName = String(params['agentName']);
      }
    }
  }

  /**
   * 添加消息到列表
   */
  private appendMessage(msg: ChatMessage) {
    const newMessages: ChatMessage[] = [];
    for (let i = 0; i < this.messages.length; i++) {
      newMessages.push(this.messages[i]);
    }
    newMessages.push(msg);
    this.messages = newMessages;
  }

  /**
   * 更新指定索引的消息内容
   */
  private updateMessageContent(index: number, newContent: string) {
    if (index < 0 || index >= this.messages.length) {
      return;
    }
    
    const newMessages: ChatMessage[] = [];
    for (let i = 0; i < this.messages.length; i++) {
      if (i === index) {
        newMessages.push({
          role: this.messages[i].role,
          content: newContent,
          time: new Date().toISOString()
        });
      } else {
        newMessages.push(this.messages[i]);
      }
    }
    
    this.messages = newMessages;
  }

  /**
   * 移除指定索引的消息
   */
  private removeMessageAt(index: number) {
    if (index < 0 || index >= this.messages.length) return;
    const arr = this.messages.slice();
    arr.splice(index, 1);
    this.messages = arr;
  }

  /**
   * 发送消息
   */
  async sendMessage() {
    const text = (this.inputText || '').trim();
    if (!text) return;

    // 防重入
    if (this.isLoading) {
      console.warn('[AgentChatPage] send blocked: isLoading=true');
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

    // 3) 插入 assistant 占位气泡
    this.appendMessage({
      role: 'assistant',
      content: '',
      time: new Date().toISOString()
    });
    const aiMsgIndex = this.messages.length - 1;

    // 4) 调用DashScope API
    try {
      console.info(`[AgentChatPage] 发送问题: ${userMessage}`);
      const result = await KnowledgeBaseService.queryKnowledgeBase(userMessage, this.agentId);
      
      if (ResultUtil.isSuccess(result)) {
        const answer = result.data || '';
        if (!answer || answer.trim() === '') {
          console.warn('[AgentChatPage] AI响应为空');
          this.errorMessage = 'AI响应为空，请重试';
          this.removeMessageAt(aiMsgIndex);
          this.isLoading = false;
          return;
        }
        
        console.info(`[AgentChatPage] 收到回答，长度: ${answer.length}`);
        this.updateMessageContent(aiMsgIndex, answer);
        this.isLoading = false;
      } else {
        this.errorMessage = ResultUtil.getErrorMessage(result) || '获取回答失败';
        console.error(`[AgentChatPage] 获取回答失败: ${this.errorMessage}`);
        if (this.messages[aiMsgIndex]?.content === '') {
          this.removeMessageAt(aiMsgIndex);
        }
        this.isLoading = false;
      }
    } catch (err) {
      console.error('[AgentChatPage] 发送消息异常:', err);
      this.errorMessage = `发送失败: ${err instanceof Error ? err.message : JSON.stringify(err)}`;
      if (this.messages[aiMsgIndex]?.content === '') {
        this.removeMessageAt(aiMsgIndex);
      }
      this.isLoading = false;
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
        
        Text(this.agentName || '智能体助手')
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
      List() {
        ForEach(this.messages, (message: ChatMessage, index: number) => {
          ListItem() {
            Row() {
              if (message.role === 'user') {
                Blank()
                  .layoutWeight(1);
                
                Column() {
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
        }, (message: ChatMessage, index: number) => `${index}_${message.time}`);
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


