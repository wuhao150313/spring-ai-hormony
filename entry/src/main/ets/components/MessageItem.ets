import { ChatMessage } from '../models/ChatMessage';
import { Constants } from '../utils/Constants';
import { DateUtil } from '../utils/DateUtil';
import { MarkdownText } from './MarkdownText';

/**
 * 消息项组件
 */
@Component
export struct MessageItem {
  @Prop message: ChatMessage;

  build() {
    Row() {
      if (this.message.role === Constants.ROLE_USER) {
        // 用户消息 - 右对齐
        Blank()
          .layoutWeight(1);
        
        Column() {
          Text(this.message.content)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor('#007AFF')
            .borderRadius(8);
        }
        .alignItems(HorizontalAlign.End)
        .margin({ right: 16, top: 8, bottom: 8 });
      } else {
        // AI 消息 - 左对齐，使用MarkdownText渲染markdown内容
        Column() {
          Column() {
            MarkdownText({
              content: this.message.content,
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
}

