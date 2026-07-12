import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AlertRecord, alertLevelText, categoryLabel, AlertLevel, AlarmData } from '../model/PatrolModels';
import { PatrolStore } from '../store/PatrolStore';
import { levelColor } from '../utils/PatrolUiUtils';
import { queryAlarmQuestion } from '../utils/DeepSeekUtil';
import { PageHeader, InfoCard } from '../components/PageHeader';
import { CardShadow, ButtonShadow } from '../styles/styles';

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

export class ChatSession {
  alertId: string = '';
  items: ChatItem[] = [];
  inputText: string = '';

  constructor(alertId: string) {
    this.alertId = alertId;
    this.items = [];
    this.inputText = '';
  }

  addUserMessage(text: string): void {
    this.items.push(new ChatItem(Date.now().toString(), true, text));
  }

  addAiMessage(text: string, loading?: boolean): void {
    this.items.push(new ChatItem((Date.now() + 1).toString(), false, text, loading));
  }

  updateLastMessage(text: string): void {
    if (this.items.length > 0) {
      this.items[this.items.length - 1].text = text;
      this.items[this.items.length - 1].loading = false;
    }
  }

  getItems(): ChatItem[] {
    return this.items;
  }

  getInputText(): string {
    return this.inputText;
  }

  setInputText(text: string): void {
    this.inputText = text;
  }
}

@Entry
@Component
struct AlertRecords {
  @State alerts: AlertRecord[] = [];
  @State analysisExpandedId: string = '';
  @State chatExpandedId: string = '';
  @State chatSessions: ChatSession[] = [];
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

  toggleChat(id: string): void {
    this.chatExpandedId = this.chatExpandedId === id ? '' : id;
    if (this.chatExpandedId === id) {
      this.getOrCreateChatSession(id);
    }
  }

  getOrCreateChatSession(alertId: string): ChatSession {
    let session = this.chatSessions.find((s: ChatSession): boolean => s.alertId === alertId);
    if (!session) {
      session = new ChatSession(alertId);
      this.chatSessions = [...this.chatSessions, session];
    }
    return session;
  }

  async sendChat(alertId: string, alert: AlertRecord): Promise<void> {
    const session = this.getOrCreateChatSession(alertId);
    const input = session.getInputText();
    if (!input.trim()) {
      return;
    }
    session.addUserMessage(input.trim());
    session.addAiMessage('', true);
    session.setInputText('');
    this.notifyUiUpdate();
    let levelStr: string = '正常';
    if (alert.level === AlertLevel.Critical) {
      levelStr = '严重';
    } else if (alert.level === AlertLevel.Warning) {
      levelStr = '预警';
    }
    const alarmData: AlarmData = {
      alarm_id: alert.id,
      time: alert.time,
      point: alert.point,
      alarm_type: alert.category,
      message: alert.message,
      level: levelStr
    };
    try {
      const answer: string = await queryAlarmQuestion(JSON.stringify(alarmData), input.trim());
      session.updateLastMessage(answer);
      this.notifyUiUpdate();
    } catch (err) {
      session.updateLastMessage('AI咨询失败，请检查网络');
      this.notifyUiUpdate();
    }
  }

  notifyUiUpdate(): void {
    this.chatSessions = [...this.chatSessions];
  }

  getChatItems(alertId: string): ChatItem[] {
    const session = this.getOrCreateChatSession(alertId);
    return session.getItems();
  }

  getChatInputText(alertId: string): string {
    const session = this.getOrCreateChatSession(alertId);
    return session.getInputText();
  }

  @State tempInputText: string = '';

  @Builder
  ChatContent(item: AlertRecord, chatItems: ChatItem[], inputText: string) {
    Column({ space: '6vp' }) {
      Scroll() {
        Column({ space: '5vp' }) {
          ForEach(chatItems, (chat: ChatItem) => {
            Column({ space: '2vp' }) {
              if (chat.isUser) {
                Text('我')
                  .fontSize('10fp')
                  .fontColor($r('app.color.text_secondary'))
                  .textAlign(TextAlign.End)
                  .width('100%')
                Text(chat.text)
                  .fontSize('12fp')
                  .fontColor(Color.White)
                  .padding({ left: '10vp', right: '10vp', top: '7vp', bottom: '7vp' })
                  .backgroundColor($r('app.color.button_primary'))
                  .borderRadius('12vp')
                  .borderRadius({ bottomRight: '4vp' })
                  .maxLines(10)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              } else {
                Text('AI')
                  .fontSize('10fp')
                  .fontColor($r('app.color.text_secondary'))
                  .textAlign(TextAlign.Start)
                  .width('100%')
                Text(chat.text)
                  .fontSize('12fp')
                  .fontColor($r('app.color.text'))
                  .padding({ left: '10vp', right: '10vp', top: '7vp', bottom: '7vp' })
                  .backgroundColor($r('app.color.card_background'))
                  .borderRadius('12vp')
                  .borderRadius({ bottomLeft: '4vp' })
                  .maxLines(10)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
            }
            .width('100%')
            .alignItems(chat.isUser ? HorizontalAlign.End : HorizontalAlign.Start)
          }, (chat: ChatItem) => chat.id)
        }
        .width('100%')
      }
      .height('120vp')
      .scrollBar(BarState.Off)

      Row({ space: '8vp' }) {
        TextInput({ placeholder: '输入您的问题...', text: this.tempInputText })
          .layoutWeight(1)
          .height('36vp')
          .fontSize('12fp')
          .backgroundColor($r('app.color.card_background'))
          .borderRadius('18vp')
          .padding({ left: '14vp', right: '14vp' })
          .onChange((value: string): void => {
            this.tempInputText = value;
          })
        Button('发送')
          .width('64vp')
          .height('36vp')
          .fontSize('12fp')
          .fontColor($r('app.color.text_on_accent'))
          .backgroundColor($r('app.color.button_primary'))
          .borderRadius('18vp')
          .onClick(() => {
            const inputValue = this.tempInputText.trim();
            if (!inputValue) {
              return;
            }
            const session = this.getOrCreateChatSession(item.id);
            session.addUserMessage(inputValue);
            session.addAiMessage('', true);
            this.tempInputText = '';
            this.notifyUiUpdate();
            let levelStr: string = '正常';
            if (item.level === AlertLevel.Critical) {
              levelStr = '严重';
            } else if (item.level === AlertLevel.Warning) {
              levelStr = '预警';
            }
            const alarmData: AlarmData = {
              alarm_id: item.id,
              time: item.time,
              point: item.point,
              alarm_type: item.category,
              message: item.message,
              level: levelStr
            };
            this.queryAndUpdate(item.id, JSON.stringify(alarmData), inputValue);
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding('12vp')
    .backgroundColor($r('app.color.card_elevated'))
    .borderRadius('12vp')
  }

  async queryAndUpdate(alertId: string, alarmData: string, question: string): Promise<void> {
    try {
      const answer: string = await queryAlarmQuestion(alarmData, question);
      const session = this.getOrCreateChatSession(alertId);
      session.updateLastMessage(answer);
      this.notifyUiUpdate();
    } catch (err) {
      const session = this.getOrCreateChatSession(alertId);
      session.updateLastMessage('AI咨询失败，请检查网络');
      this.notifyUiUpdate();
    }
  }

  build() {
    Column({ space: '0vp' }) {
      Row({ space: '10vp' }) {
        Column({ space: '4vp' }) {
          Text('异常告警记录')
            .fontSize('20fp')
            .fontColor($r('app.color.text'))
            .fontWeight(FontWeight.Bold)
          Text(`共 ${this.alerts.length} 条记录`)
            .fontSize('12fp')
            .fontColor($r('app.color.text_secondary'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Button('清空')
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
      .padding({ left: '14vp', right: '14vp', top: '12vp', bottom: '10vp' })
      .backgroundColor($r('app.color.header_background'))
      .shadow(CardShadow)

      if (this.alerts.length === 0) {
        Column() {
          Column({ space: '10vp' }) {
            Text('📋')
              .fontSize('44fp')
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
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: '10vp' }) {
          ForEach(this.alerts, (item: AlertRecord) => {
            ListItem() {
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
                    .layoutWeight(1)
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
                  .fontSize('13fp')
                  .fontColor($r('app.color.text'))
                  .width('100%')
                  .fontWeight(FontWeight.Medium)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                if (item.imageUrl.length > 0) {
                  Text(`截图已保存`)
                    .fontSize('10fp')
                    .fontColor($r('app.color.status_active'))
                    .maxLines(1)
                }

                if (item.aiAnalyzing || item.aiAnalysis) {
                  Row({ space: '6vp' }) {
                    Text(item.aiAnalyzing ? 'AI分析中...' : 'AI分析')
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
                        .maxLines(3)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                      Text('风险：' + item.aiAnalysis.risk)
                        .fontSize('12fp')
                        .fontColor($r('app.color.alert_critical'))
                        .width('100%')
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                      Column({ space: '4vp' }) {
                        Text('处置建议')
                          .fontSize('11fp')
                          .fontColor($r('app.color.button_primary'))
                          .fontWeight(FontWeight.Bold)
                        ForEach(item.aiAnalysis.solve, (step: string, index: number) => {
                          Row({ space: '4vp' }) {
                            Text(`${index + 1}.`)
                              .fontSize('11fp')
                              .fontColor($r('app.color.text_secondary'))
                            Text(step)
                              .fontSize('11fp')
                              .fontColor($r('app.color.text_secondary'))
                              .layoutWeight(1)
                              .maxLines(2)
                              .textOverflow({ overflow: TextOverflow.Ellipsis })
                          }
                          .width('100%')
                        }, (step: string) => step)
                      }
                      .width('100%')
                    }
                    .width('100%')
                    .padding('10vp')
                    .backgroundColor($r('app.color.card_elevated'))
                    .borderRadius('10vp')
                  }
                }

                Button('AI咨询')
                  .width('100%')
                  .height('34vp')
                  .fontSize('12fp')
                  .fontColor($r('app.color.text_on_accent'))
                  .backgroundColor($r('app.color.button_primary'))
                  .borderRadius('10vp')
                  .onClick((): void => {
                    this.toggleChat(item.id);
                  })
                if (this.chatExpandedId === item.id) {
                  this.ChatContent(item, this.getChatItems(item.id), this.getChatInputText(item.id));
                }
              }
              .width('100%')
              .padding('12vp')
              .backgroundColor($r('app.color.card_background'))
              .borderRadius('12vp')
              .border({ width: '1vp', color: $r('app.color.divider') })
              .shadow(CardShadow)
            }
          }, (item: AlertRecord) => item.id)
        }
        .layoutWeight(1)
        .padding({ left: '12vp', right: '12vp', top: '10vp', bottom: '12vp' })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.window_background'))
  }
}
