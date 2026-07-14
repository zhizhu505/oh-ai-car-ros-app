import {
  VisionLogRecord,
  VisionSnapshot
} from '../model/PatrolModels';
import { PatrolStore } from '../store/PatrolStore';
import { ModuleTabBar, InfoCard } from '../components/PageHeader';
import { VideoComponents } from '../components/VideoComponents';
import { CardShadow } from '../styles/styles';
import { carApi } from '../CarUtill/CarApi';
import { CarEncode } from '../CarUtill/CarEncode';
import { AlertAreaStatus, PatrolCommandUtils, RedBottleDemoStatus } from '../tcp/PatrolCommandUtils';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct Module4Vision {
  @State currentTabIndex: number = 0;
  @State point: string = '-';
  @State personDetected: boolean = false;
  @State boxInChannel: boolean = false;
  @State redBottleDetectedLive: boolean = false;
  @State alertAreaDetectedLive: boolean = false;
  @State recommendedAction: string = 'forward';
  @State message: string = '等待数据';
  @State imageUrl: string = '';
  @State updateTime: string = '-';
  @State visionLogs: VisionLogRecord[] = [];
  @State demoStarting: boolean = false;
  @State demoStopping: boolean = false;
  @State demoEmergencyStopping: boolean = false;
  @State redBottleStatus: string = '未启动';
  @State redBottleDistance: string = '--';
  @State redBottleThreshold: string = '0.30m';
  @State redBottleSpeed: string = '0.05m/s';
  @State redBottleAlarmActive: boolean = false;
  @State redBottleDetected: boolean = false;
  @State redBottleMessage: string = '等待状态同步';
  @State alertAreaStatus: string = '未启动';
  @State alertAreaDetected: boolean = false;
  @State alertAreaConfirmed: boolean = false;
  @State alertAreaAction: string = 'forward';
  @State alertAreaConfidence: string = '--';
  @State alertAreaMessage: string = '等待状态同步';
  private tabs: string[] = ['实时数据', '阈值规则', '视觉日志'];
  private redBottleStatusTimer: number = -1;
  private lastAlertAreaLogSignature: string = '';
  private refreshHandler: () => void = (): void => {
    this.refreshData();
  };

  aboutToAppear(): void {
    this.refreshData();
    PatrolStore.getInstance().subscribe(this.refreshHandler);
    this.startRedBottleStatusPolling();
  }

  aboutToDisappear(): void {
    PatrolStore.getInstance().unsubscribe(this.refreshHandler);
    this.stopRedBottleStatusPolling();
  }

  refreshData(): void {
    const vision: VisionSnapshot = PatrolStore.getInstance().vision;
    this.point = vision.point;
    this.personDetected = vision.personDetected;
    this.boxInChannel = vision.boxInChannel;
    this.redBottleDetectedLive = vision.redBottleDetected;
    this.alertAreaDetectedLive = vision.alertAreaDetected;
    this.recommendedAction = vision.recommendedAction;
    this.message = vision.message;
    this.imageUrl = vision.imageUrl;
    this.updateTime = vision.updateTime;
    this.visionLogs = PatrolStore.getInstance().visionLogs;
  }

  build() {
    Column({ space: '0vp' }) {
      ModuleTabBar({
        currentIndex: $currentTabIndex,
        tabs: this.tabs,
        accentColor: $r('app.color.module4_accent'),
        title: '视觉识别',
        subtitle: '红瓶停车与警戒区识别'
      })

      Scroll() {
        Column() {
          if (this.currentTabIndex === 0) {
            this.DetectView()
          } else if (this.currentTabIndex === 1) {
            this.RuleView()
          } else {
            this.LogView()
          }
        }
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.window_background'))
  }

  @Builder
  DetectView() {
    Column({ space: '10vp' }) {
      Column() {
        InfoCard({ title: '视频预览' }) {
          VideoComponents({
            previewWidth: '330vp',
            previewHeight: '190vp',
            showActions: true
          })
        }
      }
      .padding({ left: '14vp', right: '14vp' })

      Column() {
        InfoCard({ title: '检测状态' }) {
          Column({ space: '8vp' }) {
            Row({ space: '10vp' }) {
              Column({ space: '2vp' }) {
                Text('检测点位')
                  .fontSize('12fp')
                  .fontColor($r('app.color.text_secondary'))
                Text(this.point)
                  .fontSize('14fp')
                  .fontColor($r('app.color.text'))
                  .fontWeight(FontWeight.Medium)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .alignItems(HorizontalAlign.Start)
            }
            Row({ space: '10vp' }) {
              DetectStatusCard({
                title: '人员闯入',
                detected: this.personDetected,
                normalText: '未检测到人员',
                alertText: '检测到人员闯入！'
              })
              .layoutWeight(1)
              DetectStatusCard({
                title: '通道占道',
                detected: this.boxInChannel,
                normalText: '通道畅通',
                alertText: '检测到杂物占道！'
              })
              .layoutWeight(1)
            }
            Row({ space: '10vp' }) {
              DetectStatusCard({
                title: '红瓶停车',
                detected: this.redBottleDetectedLive || this.redBottleDetected,
                normalText: '未触发红瓶',
                alertText: '检测到红瓶！'
              })
              .layoutWeight(1)
              DetectStatusCard({
                title: '警戒区',
                detected: this.alertAreaDetectedLive || this.alertAreaDetected,
                normalText: '未进入警戒区',
                alertText: '检测到警戒区！'
              })
              .layoutWeight(1)
            }
          }
        }
      }
      .padding({ left: '14vp', right: '14vp' })

      Column() {
        InfoCard({ title: '状态信息' }) {
          Column({ space: '6vp' }) {
            Text(this.message)
              .fontSize('13fp')
              .fontColor($r('app.color.text'))
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(`更新时间：${this.updateTime}`)
              .fontSize('12fp')
              .fontColor($r('app.color.text_secondary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            if (this.imageUrl.length > 0) {
              Text(`异常截图已保存`)
                .fontSize('12fp')
                .fontColor($r('app.color.status_active'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            Button('停止蜂鸣')
              .height('34vp')
              .fontSize('12fp')
              .fontColor($r('app.color.text_on_accent'))
              .backgroundColor($r('app.color.alert_critical'))
              .borderRadius('17vp')
              .onClick((): void => {
                carApi.send(CarEncode.StopBuzzerEncode());
                PatrolCommandUtils.stopBuzzer();
                PatrolStore.getInstance().addVisionLog('已发送停止蜂鸣指令');
                promptAction.showToast({ message: '已发送停止蜂鸣指令' });
              })
            Row({ space: '8vp' }) {
              Button(this.demoStarting ? '启动中' : '启动红瓶停车演示')
                .layoutWeight(1)
                .height('36vp')
                .fontSize('12fp')
                .fontColor($r('app.color.text_on_accent'))
                .backgroundColor(this.demoStarting ? $r('app.color.button_disabled') : $r('app.color.module4_accent'))
                .borderRadius('18vp')
                .enabled(!this.demoStarting)
                .onClick((): void => {
                  this.startRedBottleDemo();
                })
              Button(this.demoStopping ? '停止中' : '停止演示')
                .layoutWeight(1)
                .height('36vp')
                .fontSize('12fp')
                .fontColor($r('app.color.text'))
                .backgroundColor($r('app.color.card_elevated'))
                .borderRadius('18vp')
                .enabled(!this.demoStopping)
                .onClick((): void => {
                  this.stopRedBottleDemo();
                })
            }
            Button(this.demoEmergencyStopping ? '急停中' : '紧急停车 / 关蜂鸣')
              .height('42vp')
              .fontSize('14fp')
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_on_accent'))
              .backgroundColor($r('app.color.alert_critical'))
              .borderRadius('21vp')
              .enabled(!this.demoEmergencyStopping)
              .onClick((): void => {
                this.emergencyStopRedBottleDemo();
              })
          }
        }
      }
      .padding({ left: '14vp', right: '14vp' })

      Column() {
        InfoCard({ title: '红瓶演示运行状态' }) {
          Column({ space: '8vp' }) {
            Row({ space: '8vp' }) {
              Text(this.redBottleStatus)
                .fontSize('16fp')
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .backgroundColor(this.redBottleAlarmActive ? $r('app.color.alert_critical') : $r('app.color.module4_accent'))
                .padding({ left: '12vp', right: '12vp', top: '7vp', bottom: '7vp' })
                .borderRadius('14vp')
              Text(this.redBottleDetected ? '已识别红瓶' : '未识别红瓶')
                .fontSize('12fp')
                .fontColor(this.redBottleDetected ? $r('app.color.status_active') : $r('app.color.text_secondary'))
                .layoutWeight(1)
                .textAlign(TextAlign.End)
            }
            Row({ space: '8vp' }) {
              RedBottleMetricCard({ label: '当前距离', value: this.redBottleDistance })
                .layoutWeight(1)
              RedBottleMetricCard({ label: '停止阈值', value: this.redBottleThreshold })
                .layoutWeight(1)
              RedBottleMetricCard({ label: '演示速度', value: this.redBottleSpeed })
                .layoutWeight(1)
            }
            Text(this.redBottleMessage)
              .fontSize('12fp')
              .fontColor($r('app.color.text_secondary'))
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
        }
      }
      .padding({ left: '14vp', right: '14vp' })

      Column() {
        InfoCard({ title: '警戒区守护状态' }) {
          Column({ space: '8vp' }) {
            Row({ space: '8vp' }) {
              Text(this.alertAreaStatus)
                .fontSize('16fp')
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .backgroundColor(this.alertAreaConfirmed ? $r('app.color.alert_warning') : $r('app.color.module4_accent'))
                .padding({ left: '12vp', right: '12vp', top: '7vp', bottom: '7vp' })
                .borderRadius('14vp')
              Text(this.alertAreaDetected ? '已识别警戒区' : '未识别警戒区')
                .fontSize('12fp')
                .fontColor(this.alertAreaDetected ? $r('app.color.status_active') : $r('app.color.text_secondary'))
                .layoutWeight(1)
                .textAlign(TextAlign.End)
            }
            Row({ space: '8vp' }) {
              RedBottleMetricCard({ label: '置信度', value: this.alertAreaConfidence })
                .layoutWeight(1)
              RedBottleMetricCard({ label: '建议动作', value: this.alertAreaAction })
                .layoutWeight(1)
              RedBottleMetricCard({ label: '确认状态', value: this.alertAreaConfirmed ? '已确认' : '观察中' })
                .layoutWeight(1)
            }
            Text(this.alertAreaMessage)
              .fontSize('12fp')
              .fontColor($r('app.color.text_secondary'))
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
        }
      }
      .padding({ left: '14vp', right: '14vp' })
    }
    .width('100%')
    .padding({ top: '8vp', bottom: '16vp' })
  }

  @Builder
  RuleView() {
    Column({ space: '12vp' }) {
      InfoCard({ title: '当前已接入规则' }) {
        Column({ space: '10vp' }) {
          VisionRuleCard({
            title: '红瓶识别停车报警',
            rule: '识别到红瓶并接近至 0.30m 停车阈值内时，触发停车锁存、蜂鸣与视觉告警日志',
            icon: '红'
          })
          VisionRuleCard({
            title: '警戒区识别',
            rule: '识别红色胶带等警戒区域，达到置信度与连续帧确认条件后返回避让建议动作',
            icon: '区'
          })
        }
        .width('100%')
      }
      InfoCard({ title: '最小落地版本' }) {
        Text('红瓶识别停车报警 + 警戒区识别')
          .fontSize('13fp')
          .fontColor($r('app.color.alert_warning'))
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }
    .padding({ left: '14vp', right: '14vp', top: '12vp', bottom: '16vp' })
    .width('100%')
  }

  @Builder
  LogView() {
    Column({ space: '12vp' }) {
      InfoCard({ title: '实时视觉日志' }) {
        Column({ space: '8vp' }) {
          if (this.visionLogs.length === 0) {
            Text('等待小车视觉日志')
              .fontSize('13fp')
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: '12vp', bottom: '12vp' })
          } else {
            ForEach(this.visionLogs.slice(0, 20), (item: VisionLogRecord) => {
              VisionLogItem({ item: item })
            }, (item: VisionLogRecord): string => `${item.time}_${item.point}_${item.message}`)
          }
        }
        .width('100%')
      }
    }
    .padding({ left: '14vp', right: '14vp', top: '12vp', bottom: '16vp' })
    .width('100%')
  }

  private async startRedBottleDemo(): Promise<void> {
    this.demoStarting = true;
    this.redBottleStatus = '启动中';
    PatrolStore.getInstance().addVisionLog('正在启动红瓶停车演示：0.05m/s，0.30m停车，蜂鸣3秒');
    const ok = await PatrolCommandUtils.startRedBottleDemo();
    this.demoStarting = false;
    PatrolStore.getInstance().addVisionLog(ok ? '红瓶停车演示启动命令已发送' : '红瓶停车演示启动命令发送失败', '视觉AI', !ok);
    promptAction.showToast({ message: ok ? '红瓶停车演示已启动' : '启动命令发送失败，请检查连接' });
    this.pollRedBottleStatus();
  }

  private async stopRedBottleDemo(): Promise<void> {
    this.demoStopping = true;
    PatrolStore.getInstance().addVisionLog('正在停止红瓶停车演示');
    const ok = await PatrolCommandUtils.stopRedBottleDemo();
    await PatrolCommandUtils.stopBuzzer();
    this.demoStopping = false;
    PatrolStore.getInstance().addVisionLog(ok ? '红瓶停车演示已停止，已补发停车和关蜂鸣' : '红瓶停车演示停止命令发送失败', '视觉AI', !ok);
    promptAction.showToast({ message: ok ? '红瓶停车演示已停止' : '停止命令发送失败，请检查连接' });
    this.pollRedBottleStatus();
  }

  private async emergencyStopRedBottleDemo(): Promise<void> {
    this.demoEmergencyStopping = true;
    this.redBottleStatus = '已停止';
    PatrolStore.getInstance().addVisionLog('紧急停车：连续发送停车和关蜂鸣指令', '视觉AI', true);
    carApi.send(CarEncode.StopBuzzerEncode());
    const ok = await PatrolCommandUtils.emergencyStopRedBottleDemo();
    await PatrolCommandUtils.stopBuzzer();
    this.demoEmergencyStopping = false;
    PatrolStore.getInstance().addVisionLog(ok ? '紧急停车/关蜂鸣已执行' : '紧急停车命令发送失败，请检查连接', '视觉AI', !ok);
    promptAction.showToast({ message: ok ? '已执行紧急停车/关蜂鸣' : '急停命令发送失败' });
    this.pollRedBottleStatus();
  }

  private startRedBottleStatusPolling(): void {
    this.pollRedBottleStatus();
    if (this.redBottleStatusTimer !== -1) {
      clearInterval(this.redBottleStatusTimer);
    }
    this.redBottleStatusTimer = setInterval((): void => {
      this.pollRedBottleStatus();
    }, 2000);
  }

  private stopRedBottleStatusPolling(): void {
    if (this.redBottleStatusTimer !== -1) {
      clearInterval(this.redBottleStatusTimer);
      this.redBottleStatusTimer = -1;
    }
  }

  private async pollRedBottleStatus(): Promise<void> {
    const status: RedBottleDemoStatus = await PatrolCommandUtils.getRedBottleStatus();
    this.redBottleStatus = status.status;
    this.redBottleDistance = this.formatMeters(status.distance_m);
    this.redBottleThreshold = this.formatMeters(status.threshold_m);
    this.redBottleSpeed = `${status.speed_mps.toFixed(2)}m/s`;
    this.redBottleAlarmActive = status.alarm_active;
    this.redBottleDetected = status.detection;
    this.redBottleMessage = status.message;
    const alertStatus: AlertAreaStatus = await PatrolCommandUtils.getAlertAreaStatus();
    this.alertAreaStatus = alertStatus.status;
    this.alertAreaDetected = alertStatus.detection;
    this.alertAreaConfirmed = alertStatus.confirmed;
    this.alertAreaAction = alertStatus.recommended_action;
    this.alertAreaConfidence = alertStatus.confidence > 0 ? alertStatus.confidence.toFixed(2) : '--';
    this.alertAreaMessage = alertStatus.message;
    this.syncAlertAreaLog(alertStatus);
  }

  private syncAlertAreaLog(status: AlertAreaStatus): void {
    const signature = `${status.status}_${status.detection}_${status.confirmed}_${status.recommended_action}_${status.message}`;
    if (signature === this.lastAlertAreaLogSignature) {
      return;
    }
    this.lastAlertAreaLogSignature = signature;

    if (!status.guard_active && !status.detection && status.status === '未启动') {
      return;
    }

    let message = status.message;
    let isAlert = false;
    if (status.confirmed) {
      message = `警戒区已确认，建议动作：${status.recommended_action}`;
      isAlert = true;
    } else if (status.detection) {
      message = `识别到警戒区，置信度：${status.confidence.toFixed(2)}`;
      isAlert = true;
    } else if (message.length === 0) {
      message = `警戒区状态：${status.status}`;
    }
    PatrolStore.getInstance().addVisionLog(message, '警戒区视觉', isAlert);
  }

  private formatMeters(value: number | null): string {
    if (value === null || value < 0) {
      return '--';
    }
    return `${value.toFixed(2)}m`;
  }
}

@Component
struct RedBottleMetricCard {
  @Prop label: string = '';
  @Prop value: string = '';

  build() {
    Column({ space: '4vp' }) {
      Text(this.label)
        .fontSize('11fp')
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
      Text(this.value)
        .fontSize('14fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({ left: '8vp', right: '8vp', top: '8vp', bottom: '8vp' })
    .backgroundColor($r('app.color.card_elevated'))
    .borderRadius('10vp')
  }
}

@Component
struct VisionLogItem {
  @Prop item: VisionLogRecord = {
    time: '-',
    point: '-',
    message: '',
    personDetected: false,
    boxInChannel: false,
    redBottleDetected: false,
    alertAreaDetected: false
  };

  build() {
    Row({ space: '8vp' }) {
      Text()
        .width('8vp')
        .height('8vp')
        .backgroundColor(this.item.personDetected || this.item.boxInChannel ||
          this.item.redBottleDetected || this.item.alertAreaDetected ?
          $r('app.color.alert_critical') : $r('app.color.status_active'))
        .borderRadius('4vp')
      Column({ space: '3vp' }) {
        Row({ space: '8vp' }) {
          Text(this.item.time)
            .fontSize('12fp')
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
          Text(this.item.point)
            .fontSize('12fp')
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
        Text(this.item.message)
          .fontSize('13fp')
          .fontColor($r('app.color.text'))
          .width('100%')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: '10vp', right: '10vp', top: '8vp', bottom: '8vp' })
    .backgroundColor($r('app.color.card_elevated'))
    .borderRadius('8vp')
  }

}

@Component
struct DetectStatusCard {
  @Prop title: string = '';
  @Prop detected: boolean = false;
  @Prop normalText: string = '';
  @Prop alertText: string = '';

  build() {
    Column({ space: '6vp' }) {
      Text(this.title)
        .fontSize('14fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(this.detected ? this.alertText : this.normalText)
        .fontSize('13fp')
        .fontColor(Color.White)
        .backgroundColor(this.detected ? $r('app.color.alert_critical') : $r('app.color.alert_normal'))
        .padding({ left: '10vp', right: '10vp', top: '8vp', bottom: '8vp' })
        .borderRadius('8vp')
        .width('100%')
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding('12vp')
    .backgroundColor($r('app.color.card_elevated'))
    .borderRadius('12vp')
  }
}

@Component
struct VisionRuleCard {
  @Prop title: string = '';
  @Prop rule: string = '';
  @Prop icon: string = '';

  build() {
    Row({ space: '10vp' }) {
      Text(this.icon)
        .fontSize('12fp')
        .fontColor($r('app.color.text_on_accent'))
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .width('28vp')
        .height('28vp')
        .backgroundColor($r('app.color.module4_accent'))
        .borderRadius('14vp')
      Column({ space: '4vp' }) {
        Text(this.title)
          .fontSize('14fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.rule)
          .fontSize('13fp')
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .padding('12vp')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('12vp')
    .border({ width: '1vp', color: $r('app.color.divider') })
    .shadow(CardShadow)
  }
}

