/**
 * Markdown解析工具类
 * 将markdown文本解析为结构化的节点
 */
export interface MarkdownNode {
  type: 'text' | 'bold' | 'italic' | 'code' | 'codeBlock' | 'heading' | 'list' | 'link' | 'lineBreak';
  content?: string;
  level?: number; // 用于heading
  language?: string; // 用于codeBlock
  children?: MarkdownNode[];
  url?: string; // 用于link
}

export class MarkdownParser {
  /**
   * 解析markdown文本为节点数组
   */
  static parse(text: string): MarkdownNode[] {
    if (!text) {
      return [];
    }

    const nodes: MarkdownNode[] = [];
    const lines = text.split('\n');
    let i = 0;

    while (i < lines.length) {
      const line = lines[i];

      // 代码块
      if (line.trim().startsWith('```')) {
        const language = line.trim().substring(3).trim();
        const codeLines: string[] = [];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeLines.push(lines[i]);
          i++;
        }
        nodes.push({
          type: 'codeBlock',
          content: codeLines.join('\n'),
          language: language || undefined
        });
        i++;
        continue;
      }

      // 标题
      const headingMatch = line.match(/^(#{1,6})\s+(.+)$/);
      if (headingMatch) {
        nodes.push({
          type: 'heading',
          level: headingMatch[1].length,
          children: MarkdownParser.parseInline(headingMatch[2])
        });
        i++;
        continue;
      }

      // 无序列表
      const ulMatch = line.match(/^[-*+]\s+(.+)$/);
      if (ulMatch) {
        nodes.push({
          type: 'list',
          children: MarkdownParser.parseInline(ulMatch[1])
        });
        i++;
        continue;
      }

      // 有序列表
      const olMatch = line.match(/^\d+\.\s+(.+)$/);
      if (olMatch) {
        nodes.push({
          type: 'list',
          children: MarkdownParser.parseInline(olMatch[1])
        });
        i++;
        continue;
      }

      // 普通文本行
      if (line.trim()) {
        const inlineNodes = MarkdownParser.parseInline(line);
        if (inlineNodes.length > 0) {
          nodes.push(...inlineNodes);
        }
      } else {
        // 空行作为换行
        nodes.push({ type: 'lineBreak' });
      }

      i++;
    }

    return nodes;
  }

  /**
   * 解析行内markdown语法
   */
  static parseInline(text: string): MarkdownNode[] {
    const nodes: MarkdownNode[] = [];
    let i = 0;
    let currentText = '';

    while (i < text.length) {
      // 代码片段 `code`
      if (text[i] === '`' && (i === 0 || text[i - 1] !== '\\')) {
        if (currentText) {
          nodes.push({ type: 'text', content: currentText });
          currentText = '';
        }
        const codeEnd = text.indexOf('`', i + 1);
        if (codeEnd !== -1) {
          nodes.push({
            type: 'code',
            content: text.substring(i + 1, codeEnd)
          });
          i = codeEnd + 1;
          continue;
        }
      }

      // 粗体 **text** 或 __text__
      if ((text[i] === '*' && text[i + 1] === '*') || (text[i] === '_' && text[i + 1] === '_')) {
        if (currentText) {
          nodes.push({ type: 'text', content: currentText });
          currentText = '';
        }
        const marker = text.substring(i, i + 2);
        const boldEnd = text.indexOf(marker, i + 2);
        if (boldEnd !== -1) {
          nodes.push({
            type: 'bold',
            children: MarkdownParser.parseInline(text.substring(i + 2, boldEnd))
          });
          i = boldEnd + 2;
          continue;
        }
      }

      // 斜体 *text* 或 _text_ (但不是 ** 或 __)
      if ((text[i] === '*' || text[i] === '_') && text[i + 1] !== text[i]) {
        if (currentText) {
          nodes.push({ type: 'text', content: currentText });
          currentText = '';
        }
        const marker = text[i];
        // 找到下一个相同的marker，但确保不是两个连续的
        let italicEnd = -1;
        for (let j = i + 1; j < text.length; j++) {
          if (text[j] === marker && (j === text.length - 1 || text[j + 1] !== marker)) {
            italicEnd = j;
            break;
          }
        }
        if (italicEnd !== -1) {
          nodes.push({
            type: 'italic',
            children: MarkdownParser.parseInline(text.substring(i + 1, italicEnd))
          });
          i = italicEnd + 1;
          continue;
        }
      }

      // 链接 [text](url)
      if (text[i] === '[') {
        if (currentText) {
          nodes.push({ type: 'text', content: currentText });
          currentText = '';
        }
        const linkTextEnd = text.indexOf(']', i);
        if (linkTextEnd !== -1 && text[linkTextEnd + 1] === '(') {
          const linkUrlEnd = text.indexOf(')', linkTextEnd + 2);
          if (linkUrlEnd !== -1) {
            nodes.push({
              type: 'link',
              content: text.substring(i + 1, linkTextEnd),
              url: text.substring(linkTextEnd + 2, linkUrlEnd)
            });
            i = linkUrlEnd + 1;
            continue;
          }
        }
      }

      currentText += text[i];
      i++;
    }

    if (currentText) {
      nodes.push({ type: 'text', content: currentText });
    }

    return nodes;
  }
}

