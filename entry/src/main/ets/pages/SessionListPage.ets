import { SessionService } from '../services/SessionService';
import { ChatSession } from '../models/ChatSession';
import { ResultUtil } from '../models/Result';
import { SessionItem } from '../components/SessionItem';
import { LoadingView } from '../components/LoadingView';
import { EmptyView } from '../components/EmptyView';
import router from '@ohos.router';

/**
 * 会话列表页面
 */
@Component
export struct SessionListPage {
  @State sessions: ChatSession[] = [];
  @State isLoading: boolean = true;
  @State errorMessage: string = '';

  async aboutToAppear() {
    this.loadSessions();
  }

  /**
   * 加载会话列表
   */
  async loadSessions() {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const result = await SessionService.getSessionList();
      if (ResultUtil.isSuccess(result)) {
        this.sessions = result.data || [];
      } else {
        // 如果是未认证错误，不显示错误，直接显示空列表（允许未登录使用）
        const errorMsg = ResultUtil.getErrorMessage(result);
        if (errorMsg.includes('未认证') || errorMsg.includes('未登录') || errorMsg.includes('UNAUTHORIZED')) {
          this.sessions = [];
          this.errorMessage = '';
        } else {
          this.errorMessage = errorMsg;
        }
      }
    } catch (err) {
      // 网络错误或其他异常，也不显示错误，显示空列表
      this.sessions = [];
      this.errorMessage = '';
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 创建新会话
   */
  createSession() {
    router.pushUrl({
      url: 'pages/SessionCreatePage'
    }).then(() => {
      // 页面返回时刷新列表
    }).catch((err: Error) => {
      console.error('Failed to navigate:', JSON.stringify(err));
    });
  }

  /**
   * 页面显示时刷新列表（从其他页面返回时）
   */
  onPageShow() {
    this.loadSessions();
  }

  /**
   * 点击会话项
   */
  onSessionClick(session: ChatSession) {
    router.pushUrl({
      url: 'pages/ChatPage',
      params: {
        sessionId: session.id
      }
    }).catch((err: Error) => {
      console.error('Failed to navigate:', JSON.stringify(err));
    });
  }

  @State deleteDialogVisible: boolean = false;
  @State sessionToDelete: ChatSession | null = null;
  deleteDialogController: CustomDialogController | null = null;

  /**
   * 显示删除确认弹窗
   */
  showDeleteDialog(session: ChatSession) {
    this.sessionToDelete = session;
    if (this.deleteDialogController) {
      try {
        this.deleteDialogController.close();
      } catch (err) {
        console.warn(`[SessionListPage] 关闭旧对话框失败:`, err);
      }
      this.deleteDialogController = null;
    }
    
    let dialogController: CustomDialogController | null = null;
    dialogController = new CustomDialogController({
      builder: () => {
        DeleteConfirmDialog({
          controller: dialogController!,
          sessionTitle: session.title || '新会话',
          onCancel: () => {
            this.cancelDelete();
          },
          onConfirm: () => {
            this.confirmDeleteSession();
          }
        });
      },
      cancel: () => {
        this.cancelDelete();
      },
      autoCancel: true
    });
    this.deleteDialogController = dialogController;
    
    try {
      dialogController.open();
    } catch (err) {
      console.error(`[SessionListPage] 打开对话框失败:`, err);
      this.errorMessage = '打开对话框失败';
    }
  }

  /**
   * 确认删除会话
   */
  async confirmDeleteSession() {
    if (!this.sessionToDelete) {
      return;
    }

    if (this.deleteDialogController) {
      this.deleteDialogController.close();
      this.deleteDialogController = null;
    }
    this.deleteDialogVisible = false;

    const sessionIdToDelete = this.sessionToDelete.id;
    this.sessionToDelete = null;

    try {
      console.info(`[SessionListPage] 开始删除会话，sessionId: ${sessionIdToDelete}`);
      const result = await SessionService.deleteSession(sessionIdToDelete);
      if (ResultUtil.isSuccess(result)) {
        console.info(`[SessionListPage] 会话删除成功，重新加载列表`);
        await this.loadSessions();
      } else {
        const errorMsg = ResultUtil.getErrorMessage(result);
        this.errorMessage = errorMsg || '删除失败';
        console.error(`[SessionListPage] 删除会话失败: ${errorMsg}`);
      }
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : `删除失败: ${JSON.stringify(err)}`;
      this.errorMessage = errorMsg;
      console.error(`[SessionListPage] 删除会话异常:`, err);
    }
  }

  /**
   * 取消删除
   */
  cancelDelete() {
    this.deleteDialogVisible = false;
    this.sessionToDelete = null;
    if (this.deleteDialogController) {
      this.deleteDialogController = null;
    }
  }

  /**
   * 左滑删除按钮构建器
   */
  @Builder
  swipeDeleteBuilder(session: ChatSession) {
    Row() {
      Button('删除')
        .fontSize(14)
        .fontColor('#FFFFFF')
        .type(ButtonType.Normal)
        .backgroundColor('#FF3B30')
        .width(80)
        .height('100%')
        .onClick(() => {
          this.showDeleteDialog(session);
        });
    }
    .width(80)
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('AI 智能助手')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1);
        
        Button('新建')
          .fontSize(14)
          .type(ButtonType.Normal)
          .onClick(() => {
            this.createSession();
          });
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center);

      // 内容区域
      if (this.isLoading) {
        LoadingView({ message: '加载会话列表...' });
      } else if (this.errorMessage) {
        Column() {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#FF0000')
            .margin({ bottom: 16 });
          
          Button('重试')
            .onClick(() => {
              this.loadSessions();
            });
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);
      } else if (this.sessions.length === 0) {
        EmptyView({ message: '暂无会话，点击新建创建第一个会话' });
      } else {
        List() {
          ForEach(this.sessions, (session: ChatSession) => {
            ListItem() {
              SessionItem({
                session: session,
                onItemClick: () => {
                  this.onSessionClick(session);
                },
                onDelete: () => {
                  this.showDeleteDialog(session);
                }
              });
            }
            .swipeAction({
              start: () => {
                this.swipeDeleteBuilder(session);
              }
            })
          }, (session: ChatSession) => session.id.toString());
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 8 });
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5');
  }
}

/**
 * 删除确认弹窗组件
 */
@CustomDialog
struct DeleteConfirmDialog {
  controller: CustomDialogController;
  sessionTitle: string = '';
  onCancel: () => void = () => {};
  onConfirm: () => void = () => {};

  build() {
    Column() {
      Text('确认删除')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 24, bottom: 16 });

      Text(`确定要删除会话"${this.sessionTitle}"吗？`)
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 24 })
        .padding({ left: 24, right: 24 });

      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .fontColor('#333333')
          .backgroundColor('#F5F5F5')
          .onClick(() => {
            this.controller.close();
            this.onCancel();
          });

        Button('删除')
          .layoutWeight(1)
          .height(44)
          .fontColor('#FFFFFF')
          .backgroundColor('#FF3B30')
          .margin({ left: 12 })
          .onClick(() => {
            this.controller.close();
            this.onConfirm();
          });
      }
      .width('100%')
      .padding({ left: 24, right: 24, bottom: 24 });
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12);
  }
}

