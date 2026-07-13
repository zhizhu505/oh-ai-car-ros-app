import {
  ALERT_CATEGORY_VISION,
  VisionLogRecord,
  VisionSnapshot
} from '../model/PatrolModels';
import { PatrolStore } from '../store/PatrolStore';
import { ModuleTabBar, InfoCard } from '../components/PageHeader';
import { ModuleAlertList } from '../components/ModuleAlertList';
import { VideoComponents } from '../components/VideoComponents';
import { CardShadow } from '../styles/styles';
import { carApi } from '../CarUtill/CarApi';
import { CarEncode } from '../CarUtill/CarEncode';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct Module4Vision {
  @State currentTabIndex: number = 0;
  @State point: string = '-';
  @State personDetected: boolean = false;
  @State boxInChannel: boolean = false;
  @State message: string = '等待数据';
  @State imageUrl: string = '';
  @State updateTime: string = '-';
  @State visionLogs: VisionLogRecord[] = [];
  private tabs: string[] = ['实时数据', '阈值规则', '异常记录'];
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
    const vision: VisionSnapshot = PatrolStore.getInstance().vision;
    this.point = vision.point;
    this.personDetected = vision.personDetected;
    this.boxInChannel = vision.boxInChannel;
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
        subtitle: '人员杂物识别与截图'
      })

      Scroll() {
        Column() {
          if (this.currentTabIndex === 0) {
            this.DetectView()
          } else if (this.currentTabIndex === 1) {
            this.RuleView()
          } else {
            this.AlertView()
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
          VideoComponents()
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
                promptAction.showToast({ message: '已发送停止蜂鸣指令' });
              })
          }
        }
      }
      .padding({ left: '14vp', right: '14vp' })

      Column() {
        InfoCard({ title: '实时视觉日志' }) {
          Column({ space: '8vp' }) {
            if (this.visionLogs.length === 0) {
              Text('等待小车视觉日志')
                .fontSize('13fp')
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding({ top: '10vp', bottom: '10vp' })
            } else {
              ForEach(this.visionLogs.slice(0, 8), (item: VisionLogRecord) => {
                VisionLogItem({ item: item })
              }, (item: VisionLogRecord): string => `${item.time}_${item.point}_${item.message}`)
            }
          }
          .width('100%')
        }
      }
      .padding({ left: '14vp', right: '14vp' })
    }
    .width('100%')
    .padding({ top: '12vp', bottom: '16vp' })
  }

  @Builder
  RuleView() {
    Column({ space: '12vp' }) {
      VisionRuleCard({
        title: '人员闯入检测',
        rule: 'YOLOv5 检测 person 类，出现在禁入区或管廊通道内即报警',
        icon: '👤'
      })
      VisionRuleCard({
        title: '杂物占道检测',
        rule: '检测框进入通道区域判定为杂物越界',
        icon: '📦'
      })
      VisionRuleCard({
        title: '杂物堆放异常',
        rule: '杂物偏移、倒下或越界到管廊通道',
        icon: '📥'
      })
      VisionRuleCard({
        title: '目标设备识别',
        rule: '识别设备标签、颜色、二维码与巡检标识',
        icon: '🏷️'
      })
      VisionRuleCard({
        title: '深度相机辅助',
        rule: '结合深度判断目标距离，确认是否阻挡通道',
        icon: '📐'
      })
      InfoCard({ title: '最小落地版本' }) {
        Text('人员闯入 + 杂物占道检测')
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
  AlertView() {
    Column() {
      ModuleAlertList({
        category: ALERT_CATEGORY_VISION,
        emptyHint: '暂无视觉异常记录'
      })
    }
    .padding({ left: '14vp', right: '14vp', top: '12vp' })
    .width('100%')
  }
}

@Component
struct VisionLogItem {
  @Prop item: VisionLogRecord = {
    time: '-',
    point: '-',
    message: '',
    personDetected: false,
    boxInChannel: false
  };

  build() {
    Row({ space: '8vp' }) {
      Text()
        .width('8vp')
        .height('8vp')
        .backgroundColor(this.item.personDetected || this.item.boxInChannel ?
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
        .fontSize('18fp')
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

