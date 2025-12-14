import { AuthService } from '../services/AuthService';
import { UserInfoVO } from '../models/UserInfoVO';
import { StorageUtil } from '../utils/StorageUtil';
import { ResultUtil } from '../models/Result';
import router from '@ohos.router';

/**
 * 用户中心页面
 */
@Component
export struct UserCenterPage {
  @State isLoggedIn: boolean = false;
  @State userInfo: UserInfoVO | null = null;
  @State isLoading: boolean = false;
  @StorageLink('refreshUserCenter') refreshTrigger: number = 0;
  lastRefreshTrigger: number = 0;

  async aboutToAppear() {
    // 初始化 AppStorage 键
    if (!AppStorage.has('refreshUserCenter')) {
      AppStorage.setOrCreate('refreshUserCenter', 0);
    }
    this.lastRefreshTrigger = this.refreshTrigger;
    await this.checkLoginStatus();
  }

  aboutToUpdate() {
    // 监听 refreshTrigger 变化，刷新登录状态
    if (this.refreshTrigger !== this.lastRefreshTrigger && this.refreshTrigger !== 0) {
      this.lastRefreshTrigger = this.refreshTrigger;
      this.checkLoginStatus();
    }
  }

  /**
   * 检查登录状态
   */
  async checkLoginStatus() {
    this.isLoading = true;
    try {
      const loggedIn = await AuthService.isLoggedIn();
      this.isLoggedIn = loggedIn;
      if (loggedIn) {
        // 先从本地加载用户信息
        const localUserInfo = await StorageUtil.getUserInfo();
        if (localUserInfo) {
          this.userInfo = localUserInfo;
        }
        
        // 再从后端获取最新用户信息（可能会覆盖本地）
        try {
          const result = await AuthService.getCurrentUserInfo();
          if (ResultUtil.isSuccess(result) && result.data) {
            this.userInfo = result.data;
            // 保存到本地
            await StorageUtil.saveUserInfo(result.data);
          }
        } catch (err) {
          console.warn('[UserCenterPage] 获取用户信息失败，使用本地数据:', JSON.stringify(err));
        }
      } else {
        // 未登录，清空用户信息
        this.userInfo = null;
      }
    } catch (err) {
      console.error('[UserCenterPage] 检查登录状态失败:', err);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 跳转到登录页
   */
  navigateToLogin() {
    router.pushUrl({
      url: 'pages/LoginPage'
    }).then(() => {
      // 登录页面返回后刷新状态
    }).catch((err: Error) => {
      console.error('Failed to navigate:', JSON.stringify(err));
    });
  }

  /**
   * 退出登录
   */
  async handleLogout() {
    try {
      await AuthService.logout();
      this.isLoggedIn = false;
      this.userInfo = null;
    } catch (err) {
      console.error('[UserCenterPage] 退出登录失败:', err);
    }
  }

  /**
   * 编辑个人资料
   */
  editProfile() {
    // TODO: 跳转到编辑资料页面
  }

  build() {
    Column() {
      if (this.isLoading) {
        LoadingProgress()
          .width(40)
          .height(40)
          .color('#007AFF')
          .margin({ top: 100 });
      } else if (!this.isLoggedIn) {
        // 未登录状态
        Column() {
          // 头像占位
          Text('👤')
            .fontSize(60)
            .width(80)
            .height(80)
            .textAlign(TextAlign.Center)
            .backgroundColor('#E6F0FF')
            .borderRadius(40)
            .margin({ top: 60, bottom: 16 });

          Text('点击登录')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .margin({ bottom: 8 })
            .onClick(() => {
              this.navigateToLogin();
            });

          Button('登录')
            .width(200)
            .height(44)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#007AFF')
            .borderRadius(22)
            .onClick(() => {
              this.navigateToLogin();
            });
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);
      } else {
        // 已登录状态
        Column() {
          Scroll() {
            Column() {
              // 用户信息区域
              Column() {
                // 头像
                if (this.userInfo?.avatar && this.userInfo.avatar.trim() !== '') {
                  Image(this.userInfo.avatar)
                    .width(100)
                    .height(100)
                    .borderRadius(50)
                    .objectFit(ImageFit.Cover)
                    .margin({ top: 20, bottom: 16 })
                    .alt('头像')
                    .onError(() => {
                      console.error('[UserCenterPage] 头像加载失败:', this.userInfo?.avatar);
                    });
                } else {
                  Text('👤')
                    .fontSize(80)
                    .width(100)
                    .height(100)
                    .textAlign(TextAlign.Center)
                    .backgroundColor('#E6F0FF')
                    .borderRadius(50)
                    .margin({ top: 20, bottom: 16 });
                }

                // 用户名（优先显示昵称，其次用户名）
                Text(this.userInfo?.nickname || this.userInfo?.username || '用户')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')
                  .margin({ bottom: 8 });

                // 用户名（@格式）
                Text(`@${this.userInfo?.username || '用户'}`)
                  .fontSize(14)
                  .fontColor('#999999')
                  .margin({ bottom: 16 });

                // 编辑个人资料按钮
                Button('编辑个人资料')
                  .width(200)
                  .height(36)
                  .fontSize(14)
                  .fontColor('#333333')
                  .backgroundColor('#F5F5F5')
                  .borderRadius(18)
                  .onClick(() => {
                    this.editProfile();
                  });
              }
              .width('100%')
              .padding({ top: 20, bottom: 20 })
              .backgroundColor('#FFFFFF')
              .alignItems(HorizontalAlign.Center);

              // 退出登录按钮
              Button('退出登录')
                .width('90%')
                .height(44)
                .fontSize(16)
                .fontColor('#FF3B30')
                .backgroundColor('#FFFFFF')
                .borderRadius(22)
                .margin({ top: 20, bottom: 20 })
                .onClick(() => {
                  this.handleLogout();
                });
            }
            .width('100%')
          }
          .layoutWeight(1)
          .width('100%')
          .backgroundColor('#F5F5F5');
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#F5F5F5');
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5');
  }

  /**
   * 页面显示时刷新状态
   */
  onPageShow() {
    // 页面显示时检查是否需要刷新
    this.checkLoginStatus();
  }
}

