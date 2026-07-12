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

  @Builder
  ChatContent(item: AlertRecord, chatItems: ChatItem[], inputText: string) {
    Column({ space: '8vp' }) {
      if (chatItems.length > 0) {
        Scroll() {
          Column({ space: '8vp' }) {
            ForEach(chatItems, (chat: ChatItem) => {
              Row({ space: '8vp' }) {
                if (chat.isUser) {
                  Blank()
                    .layoutWeight(1)
                  Column() {
                    Text(chat.text)
                      .fontSize('13fp')
                      .fontColor($r('app.color.text'))
                      .padding({ left: '10vp', right: '10vp', top: '8vp', bottom: '8vp' })
                      .backgroundColor($r('app.color.button_primary'))
                      .borderRadius('12vp')
                      .borderRadius({ bottomLeft: '2vp' })
                  }
                } else {
                  Column() {
                    if (chat.loading) {
                      Text('AI思考中...')
                        .fontSize('13fp')
                        .fontColor($r('app.color.text_secondary'))
                        .padding({ left: '10vp', right: '10vp', top: '8vp', bottom: '8vp' })
                        .backgroundColor($r('app.color.card_elevated'))
                        .borderRadius('12vp')
                        .borderRadius({ bottomRight: '2vp' })
                    } else {
                      Text(chat.text)
                        .fontSize('13fp')
                        .fontColor($r('app.color.text'))
                        .padding({ left: '10vp', right: '10vp', top: '8vp', bottom: '8vp' })
                        .backgroundColor($r('app.color.card_elevated'))
                        .borderRadius('12vp')
                        .borderRadius({ bottomRight: '2vp' })
                    }
                  }
                  Blank()
                    .layoutWeight(1)
                }
              }
              .width('100%')
            }, (chat: ChatItem) => chat.id)
          }
          .width('100%')
        }
        .height('120vp')
      }
      Row({ space: '6vp' }) {
        TextInput({ placeholder: '输入您的问题...', text: inputText })
          .width('100%')
          .height('36vp')
          .fontSize('13fp')
          .backgroundColor($r('app.color.card_elevated'))
          .borderRadius('18vp')
          .padding({ left: '14vp', right: '14vp' })
          .onChange((value: string): void => {
            const session = this.getOrCreateChatSession(item.id);
            session.setInputText(value);
            this.notifyUiUpdate();
          })
        Button('发送')
          .width('56vp')
          .height('36vp')
          .fontSize('12fp')
          .fontColor($r('app.color.text_on_accent'))
          .backgroundColor($r('app.color.button_primary'))
          .borderRadius('18vp')
          .onClick((): void => {
            this.sendChat(item.id, item);
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding('10vp')
    .backgroundColor($r('app.color.card_elevated'))
    .borderRadius('12vp')
  }

  build() {
    Column({ space: '12vp' }) {
      Stack() {
        PageHeader({
          title: '异常告警记录',
          subtitle: `共 ${this.alerts.length} 条记录`,
          accentColor: $r('app.color.alert_warning')
        })
        Button('清空')
          .width('68vp')
          .height('34vp')
          .fontSize('13fp')
          .fontColor($r('app.color.text'))
          .backgroundColor($r('app.color.button_secondary'))
          .borderRadius('17vp')
          .shadow(ButtonShadow)
          .onClick((): void => {
            PatrolStore.getInstance().clearAlerts();
            promptAction.showToast({ message: '告警记录已清空' });
          })
          .alignSelf(ItemAlign.End)
          .margin({ right: '32vp', top: '22vp' })
      }
      .width('100%')

      if (this.alerts.length === 0) {
        InfoCard({ title: '' }) {
          Column({ space: '12vp' }) {
            Text('📋')
              .fontSize('48fp')
            Text('暂无异常记录')
              .fontSize('16fp')
              .fontColor($r('app.color.text'))
              .fontWeight(FontWeight.Medium)
            Text('小车巡检过程中检测到的环境、雷达、视觉异常会显示在这里')
              .fontSize('14fp')
              .fontColor($r('app.color.text_secondary'))
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .padding({ top: '40vp', bottom: '40vp' })
        }
      } else {
        List({ space: '12vp' }) {
          ForEach(this.alerts, (item: AlertRecord) => {
            ListItem() {
              Column({ space: '10vp' }) {
                Row({ space: '12vp' }) {
                  Text(item.time)
                    .fontSize('13fp')
                    .fontColor($r('app.color.text_secondary'))
                  Text(categoryLabel(item.category))
                    .fontSize('12fp')
                    .fontColor($r('app.color.text_on_accent'))
                    .backgroundColor($r('app.color.status_active'))
                    .padding({ left: '10vp', right: '10vp', top: '4vp', bottom: '4vp' })
                    .borderRadius('10vp')
                  Blank()
                  Text(alertLevelText(item.level))
                    .fontSize('12fp')
                    .fontColor($r('app.color.text_on_accent'))
                    .backgroundColor(levelColor(item.level))
                    .padding({ left: '12vp', right: '12vp', top: '4vp', bottom: '4vp' })
                    .borderRadius('12vp')
                }
                .width('100%')
                Text(`${item.point}：${item.message}`)
                  .fontSize('16fp')
                  .fontColor($r('app.color.text'))
                  .width('100%')
                  .fontWeight(FontWeight.Medium)
                if (item.imageUrl.length > 0) {
                  Text(`截图已保存`)
                    .fontSize('12fp')
                    .fontColor($r('app.color.status_active'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                if (item.aiAnalyzing || item.aiAnalysis) {
                  Row({ space: '8vp' }) {
                    Text(item.aiAnalyzing ? 'AI分析中...' : 'AI分析')
                      .fontSize('12fp')
                      .fontColor($r('app.color.button_primary'))
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
                    Column({ space: '8vp' }) {
                      Text('异常摘要：' + item.aiAnalysis.summary)
                        .fontSize('14fp')
                        .fontColor($r('app.color.text'))
                        .width('100%')
                      Text('风险评估：' + item.aiAnalysis.risk)
                        .fontSize('13fp')
                        .fontColor($r('app.color.alert_critical'))
                        .width('100%')
                      Column({ space: '4vp' }) {
                        Text('处置建议')
                          .fontSize('12fp')
                          .fontColor($r('app.color.button_primary'))
                          .fontWeight(FontWeight.Bold)
                        ForEach(item.aiAnalysis.solve, (step: string, index: number) => {
                          Row({ space: '6vp' }) {
                            Text(`${index + 1}.`)
                              .fontSize('13fp')
                              .fontColor($r('app.color.text_secondary'))
                            Text(step)
                              .fontSize('13fp')
                              .fontColor($r('app.color.text_secondary'))
                              .layoutWeight(1)
                          }
                          .width('100%')
                        }, (step: string) => step)
                      }
                      .width('100%')
                    }
                    .width('100%')
                    .padding('12vp')
                    .backgroundColor($r('app.color.card_elevated'))
                    .borderRadius('12vp')
                  }
                }
                Button('AI咨询')
                  .width('100%')
                  .height('40vp')
                  .fontSize('14fp')
                  .fontColor($r('app.color.text_on_accent'))
                  .backgroundColor($r('app.color.button_primary'))
                  .borderRadius('12vp')
                  .shadow(ButtonShadow)
                  .onClick((): void => {
                    this.toggleChat(item.id);
                  })
                if (this.chatExpandedId === item.id) {
                  this.ChatContent(item, this.getChatItems(item.id), this.getChatInputText(item.id));
                }
              }
              .width('100%')
              .padding('16vp')
              .backgroundColor($r('app.color.card_background'))
              .borderRadius('16vp')
              .border({ width: '1vp', color: $r('app.color.divider') })
              .shadow(CardShadow)
            }
          }, (item: AlertRecord) => item.id)
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.window_background'))
    .padding({ left: '20vp', right: '20vp', bottom: '20vp' })
  }
}