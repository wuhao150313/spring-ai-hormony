import { AuthService } from '../services/AuthService';
import { ResultUtil } from '../models/Result';
import { StorageUtil } from '../utils/StorageUtil';
import router from '@ohos.router';

/**
 * 登录页面
 */
@Entry
@Component
export struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State loginType: 'password' | 'sms' = 'password';
  @State mobile: string = '';
  @State smsCode: string = '';
  @State countdown: number = 0;

  /**
   * 账号密码登录
   */
  async handlePasswordLogin() {
    if (!this.username.trim()) {
      this.errorMessage = '请输入用户名';
      return;
    }
    if (!this.password.trim()) {
      this.errorMessage = '请输入密码';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';
    try {
      // 第一步：调用登录验证接口
      const loginResult = await AuthService.login(this.username, this.password);
      if (ResultUtil.isSuccess(loginResult)) {
        // 第二步：调用获取用户信息接口
        try {
          const userInfoResult = await AuthService.getCurrentUserInfo();
          if (ResultUtil.isSuccess(userInfoResult) && userInfoResult.data) {
            // 保存用户信息到本地
            await StorageUtil.saveUserInfo(userInfoResult.data);
          } else {
            console.warn('获取用户信息失败，但不影响登录:', ResultUtil.getErrorMessage(userInfoResult));
          }
        } catch (err) {
          console.warn('获取用户信息失败，但不影响登录:', JSON.stringify(err));
        }
        
        // 登录成功，通知用户中心刷新，并返回到主页面
        AppStorage.set('refreshUserCenter', Date.now());
        AppStorage.set('targetTabIndex', 4); // 切换到用户中心 Tab
        router.replaceUrl({
          url: 'pages/Index'
        }).catch((err: Error) => {
          console.error('Failed to navigate:', JSON.stringify(err));
        });
      } else {
        this.errorMessage = ResultUtil.getErrorMessage(loginResult);
      }
    } catch (err) {
      this.errorMessage = `登录失败: ${JSON.stringify(err)}`;
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 短信登录
   */
  async handleSmsLogin() {
    if (!this.mobile.trim()) {
      this.errorMessage = '请输入手机号';
      return;
    }
    if (!this.smsCode.trim()) {
      this.errorMessage = '请输入验证码';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';
    try {
      // 第一步：调用登录验证接口
      const loginResult = await AuthService.smsLogin(this.mobile, this.smsCode);
      if (ResultUtil.isSuccess(loginResult)) {
        // 第二步：调用获取用户信息接口
        try {
          const userInfoResult = await AuthService.getCurrentUserInfo();
          if (ResultUtil.isSuccess(userInfoResult) && userInfoResult.data) {
            // 保存用户信息到本地
            await StorageUtil.saveUserInfo(userInfoResult.data);
          } else {
            console.warn('获取用户信息失败，但不影响登录:', ResultUtil.getErrorMessage(userInfoResult));
          }
        } catch (err) {
          console.warn('获取用户信息失败，但不影响登录:', JSON.stringify(err));
        }
        
        // 登录成功，通知用户中心刷新，并返回到主页面
        AppStorage.set('refreshUserCenter', Date.now());
        AppStorage.set('targetTabIndex', 4); // 切换到用户中心 Tab
        router.replaceUrl({
          url: 'pages/Index'
        }).catch((err: Error) => {
          console.error('Failed to navigate:', JSON.stringify(err));
        });
      } else {
        this.errorMessage = ResultUtil.getErrorMessage(loginResult);
      }
    } catch (err) {
      this.errorMessage = `登录失败: ${JSON.stringify(err)}`;
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 发送短信验证码
   */
  async sendSmsCode() {
    if (!this.mobile.trim()) {
      this.errorMessage = '请输入手机号';
      return;
    }

    try {
      const result = await AuthService.sendSmsCode(this.mobile);
      if (ResultUtil.isSuccess(result)) {
        // 开始倒计时
        this.countdown = 60;
        const timer = setInterval(() => {
          this.countdown--;
          if (this.countdown <= 0) {
            clearInterval(timer);
          }
        }, 1000);
      } else {
        this.errorMessage = ResultUtil.getErrorMessage(result);
      }
    } catch (err) {
      this.errorMessage = `发送失败: ${JSON.stringify(err)}`;
    }
  }

  build() {
    Column() {
      // 返回按钮
      Row() {
        Button('返回')
          .fontSize(16)
          .type(ButtonType.Normal)
          .fontColor('#007AFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            router.back();
          });
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center);

      // 标题
      Text('AI 智能助手')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40, bottom: 40 });

      // 登录方式切换
      Row() {
        Button('账号密码')
          .type(this.loginType === 'password' ? ButtonType.Capsule : ButtonType.Normal)
          .backgroundColor(this.loginType === 'password' ? '#007AFF' : '#F5F5F5')
          .fontColor(this.loginType === 'password' ? '#FFFFFF' : '#333333')
          .onClick(() => {
            this.loginType = 'password';
            this.errorMessage = '';
          });

        Button('短信登录')
          .type(this.loginType === 'sms' ? ButtonType.Capsule : ButtonType.Normal)
          .backgroundColor(this.loginType === 'sms' ? '#007AFF' : '#F5F5F5')
          .fontColor(this.loginType === 'sms' ? '#FFFFFF' : '#333333')
          .margin({ left: 16 })
          .onClick(() => {
            this.loginType = 'sms';
            this.errorMessage = '';
          });
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 32 });

      // 登录表单
      if (this.loginType === 'password') {
        // 账号密码登录
        Column() {
          TextInput({ placeholder: '请输入用户名' })
            .width('100%')
            .height(48)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .padding({ left: 16, right: 16 })
            .margin({ bottom: 16 })
            .onChange((value: string) => {
              this.username = value;
            });

          TextInput({ placeholder: '请输入密码' })
            .type(InputType.Password)
            .width('100%')
            .height(48)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .padding({ left: 16, right: 16 })
            .margin({ bottom: 24 })
            .onChange((value: string) => {
              this.password = value;
            });

          Button('登录')
            .width('100%')
            .height(48)
            .fontSize(16)
            .enabled(!this.isLoading)
            .onClick(() => {
              this.handlePasswordLogin();
            });
        }
        .width('100%')
        .padding({ left: 32, right: 32 });
      } else {
        // 短信登录
        Column() {
          TextInput({ placeholder: '请输入手机号' })
            .width('100%')
            .height(48)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .padding({ left: 16, right: 16 })
            .margin({ bottom: 16 })
            .onChange((value: string) => {
              this.mobile = value;
            });

          Row() {
            TextInput({ placeholder: '请输入验证码' })
              .layoutWeight(1)
              .height(48)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .padding({ left: 16, right: 16 })
              .onChange((value: string) => {
                this.smsCode = value;
              });

            Button(this.countdown > 0 ? `${this.countdown}秒` : '获取验证码')
              .width(100)
              .height(48)
              .margin({ left: 12 })
              .enabled(this.countdown === 0)
              .onClick(() => {
                this.sendSmsCode();
              });
          }
          .width('100%')
          .margin({ bottom: 24 });

          Button('登录')
            .width('100%')
            .height(48)
            .fontSize(16)
            .enabled(!this.isLoading)
            .onClick(() => {
              this.handleSmsLogin();
            });
        }
        .width('100%')
        .padding({ left: 32, right: 32 });
      }

      // 错误提示
      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(14)
          .fontColor('#FF0000')
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 16 });
      }

      // 加载提示
      if (this.isLoading) {
        LoadingProgress()
          .width(40)
          .height(40)
          .color('#007AFF')
          .margin({ top: 16 });
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .padding({ left: 16, right: 16 });
  }
}

