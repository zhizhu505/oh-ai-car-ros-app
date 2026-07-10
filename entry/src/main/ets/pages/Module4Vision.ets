import {
  ALERT_CATEGORY_VISION,
  VisionSnapshot
} from '../model/PatrolModels';
import { PatrolStore } from '../store/PatrolStore';
import { PageHeader, ModuleTabBar, InfoCard } from '../components/PageHeader';
import { ModuleAlertList } from '../components/ModuleAlertList';
import { VideoComponents } from '../components/VideoComponents';
import { CardShadow } from '../styles/styles';

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
  private tabs: string[] = ['实时检测', '检测规则', '视觉告警'];
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
  }

  build() {
    Column({ space: '0vp' }) {
      PageHeader({
        title: '模块4：视觉目标识别',
        subtitle: '人员闯入 / 货物占道 / 货箱异常检测',
        accentColor: $r('app.color.module4_accent')
      })

      ModuleTabBar({ currentIndex: $currentTabIndex, tabs: this.tabs, accentColor: $r('app.color.module4_accent') })

      if (this.currentTabIndex === 0) {
        this.DetectView()
      } else if (this.currentTabIndex === 1) {
        this.RuleView()
      } else {
        this.AlertView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.window_background'))
  }

  @Builder
  DetectView() {
    Row({ space: '16vp' }) {
      Column({ space: '14vp' }) {
        InfoCard({ title: '检测状态' }) {
          Column({ space: '8vp' }) {
            Row({ space: '12vp' }) {
              Column({ space: '2vp' }) {
                Text('检测点位')
                  .fontSize('13fp')
                  .fontColor($r('app.color.text_secondary'))
                Text(this.point)
                  .fontSize('16fp')
                  .fontColor($r('app.color.text'))
                  .fontWeight(FontWeight.Medium)
              }
              .alignItems(HorizontalAlign.Start)
            }
            DetectStatusCard({
              title: '人员闯入',
              detected: this.personDetected,
              normalText: '未检测到人员',
              alertText: '检测到人员闯入！'
            })
            DetectStatusCard({
              title: '通道占道',
              detected: this.boxInChannel,
              normalText: '通道畅通',
              alertText: '检测到箱子占道！'
            })
          }
        }

        InfoCard({ title: '状态信息' }) {
          Column({ space: '6vp' }) {
            Text(this.message)
              .fontSize('14fp')
              .fontColor($r('app.color.text'))
            Text(`更新时间：${this.updateTime}`)
              .fontSize('13fp')
              .fontColor($r('app.color.text_secondary'))
            if (this.imageUrl.length > 0) {
              Text(`异常截图已保存`)
                .fontSize('12fp')
                .fontColor($r('app.color.status_active'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
          }
        }
      }
      .layoutWeight(1)
      .padding({ left: '20vp' })

      Column({ space: '12vp' }) {
        InfoCard({ title: '视频预览' }) {
          VideoComponents()
        }
      }
      .layoutWeight(1)
      .padding({ right: '20vp' })
    }
    .layoutWeight(1)
  }

  @Builder
  RuleView() {
    Scroll() {
      Column({ space: '12vp' }) {
        VisionRuleCard({
          title: '人员闯入检测',
          rule: 'YOLOv5 检测 person 类，出现在禁入区或货架通道内即报警',
          icon: '👤'
        })
        VisionRuleCard({
          title: '货物占道检测',
          rule: '检测框进入通道区域判定为货物越界',
          icon: '📦'
        })
        VisionRuleCard({
          title: '货物摆放异常',
          rule: '货箱偏移、倒下、越界到通道、货架空位',
          icon: '📥'
        })
        VisionRuleCard({
          title: '目标货物识别',
          rule: '识别指定标签、颜色、二维码、货箱类型',
          icon: '🏷️'
        })
        VisionRuleCard({
          title: '深度相机辅助',
          rule: '结合深度判断目标距离，确认是否阻挡通道',
          icon: '📐'
        })
        InfoCard({ title: '最小落地版本' }) {
          Text('人员闯入 + 箱子占道检测')
            .fontSize('14fp')
            .fontColor($r('app.color.alert_warning'))
            .width('100%')
        }
      }
      .padding({ left: '20vp', right: '20vp', bottom: '16vp' })
    }
    .layoutWeight(1)
  }

  @Builder
  AlertView() {
    Column() {
      ModuleAlertList({
        category: ALERT_CATEGORY_VISION,
        emptyHint: '暂无视觉异常记录'
      })
    }
    .layoutWeight(1)
    .padding({ left: '20vp', right: '20vp' })
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
        .fontSize('15fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Medium)
        .width('100%')
      Text(this.detected ? this.alertText : this.normalText)
        .fontSize('14fp')
        .fontColor(Color.White)
        .backgroundColor(this.detected ? $r('app.color.alert_critical') : $r('app.color.alert_normal'))
        .padding({ left: '12vp', right: '12vp', top: '10vp', bottom: '10vp' })
        .borderRadius('10vp')
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding('14vp')
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
    Row({ space: '12vp' }) {
      Text(this.icon)
        .fontSize('20fp')
      Column({ space: '4vp' }) {
        Text(this.title)
          .fontSize('16fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Medium)
          .width('100%')
        Text(this.rule)
          .fontSize('14fp')
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
}

