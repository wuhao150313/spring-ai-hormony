/**
 * 空状态组件
 */
@Component
export struct EmptyView {
  @Prop message: string = '暂无数据';
  @Prop icon: string = '';

  build() {
    Column() {
      if (this.icon) {
        Image(this.icon)
          .width(80)
          .height(80)
          .opacity(0.5);
      }
      
      Text(this.message)
        .fontSize(16)
        .fontColor('#999999')
        .margin({ top: 16 });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }
}

