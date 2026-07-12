import {
  ALERT_CATEGORY_LIDAR,
  ChannelStatus,
  LidarSnapshot,
  channelStatusText
} from '../model/PatrolModels';
import { PatrolStore } from '../store/PatrolStore';
import { ModuleTabBar, InfoCard } from '../components/PageHeader';
import { ModuleAlertList } from '../components/ModuleAlertList';
import { channelStatusColor } from '../utils/PatrolUiUtils';
import { CardShadow } from '../styles/styles';

@Entry
@Component
struct Module3Lidar {
  @State currentTabIndex: number = 0;
  @State point: string = '-';
  @State frontDistance: number = 0;
  @State leftDistance: number = 0;
  @State rightDistance: number = 0;
  @State channelStatus: ChannelStatus = ChannelStatus.Clear;
  @State message: string = '等待数据';
  @State updateTime: string = '-';
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
    const lidar: LidarSnapshot = PatrolStore.getInstance().lidar;
    this.point = lidar.point;
    this.frontDistance = lidar.frontDistance;
    this.leftDistance = lidar.leftDistance;
    this.rightDistance = lidar.rightDistance;
    this.channelStatus = lidar.channelStatus;
    this.message = lidar.message;
    this.updateTime = lidar.updateTime;
  }

  build() {
    Column({ space: '0vp' }) {
      ModuleTabBar({
        currentIndex: $currentTabIndex,
        tabs: this.tabs,
        accentColor: $r('app.color.module3_accent'),
        title: '激光雷达',
        subtitle: '前方扇区、左右货架距离与通道占用检测'
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
      Row({ space: '10vp' }) {
        Column({ space: '8vp' }) {
          Row({ space: '8vp' }) {
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
            .layoutWeight(1)
            Text(channelStatusText(this.channelStatus))
              .fontSize('11fp')
              .fontColor(Color.White)
              .backgroundColor(channelStatusColor(this.channelStatus))
              .padding({ left: '8vp', right: '8vp', top: '5vp', bottom: '5vp' })
              .borderRadius('8vp')
          }
          .width('100%')
          Row({ space: '8vp' }) {
            Column({ space: '2vp' }) {
              Text('状态信息')
                .fontSize('12fp')
                .fontColor($r('app.color.text_secondary'))
              Text(this.message)
                .fontSize('13fp')
                .fontColor($r('app.color.text'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          Row({ space: '8vp' }) {
            Column({ space: '2vp' }) {
              Text('更新时间')
                .fontSize('12fp')
                .fontColor($r('app.color.text_secondary'))
              Text(this.updateTime)
                .fontSize('13fp')
                .fontColor($r('app.color.text'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
        }
        .layoutWeight(1)
        .padding('11vp')
        .backgroundColor($r('app.color.card_background'))
        .borderRadius('12vp')
        .border({ width: '1vp', color: $r('app.color.divider') })
        .shadow(CardShadow)
      }
      .padding({ left: '14vp', right: '14vp' })

      Row({ space: '10vp' }) {
        DistanceCard({ title: '前方扇区', distance: this.frontDistance, threshold: 0.8, icon: '⬆️' })
        DistanceCard({ title: '左侧货架', distance: this.leftDistance, threshold: 0.5, icon: '⬅️' })
        DistanceCard({ title: '右侧货架', distance: this.rightDistance, threshold: 0.5, icon: '➡️' })
      }
      .padding({ left: '14vp', right: '14vp' })

      InfoCard({ title: '占用状态分类' }) {
        Column({ space: '6vp' }) {
          StatusItem({ label: '短时障碍', desc: '人员经过，减速观察', icon: '👤' })
          StatusItem({ label: '长时障碍', desc: '货物堆放异常，触发告警', icon: '📦' })
          StatusItem({ label: '通道堵塞', desc: '无法通行，停车等待', icon: '🚧' })
        }
      }
    }
    .width('100%')
    .padding({ top: '10vp', bottom: '12vp' })
  }

  @Builder
  RuleView() {
    Column({ space: '10vp' }) {
      RuleCard({ title: '前方 0.8m 内有障碍', action: '减速通行', level: 'warning' })
      RuleCard({ title: '前方 0.4m 内有障碍', action: '立即停车', level: 'critical' })
      RuleCard({ title: '持续 5 秒有障碍', action: '通道占用告警', level: 'critical' })
      RuleCard({ title: '左右货架距离偏差', action: '调整居中行驶', level: 'normal' })
      RuleCard({ title: '危险品区域移动目标', action: '警戒区域报警', level: 'critical' })
      InfoCard({ title: '检测区域' }) {
        Text('前方扇区 + 左侧货架距离 + 右侧货架距离')
          .fontSize('13fp')
          .fontColor($r('app.color.text'))
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }
    .padding({ left: '14vp', right: '14vp', top: '10vp', bottom: '12vp' })
    .width('100%')
  }

  @Builder
  AlertView() {
    Column() {
      ModuleAlertList({
        category: ALERT_CATEGORY_LIDAR,
        emptyHint: '暂无通道占用告警'
      })
    }
    .padding({ left: '14vp', right: '14vp', top: '10vp' })
    .width('100%')
  }
}

@Component
struct DistanceCard {
  @Prop title: string = '';
  @Prop distance: number = 0;
  @Prop threshold: number = 1;
  @Prop icon: string = '';

  build() {
    Column({ space: '6vp' }) {
      Text(this.icon)
        .fontSize('20fp')
      Text(this.title)
        .fontSize('12fp')
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(`${this.distance.toFixed(2)} m`)
        .fontSize('20fp')
        .fontWeight(FontWeight.Bold)
        .fontColor(this.distance < this.threshold ? $r('app.color.alert_critical') : $r('app.color.text'))
        .maxLines(1)
      Text(`阈值 ${this.threshold}m`)
        .fontSize('11fp')
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
    }
    .layoutWeight(1)
    .padding('11vp')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('12vp')
    .border({ width: '1vp', color: $r('app.color.divider') })
    .shadow(CardShadow)
    .alignItems(HorizontalAlign.Center)
  }
}

@Component
struct StatusItem {
  @Prop label: string = '';
  @Prop desc: string = '';
  @Prop icon: string = '';

  build() {
    Row({ space: '10vp' }) {
      Text(this.icon)
        .fontSize('16fp')
      Text(this.label)
        .fontSize('14fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
      Text(this.desc)
        .fontSize('13fp')
        .fontColor($r('app.color.text_secondary'))
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding('6vp')
  }
}

@Component
struct RuleCard {
  @Prop title: string = '';
  @Prop action: string = '';
  @Prop level: string = 'normal';

  private getBg(): ResourceColor {
    if (this.level === 'critical') {
      return $r('app.color.alert_critical');
    }
    if (this.level === 'warning') {
      return $r('app.color.alert_warning');
    }
    return $r('app.color.alert_normal');
  }

  private getLevelText(): string {
    if (this.level === 'critical') {
      return '严重';
    }
    if (this.level === 'warning') {
      return '预警';
    }
    return '正常';
  }

  build() {
    Row({ space: '10vp' }) {
      Column({ space: '4vp' }) {
        Text(this.title)
          .fontSize('14fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`动作：${this.action}`)
          .fontSize('13fp')
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(this.getLevelText())
        .fontSize('11fp')
        .fontColor(Color.White)
        .backgroundColor(this.getBg())
        .padding({ left: '8vp', right: '8vp', top: '5vp', bottom: '5vp' })
        .borderRadius('8vp')
    }
    .width('100%')
    .padding('11vp')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('12vp')
    .border({ width: '1vp', color: $r('app.color.divider') })
    .shadow(CardShadow)
  }
}

