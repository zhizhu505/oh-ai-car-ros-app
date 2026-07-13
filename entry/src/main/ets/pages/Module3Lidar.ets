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
import { CardShadow, ElevatedShadow } from '../styles/styles';

type OccupancyClass = 'clear' | 'short' | 'long' | 'blocked';

@Entry
@Component
struct Module3Lidar {
  @State currentTabIndex: number = 0;
  @State showStrategyDialog: boolean = false;
  @State point: string = '-';
  @State frontDistance: number = 0;
  @State leftDistance: number = 0;
  @State rightDistance: number = 0;
  @State channelStatus: ChannelStatus = ChannelStatus.Clear;
  @State message: string = '等待数据';
  @State updateTime: string = '-';
  @State slowDownThreshold: number = 0.8;
  @State stopThreshold: number = 0.4;
  @State alertDurationSec: number = 5;
  @State shelfIdealDistance: number = 0.6;
  @State shelfTolerance: number = 0.12;
  @State guardRegionEnabled: boolean = true;
  @State movingTargetDetected: boolean = false;
  @State obstacleDurationSec: number = 2;
  private tabs: string[] = ['实时检测', '异常记录'];
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

  private getCenterOffset(): number {
    return Math.abs(this.leftDistance - this.rightDistance);
  }

  private getShelfBiasText(): string {
    const delta = this.leftDistance - this.rightDistance;
    if (Math.abs(delta) <= this.shelfTolerance) {
      return '车体居中，可保持当前通道姿态';
    }
    return delta > 0 ? '车体偏右，建议向左微调保持居中' : '车体偏左，建议向右微调保持居中';
  }

  private getOccupancyClass(): OccupancyClass {
    if (this.frontDistance <= this.stopThreshold) {
      return 'blocked';
    }
    if (this.frontDistance <= this.slowDownThreshold) {
      if (this.obstacleDurationSec >= this.alertDurationSec) {
        return 'long';
      }
      return 'short';
    }
    return 'clear';
  }

  private getScenarioTitle(): string {
    if (this.guardRegionEnabled && this.movingTargetDetected) {
      return '警戒区域触发';
    }
    const occupancy = this.getOccupancyClass();
    if (occupancy === 'blocked') {
      return '通道堵塞';
    }
    if (occupancy === 'long') {
      return '长时障碍';
    }
    if (occupancy === 'short') {
      return '短时障碍';
    }
    return '通道畅通';
  }

  private getActionText(): string {
    if (this.guardRegionEnabled && this.movingTargetDetected) {
      return '危险品区域检测到移动目标，按固定规则触发告警并等待人工确认';
    }
    const occupancy = this.getOccupancyClass();
    if (occupancy === 'blocked') {
      return '前方距离进入停车阈值，立即停车并等待通道恢复';
    }
    if (occupancy === 'long') {
      return '持续障碍超过固定阈值，自动判定为通道占用告警';
    }
    if (occupancy === 'short') {
      return '检测到短时障碍，减速通行并持续追踪障碍物变化';
    }
    if (this.getCenterOffset() > this.shelfTolerance) {
      return '左右货架距离不均衡，建议进行居中修正';
    }
    return '通道状态稳定，可保持巡检速度继续行驶';
  }

  private getDerivedStatus(): ChannelStatus {
    if (this.guardRegionEnabled && this.movingTargetDetected) {
      return ChannelStatus.Blocked;
    }
    const occupancy = this.getOccupancyClass();
    if (occupancy === 'blocked') {
      return ChannelStatus.Blocked;
    }
    if (occupancy === 'long') {
      return ChannelStatus.Occupied;
    }
    if (occupancy === 'short') {
      return ChannelStatus.SlowDown;
    }
    return this.getCenterOffset() > this.shelfTolerance ? ChannelStatus.SlowDown : ChannelStatus.Clear;
  }

  private simulateScenario(front: number, left: number, right: number, duration: number, movingTarget: boolean): void {
    this.frontDistance = front;
    this.leftDistance = left;
    this.rightDistance = right;
    this.obstacleDurationSec = duration;
    this.movingTargetDetected = movingTarget;
    const now = new Date();
    const snapshot: LidarSnapshot = {
      point: this.point === '-' ? 'B区货架通道' : this.point,
      frontDistance: front,
      leftDistance: left,
      rightDistance: right,
      channelStatus: this.getDerivedStatus(),
      message: this.getActionText(),
      updateTime: `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`
    };
    PatrolStore.getInstance().updateLidar(snapshot);
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column({ space: '0vp' }) {
        ModuleTabBar({
          currentIndex: $currentTabIndex,
          tabs: this.tabs,
          accentColor: $r('app.color.module3_accent'),
          title: '仓库通道安全检测',
          subtitle: '激光雷达占用检测、货架居中、动态避障与固定告警'
        })

        Scroll() {
          Column() {
            if (this.currentTabIndex === 0) {
              this.DetectView()
            } else {
              this.AlertView()
            }
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.window_background'))

      if (this.showStrategyDialog) {
        this.StrategyDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  DetectView() {
    Column({ space: '10vp' }) {
      InfoCard({ title: '通道检测概览' }) {
        Column({ space: '10vp' }) {
          Row({ space: '8vp' }) {
            Column({ space: '4vp' }) {
              Text('检测点位')
                .fontSize('12fp')
                .fontColor($r('app.color.text_secondary'))
              Text(this.point)
                .fontSize('15fp')
                .fontColor($r('app.color.text'))
                .fontWeight(FontWeight.Medium)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Text(channelStatusText(this.getDerivedStatus()))
              .fontSize('11fp')
              .fontColor(Color.White)
              .backgroundColor(channelStatusColor(this.getDerivedStatus()))
              .padding({ left: '8vp', right: '8vp', top: '5vp', bottom: '5vp' })
              .borderRadius('8vp')
          }
          .width('100%')

          Row({ space: '8vp' }) {
            MetricCard({ title: '检测类型', value: this.getScenarioTitle(), desc: this.getActionText() })
            MetricCard({ title: '更新时间', value: this.updateTime, desc: this.message })
          }
          .width('100%')
        }
      }

      Row({ space: '10vp' }) {
        DistanceCard({ title: '前方扇区', distance: this.frontDistance, threshold: this.slowDownThreshold, icon: '前' })
        DistanceCard({ title: '左侧货架', distance: this.leftDistance, threshold: this.shelfIdealDistance, icon: '左' })
        DistanceCard({ title: '右侧货架', distance: this.rightDistance, threshold: this.shelfIdealDistance, icon: '右' })
      }

      InfoCard({ title: '通道占用分类' }) {
        Column({ space: '8vp' }) {
          StatusItem({
            label: '短时障碍',
            desc: '人员经过或临时货物经过，前方小于减速阈值但持续时间较短',
            active: this.getOccupancyClass() === 'short'
          })
          StatusItem({
            label: '长时障碍',
            desc: '持续超过阈值的占用事件，固定触发通道占用告警',
            active: this.getOccupancyClass() === 'long'
          })
          StatusItem({
            label: '通道堵塞',
            desc: '前方距离进入停车阈值，车辆必须停车等待',
            active: this.getOccupancyClass() === 'blocked'
          })
          StatusItem({
            label: '货架居中',
            desc: this.getShelfBiasText(),
            active: this.getCenterOffset() <= this.shelfTolerance
          })
        }
      }

      InfoCard({ title: '模拟场景' }) {
        Column({ space: '10vp' }) {
          Row({ space: '8vp' }) {
            ActionChip({ label: '人员经过', accent: $r('app.color.alert_warning'), onTap: (): void => {
              this.simulateScenario(0.62, 0.54, 0.66, 2, false);
            } })
            ActionChip({ label: '货物堆放', accent: $r('app.color.alert_critical'), onTap: (): void => {
              this.simulateScenario(0.56, 0.50, 0.72, 7, false);
            } })
          }
          Row({ space: '8vp' }) {
            ActionChip({ label: '通道堵塞', accent: $r('app.color.alert_critical'), onTap: (): void => {
              this.simulateScenario(0.32, 0.58, 0.61, 9, false);
            } })
            ActionChip({ label: '禁区闯入', accent: $r('app.color.module3_accent'), onTap: (): void => {
              this.simulateScenario(1.20, 0.60, 0.58, 1, true);
            } })
          }
        }
      }

      InfoCard({ title: '策略配置' }) {
        Row({ space: '8vp' }) {
          Column({ space: '4vp' }) {
            Text('固定阈值策略')
              .fontSize('14fp')
              .fontColor($r('app.color.text'))
              .fontWeight(FontWeight.Medium)
            Text('点击查看各项检测配置，告警会按固定规则自动触发。')
              .fontSize('12fp')
              .fontColor($r('app.color.text_secondary'))
              .maxLines(2)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Button('查看配置')
            .height('32vp')
            .fontSize('11fp')
            .fontColor($r('app.color.text'))
            .backgroundColor($r('app.color.card_elevated'))
            .borderRadius('16vp')
            .onClick((): void => {
              this.showStrategyDialog = true;
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
    }
    .width('100%')
    .padding({ left: '14vp', right: '14vp', top: '10vp', bottom: '12vp' })
  }

  @Builder
  AlertView() {
    Column({ space: '10vp' }) {
      InfoCard({ title: '固定告警规则' }) {
        Column({ space: '8vp' }) {
          StrategyRow({ title: '减速触发', desc: `前方距离小于 ${this.slowDownThreshold.toFixed(2)}m 时减速通行。` })
          StrategyRow({ title: '停车触发', desc: `前方距离小于 ${this.stopThreshold.toFixed(2)}m 时立即停车。` })
          StrategyRow({ title: '占用触发', desc: `障碍持续超过 ${this.alertDurationSec.toFixed(0)}s 时固定判定为通道占用。` })
          StrategyRow({ title: '警戒区触发', desc: this.guardRegionEnabled ? '警戒区检测到移动目标时固定触发告警。' : '警戒区检测已关闭。' })
        }
      }

      InfoCard({ title: '雷达告警记录' }) {
        Column() {
          ModuleAlertList({
            category: ALERT_CATEGORY_LIDAR,
            emptyHint: '暂无通道占用告警'
          })
            .width('100%')
            .height('340vp')
        }
      }
    }
    .width('100%')
    .padding({ left: '14vp', right: '14vp', top: '10vp', bottom: '12vp' })
  }

  @Builder
  StrategyDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000055')
        .onClick((): void => {
          this.showStrategyDialog = false;
        })

      Column({ space: '12vp' }) {
        Row({ space: '8vp' }) {
          Text('策略配置')
            .layoutWeight(1)
            .fontSize('18fp')
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text'))
          Button('关闭')
            .height('30vp')
            .fontSize('11fp')
            .fontColor($r('app.color.text'))
            .backgroundColor($r('app.color.card_elevated'))
            .borderRadius('15vp')
            .onClick((): void => {
              this.showStrategyDialog = false;
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Scroll() {
          Column({ space: '10vp' }) {
            InfoBlock({
              title: '检测区域定义',
              desc: `前方扇区在 ${this.slowDownThreshold.toFixed(2)}m 内减速、${this.stopThreshold.toFixed(2)}m 内停车；左右货架距离用于居中修正。`
            })

            ThresholdSlider({ title: '前方减速阈值', unit: 'm', value: $slowDownThreshold, min: 0.3, max: 1.5, step: 0.05 })
            ThresholdSlider({ title: '前方停车阈值', unit: 'm', value: $stopThreshold, min: 0.2, max: 1.0, step: 0.05 })
            ThresholdSlider({ title: '占用判定时长', unit: 's', value: $alertDurationSec, min: 2, max: 15, step: 1 })
            ThresholdSlider({ title: '货架理想距离', unit: 'm', value: $shelfIdealDistance, min: 0.3, max: 1.2, step: 0.05 })
            ThresholdSlider({ title: '居中容差', unit: 'm', value: $shelfTolerance, min: 0.05, max: 0.4, step: 0.01 })

            Row({ space: '10vp' }) {
              Text('警戒区域检测')
                .layoutWeight(1)
                .fontSize('14fp')
                .fontColor($r('app.color.text'))
              Toggle({ type: ToggleType.Switch, isOn: this.guardRegionEnabled })
                .onChange((value: boolean): void => {
                  this.guardRegionEnabled = value;
                })
            }
            .width('100%')

            Row({ space: '10vp' }) {
              Text('模拟移动目标')
                .layoutWeight(1)
                .fontSize('14fp')
                .fontColor($r('app.color.text'))
              Toggle({ type: ToggleType.Switch, isOn: this.movingTargetDetected })
                .onChange((value: boolean): void => {
                  this.movingTargetDetected = value;
                })
            }
            .width('100%')

            InfoBlock({
              title: '固定告警规则',
              desc: '前方进入停车阈值、障碍持续超过占用时长、或警戒区检测到移动目标时，都会固定触发雷达告警并同步到统一告警中心。'
            })
          }
          .width('100%')
        }
        .width('100%')
        .constraintSize({ minHeight: '220vp', maxHeight: '420vp' })
        .scrollBar(BarState.Off)
      }
      .width('90%')
      .constraintSize({ maxWidth: '520vp', maxHeight: '82%' })
      .padding('16vp')
      .backgroundColor($r('app.color.card_background'))
      .borderRadius('18vp')
      .border({ width: '1vp', color: $r('app.color.divider') })
      .shadow(ElevatedShadow)
    }
    .width('100%')
    .height('100%')
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
        .fontSize('16fp')
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.module3_accent'))
      Text(this.title)
        .fontSize('12fp')
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(`${this.distance.toFixed(2)} m`)
        .fontSize('19fp')
        .fontWeight(FontWeight.Bold)
        .fontColor(this.distance < this.threshold ? $r('app.color.alert_critical') : $r('app.color.text'))
        .maxLines(1)
      Text(`阈值 ${this.threshold.toFixed(2)}m`)
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
struct MetricCard {
  @Prop title: string = '';
  @Prop value: string = '';
  @Prop desc: string = '';

  build() {
    Column({ space: '6vp' }) {
      Text(this.title)
        .fontSize('12fp')
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
      Text(this.value)
        .fontSize('15fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(this.desc)
        .fontSize('12fp')
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .padding('10vp')
    .backgroundColor($r('app.color.card_elevated'))
    .borderRadius('10vp')
    .alignItems(HorizontalAlign.Start)
  }
}

@Component
struct StatusItem {
  @Prop label: string = '';
  @Prop desc: string = '';
  @Prop active: boolean = false;

  build() {
    Row({ space: '10vp' }) {
      Column()
        .width('10vp')
        .height('10vp')
        .backgroundColor(this.active ? $r('app.color.module3_accent') : $r('app.color.divider'))
        .borderRadius('5vp')
      Column({ space: '4vp' }) {
        Text(this.label)
          .fontSize('14fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Medium)
          .width('100%')
        Text(this.desc)
          .fontSize('12fp')
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding('8vp')
    .backgroundColor(this.active ? $r('app.color.card_elevated') : $r('app.color.card_background'))
    .borderRadius('10vp')
  }
}

@Component
struct StrategyRow {
  @Prop title: string = '';
  @Prop desc: string = '';

  build() {
    Column({ space: '4vp' }) {
      Text(this.title)
        .fontSize('13fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Medium)
        .width('100%')
      Text(this.desc)
        .fontSize('12fp')
        .fontColor($r('app.color.text_secondary'))
        .lineHeight('18fp')
        .width('100%')
    }
    .width('100%')
  }
}

@Component
struct InfoBlock {
  @Prop title: string = '';
  @Prop desc: string = '';

  build() {
    Column({ space: '6vp' }) {
      Text(this.title)
        .fontSize('13fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Medium)
        .width('100%')
      Text(this.desc)
        .fontSize('12fp')
        .fontColor($r('app.color.text_secondary'))
        .lineHeight('18fp')
        .width('100%')
    }
    .width('100%')
    .padding('10vp')
    .backgroundColor($r('app.color.card_elevated'))
    .borderRadius('10vp')
  }
}

@Component
struct ActionChip {
  @Prop label: string = '';
  @Prop accent: ResourceColor = $r('app.color.module3_accent');
  onTap: () => void = (): void => {};

  build() {
    Button(this.label)
      .layoutWeight(1)
      .height('34vp')
      .fontSize('12fp')
      .fontColor($r('app.color.text_on_accent'))
      .backgroundColor(this.accent)
      .borderRadius('17vp')
      .onClick((): void => {
        this.onTap();
      })
  }
}

@Component
struct ThresholdSlider {
  @Prop title: string = '';
  @Prop unit: string = '';
  @Link value: number;
  @Prop min: number = 0;
  @Prop max: number = 1;
  @Prop step: number = 0.1;

  build() {
    Column({ space: '8vp' }) {
      Row({ space: '8vp' }) {
        Text(this.title)
          .layoutWeight(1)
          .fontSize('13fp')
          .fontColor($r('app.color.text'))
        Text(`${this.value.toFixed(this.step >= 1 ? 0 : 2)} ${this.unit}`)
          .fontSize('12fp')
          .fontColor($r('app.color.module3_accent'))
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      Slider({
        value: this.value,
        min: this.min,
        max: this.max,
        step: this.step,
        style: SliderStyle.InSet
      })
        .blockColor($r('app.color.module3_accent'))
        .trackColor($r('app.color.track_background'))
        .selectedColor($r('app.color.module3_accent'))
        .onChange((val: number) => {
          this.value = val;
        })
    }
    .width('100%')
  }
}
