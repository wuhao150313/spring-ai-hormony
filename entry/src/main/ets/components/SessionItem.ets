import { ChatSession } from '../models/ChatSession';
import { DateUtil } from '../utils/DateUtil';

/**
 * 会话项组件
 */
@Component
export struct SessionItem {
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
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .onClick(() => {
      this.onItemClick();
    });
  }
}

