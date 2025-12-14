import { SessionService } from '../services/SessionService';
import { ModelService } from '../services/ModelService';
import { AIModel } from '../models/AIModel';
import { ResultUtil } from '../models/Result';
import { Constants } from '../utils/Constants';
import router from '@ohos.router';

/**
 * 创建会话页面
 */
@Entry
@Component
struct SessionCreatePage {
  @State title: string = '';
  @State models: AIModel[] = [];
  @State selectedModel: string = Constants.MODEL_QWEN_MAX;
  @State isLoading: boolean = false;
  @State errorMessage: string = '';

  aboutToAppear() {
    this.loadModels();
  }

  /**
   * 加载模型列表
   */
  async loadModels() {
    try {
      const result = await ModelService.getModelList();
      if (ResultUtil.isSuccess(result)) {
        this.models = result.data || [];
        // 设置默认选中当前模型
        const currentModel = this.models.find(m => m.isCurrent);
        if (currentModel) {
          this.selectedModel = currentModel.name;
        }
      }
    } catch (err) {
      console.error('Failed to load models:', JSON.stringify(err));
    }
  }

  /**
   * 创建会话
   */
  async createSession() {
    if (!this.selectedModel) {
      this.errorMessage = '请选择模型';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';
    try {
      const result = await SessionService.createSession(this.title || '新会话', this.selectedModel);
      if (ResultUtil.isSuccess(result)) {
        // 返回上一页
        router.back();
        // 注意：页面返回后会在 onPageShow 中刷新列表
      } else {
        this.errorMessage = ResultUtil.getErrorMessage(result);
      }
    } catch (err) {
      this.errorMessage = `创建失败: ${JSON.stringify(err)}`;
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Button('取消')
          .fontSize(16)
          .type(ButtonType.Normal)
          .fontColor('#007AFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            router.back();
          });
        
        Text('新建会话')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center);
        
        Button('完成')
          .fontSize(16)
          .type(ButtonType.Normal)
          .fontColor('#007AFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.createSession();
          });
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF');

      // 表单内容
      Column() {
        // 会话标题
        Column() {
          Text('会话标题')
            .fontSize(14)
            .fontColor('#666666')
            .width('100%')
            .textAlign(TextAlign.Start)
            .margin({ bottom: 8 });
          
          TextInput({ placeholder: '请输入会话标题（可选）' })
            .width('100%')
            .height(40)
            .backgroundColor('#F5F5F5')
            .borderRadius(4)
            .onChange((value: string) => {
              this.title = value;
            });
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 });

        // 模型选择
        Column() {
          Text('选择模型')
            .fontSize(14)
            .fontColor('#666666')
            .width('100%')
            .textAlign(TextAlign.Start)
            .margin({ bottom: 8 });
          
          if (this.models.length > 0) {
            ForEach(this.models, (model: AIModel) => {
              Row() {
                Radio({ value: model.name, group: 'modelGroup' })
                  .checked(model.name === this.selectedModel)
                  .onChange((isChecked: boolean) => {
                    if (isChecked) {
                      this.selectedModel = model.name;
                    }
                  });
                
                Column() {
                  Text(model.displayName || model.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium);
                  
                  if (model.description) {
                    Text(model.description)
                      .fontSize(12)
                      .fontColor('#999999')
                      .margin({ top: 4 });
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .margin({ left: 12 });
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .margin({ bottom: 8 })
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .onClick(() => {
                this.selectedModel = model.name;
              });
            }, (model: AIModel) => model.name);
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 });

        // 错误提示
        if (this.errorMessage) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#FF0000')
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 });
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#FFFFFF');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5');
  }
}

