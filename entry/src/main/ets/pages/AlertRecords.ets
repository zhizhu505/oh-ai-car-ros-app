import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AlertRecord, alertLevelText, categoryLabel, AlertLevel, AlarmData } from '../model/PatrolModels';
import { PatrolStore } from '../store/PatrolStore';
import { levelColor } from '../utils/PatrolUiUtils';
import { queryAlarmQuestion } from '../utils/DeepSeekUtil';
import { CardShadow, ElevatedShadow } from '../styles/styles';
import { carApi } from '../CarUtill/CarApi';
import { CarEncode } from '../CarUtill/CarEncode';

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
  @State selectedAlertIds: string[] = [];
  @State chatInputText: string = '';
  @State chatItems: ChatItem[] = [];
  @State summaryText: string = '';
  @State summaryLoading: boolean = false;
  @State summaryExpanded: boolean = true;
  private readonly questionTemplates: string[] = [
    '这几条告警的共同风险是什么？',
    '优先处理顺序应该怎么排？',
    '请给出现场处置步骤。',
    '哪些告警可能是同一原因导致？',
    '如果继续巡检，需要重点关注什么？'
  ];
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
      const record: AlertRecord = {
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
    this.selectedAlertIds = this.selectedAlertIds.filter((id: string): boolean => {
      return this.alerts.some((item: AlertRecord): boolean => item.id === id);
    });
  }

  toggleAnalysis(id: string): void {
    this.analysisExpandedId = this.analysisExpandedId === id ? '' : id;
  }

  openChat(): void {
    if (this.selectedAlertIds.length === 0 && this.alerts.length > 0) {
      this.selectedAlertIds = [this.alerts[0].id];
    }
    this.showChatDialog = true;
  }

  closeChat(): void {
    this.showChatDialog = false;
    this.chatInputText = '';
  }

  toggleAlertSelection(alertId: string): void {
    if (this.selectedAlertIds.includes(alertId)) {
      this.selectedAlertIds = this.selectedAlertIds.filter((id: string): boolean => id !== alertId);
      return;
    }
    this.selectedAlertIds = [...this.selectedAlertIds, alertId];
  }

  clearSelections(): void {
    this.selectedAlertIds = [];
  }

  isAlertSelected(alertId: string): boolean {
    return this.selectedAlertIds.includes(alertId);
  }

  getSelectedAlerts(): AlertRecord[] {
    const selected: AlertRecord[] = [];
    this.selectedAlertIds.forEach((id: string): void => {
      const matched: AlertRecord | undefined = this.alerts.find((item: AlertRecord): boolean => item.id === id);
      if (matched !== undefined) {
        selected.push(matched as AlertRecord);
      }
    });
    return selected;
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

  buildSelectedPayload(): string {
    const payload = this.getSelectedAlerts().map((alert: AlertRecord): AlarmData => {
      return this.createAlarmData(alert);
    });
    return JSON.stringify(payload);
  }

  applyTemplate(template: string): void {
    this.chatInputText = template;
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
    const selectedAlerts = this.getSelectedAlerts();
    if (!question) {
      return;
    }
    if (selectedAlerts.length === 0) {
      promptAction.showToast({ message: '请先选择引用告警' });
      return;
    }
    this.chatItems = [...this.chatItems, new ChatItem(Date.now().toString(), true, question)];
    const loadingId = (Date.now() + 1).toString();
    this.chatItems = [...this.chatItems, new ChatItem(loadingId, false, `AI正在分析 ${selectedAlerts.length} 条引用告警...`, true)];
    this.chatInputText = '';
    try {
      const answer = await queryAlarmQuestion(this.buildSelectedPayload(), question);
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
    Column({ space: '12vp' }) {
      Column({ space: '4vp' }) {
        Text('异常告警中心')
          .fontSize('21fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .maxLines(1)
        Text(`共 ${this.alerts.length} 条记录，严重 ${this.getCriticalCount()} 条`)
          .fontSize('12fp')
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .maxLines(2)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Row({ space: '10vp' }) {
        Button('???')
          .layoutWeight(1)
          .height('34vp')
          .fontSize('12fp')
          .fontColor($r('app.color.text'))
          .backgroundColor($r('app.color.card_elevated'))
          .borderRadius('17vp')
          .border({ width: '1vp', color: $r('app.color.divider') })
          .onClick((): void => {
            PatrolStore.getInstance().clearAlerts();
            promptAction.showToast({ message: '???????????' });
          })

        Button('???')
          .layoutWeight(1)
          .height('34vp')
          .fontSize('12fp')
          .fontColor($r('app.color.text'))
          .backgroundColor($r('app.color.button_secondary'))
          .borderRadius('17vp')
          .onClick((): void => {
            router.back();
          })
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: '16vp', right: '16vp', top: '24vp', bottom: '14vp' })
    .backgroundColor($r('app.color.header_background'))
    .shadow({ radius: 18, offsetX: 0, offsetY: 8, color: '#00000042' })
  }

  @Builder
  SummaryPanel() {
    Column({ space: '10vp' }) {
      Row({ space: '10vp' }) {
        Text('AI总体研判')
          .layoutWeight(1)
          .fontSize('15fp')
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text'))
          .maxLines(1)
        Button(this.summaryLoading ? '分析中' : '汇总分析')
          .constraintSize({ minWidth: '88vp' })
          .height('32vp')
          .fontSize('11fp')
          .fontColor($r('app.color.text_on_accent'))
          .backgroundColor($r('app.color.module5_accent'))
          .borderRadius('16vp')
          .onClick((): void => {
            this.analyzeSummary();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row({ space: '8vp' }) {
        this.StatBadge('全部', `${this.alerts.length}`, $r('app.color.button_primary'))
        this.StatBadge('严重', `${this.getCriticalCount()}`, $r('app.color.alert_critical'))
      }
      .width('100%')

      Row({ space: '8vp' }) {
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
          .width('100%')
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
        .maxLines(1)
    }
    .layoutWeight(1)
    .height('54vp')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.card_elevated'))
    .borderRadius('10vp')
  }

  @Builder
  AlertCard(item: AlertRecord) {
    Column({ space: '10vp' }) {
      Row({ space: '10vp' }) {
        Column({ space: '6vp' }) {
          Text(item.time)
            .fontSize('11fp')
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .maxLines(1)
          Text(categoryLabel(item.category))
            .fontSize('10fp')
            .fontColor($r('app.color.text_on_accent'))
            .backgroundColor($r('app.color.status_active'))
            .padding({ left: '6vp', right: '6vp', top: '3vp', bottom: '3vp' })
            .borderRadius('6vp')
            .maxLines(1)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(alertLevelText(item.level))
          .fontSize('10fp')
          .fontColor($r('app.color.text_on_accent'))
          .backgroundColor(levelColor(item.level))
          .padding({ left: '8vp', right: '8vp', top: '3vp', bottom: '3vp' })
          .borderRadius('8vp')
          .maxLines(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Text(`${item.point}：${item.message}`)
        .fontSize('14fp')
        .fontColor($r('app.color.text'))
        .width('100%')
        .fontWeight(FontWeight.Medium)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      if (item.aiAnalyzing || item.aiAnalysis) {
        Row({ space: '6vp' }) {
          Text(item.aiAnalyzing ? 'AI分析中...' : '单条 AI 分析')
            .fontSize('12fp')
            .fontColor($r('app.color.button_primary'))
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
          Text('v')
            .fontSize('10fp')
            .fontColor($r('app.color.text_secondary'))
            .rotate({ angle: this.analysisExpandedId === item.id ? 180 : 0 })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .onClick((): void => {
          this.toggleAnalysis(item.id);
        })

        if (this.analysisExpandedId === item.id && item.aiAnalysis) {
          Column({ space: '6vp' }) {
            Text(`摘要：${item.aiAnalysis.summary}`)
              .fontSize('12fp')
              .fontColor($r('app.color.text'))
              .width('100%')
            Text(`风险：${item.aiAnalysis.risk}`)
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

      if (item.imageUrl.length > 0) {
        Text('截图已保存')
          .fontSize('10fp')
          .fontColor($r('app.color.status_active'))
          .maxLines(1)
      }
    }
    .width('100%')
    .padding('12vp')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('12vp')
    .border({ width: '1vp', color: $r('app.color.divider') })
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
    .padding({ left: '20vp', right: '20vp', top: '32vp', bottom: '32vp' })
  }

  @Builder
  FloatingChatButton() {
    Button() {
      Image($r('app.media.ai_chat_icon'))
        .width('28vp')
        .height('28vp')
        .objectFit(ImageFit.Contain)
    }
    .width('44vp')
    .height('44vp')
    .backgroundColor($r('app.color.text_on_accent'))
    .borderRadius('22vp')
    .border({ width: '1vp', color: '#D1D5DB' })
    .shadow(ElevatedShadow)
    .onClick((): void => {
      this.openChat();
    })
    .position({ right: '18vp', bottom: '22vp' })
  }

  @Builder
  SelectedAlertChip(item: AlertRecord) {
    Row({ space: '6vp' }) {
      Text(item.point)
        .fontSize('10fp')
        .fontColor($r('app.color.text_on_accent'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Button('x')
        .width('18vp')
        .height('18vp')
        .fontSize('10fp')
        .fontColor($r('app.color.text'))
        .backgroundColor('#FFFFFFCC')
        .borderRadius('9vp')
        .onClick((): void => {
          this.toggleAlertSelection(item.id);
        })
    }
    .padding({ left: '10vp', right: '8vp', top: '7vp', bottom: '7vp' })
    .backgroundColor($r('app.color.module5_accent'))
    .borderRadius('16vp')
  }

  @Builder
  AlertChip(item: AlertRecord) {
    Button() {
      Row({ space: '6vp' }) {
        Text(this.isAlertSelected(item.id) ? 'Y' : '+')
          .fontSize('10fp')
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isAlertSelected(item.id) ? $r('app.color.text_on_accent') : $r('app.color.text_secondary'))
        Text(item.point)
          .fontSize('10fp')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .fontColor(this.isAlertSelected(item.id) ? $r('app.color.text_on_accent') : $r('app.color.text'))
      }
    }
    .constraintSize({ minWidth: '86vp', maxWidth: '152vp' })
    .height('34vp')
    .backgroundColor(this.isAlertSelected(item.id) ? $r('app.color.module5_accent') : $r('app.color.card_elevated'))
    .borderRadius('17vp')
    .padding({ left: '12vp', right: '12vp' })
    .onClick((): void => {
      this.toggleAlertSelection(item.id);
    })
  }

  @Builder
  TemplateChip(template: string) {
    Button(template)
      .constraintSize({ minWidth: '120vp', maxWidth: '200vp' })
      .height('32vp')
      .fontSize('11fp')
      .fontColor($r('app.color.text'))
      .backgroundColor($r('app.color.card_elevated'))
      .borderRadius('16vp')
      .padding({ left: '12vp', right: '12vp' })
      .onClick((): void => {
        this.applyTemplate(template);
      })
  }

  @Builder
  SelectedAlertsRowEmpty() {
    Text('尚未引用告警')
      .fontSize('11fp')
      .fontColor($r('app.color.text_secondary'))
  }

  @Builder
  SelectedAlertsRowList() {
    Scroll() {
      Row({ space: '8vp' }) {
        ForEach(this.getSelectedAlerts(), (item: AlertRecord) => {
          this.SelectedAlertChip(item)
        }, (item: AlertRecord) => `selected_${item.id}`)
      }
      .alignItems(VerticalAlign.Center)
      .width('max-content')
    }
    .width('100%')
    .scrollBar(BarState.On)
  }

  @Builder
  ChatDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000055')
        .onClick((): void => {
          this.closeChat();
        })

      Column({ space: '12vp' }) {
        Row({ space: '10vp' }) {
          Column({ space: '3vp' }) {
            Text('AI 告警咨询')
              .fontSize('18fp')
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text'))
            Text('支持多选引用告警，并可随时取消引用')
              .fontSize('11fp')
              .fontColor($r('app.color.text_secondary'))
              .maxLines(2)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Button('X')
            .constraintSize({ minWidth: '34vp' })
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
        .alignItems(VerticalAlign.Top)

        Row({ space: '8vp' }) {
          Text(`已引用 ${this.selectedAlertIds.length} 条`)
            .layoutWeight(1)
            .fontSize('12fp')
            .fontColor($r('app.color.text_secondary'))
          if (this.selectedAlertIds.length > 0) {
            Button('清空引用')
              .height('28vp')
              .fontSize('10fp')
              .fontColor($r('app.color.text'))
              .backgroundColor($r('app.color.card_elevated'))
              .borderRadius('14vp')
              .onClick((): void => {
                this.clearSelections();
              })
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Scroll() {
          if (this.getSelectedAlerts().length === 0) {
            this.SelectedAlertsRowEmpty()
          } else {
            this.SelectedAlertsRowList()
          }
        }
        .height('42vp')
        .width('100%')
        .scrollBar(BarState.Off)

        Scroll() {
          Row({ space: '8vp' }) {
            ForEach(this.alerts, (item: AlertRecord) => {
              this.AlertChip(item)
            }, (item: AlertRecord) => item.id)
          }
          .alignItems(VerticalAlign.Center)
          .width('max-content')
        }
        .height('42vp')
        .width('100%')
        .scrollBar(BarState.On)

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
                  .constraintSize({ maxWidth: '78%' })
                if (!chat.isUser) {
                  Blank()
                }
              }
              .width('100%')
            }, (chat: ChatItem) => chat.id)
          }
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
        .constraintSize({ minHeight: '140vp', maxHeight: '260vp' })
        .scrollBar(BarState.Off)

        Scroll() {
          Row({ space: '8vp' }) {
            ForEach(this.questionTemplates, (template: string) => {
              this.TemplateChip(template)
            }, (template: string) => template)
          }
          .alignItems(VerticalAlign.Center)
          .width('max-content')
        }
        .height('40vp')
        .width('100%')
        .scrollBar(BarState.On)

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
            .constraintSize({ minWidth: '68vp' })
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
        .alignItems(VerticalAlign.Center)
      }
      .width('90%')
      .constraintSize({ maxWidth: '520vp', maxHeight: '84%' })
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
