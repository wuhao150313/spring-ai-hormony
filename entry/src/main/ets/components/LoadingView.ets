/**
 * 加载组件
 */
@Component
export struct LoadingView {
  @Prop message: string = '加载中...';

  build() {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
        .color('#007AFF');
      
      if (this.message) {
        Text(this.message)
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 12 });
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }
}

