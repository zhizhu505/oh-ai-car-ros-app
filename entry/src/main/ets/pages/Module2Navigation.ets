import promptAction from '@ohos.promptAction';
import {
  PatrolPoint,
  PatrolTaskState,
  patrolTaskStateText
} from '../model/PatrolModels';
import { ModuleTabBar, InfoCard } from '../components/PageHeader';
import { ButtonShadow, CardShadow } from '../styles/styles';
import { PatrolStore } from '../store/PatrolStore';
import { PatrolCommandUtils } from '../tcp/PatrolCommandUtils';

@Entry
@Component
struct Module2Navigation {
  @State currentTabIndex: number = 0;
  @State patrolStatusTextValue: string = '等待连接';
  @State currentPointId: string = 'P0';
  @State currentPoint: string = 'P0 管廊入口';
  @State nextPointId: string = 'P1';
  @State nextPoint: string = 'P1 入廊检测点';
  @State currentIndex: number = 0;
  @State totalWaypoints: number = 0;
  @State progress: number = 0;
  @State route: string = 'pipeline_route_01';
  @State message: string = '等待小车连接';
  @State online: boolean = false;
  @State taskActive: boolean = false;
  @State hasAlert: boolean = false;
  @State alertPoint: string = '';
  @State alertTitle: string = '';
  @State alertDetail: string = '';
  @State alertCritical: boolean = false;
  @State patrolPoints: PatrolPoint[] = [];
  private tabs: string[] = ['巡检态势', '策略规则', '异常监测'];
  private refreshHandler: () => void = (): void => {
    this.syncFromStore();
  };

  aboutToAppear(): void {
    this.syncFromStore();
    PatrolStore.getInstance().subscribe(this.refreshHandler);
  }

  aboutToDisappear(): void {
    PatrolStore.getInstance().unsubscribe(this.refreshHandler);
  }

  private syncFromStore(): void {
    const store = PatrolStore.getInstance();
    const vehicle = store.vehicle;
    this.online = vehicle.online;
    this.patrolStatusTextValue = patrolTaskStateText(vehicle.taskState);
    this.currentPointId = vehicle.currentPoint;
    this.nextPointId = vehicle.nextPoint;
    this.currentPoint = store.getPointName(vehicle.currentPoint);
    this.nextPoint = vehicle.nextPoint === '-' ? '无' : store.getPointName(vehicle.nextPoint);
    this.currentIndex = vehicle.currentIndex;
    this.totalWaypoints = vehicle.totalWaypoints;
    this.progress = vehicle.progress;
    this.route = vehicle.routeId;
    this.message = vehicle.message;
    this.taskActive = vehicle.taskState === PatrolTaskState.Starting || vehicle.taskState === PatrolTaskState.Running ||
      vehicle.taskState === PatrolTaskState.Paused || vehicle.taskState === PatrolTaskState.Stopping;
    const latestAlert = store.alerts.length > 0 ? store.alerts[0] : undefined;
    this.hasAlert = latestAlert !== undefined;
    if (latestAlert !== undefined) {
      this.alertPoint = latestAlert.point;
      this.alertTitle = latestAlert.category;
      this.alertDetail = latestAlert.message;
      this.alertCritical = latestAlert.level === 'critical';
    }
    this.patrolPoints = store.patrolPoints.map((point: PatrolPoint): PatrolPoint => {
      return { id: point.id, name: point.name, visited: point.visited, abnormal: point.abnormal };
    });
  }

  build() {
    Column({ space: '0vp' }) {
      ModuleTabBar({
        currentIndex: $currentTabIndex,
        tabs: this.tabs,
        accentColor: $r('app.color.module2_accent'),
        title: 'SLAM导航',
        subtitle: '地下管廊路线 · 异常监测 · 安全避障'
      })

      Scroll() {
        Column() {
          if (this.currentTabIndex === 0) {
            this.RouteView()
          } else if (this.currentTabIndex === 1) {
            this.ControlView()
          } else {
            this.AbnormalView()
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
  RouteView() {
    Column({ space: '12vp' }) {
      this.PatrolMapCard()

      Column({ space: '10vp' }) {
        Row({ space: '8vp' }) {
          Text(this.patrolStatusTextValue)
            .fontSize('11fp')
            .fontColor(Color.White)
            .backgroundColor($r('app.color.alert_warning'))
            .padding({ left: '9vp', right: '9vp', top: '5vp', bottom: '5vp' })
            .borderRadius('9vp')
          Text(this.online ? '设备已连接' : '等待连接')
            .fontSize('11fp')
            .fontColor(this.online ? $r('app.color.module2_accent') : $r('app.color.text_secondary'))
            .padding({ left: '8vp', right: '8vp', top: '4vp', bottom: '4vp' })
            .backgroundColor($r('app.color.module2_accent') + '22')
            .borderRadius('8vp')
        }
        .width('100%')

        Row({ space: '10vp' }) {
          NavigationMetric({ label: '当前点位', value: this.currentPoint, accent: $r('app.color.alert_warning') })
            .layoutWeight(1)
          NavigationMetric({ label: '下一点位', value: this.nextPoint, accent: $r('app.color.module2_accent') })
            .layoutWeight(1)
        }
        .width('100%')

        Column({ space: '5vp' }) {
          Row() {
            Text(`巡检进度 · 已完成 ${this.currentIndex} / ${this.totalWaypoints} 点`)
              .fontSize('12fp')
              .fontColor($r('app.color.text_secondary'))
              .layoutWeight(1)
            Text(`${this.progress}%`)
              .fontSize('14fp')
              .fontColor($r('app.color.text'))
              .fontWeight(FontWeight.Bold)
          }
          .width('100%')
          Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
            .width('100%')
            .height('6vp')
            .color($r('app.color.module2_accent'))
            .backgroundColor($r('app.color.divider'))
            .borderRadius('3vp')
        }
      }
      .width('100%')
      .padding('12vp')
      .backgroundColor($r('app.color.card_background'))
      .borderRadius('14vp')
      .border({ width: '1vp', color: $r('app.color.divider') })
      .shadow(CardShadow)

      Column({ space: '8vp' }) {
        Text('巡检航点状态')
          .fontSize('15fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Bold)
          .width('100%')
        Row({ space: '8vp' }) {
          Column({ space: '8vp' }) {
            ForEach(this.patrolPoints.slice(0, 4), (point: PatrolPoint) => {
              PatrolPointCard({ point: point, isCurrent: point.id === this.currentPointId, isNext: point.id === this.nextPointId })
            }, (point: PatrolPoint) => point.id)
          }
          .layoutWeight(1)

          Column({ space: '8vp' }) {
            ForEach(this.patrolPoints.slice(4), (point: PatrolPoint) => {
              PatrolPointCard({ point: point, isCurrent: point.id === this.currentPointId, isNext: point.id === this.nextPointId })
            }, (point: PatrolPoint) => point.id)
          }
          .layoutWeight(1)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding({ left: '14vp', right: '14vp', top: '12vp', bottom: '18vp' })
  }

  @Builder
  PatrolMapCard() {
    Column({ space: '8vp' }) {
      Row() {
        Column({ space: '2vp' }) {
          Text('管廊巡检地图')
            .fontSize('16fp')
            .fontColor($r('app.color.text'))
            .fontWeight(FontWeight.Bold)
          Text('P0 入口 → P6 终点 · P4 异物 · P5 障碍')
            .fontSize('11fp')
            .fontColor($r('app.color.text_secondary'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text('巡检路线')
          .fontSize('10fp')
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .backgroundColor($r('app.color.module2_accent'))
          .padding({ left: '8vp', right: '8vp', top: '4vp', bottom: '4vp' })
          .borderRadius('8vp')
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Stack({ alignContent: Alignment.Center }) {
        Image($r('app.media.pipeline_patrol_map'))
          .width('100%')
          .height('360vp')
          .objectFit(ImageFit.Contain)
          .borderRadius('10vp')
      }
      .width('100%')
      .height('360vp')
      .backgroundColor('#F7F7F5')
      .borderRadius('10vp')
      .clip(true)

      Text('橙色路线为预设巡检路径；红色标注为当前异常监测区域')
        .fontSize('11fp')
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding('12vp')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('14vp')
    .border({ width: '1vp', color: $r('app.color.divider') })
    .shadow(CardShadow)
  }

  @Builder
  ControlView() {
    Column({ space: '10vp' }) {
      InfoCard({ title: '巡检任务状态' }) {
        Column({ space: '6vp' }) {
          Text(this.message)
            .fontSize('13fp')
            .fontColor($r('app.color.text'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(`当前路线：${this.route}`)
            .fontSize('13fp')
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }

      InfoCard({ title: '导航策略' }) {
        Column({ space: '6vp' }) {
          StrategyItem({ icon: '📏', text: '窄通道自动降速' })
          StrategyItem({ icon: '🛡️', text: '靠近管线、阀门保持安全距离' })
          StrategyItem({ icon: '🔄', text: '异常物体触发局部绕行与人工复核' })
          StrategyItem({ icon: '📸', text: '到点采集气体、温湿度与视觉数据' })
        }
      }

      Column({ space: '10vp' }) {
        Text('控制指令')
          .fontSize('15fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .maxLines(1)

        Text('巡检任务由首页统一启动；状态与点位信息由小车实时回传。')
          .fontSize('12fp')
          .fontColor($r('app.color.text_secondary'))
          .width('100%')

        if (this.taskActive) {
          ActionButton({ title: '停止巡检', bgColor: $r('app.color.alert_critical'), action: 'stop', onAction: this.sendCommand })
        } else {
          Text('当前没有执行中的巡检任务，请在首页启动巡检。')
            .fontSize('12fp')
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .padding('12vp')
            .backgroundColor($r('app.color.card_elevated'))
            .borderRadius('10vp')
        }
      }
    }
    .padding({ left: '14vp', right: '14vp', top: '10vp', bottom: '12vp' })
    .width('100%')
  }

  @Builder
  AbnormalView() {
    Column({ space: '10vp' }) {
      InfoCard({ title: '异常监测记录' }) {
        Column({ space: '10vp' }) {
          if (this.hasAlert) {
            PatrolAlertCard({
              point: this.alertPoint,
              title: this.alertTitle,
              detail: this.alertDetail,
              level: this.alertCritical ? '严重' : '预警',
              color: this.alertCritical ? $r('app.color.alert_critical') : $r('app.color.alert_warning')
            })
          } else {
            Text('暂无实时告警')
              .fontSize('14fp')
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding('22vp')
              .backgroundColor($r('app.color.card_elevated'))
              .borderRadius('10vp')
          }
        }
      }
    }
    .padding({ left: '14vp', right: '14vp', top: '10vp' })
    .width('100%')
  }

  private async sendCommand(action: string): Promise<void> {
    if (!this.online) {
      promptAction.showToast({ message: '小车未连接，无法发送巡检指令' });
      return;
    }
    if (action === 'stop') {
      const result = await PatrolCommandUtils.stopPatrol();
      if (result) {
        PatrolStore.getInstance().updateVehicle({ message: '停止指令已发送，等待小车状态确认' });
      } else {
        promptAction.showToast({ message: '停止指令发送失败' });
      }
    }
  }
}

@Component
struct NavigationMetric {
  @Prop label: string = '';
  @Prop value: string = '';
  @Prop accent: ResourceColor = $r('app.color.module2_accent');

  build() {
    Column({ space: '4vp' }) {
      Text(this.label)
        .fontSize('11fp')
        .fontColor($r('app.color.text_secondary'))
      Text(this.value)
        .fontSize('13fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .alignItems(HorizontalAlign.Start)
    .padding({ left: '10vp', right: '10vp', top: '8vp', bottom: '8vp' })
    .backgroundColor($r('app.color.card_elevated'))
    .border({ width: '1vp', color: this.accent })
    .borderRadius('10vp')
  }
}

@Component
struct PatrolPointCard {
  @Prop point: PatrolPoint = { id: '', name: '', visited: false, abnormal: false };
  @Prop isCurrent: boolean = false;
  @Prop isNext: boolean = false;

  build() {
    Row({ space: '10vp' }) {
      Column({ space: '4vp' }) {
        Text(this.point.id)
          .fontSize('14fp')
          .fontColor(Color.White)
          .backgroundColor(this.isCurrent ? $r('app.color.alert_warning') :
            (this.point.abnormal ? $r('app.color.alert_critical') :
              (this.point.visited ? $r('app.color.alert_normal') : $r('app.color.button_primary'))))
          .width('40vp')
          .height('40vp')
          .textAlign(TextAlign.Center)
          .borderRadius('10vp')
          .fontWeight(FontWeight.Bold)
      }
      .alignItems(HorizontalAlign.Center)
      Column({ space: '2vp' }) {
        Text(this.point.name)
          .fontSize('14fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.isCurrent ? '当前巡检中' : (this.point.abnormal ? '异常待复核' :
          (this.isNext ? '下一巡检点' : (this.point.visited ? '已巡检' : '待巡检'))))
          .fontSize('12fp')
          .fontColor(this.isCurrent ? $r('app.color.alert_warning') :
            (this.point.abnormal ? $r('app.color.alert_critical') :
              (this.point.visited ? $r('app.color.alert_normal') : $r('app.color.text_secondary'))))
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      if (this.isCurrent) {
        Text('●')
          .fontSize('18fp')
          .fontColor($r('app.color.alert_warning'))
      } else if (this.point.abnormal) {
        Text('⚠')
          .fontSize('18fp')
      } else if (this.point.visited) {
        Text('✓')
          .fontSize('18fp')
          .fontColor($r('app.color.alert_normal'))
      }
    }
    .width('100%')
    .padding('11vp')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('12vp')
    .border({ width: '1vp', color: $r('app.color.divider') })
    .shadow(CardShadow)
  }
}

@Component
struct PatrolAlertCard {
  @Prop point: string = '';
  @Prop title: string = '';
  @Prop detail: string = '';
  @Prop level: string = '';
  @Prop color: ResourceColor = $r('app.color.alert_warning');

  build() {
    Column({ space: '5vp' }) {
      Row({ space: '8vp' }) {
        Text(this.level)
          .fontSize('10fp')
          .fontColor(Color.White)
          .backgroundColor(this.color)
          .padding({ left: '7vp', right: '7vp', top: '3vp', bottom: '3vp' })
          .borderRadius('7vp')
        Text(this.title)
          .fontSize('13fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      Text(this.point)
        .fontSize('11fp')
        .fontColor(this.color)
        .maxLines(1)
      Text(this.detail)
        .fontSize('12fp')
        .fontColor($r('app.color.text_secondary'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding('10vp')
    .backgroundColor($r('app.color.card_elevated'))
    .border({ width: '1vp', color: this.color })
    .borderRadius('10vp')
  }
}

@Component
struct StrategyItem {
  @Prop icon: string = '';
  @Prop text: string = '';

  build() {
    Row({ space: '10vp' }) {
      Text(this.icon)
        .fontSize('16fp')
      Text(this.text)
        .fontSize('13fp')
        .fontColor($r('app.color.text'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .width('100%')
  }
}

@Component
struct ActionButton {
  @Prop title: string = '';
  @Prop bgColor: ResourceColor = $r('app.color.button_primary');
  @Prop action: string = '';
  onAction: (action: string) => void = () => { };

  build() {
    Button(this.title)
      .width('100%')
      .height('44vp')
      .fontSize('15fp')
      .fontColor(Color.White)
      .backgroundColor(this.bgColor)
      .borderRadius('22vp')
      .shadow(ButtonShadow)
      .onClick((): void => {
        this.onAction(this.action);
      })
  }
}
