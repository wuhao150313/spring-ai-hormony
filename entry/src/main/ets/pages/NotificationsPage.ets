import { NotificationVO } from '../models/NotificationVO';

/**
 * 通知页面
 */
@Component
export struct NotificationsPage {
  @State notifications: NotificationVO[] = [];

  aboutToAppear() {
    this.loadNotifications();
  }

  /**
   * 加载通知列表（模拟数据）
   */
  loadNotifications() {
    // 模拟数据，实际应该从后端获取
    this.notifications = [];
    // 暂时为空，显示空状态
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('通知')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center);
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      .alignItems(VerticalAlign.Center);

      // 内容区域
      if (this.notifications.length === 0) {
        // 空状态
        Column() {
          Text('👻')
            .fontSize(60)
            .margin({ bottom: 16 });
          
          Text('暂未收到通知')
            .fontSize(16)
            .fontColor('#999999');
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);
      } else {
        List() {
          ForEach(this.notifications, (notification: NotificationVO) => {
            ListItem() {
              Row() {
                Column() {
                  Text(notification.title)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#333333');
                  
                  Text(notification.content)
                    .fontSize(14)
                    .fontColor('#666666')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 4 });
                  
                  Text(notification.createTime)
                    .fontSize(12)
                    .fontColor('#999999')
                    .margin({ top: 4 });
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start);

                if (!notification.isRead) {
                  Blank()
                    .width(8)
                    .height(8)
                    .backgroundColor('#FF3B30')
                    .borderRadius(4);
                }
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .backgroundColor('#FFFFFF')
              .onClick(() => {
                // 标记为已读
                notification.isRead = true;
              });
            }
          }, (notification: NotificationVO) => notification.id.toString());
        }
        .layoutWeight(1)
        .backgroundColor('#F5F5F5');
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5');
  }
}

