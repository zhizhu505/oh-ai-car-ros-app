import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import pasteboard from '@ohos.pasteboard';
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
  @State reportGeneratedAt: string = '';
  @State showReportDialog: boolean = false;
  @State showEmailFallbackDialog: boolean = false;
  private readonly leaderEmail: string = '1123844859@qq.com';
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

  seedDemoAlerts(): void {
    const store = PatrolStore.getInstance();
    const now = new Date();
    const hour = now.getHours().toString().padStart(2, '0');
    const minute = now.getMinutes().toString().padStart(2, '0');
    const second = now.getSeconds().toString().padStart(2, '0');
    const time = `${hour}:${minute}:${second}`;
    store.createAlert(time, 'B区P4设备区', 'lidar_block', '雷达检测到管廊通道堵塞，前方距离0.42m', AlertLevel.Critical);
    store.createAlert(time, 'A区P2通道', 'vision_person', '视觉检测到人员闯入禁区', AlertLevel.Warning);
    store.createAlert(time, '地下管廊环境监测', 'env', '可燃气体短时升高，当前42ppm', AlertLevel.Warning);
    promptAction.showToast({ message: '已生成测试告警，可进行 AI 分析' });
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

  formatCurrentTime(): string {
    const now = new Date();
    const year = now.getFullYear().toString();
    const month = (now.getMonth() + 1).toString().padStart(2, '0');
    const day = now.getDate().toString().padStart(2, '0');
    const hour = now.getHours().toString().padStart(2, '0');
    const minute = now.getMinutes().toString().padStart(2, '0');
    return `${year}-${month}-${day} ${hour}:${minute}`;
  }

  buildReportPrompt(): string {
    return '请基于全部告警生成一份可直接发给领导的巡检异常总结汇报。要求：1. 使用中文；2. 不要输出JSON；3. 不要使用Markdown语法，不要使用**、#、```；4. 按固定结构输出：一、总体结论；二、重点告警清单；三、原因分析；四、处置建议；五、需领导关注事项；5. 每个重点告警必须包含点位、级别、现象、可能原因、影响风险；6. 内容务实简洁，适合手机阅读和邮件正文。';
  }

  buildFallbackReport(): string {
    const lines: string[] = [];
    lines.push('地下管廊巡检异常告警汇报');
    lines.push(`生成时间：${this.reportGeneratedAt || this.formatCurrentTime()}`);
    lines.push('');
    lines.push('一、总体结论');
    lines.push(`本次共记录 ${this.alerts.length} 条告警，其中严重 ${this.getCriticalCount()} 条、预警 ${this.getWarningCount()} 条、正常 ${this.getNormalCount()} 条。建议优先核查严重告警点位，并对重复出现的环境、雷达、视觉异常进行现场复核。`);
    lines.push('');
    lines.push('二、重点告警清单');
    this.alerts.forEach((alert: AlertRecord, index: number): void => {
      lines.push(`${index + 1}. ${alert.point}`);
      lines.push(`   级别：${this.getLevelText(alert.level)}`);
      lines.push(`   类型：${categoryLabel(alert.category)}`);
      lines.push(`   现象：${alert.message}`);
      lines.push(`   可能原因：现场通道占用、人员误入、环境参数波动或传感器检测异常，请结合现场复核。`);
      lines.push(`   影响风险：可能影响巡检通行、安全预警准确性和现场处置效率。`);
    });
    lines.push('');
    lines.push('三、原因分析');
    lines.push('异常主要集中在通道占用、人员闯入、环境指标异常或设备感知异常几类问题，可能与现场施工、杂物堆放、人员管理、环境波动及设备传感器状态有关。');
    lines.push('');
    lines.push('四、处置建议');
    lines.push('1. 优先安排人员核查严重告警点位。');
    lines.push('2. 对通道堵塞、人员闯入等安全风险立即处置并记录闭环。');
    lines.push('3. 对环境和传感器异常进行复测，确认是否需要维护设备或调整阈值。');
    lines.push('');
    lines.push('五、需领导关注事项');
    lines.push('建议关注严重告警点位的现场处置进度，以及是否存在连续异常或重复异常点位。');
    return lines.join('\n');
  }

  getReportSubject(): string {
    return `地下管廊巡检异常总结汇报（${this.reportGeneratedAt || this.formatCurrentTime()}）`;
  }

  getReportBody(): string {
    if (this.summaryText.length > 0) {
      return `${this.getReportSubject()}\n\n${this.summaryText}`;
    }
    return this.buildFallbackReport();
  }

  normalizeReportText(text: string): string {
    return text
      .split('**').join('')
      .split('###').join('')
      .split('##').join('')
      .split('#').join('')
      .split('```').join('')
      .trim();
  }

  getReportPreviewLines(): string[] {
    const text = this.summaryLoading && this.summaryText.length === 0 ? 'AI 正在整理告警原因、风险影响、处置建议和领导关注事项...' :
      this.normalizeReportText(this.summaryText.length > 0 ? this.summaryText : this.buildFallbackReport());
    return text.split('\n').filter((line: string): boolean => line.trim().length > 0).slice(0, 8);
  }

  getReportLines(): string[] {
    const text = this.summaryLoading && this.summaryText.length === 0 ? 'AI 正在整理告警原因、风险影响、处置建议和领导关注事项...' :
      this.normalizeReportText(this.summaryText.length > 0 ? this.summaryText : this.buildFallbackReport());
    return text.split('\n').filter((line: string): boolean => line.trim().length > 0);
  }

  isReportHeading(line: string): boolean {
    return line.startsWith('一、') || line.startsWith('二、') || line.startsWith('三、') ||
      line.startsWith('四、') || line.startsWith('五、');
  }

  applyTemplate(template: string): void {
    this.chatInputText = template;
  }

  async analyzeSummary(): Promise<void> {
    if (this.alerts.length === 0) {
      promptAction.showToast({ message: '暂无告警数据' });
      return;
    }
    this.summaryExpanded = true;
    this.reportGeneratedAt = this.formatCurrentTime();
    this.summaryText = '';
    this.summaryLoading = true;
    const question = this.buildReportPrompt();
    try {
      const aiReport = await queryAlarmQuestion(this.buildSummaryPayload(), question);
      if (aiReport.length > 0) {
        this.summaryText = aiReport;
      }
    } catch (err) {
      this.summaryText = this.buildFallbackReport();
      promptAction.showToast({ message: `AI汇总失败，已生成本地汇报：${err}` });
    } finally {
      this.summaryLoading = false;
    }
  }

  buildLocalChatAnswer(question: string, selectedAlerts: AlertRecord[]): string {
    const criticalCount = selectedAlerts.filter((item: AlertRecord): boolean => item.level === AlertLevel.Critical).length;
    const warningCount = selectedAlerts.filter((item: AlertRecord): boolean => item.level === AlertLevel.Warning).length;
    const points = selectedAlerts.map((item: AlertRecord): string => item.point).join('、');
    if (question.includes('共同风险')) {
      return `这 ${selectedAlerts.length} 条告警的共同风险是：现场通行和巡检安全受到影响。涉及点位：${points}。其中严重 ${criticalCount} 条、预警 ${warningCount} 条，建议优先核查严重点位，并确认是否存在通道堵塞、人员误入、环境异常或传感器误报。`;
    }
    if (question.includes('优先')) {
      return `优先处理顺序建议：1. 先处理严重告警点位；2. 再处理影响通行或人员安全的告警；3. 最后复核预警类环境和视觉异常。当前严重 ${criticalCount} 条，建议先核查：${points}。`;
    }
    if (question.includes('处置') || question.includes('步骤')) {
      return `现场处置建议：1. 派人到告警点位复核；2. 清理障碍物或确认人员撤离；3. 复测环境和传感器状态；4. 记录处理结果并确认告警是否恢复。涉及点位：${points}。`;
    }
    if (question.includes('继续巡检') || question.includes('关注')) {
      return `继续巡检时需要重点关注：严重告警点位是否已解除、通道是否畅通、人员是否进入禁区、环境指标是否持续升高。建议巡检前先确认：${points}。`;
    }
    return `基于当前 ${selectedAlerts.length} 条引用告警，建议先关注严重 ${criticalCount} 条和预警 ${warningCount} 条。涉及点位：${points}。请优先现场复核异常原因，再决定是否继续巡检或启动人工处置。`;
  }

  async copyText(text: string, successMessage: string): Promise<void> {
    try {
      const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      await pasteboard.getSystemPasteboard().setData(pasteboardData);
      promptAction.showToast({ message: successMessage });
    } catch (err) {
      promptAction.showToast({ message: '复制失败，请手动选择文本' });
    }
  }

  async copyReport(): Promise<void> {
    if (this.alerts.length === 0) {
      promptAction.showToast({ message: '暂无告警数据' });
      return;
    }
    await this.copyText(this.getReportBody(), '汇报内容已复制');
  }

  async copyLeaderEmail(): Promise<void> {
    await this.copyText(this.leaderEmail, '领导邮箱已复制');
  }

  async shareReportByEmail(): Promise<void> {
    if (this.alerts.length === 0) {
      promptAction.showToast({ message: '暂无告警数据' });
      return;
    }
    if (this.summaryText.length === 0) {
      this.summaryText = this.buildFallbackReport();
      this.reportGeneratedAt = this.reportGeneratedAt || this.formatCurrentTime();
    }
    await this.copyReport();
    this.showEmailFallbackDialog = true;
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
    this.chatItems = [...this.chatItems, new ChatItem(loadingId, false, 'AI正在分析告警，请稍候...', true)];
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
      const localAnswer = this.buildLocalChatAnswer(question, selectedAlerts);
      this.chatItems = this.chatItems.map((item: ChatItem): ChatItem => {
        if (item.id === loadingId) {
          return new ChatItem(item.id, false, `AI咨询失败，已使用本地规则兜底。\n${localAnswer}`, false);
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
        Button('清空记录')
          .layoutWeight(1)
          .height('34vp')
          .fontSize('12fp')
          .fontColor($r('app.color.text'))
          .backgroundColor($r('app.color.card_elevated'))
          .borderRadius('17vp')
          .border({ width: '1vp', color: $r('app.color.divider') })
          .onClick((): void => {
            PatrolStore.getInstance().clearAlerts();
            promptAction.showToast({ message: '已清空告警记录' });
          })

        Button('返回')
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
    Column({ space: '12vp' }) {
      Row({ space: '10vp' }) {
        Column({ space: '3vp' }) {
          Text('总结汇报')
            .fontSize('15fp')
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text'))
            .maxLines(1)
          Text(this.summaryLoading ? '已先生成本地汇报，AI 正在后台优化' :
            (this.reportGeneratedAt.length > 0 ? `生成时间 ${this.reportGeneratedAt}` : 'AI 整理告警原因、影响风险和处置建议'))
            .fontSize('10fp')
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

        Button(this.summaryLoading ? 'AI优化中' : '生成汇报')
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
        this.StatBadge('预警', `${this.getWarningCount()}`, $r('app.color.alert_warning'))
        this.StatBadge('正常', `${this.getNormalCount()}`, $r('app.color.alert_normal'))
      }
      .width('100%')

      if (this.summaryLoading || this.summaryText.length > 0) {
        this.ReportContent()
        if (!this.summaryLoading) {
          this.ReportActions()
        }
      } else {
        Text(this.alerts.length === 0 ? '暂无告警数据，AI 需要至少一条告警记录才能研判。' : '点击汇总分析，快速定位最优先处理的告警点位。')
          .fontSize('12fp')
          .fontColor($r('app.color.text_secondary'))
          .width('100%')

        if (this.alerts.length === 0) {
          Button('生成测试告警')
            .height('32vp')
            .fontSize('11fp')
            .fontColor($r('app.color.text_on_accent'))
            .backgroundColor($r('app.color.button_primary'))
            .borderRadius('16vp')
            .onClick((): void => {
              this.seedDemoAlerts();
            })
        }
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
  ReportContent() {
    Column({ space: '8vp' }) {
      Row({ space: '8vp' }) {
        Text('汇报正文')
          .fontSize('12fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
        if (!this.summaryLoading) {
          Text('查看全文')
            .fontSize('10fp')
            .fontColor($r('app.color.button_primary'))
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Column({ space: '6vp' }) {
        ForEach(this.getReportPreviewLines(), (line: string) => {
          Text(line)
            .fontSize(this.isReportHeading(line) ? '13fp' : '12fp')
            .fontColor(this.isReportHeading(line) ? $r('app.color.text') : $r('app.color.text_secondary'))
            .fontWeight(this.isReportHeading(line) ? FontWeight.Bold : FontWeight.Regular)
            .lineHeight('19fp')
            .width('100%')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }, (line: string, index: number) => `${index}_${line}`)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: '12vp', right: '12vp', top: '10vp', bottom: '10vp' })
    .backgroundColor($r('app.color.card_elevated'))
    .borderRadius('10vp')
    .onClick((): void => {
      if (!this.summaryLoading) {
        this.showReportDialog = true;
      }
    })
  }

  @Builder
  ReportActions() {
    Row({ space: '8vp' }) {
      Button('复制报告')
        .layoutWeight(1)
        .height('34vp')
        .fontSize('11fp')
        .fontColor($r('app.color.text'))
        .backgroundColor($r('app.color.button_secondary'))
        .borderRadius('17vp')
        .onClick((): void => {
          this.copyReport();
        })

      Button('发送领导')
        .layoutWeight(1)
        .height('34vp')
        .fontSize('11fp')
        .fontColor($r('app.color.text_on_accent'))
        .backgroundColor($r('app.color.module5_accent'))
        .borderRadius('17vp')
        .onClick((): void => {
          this.shareReportByEmail();
        })
    }
    .width('100%')
  }

  @Builder
  ReportDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000066')
        .onClick((): void => {
          this.showReportDialog = false;
        })

      Column({ space: '12vp' }) {
        Row({ space: '10vp' }) {
          Column({ space: '3vp' }) {
            Text('总结汇报全文')
              .fontSize('18fp')
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text'))
            Text(this.reportGeneratedAt.length > 0 ? `生成时间 ${this.reportGeneratedAt}` : '可下拉查看全部内容')
              .fontSize('11fp')
              .fontColor($r('app.color.text_secondary'))
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Button('关闭')
            .height('32vp')
            .fontSize('11fp')
            .fontColor($r('app.color.text'))
            .backgroundColor($r('app.color.card_elevated'))
            .borderRadius('16vp')
            .onClick((): void => {
              this.showReportDialog = false;
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Row({ space: '8vp' }) {
          Button('复制报告')
            .layoutWeight(1)
            .height('32vp')
            .fontSize('11fp')
            .fontColor($r('app.color.text'))
            .backgroundColor($r('app.color.button_secondary'))
            .borderRadius('16vp')
            .onClick((): void => {
              this.copyReport();
            })

          Button('发送领导')
            .layoutWeight(1)
            .height('32vp')
            .fontSize('11fp')
            .fontColor($r('app.color.text_on_accent'))
            .backgroundColor($r('app.color.module5_accent'))
            .borderRadius('16vp')
            .onClick((): void => {
              this.shareReportByEmail();
            })
        }
        .width('100%')

        Scroll() {
          Column({ space: '8vp' }) {
            ForEach(this.getReportLines(), (line: string) => {
              Text(line)
                .fontSize(this.isReportHeading(line) ? '14fp' : '12fp')
                .fontColor(this.isReportHeading(line) ? $r('app.color.text') : $r('app.color.text_secondary'))
                .fontWeight(this.isReportHeading(line) ? FontWeight.Bold : FontWeight.Regular)
                .lineHeight('21fp')
                .width('100%')
            }, (line: string, index: number) => `${index}_${line}`)
          }
          .width('100%')
          .padding({ left: '12vp', right: '12vp', top: '12vp', bottom: '12vp' })
          .backgroundColor($r('app.color.card_elevated'))
          .borderRadius('12vp')
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.On)
      }
      .width('92%')
      .height('78%')
      .padding('16vp')
      .backgroundColor($r('app.color.card_background'))
      .borderRadius('18vp')
      .border({ width: '1vp', color: $r('app.color.divider') })
      .shadow(ElevatedShadow)
    }
    .width('100%')
    .height('100%')
    .zIndex(20)
  }

  @Builder
  EmailFallbackDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000066')
        .onClick((): void => {
          this.showEmailFallbackDialog = false;
        })

      Column({ space: '12vp' }) {
        Row({ space: '10vp' }) {
          Column({ space: '3vp' }) {
            Text('发送给领导')
              .fontSize('18fp')
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text'))
            Text('当前设备未配置可打开的邮件应用，已为你准备好收件人和汇报正文')
              .fontSize('11fp')
              .fontColor($r('app.color.text_secondary'))
              .maxLines(2)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Button('关闭')
            .height('32vp')
            .fontSize('11fp')
            .fontColor($r('app.color.text'))
            .backgroundColor($r('app.color.card_elevated'))
            .borderRadius('16vp')
            .onClick((): void => {
              this.showEmailFallbackDialog = false;
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Column({ space: '8vp' }) {
          EmailInfoRow({ label: '收件人', value: this.leaderEmail })
          EmailInfoRow({ label: '主题', value: this.getReportSubject() })
        }
        .width('100%')
        .padding('12vp')
        .backgroundColor($r('app.color.card_elevated'))
        .borderRadius('12vp')

        Row({ space: '8vp' }) {
          Button('复制邮箱')
            .layoutWeight(1)
            .height('34vp')
            .fontSize('11fp')
            .fontColor($r('app.color.text'))
            .backgroundColor($r('app.color.button_secondary'))
            .borderRadius('17vp')
            .onClick((): void => {
              this.copyLeaderEmail();
            })

          Button('复制正文')
            .layoutWeight(1)
            .height('34vp')
            .fontSize('11fp')
            .fontColor($r('app.color.text_on_accent'))
            .backgroundColor($r('app.color.module5_accent'))
            .borderRadius('17vp')
            .onClick((): void => {
              this.copyReport();
            })
        }
        .width('100%')

        Text('操作方式：打开任意邮箱或 QQ 邮箱，把收件人填入上方邮箱，正文直接粘贴即可。')
          .fontSize('11fp')
          .fontColor($r('app.color.text_secondary'))
          .lineHeight('18fp')
          .width('100%')

        Scroll() {
          Column({ space: '8vp' }) {
            ForEach(this.getReportLines(), (line: string) => {
              Text(line)
                .fontSize(this.isReportHeading(line) ? '13fp' : '11fp')
                .fontColor(this.isReportHeading(line) ? $r('app.color.text') : $r('app.color.text_secondary'))
                .fontWeight(this.isReportHeading(line) ? FontWeight.Bold : FontWeight.Regular)
                .lineHeight('19fp')
                .width('100%')
            }, (line: string, index: number) => `mail_${index}_${line}`)
          }
          .width('100%')
          .padding('12vp')
          .backgroundColor($r('app.color.card_elevated'))
          .borderRadius('12vp')
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.On)
      }
      .width('92%')
      .height('76%')
      .padding('16vp')
      .backgroundColor($r('app.color.card_background'))
      .borderRadius('18vp')
      .border({ width: '1vp', color: $r('app.color.divider') })
      .shadow(ElevatedShadow)
    }
    .width('100%')
    .height('100%')
    .zIndex(30)
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
      Button('生成测试告警')
        .height('34vp')
        .fontSize('12fp')
        .fontColor($r('app.color.text_on_accent'))
        .backgroundColor($r('app.color.button_primary'))
        .borderRadius('17vp')
        .onClick((): void => {
          this.seedDemoAlerts();
        })
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

      if (this.showReportDialog) {
        this.ReportDialog()
      }

      if (this.showEmailFallbackDialog) {
        this.EmailFallbackDialog()
      }
    }
    .width('100%')
    .height('100%')
  }
}

@Component
struct EmailInfoRow {
  @Prop label: string = '';
  @Prop value: string = '';

  build() {
    Column({ space: '4vp' }) {
      Text(this.label)
        .fontSize('10fp')
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
      Text(this.value)
        .fontSize('12fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
