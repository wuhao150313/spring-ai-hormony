import { MainPage } from './MainPage';

/**
 * 应用入口
 */
@Entry
@Component
struct Index {
  build() {
    Column() {
      MainPage();
    }
    .width('100%')
    .height('100%')
  }
}