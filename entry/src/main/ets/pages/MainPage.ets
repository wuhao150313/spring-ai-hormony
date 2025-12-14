import { AIChatPage } from './AIChatPage';
import { AgentBrowsePage } from './AgentBrowsePage';
import { NotificationsPage } from './NotificationsPage';
import { UserCenterPage } from './UserCenterPage';

/**
 * 主入口页面 - SDK 20 正确的底部导航实现
 */
@Component
export struct MainPage {
  @State currentIndex: number = 0;
  @StorageLink('targetTabIndex') targetTabIndex: number = 0;

  aboutToAppear() {
    // 初始化全局状态
    if (!AppStorage.has('targetTabIndex')) {
      AppStorage.setOrCreate('targetTabIndex', 0);
    }
    if (!AppStorage.has('refreshUserCenter')) {
      AppStorage.setOrCreate('refreshUserCenter', 0);
    }
    this.currentIndex = 0;
  }

  aboutToUpdate() {
    // 外部指令切换 Tab（如登录后跳转）
    if (
      this.targetTabIndex >= 0 &&
      this.targetTabIndex <= 4 &&
      this.targetTabIndex !== this.currentIndex
    ) {
      this.currentIndex = this.targetTabIndex;
      AppStorage.set('targetTabIndex', -1);
    }
  }

  build() {
    Column() {

      /* ===================== 内容区域 ===================== */
      Column() {
        if (this.currentIndex === 0) {
          AIChatPage();
        } else if (this.currentIndex === 1) {
          AgentBrowsePage();
        } else if (this.currentIndex === 2) {
          Column() {
            Text('创作')
              .fontSize(24)
              .fontWeight(FontWeight.Bold);
            Text('创作功能开发中...')
              .fontSize(16)
              .fontColor('#999999')
              .margin({ top: 12 });
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .width('100%')
          .height('100%');
        } else if (this.currentIndex === 3) {
          NotificationsPage();
        } else if (this.currentIndex === 4) {
          UserCenterPage();
        }
      }
      .layoutWeight(1)          // ✅ 核心：内容区吃掉“剩余空间”
      .width('100%')

      /* ===================== 底部导航栏 ===================== */
      Row() {
        this.tabItem('对话', 0, '💬');
        this.tabItem('智能体', 1, '🔍');
        this.tabItem('通知', 3, '❤️');
        this.tabItem('我的', 4, '👤');
      }
      .width('100%')
      .height(56)               // ✅ 真实高度（不要再加 padding.bottom）
      .backgroundColor('#FFFFFF')
      .justifyContent(FlexAlign.SpaceAround)
      .alignItems(VerticalAlign.Center)
      .shadow({
        radius: 8,
        color: '#1F000000',
        offsetX: 0,
        offsetY: -2
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  /* ===================== Tab Item Builder ===================== */
  @Builder
  tabItem(title: string, index: number, icon: string) {
    Column() {
      Text(icon)
        .fontSize(22)
        .fontColor(this.currentIndex === index ? '#007AFF' : '#999999');
      Text(title)
        .fontSize(11)
        .fontColor(this.currentIndex === index ? '#007AFF' : '#999999')
        .margin({ top: 2 });
    }
    .onClick(() => {
      this.currentIndex = index;
      if (index === 4) {
        // 用户中心：触发刷新
        AppStorage.set('refreshUserCenter', Date.now());
      }
    })
  }
}
