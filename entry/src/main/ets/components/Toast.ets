import promptAction from '@ohos.promptAction';

/**
 * 统一提示工具类
 */
export class Toast {
  /**
   * 显示成功提示
   */
  static showSuccess(message: string) {
    promptAction.showToast({
      message: message,
      duration: 2000
    });
  }

  /**
   * 显示错误提示
   */
  static showError(message: string) {
    promptAction.showToast({
      message: message,
      duration: 2000
    });
  }

  /**
   * 显示普通提示
   */
  static show(message: string) {
    promptAction.showToast({
      message: message,
      duration: 2000
    });
  }
}

