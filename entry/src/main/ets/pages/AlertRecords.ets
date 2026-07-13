import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AlertRecord, alertLevelText, categoryLabel, AlertLevel, AlarmData } from '../model/PatrolModels';
import { PatrolStore } from '../store/PatrolStore';
import { levelColor } from '../utils/PatrolUiUtils';
import { queryAlarmQuestion } from '../utils/DeepSeekUtil';
import { CardShadow, ElevatedShadow } from '../styles/styles';

export class ChatItem {
  id: string = '';
  isUser: boolean = false;
  text: string = '';
  loading: boolean = false;

  constructor(id: string, isUser: boolean, text: string, loading?: boolean) {
    this.id = id;
    this.isUser = isUser;
    this.text = text;
    this.loading = loading ?? false;
  }
}

@Entry
@Component
struct AlertRecords {
  @State alerts: AlertRecord[] = [];
  @State analysisExpandedId: string = '';
  @State showChatDialog: boolean = false;
  @State selectedAlertId: string = '';
  @State chatInputText: string = '';
  @State chatItems: ChatItem[] = [];
  @State summaryText: string = '';
  @State summaryLoading: boolean = false;
  @State summaryExpanded: boolean = true;
  private refreshHandler: () => void = (): void => {
    this.refreshData();
  };

  aboutToAppear(): void {
    this.refreshData();
    PatrolStore.getInstance().subscribe(this.refreshHandler);
  }

  aboutToDisappear(): void {
    PatrolStore.getInstance().unsubscribe(this.refreshHandler);
  }

  refreshData(): void {
    const storeAlerts = PatrolStore.getInstance().alerts;
    this.alerts = storeAlerts.map((item: AlertRecord): AlertRecord => {
      let record: AlertRecord = {
        id: item.id,
        time: item.time,
        point: item.point,
        category: item.category,
        message: item.message,
        level: item.level,
        imageUrl: item.imageUrl
      };
      if (item.aiAnalysis) {
        record.aiAnalysis = item.aiAnalysis;
      }
      if (item.aiAnalyzing !== undefined) {
        record.aiAnalyzing = item.aiAnalyzing;
      }
      return record;
    });
  }

  toggleAnalysis(id: string): void {
    this.analysisExpandedId = this.analysisExpandedId === id ? '' : id;
  }

  openChat(alertId?: string): void {
    if (alertId) {
      this.selectedAlertId = alertId;
    } else if (!this.selectedAlertId && this.alerts.length > 0) {
      this.selectedAlertId = this.alerts[0].id;
    }
    this.showChatDialog = true;
  }

  closeChat(): void {
    this.showChatDialog = false;
    this.chatInputText = '';
  }

  getSelectedAlert(): AlertRecord | undefined {
    return this.alerts.find((item: AlertRecord): boolean => item.id === this.selectedAlertId);
  }

  getLevelText(level: AlertLevel): string {
    if (level === AlertLevel.Critical) {
      return '严重';
    }
    if (level === AlertLevel.Warning) {
      return '预警';
    }
    return '正常';
  }

  getCriticalCount(): number {
    return this.alerts.filter((item: AlertRecord): boolean => item.level === AlertLevel.Critical).length;
  }

  getWarningCount(): number {
    return this.alerts.filter((item: AlertRecord): boolean => item.level === AlertLevel.Warning).length;
  }

  getNormalCount(): number {
    return this.alerts.filter((item: AlertRecord): boolean => item.level === AlertLevel.Normal).length;
  }

  createAlarmData(alert: AlertRecord): AlarmData {
    return {
      alarm_id: alert.id,
      time: alert.time,
      point: alert.point,
      alarm_type: alert.category,
      message: alert.message,
      level: this.getLevelText(alert.level)
    };
  }

  buildSummaryPayload(): string {
    const payload = this.alerts.map((alert: AlertRecord): AlarmData => {
      return this.createAlarmData(alert);
    });
    return JSON.stringify(payload);
  }

  async analyzeSummary(): Promise<void> {
    if (this.alerts.length === 0) {
      promptAction.showToast({ message: '暂无告警数据' });
      return;
    }
    this.summaryLoading = true;
    this.summaryExpanded = true;
    this.summaryText = '';
    const question = '请汇总全部告警，输出总体风险等级、最需要优先处理的点位、可能原因和3条处置建议，语言简洁，适合手机界面阅读。';
    try {
      this.summaryText = await queryAlarmQuestion(this.buildSummaryPayload(), question);
    } catch (err) {
      this.summaryText = 'AI汇总失败，请检查网络和 DeepSeek API Key 配置。';
    } finally {
      this.summaryLoading = false;
    }
  }

  async sendChat(): Promise<void> {
    const question = this.chatInputText.trim();
    const alert = this.getSelectedAlert();
    if (!question) {
      return;
    }
    if (!alert) {
      promptAction.showToast({ message: '请先选择引用告警' });
      return;
    }
    this.chatItems = [...this.chatItems, new ChatItem(Date.now().toString(), true, question)];
    const loadingId = (Date.now() + 1).toString();
    this.chatItems = [...this.chatItems, new ChatItem(loadingId, false, 'AI正在分析引用告警...', true)];
    this.chatInputText = '';
    try {
      const answer = await queryAlarmQuestion(JSON.stringify(this.createAlarmData(alert)), question);
      this.chatItems = this.chatItems.map((item: ChatItem): ChatItem => {
        if (item.id === loadingId) {
          return new ChatItem(item.id, false, answer, false);
        }
        return item;
      });
    } catch (err) {
      this.chatItems = this.chatItems.map((item: ChatItem): ChatItem => {
        if (item.id === loadingId) {
          return new ChatItem(item.id, false, 'AI咨询失败，请检查网络和 DeepSeek API Key 配置。', false);
        }
        return item;
      });
    }
  }

  @Builder
  Header() {
    Row({ space: '10vp' }) {
      Column({ space: '4vp' }) {
        Text('异常告警中心')
          .fontSize('21fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
        Text(`共 ${this.alerts.length} 条记录，严重 ${this.getCriticalCount()} 条`)
          .fontSize('12fp')
          .fontColor($r('app.color.text_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Button('清空')
        .width('62vp')
        .height('32vp')
        .fontSize('12fp')
        .fontColor($r('app.color.text'))
        .backgroundColor($r('app.color.card_elevated'))
        .borderRadius('16vp')
        .border({ width: '1vp', color: $r('app.color.divider') })
        .onClick((): void => {
          PatrolStore.getInstance().clearAlerts();
          promptAction.showToast({ message: '告警记录已清空' });
        })

      Button('返回')
        .width('62vp')
        .height('32vp')
        .fontSize('12fp')
        .fontColor($r('app.color.text'))
        .backgroundColor($r('app.color.button_secondary'))
        .borderRadius('16vp')
        .onClick((): void => {
          router.back();
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ left: '16vp', right: '16vp', top: '24vp', bottom: '12vp' })
    .backgroundColor($r('app.color.header_background'))
    .shadow({ radius: 18, offsetX: 0, offsetY: 8, color: '#00000042' })
  }

  @Builder
  SummaryPanel() {
    Column({ space: '10vp' }) {
      Row({ space: '8vp' }) {
        Text('AI总体研判')
          .fontSize('15fp')
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text'))
        Blank()
        Button(this.summaryLoading ? '分析中' : '汇总分析')
          .height('30vp')
          .fontSize('11fp')
          .fontColor($r('app.color.text_on_accent'))
          .backgroundColor($r('app.color.module5_accent'))
          .borderRadius('15vp')
          .onClick((): void => {
            this.analyzeSummary();
          })
      }
      .width('100%')

      Row({ space: '8vp' }) {
        this.StatBadge('全部', `${this.alerts.length}`, $r('app.color.button_primary'))
        this.StatBadge('严重', `${this.getCriticalCount()}`, $r('app.color.alert_critical'))
        this.StatBadge('预警', `${this.getWarningCount()}`, $r('app.color.alert_warning'))
        this.StatBadge('正常', `${this.getNormalCount()}`, $r('app.color.alert_normal'))
      }
      .width('100%')

      if (this.summaryLoading || this.summaryText.length > 0) {
        Text(this.summaryLoading ? 'AI正在汇总告警趋势、风险点位和处置顺序...' : this.summaryText)
          .fontSize('12fp')
          .fontColor($r('app.color.text_secondary'))
          .lineHeight('19fp')
          .width('100%')
          .maxLines(this.summaryExpanded ? 8 : 2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .onClick((): void => {
            this.summaryExpanded = !this.summaryExpanded;
          })
      } else {
        Text('点击汇总分析，快速定位最优先处理的告警点位。')
          .fontSize('12fp')
          .fontColor($r('app.color.text_secondary'))
      }
    }
    .width('100%')
    .padding('14vp')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('14vp')
    .border({ width: '1vp', color: $r('app.color.divider') })
    .shadow(CardShadow)
  }

  @Builder
  StatBadge(label: string, value: string, color: ResourceColor) {
    Column({ space: '3vp' }) {
      Text(value)
        .fontSize('16fp')
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize('10fp')
        .fontColor($r('app.color.text_secondary'))
    }
    .layoutWeight(1)
    .height('50vp')
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.card_elevated'))
    .borderRadius('10vp')
  }

  @Builder
  AlertCard(item: AlertRecord) {
    Column({ space: '8vp' }) {
      Row({ space: '6vp' }) {
        Text(item.time)
          .fontSize('11fp')
          .fontColor($r('app.color.text_secondary'))
        Text(categoryLabel(item.category))
          .fontSize('10fp')
          .fontColor($r('app.color.text_on_accent'))
          .backgroundColor($r('app.color.status_active'))
          .padding({ left: '6vp', right: '6vp', top: '3vp', bottom: '3vp' })
          .borderRadius('6vp')
        Blank()
        Text(alertLevelText(item.level))
          .fontSize('10fp')
          .fontColor($r('app.color.text_on_accent'))
          .backgroundColor(levelColor(item.level))
          .padding({ left: '8vp', right: '8vp', top: '3vp', bottom: '3vp' })
          .borderRadius('8vp')
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(`${item.point}：${item.message}`)
        .fontSize('14fp')
        .fontColor($r('app.color.text'))
        .width('100%')
        .fontWeight(FontWeight.Medium)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      if (item.aiAnalyzing || item.aiAnalysis) {
        Row({ space: '6vp' }) {
          Text(item.aiAnalyzing ? 'AI分析中...' : '单条AI分析')
            .fontSize('12fp')
            .fontColor($r('app.color.button_primary'))
            .fontWeight(FontWeight.Medium)
          Text('▼')
            .fontSize('10fp')
            .fontColor($r('app.color.text_secondary'))
            .rotate({ angle: this.analysisExpandedId === item.id ? 180 : 0 })
        }
        .width('100%')
        .onClick((): void => {
          this.toggleAnalysis(item.id);
        })
        if (this.analysisExpandedId === item.id && item.aiAnalysis) {
          Column({ space: '6vp' }) {
            Text('摘要：' + item.aiAnalysis.summary)
              .fontSize('12fp')
              .fontColor($r('app.color.text'))
              .width('100%')
            Text('风险：' + item.aiAnalysis.risk)
              .fontSize('12fp')
              .fontColor($r('app.color.alert_critical'))
              .width('100%')
            ForEach(item.aiAnalysis.solve, (step: string, index: number) => {
              Text(`${index + 1}. ${step}`)
                .fontSize('11fp')
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
            }, (step: string) => step)
          }
          .width('100%')
          .padding('10vp')
          .backgroundColor($r('app.color.card_elevated'))
          .borderRadius('10vp')
        }
      }

      Row({ space: '8vp' }) {
        if (item.imageUrl.length > 0) {
          Text('截图已保存')
            .fontSize('10fp')
            .fontColor($r('app.color.status_active'))
        }
        Blank()
        Button(this.selectedAlertId === item.id ? '已引用' : '引用咨询')
          .height('30vp')
          .fontSize('11fp')
          .fontColor($r('app.color.text_on_accent'))
          .backgroundColor(this.selectedAlertId === item.id ? $r('app.color.module5_accent') : $r('app.color.button_primary'))
          .borderRadius('15vp')
          .onClick((): void => {
            this.openChat(item.id);
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding('12vp')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('12vp')
    .border({ width: '1vp', color: this.selectedAlertId === item.id ? $r('app.color.module5_accent') : $r('app.color.divider') })
    .shadow(CardShadow)
  }

  @Builder
  EmptyState() {
    Column({ space: '10vp' }) {
      Text('!')
        .fontSize('42fp')
        .fontColor($r('app.color.text_secondary'))
        .fontWeight(FontWeight.Bold)
      Text('暂无异常记录')
        .fontSize('15fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Bold)
      Text('小车巡检过程中检测到的环境、雷达、视觉异常会显示在这里')
        .fontSize('12fp')
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
        .maxLines(2)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ left: '20vp', right: '20vp' })
  }

  @Builder
  FloatingChatButton() {
    Button('AI')
      .width('54vp')
      .height('54vp')
      .fontSize('14fp')
      .fontWeight(FontWeight.Bold)
      .fontColor($r('app.color.text_on_accent'))
      .backgroundColor($r('app.color.module5_accent'))
      .borderRadius('27vp')
      .shadow(ElevatedShadow)
      .onClick((): void => {
        this.openChat();
      })
      .position({ right: '18vp', bottom: '22vp' })
  }

  @Builder
  ChatDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000088')
        .onClick((): void => {
          this.closeChat();
        })

      Column({ space: '12vp' }) {
        Row({ space: '10vp' }) {
          Column({ space: '3vp' }) {
            Text('AI告警咨询')
              .fontSize('18fp')
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text'))
            Text('选择一条告警作为引用上下文')
              .fontSize('11fp')
              .fontColor($r('app.color.text_secondary'))
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          Button('X')
            .width('34vp')
            .height('34vp')
            .fontSize('12fp')
            .fontColor($r('app.color.text'))
            .backgroundColor($r('app.color.card_elevated'))
            .borderRadius('17vp')
            .onClick((): void => {
              this.closeChat();
            })
        }
        .width('100%')

        Scroll() {
          Row({ space: '8vp' }) {
            ForEach(this.alerts, (item: AlertRecord) => {
              Button(item.point)
                .height('30vp')
                .fontSize('10fp')
                .fontColor(this.selectedAlertId === item.id ? $r('app.color.text_on_accent') : $r('app.color.text'))
                .backgroundColor(this.selectedAlertId === item.id ? $r('app.color.module5_accent') : $r('app.color.card_elevated'))
                .borderRadius('15vp')
                .onClick((): void => {
                  this.selectedAlertId = item.id;
                })
            }, (item: AlertRecord) => item.id)
          }
        }
        .height('38vp')
        .scrollBar(BarState.Off)

        if (this.getSelectedAlert()) {
          Text(`引用：${this.getSelectedAlert()!.point} - ${this.getSelectedAlert()!.message}`)
            .fontSize('12fp')
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .padding('10vp')
            .backgroundColor($r('app.color.card_elevated'))
            .borderRadius('10vp')
        }

        Scroll() {
          Column({ space: '8vp' }) {
            ForEach(this.chatItems, (chat: ChatItem) => {
              Row() {
                if (chat.isUser) {
                  Blank()
                }
                Text(chat.loading ? 'AI正在分析...' : chat.text)
                  .fontSize('12fp')
                  .fontColor(chat.isUser ? $r('app.color.text_on_accent') : $r('app.color.text'))
                  .lineHeight('18fp')
                  .padding({ left: '10vp', right: '10vp', top: '7vp', bottom: '7vp' })
                  .backgroundColor(chat.isUser ? $r('app.color.button_primary') : $r('app.color.card_elevated'))
                  .borderRadius('12vp')
                  .width('78%')
                if (!chat.isUser) {
                  Blank()
                }
              }
              .width('100%')
            }, (chat: ChatItem) => chat.id)
          }
          .width('100%')
        }
        .height('190vp')
        .scrollBar(BarState.Off)

        Row({ space: '8vp' }) {
          TextInput({ placeholder: '输入咨询问题...', text: this.chatInputText })
            .layoutWeight(1)
            .height('38vp')
            .fontSize('12fp')
            .fontColor($r('app.color.text'))
            .placeholderColor($r('app.color.text_secondary'))
            .backgroundColor($r('app.color.card_elevated'))
            .borderRadius('19vp')
            .padding({ left: '14vp', right: '14vp' })
            .onChange((value: string): void => {
              this.chatInputText = value;
            })
          Button('发送')
            .width('62vp')
            .height('38vp')
            .fontSize('12fp')
            .fontColor($r('app.color.text_on_accent'))
            .backgroundColor($r('app.color.button_primary'))
            .borderRadius('19vp')
            .onClick((): void => {
              this.sendChat();
            })
        }
        .width('100%')
      }
      .width('88%')
      .padding('16vp')
      .backgroundColor($r('app.color.card_background'))
      .borderRadius('18vp')
      .border({ width: '1vp', color: $r('app.color.divider') })
      .shadow(ElevatedShadow)
    }
    .width('100%')
    .height('100%')
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column({ space: '0vp' }) {
        this.Header()
        Scroll() {
          Column({ space: '12vp' }) {
            this.SummaryPanel()
            if (this.alerts.length === 0) {
              this.EmptyState()
            } else {
              ForEach(this.alerts, (item: AlertRecord) => {
                this.AlertCard(item)
              }, (item: AlertRecord) => item.id)
            }
          }
          .width('100%')
          .padding({ left: '12vp', right: '12vp', top: '12vp', bottom: '92vp' })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.window_background'))

      this.FloatingChatButton()

      if (this.showChatDialog) {
        this.ChatDialog()
      }
    }
    .width('100%')
    .height('100%')
  }
}
