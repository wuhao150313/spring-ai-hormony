import { MarkdownParser, MarkdownNode } from '../utils/MarkdownParser';

/**
 * Markdown文本渲染组件
 * 将markdown格式的文本渲染为格式化的UI
 */
@Component
export struct MarkdownText {
  @Prop content: string = '';
  @Prop fontSize: number = 14;
  @Prop fontColor: string = '#333333';
  
  @State private nodes: MarkdownNode[] = [];

  aboutToAppear() {
    this.parseContent();
  }

  aboutToUpdate() {
    this.parseContent();
  }

  private parseContent() {
    if (!this.content) {
      this.nodes = [];
      return;
    }
    this.nodes = MarkdownParser.parse(this.content);
  }

  build() {
    Column() {
      ForEach(this.nodes, (node: MarkdownNode, index: number) => {
        this.renderNode(node, index);
      }, (node: MarkdownNode, index: number) => `node_${index}_${node.type}_${node.content || ''}`);
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%');
  }

  /**
   * 渲染单个节点
   */
  @Builder
  private renderNode(node: MarkdownNode, index: number) {
    if (node.type === 'text') {
      Text(node.content || '')
        .fontSize(this.fontSize)
        .fontColor(this.fontColor);
    } else if (node.type === 'bold') {
      Flex({ wrap: FlexWrap.Wrap }) {
        if (node.children) {
          ForEach(node.children, (child: MarkdownNode, childIndex: number) => {
            this.renderInlineNode(child, childIndex, true, false);
          }, (child: MarkdownNode, childIndex: number) => `bold_child_${childIndex}_${child.type}_${child.content || ''}`);
        }
      }
      .width('100%');
    } else if (node.type === 'italic') {
      Flex({ wrap: FlexWrap.Wrap }) {
        if (node.children) {
          ForEach(node.children, (child: MarkdownNode, childIndex: number) => {
            this.renderInlineNode(child, childIndex, false, true);
          }, (child: MarkdownNode, childIndex: number) => `italic_child_${childIndex}_${child.type}_${child.content || ''}`);
        }
      }
      .width('100%');
    } else if (node.type === 'code') {
      Text(node.content || '')
        .fontSize(this.fontSize - 1)
        .fontColor('#E83E8C')
        .fontFamily('monospace')
        .backgroundColor('#F5F5F5')
        .padding({ left: 4, right: 4, top: 2, bottom: 2 })
        .borderRadius(4);
    } else if (node.type === 'codeBlock') {
      Column() {
        if (node.language) {
          Text(node.language)
            .fontSize(this.fontSize - 2)
            .fontColor('#999999')
            .padding({ left: 8, top: 4, bottom: 2 });
        }
        Text(node.content || '')
          .fontSize(this.fontSize - 1)
          .fontColor(this.fontColor)
          .fontFamily('monospace')
          .backgroundColor('#F5F5F5')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .borderRadius(8)
          .width('100%')
          .textAlign(TextAlign.Start);
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 4, bottom: 4 });
    } else if (node.type === 'heading') {
      Column() {
        Flex({ wrap: FlexWrap.Wrap }) {
          if (node.children) {
            ForEach(node.children, (child: MarkdownNode, childIndex: number) => {
              this.renderInlineNode(child, childIndex, true, false, this.fontSize + (7 - (node.level || 1)));
            }, (child: MarkdownNode, childIndex: number) => `heading_child_${childIndex}_${child.type}_${child.content || ''}`);
          }
        }
        .width('100%');
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 8, bottom: 4 });
    } else if (node.type === 'list') {
      Row() {
        Text('•')
          .fontSize(this.fontSize)
          .fontColor(this.fontColor)
          .margin({ right: 8 });
        Flex({ wrap: FlexWrap.Wrap }) {
          if (node.children) {
            ForEach(node.children, (child: MarkdownNode, childIndex: number) => {
              this.renderInlineNode(child, childIndex, false, false);
            }, (child: MarkdownNode, childIndex: number) => `list_child_${childIndex}_${child.type}_${child.content || ''}`);
          }
        }
        .layoutWeight(1)
        .width('100%');
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      .margin({ top: 2, bottom: 2 });
    } else if (node.type === 'link') {
      Text(node.content || '')
        .fontSize(this.fontSize)
        .fontColor('#007AFF')
        .decoration({ type: TextDecorationType.Underline });
    } else if (node.type === 'lineBreak') {
      Blank()
        .height(4);
    }
  }

  /**
   * 渲染行内节点（支持嵌套的粗体和斜体）
   */
  @Builder
  private renderInlineNode(node: MarkdownNode, index: number, isBold: boolean = false, isItalic: boolean = false, customFontSize?: number) {
    if (node.type === 'text') {
      Text(node.content || '')
        .fontSize(customFontSize || this.fontSize)
        .fontColor(this.fontColor)
        .fontWeight(isBold ? FontWeight.Bold : FontWeight.Normal)
        .fontStyle(isItalic ? FontStyle.Italic : FontStyle.Normal);
    } else if (node.type === 'bold') {
      if (node.children) {
        ForEach(node.children, (child: MarkdownNode, childIndex: number) => {
          this.renderInlineNode(child, childIndex, true, isItalic, customFontSize);
        }, (child: MarkdownNode, childIndex: number) => `inline_bold_${childIndex}_${child.type}_${child.content || ''}`);
      }
    } else if (node.type === 'italic') {
      if (node.children) {
        ForEach(node.children, (child: MarkdownNode, childIndex: number) => {
          this.renderInlineNode(child, childIndex, isBold, true, customFontSize);
        }, (child: MarkdownNode, childIndex: number) => `inline_italic_${childIndex}_${child.type}_${child.content || ''}`);
      }
    } else if (node.type === 'code') {
      Text(node.content || '')
        .fontSize((customFontSize || this.fontSize) - 1)
        .fontColor('#E83E8C')
        .fontFamily('monospace')
        .backgroundColor('#F5F5F5')
        .padding({ left: 4, right: 4, top: 2, bottom: 2 })
        .borderRadius(4);
    } else if (node.type === 'link') {
      Text(node.content || '')
        .fontSize(customFontSize || this.fontSize)
        .fontColor('#007AFF')
        .decoration({ type: TextDecorationType.Underline })
        .fontWeight(isBold ? FontWeight.Bold : FontWeight.Normal)
        .fontStyle(isItalic ? FontStyle.Italic : FontStyle.Normal);
    } else {
      // 其他类型，递归渲染
      this.renderNode(node, index);
    }
  }
}

