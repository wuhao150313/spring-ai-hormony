import { AgentVO } from '../models/AgentVO';
import router from '@ohos.router';

/**
 * 智能体浏览页面
 */
@Component
export struct AgentBrowsePage {
  @State selectedCategory: string = '精选';
  @State agents: AgentVO[] = [];
  @State searchText: string = '';
  @State filteredAgents: AgentVO[] = [];
  categories: string[] = ['精选', '拍照问', '学习', '企业', '头像生成'];

  aboutToAppear() {
    this.loadAgents();
    this.filterAgents();
  }

  /**
   * 过滤智能体列表
   */
  filterAgents() {
    if (!this.searchText || this.searchText.trim() === '') {
      this.filteredAgents = this.agents;
    } else {
      const searchKeyword = this.searchText.trim().toLowerCase();
      this.filteredAgents = this.agents.filter((agent: AgentVO) => {
        return agent.name.toLowerCase().includes(searchKeyword);
      });
    }
  }

  /**
   * 加载智能体列表（模拟数据）
   */
  loadAgents() {
    // 模拟数据，实际应该从后端获取
    this.agents = [
      {
        id: 1,
        name: '知识讲解助手',
        description: '知识讲解',
        icon: '💡',
        isOfficial: true,
        chatCount: 10074000,
        author: '@豆包官方',
        category: '精选',
        isAdded: false
      },
      {
        id: 2,
        name: '错题分析助手',
        description: '错题分析',
        icon: '✅',
        isOfficial: true,
        chatCount: 3122000,
        author: '@豆包官方',
        category: '学习',
        isAdded: false
      },
      {
        id: 3,
        name: '学习计划助手',
        description: '学习计划',
        icon: '📅',
        isOfficial: true,
        chatCount: 585000,
        author: '@豆包官方',
        category: '学习',
        isAdded: false
      },
      {
        id: 4,
        name: '课表查询助手',
        description: '课表查询',
        icon: '📆',
        isOfficial: true,
        chatCount: 10270000,
        author: '@豆包官方',
        category: '学习',
        isAdded: false
      },
      {
        id: 5,
        name: '图书馆查询助手',
        description: '图书馆借阅查询',
        icon: '📖',
        isOfficial: true,
        chatCount: 11744000,
        author: '@豆包官方',
        category: '精选',
        isAdded: false
      },
      {
        id: 6,
        name: '天气查询助手',
        description: '天气查询',
        icon: '☀️',
        isOfficial: true,
        chatCount: 5000000,
        author: '@豆包官方',
        category: '精选',
        isAdded: false
      },
      {
        id: 7,
        name: '通用查询助手',
        description: '查询',
        icon: '🔍',
        isOfficial: true,
        chatCount: 3500000,
        author: '@豆包官方',
        category: '精选',
        isAdded: false
      },
      {
        id: 8,
        name: '保修提交助手',
        description: '保修提交',
        icon: '🛠️',
        isOfficial: true,
        chatCount: 2800000,
        author: '@豆包官方',
        category: '精选',
        isAdded: false
      },
      {
        id: 9,
        name: '助学政策助手',
        description: '助学政策',
        icon: '📋',
        isOfficial: true,
        chatCount: 4200000,
        author: '@豆包官方',
        category: '精选',
        isAdded: false
      }
    ];
  }

  /**
   * 格式化聊天人数
   */
  formatChatCount(count: number): string {
    if (count >= 10000) {
      return `${(count / 10000).toFixed(1)}万人聊过`;
    }
    return `${count}人聊过`;
  }

  /**
   * 切换分类
   */
  switchCategory(category: string) {
    this.selectedCategory = category;
    // 这里可以根据分类筛选智能体
  }

  /**
   * 添加/移除智能体
   */
  toggleAgent(agent: AgentVO) {
    agent.isAdded = !agent.isAdded;
    // 这里可以调用后端API保存状态
  }

  /**
   * 处理智能体点击事件
   */
  onAgentClick(agent: AgentVO) {
    // 跳转到智能体对话页面
    router.pushUrl({
      url: 'pages/AgentChatPage',
      params: {
        agentId: agent.id,
        agentName: agent.name
      }
    }).catch((err: Error) => {
      console.error('Failed to navigate to AgentChatPage:', JSON.stringify(err));
    });
  }

  build() {
    Column() {
      // 搜索框
      TextInput({ placeholder: '搜索智能体...', text: this.searchText })
        .width('100%')
        .height(44)
        .backgroundColor('#FFFFFF')
        .padding({ left: 16, right: 16 })
        .margin({ top: 8, bottom: 8, left: 16, right: 16 })
        .borderRadius(22)
        .onChange((value: string) => {
          this.searchText = value;
          this.filterAgents();
        });

      // 智能体列表
      List() {
        ForEach(this.filteredAgents, (agent: AgentVO) => {
          ListItem() {
            Row() {
              // 图标
              Text(agent.icon)
                .fontSize(40)
                .width(60)
                .height(60)
                .textAlign(TextAlign.Center)
                .backgroundColor('#F5F5F5')
                .borderRadius(30);

              // 内容区域
              Column() {
                Row() {
                  Text(agent.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#333333');
                  
                  if (agent.isOfficial) {
                    Text('官方')
                      .fontSize(10)
                      .fontColor('#007AFF')
                      .backgroundColor('#E6F0FF')
                      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                      .borderRadius(4)
                      .margin({ left: 8 });
                  }
                }
                .width('100%')
                .alignItems(VerticalAlign.Center);

                Text(agent.description)
                  .fontSize(14)
                  .fontColor('#666666')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 4 })
                  .width('100%');

                Row() {
                  Text(this.formatChatCount(agent.chatCount))
                    .fontSize(12)
                    .fontColor('#999999');
                  
                  Text(agent.author)
                    .fontSize(12)
                    .fontColor('#999999')
                    .margin({ left: 8 });
                }
                .width('100%')
                .margin({ top: 4 });
              }
              .layoutWeight(1)
              .margin({ left: 12 });
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .margin({ left: 16, right: 16, top: 8, bottom: 8 })
            .onClick(() => {
              this.onAgentClick(agent);
            });
          }
        }, (agent: AgentVO) => agent.id.toString());
      }
      .layoutWeight(1)
      .padding({ top: 8, bottom: 8 })
      .backgroundColor('#F5F5F5');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5');
  }
}

