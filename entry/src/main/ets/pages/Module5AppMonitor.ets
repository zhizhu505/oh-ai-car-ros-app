import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import {
  ControlMode,
  PatrolPoint,
  patrolStatusText
} from '../model/PatrolModels';
import { PatrolStore } from '../store/PatrolStore';
import { PatrolCommandUtils } from '../tcp/PatrolCommandUtils';
import { PageHeader, ModuleTabBar, InfoCard } from '../components/PageHeader';
import { ModuleAlertList } from '../components/ModuleAlertList';
import { onlineColor, patrolStatusColor } from '../utils/PatrolUiUtils';
import { ButtonShadow, CardShadow } from '../styles/styles';

@Entry
@Component
struct Module5AppMonitor {
  @State currentTabIndex: number = 0;
  @State online: boolean = false;
  @State patrolStatusTextValue: string = '空闲';
  @State currentPoint: string = 'P1';
  @State nextPoint: string = 'P2';
  @State progress: number = 0;
  @State controlMode: ControlMode = ControlMode.Manual;
  @State message: string = '等待连接';
  @State patrolPoints: PatrolPoint[] = [];
  @State alertCount: number = 0;
  private tabs: string[] = ['巡检总览', '全部告警', '远程控制'];
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
    const store = PatrolStore.getInstance();
    this.online = store.vehicle.online;
    this.patrolStatusTextValue = patrolStatusText(store.vehicle.patrolStatus);
    this.currentPoint = store.getPointName(store.vehicle.currentPoint);
    this.nextPoint = store.getPointName(store.vehicle.nextPoint);
    this.progress = store.vehicle.progress;
    this.controlMode = store.vehicle.controlMode;
    this.message = store.vehicle.message;
    this.alertCount = store.alerts.length;
    this.patrolPoints = store.patrolPoints.map((p: PatrolPoint): PatrolPoint => {
      return { id: p.id, name: p.name, visited: p.visited, abnormal: p.abnormal };
    });
  }

  build() {
    Column({ space: '0vp' }) {
      PageHeader({
        title: '模块5：鸿蒙 APP 监控',
        subtitle: '巡检状态展示 / 异常告警 / 模式切换',
        accentColor: $r('app.color.module5_accent')
      })

      ModuleTabBar({ currentIndex: $currentTabIndex, tabs: this.tabs, accentColor: $r('app.color.module5_accent') })

      Scroll() {
        Column() {
          if (this.currentTabIndex === 0) {
            this.OverviewView()
          } else if (this.currentTabIndex === 1) {
            this.AllAlertView()
          } else {
            this.ControlView()
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
  OverviewView() {
    Column({ space: '10vp' }) {
      Row({ space: '10vp' }) {
        OverviewCard({
          title: '连接状态',
          value: this.online ? '在线' : '离线',
          bgColor: onlineColor(this.online),
          icon: this.online ? '🟢' : '🔴'
        })
        OverviewCard({
          title: '巡检状态',
          value: this.patrolStatusTextValue,
          bgColor: patrolStatusColor(PatrolStore.getInstance().vehicle.patrolStatus),
          icon: '🚗'
        })
        OverviewCard({
          title: '异常数量',
          value: `${this.alertCount} 条`,
          bgColor: this.alertCount > 0 ? $r('app.color.alert_warning') : $r('app.color.alert_normal'),
          icon: '⚠️'
        })
        OverviewCard({
          title: '控制模式',
          value: this.controlMode === ControlMode.Auto ? '自动' : '手动',
          bgColor: $r('app.color.status_active'),
          icon: this.controlMode === ControlMode.Auto ? '🤖' : '🎮'
        })
      }
      .padding({ left: '15vp', right: '15vp' })

      Column() {
        InfoCard({ title: '巡检进度' }) {
          Column({ space: '6vp' }) {
            Row({ space: '16vp' }) {
              Column({ space: '2vp' }) {
                Text('当前点位')
                  .fontSize('12fp')
                  .fontColor($r('app.color.text_secondary'))
                Text(this.currentPoint)
                  .fontSize('14fp')
                  .fontColor($r('app.color.text'))
                  .fontWeight(FontWeight.Medium)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .alignItems(HorizontalAlign.Start)
              Column({ space: '2vp' }) {
                Text('下一点位')
                  .fontSize('12fp')
                  .fontColor($r('app.color.text_secondary'))
                Text(this.nextPoint)
                  .fontSize('14fp')
                  .fontColor($r('app.color.text'))
                  .fontWeight(FontWeight.Medium)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            Column({ space: '4vp' }) {
              Row({ space: '10vp' }) {
                Text('进度')
                  .fontSize('12fp')
                  .fontColor($r('app.color.text_secondary'))
                Text(`${this.progress}%`)
                  .fontSize('14fp')
                  .fontColor($r('app.color.text'))
                  .fontWeight(FontWeight.Medium)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
                .width('100%')
                .height('6vp')
                .color($r('app.color.module5_accent'))
                .backgroundColor($r('app.color.divider'))
                .borderRadius('3vp')
            }
            Text(this.message)
              .fontSize('13fp')
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
      }
      .padding({ left: '15vp', right: '15vp' })

      Column() {
        InfoCard({ title: '巡检闭环流程' }) {
          Column({ space: '6vp' }) {
            Text('建图 → 路线巡检 → 环境采集 → 雷达避障 → 视觉识别 → APP告警')
              .fontSize('13fp')
              .fontColor($r('app.color.text'))
              .width('100%')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Scroll() {
              Row({ space: '8vp' }) {
                ForEach(this.patrolPoints, (point: PatrolPoint) => {
                  Column({ space: '3vp' }) {
                    Text(point.id)
                      .fontSize('12fp')
                      .fontColor(Color.White)
                      .backgroundColor(point.abnormal ? $r('app.color.alert_critical') :
                        (point.visited ? $r('app.color.alert_normal') : $r('app.color.button_primary')))
                      .width('70vp')
                      .height('38vp')
                      .textAlign(TextAlign.Center)
                      .borderRadius('8vp')
                      .maxLines(1)
                    Text(point.name)
                      .fontSize('11fp')
                      .fontColor($r('app.color.text'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .textAlign(TextAlign.Center)
                  }
                }, (point: PatrolPoint) => point.id)
              }
              .width('100%')
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
          }
        }
      }
      .padding({ left: '15vp', right: '15vp' })
    }
    .width('100%')
    .padding({ top: '10vp', bottom: '10vp' })
  }

  @Builder
  AllAlertView() {
    Column({ space: '8vp' }) {
      Button('清空告警')
        .width('80vp')
        .height('36vp')
        .fontSize('13fp')
        .fontColor($r('app.color.text'))
        .backgroundColor($r('app.color.button_secondary'))
        .borderRadius('18vp')
        .shadow(ButtonShadow)
        .onClick((): void => {
          PatrolStore.getInstance().clearAlerts();
          promptAction.showToast({ message: '告警已清空' });
        })
        .alignSelf(ItemAlign.End)

      ModuleAlertList({
        category: '',
        emptyHint: '暂无异常告警，巡检数据将实时显示在这里'
      })
    }
    .width('100%')
    .padding({ left: '15vp', right: '15vp', top: '10vp' })
  }

  @Builder
  ControlView() {
    Column({ space: '10vp' }) {
      Column() {
        InfoCard({ title: '模式切换' }) {
          Row({ space: '10vp' }) {
            ModeButton({
              title: '手动模式',
              active: this.controlMode === ControlMode.Manual,
              action: () => { this.switchMode(ControlMode.Manual); }
            })
            ModeButton({
              title: '自动巡检',
              active: this.controlMode === ControlMode.Auto,
              action: () => { this.switchMode(ControlMode.Auto); }
            })
          }
        }
      }
      .padding({ left: '15vp', right: '15vp' })

      Column() {
        InfoCard({ title: '巡检控制' }) {
          Column({ space: '10vp' }) {
            Row({ space: '8vp' }) {
              ControlButton({ title: '开始巡检', bgColor: $r('app.color.alert_normal'), action: 'start', onAction: this.sendCommand })
              ControlButton({ title: '暂停', bgColor: $r('app.color.alert_warning'), action: 'pause', onAction: this.sendCommand })
              ControlButton({ title: '返回起点', bgColor: $r('app.color.button_primary'), action: 'return', onAction: this.sendCommand })
            }
          }
        }
      }
      .padding({ left: '15vp', right: '15vp' })

      Column() {
        InfoCard({ title: '遥控入口' }) {
          Row({ space: '10vp' }) {
            NavButton({ title: '手动遥控', icon: '🎮', url: 'pages/RemoteControl' })
            NavButton({ title: '麦科朗姆轮', icon: '⚙️', url: 'pages/MecanumWheel' })
          }
        }
      }
      .padding({ left: '15vp', right: '15vp' })
    }
    .width('100%')
    .padding({ top: '10vp', bottom: '10vp' })
  }

  private async switchMode(mode: ControlMode): Promise<void> {
    const store = PatrolStore.getInstance();
    if (mode === ControlMode.Auto) {
      promptAction.showToast({ message: '请通过“开始巡检”启动自动任务' });
      return;
    }
    if (store.vehicle.manualControlLocked) {
      promptAction.showToast({ message: '巡检任务未结束，暂不能切换手动遥控' });
      return;
    }
    store.updateVehicle({ controlMode: ControlMode.Manual });
    promptAction.showToast({ message: '已切换手动遥控' });
  }

  private async sendCommand(action: string): Promise<void> {
    let ok = false;
    if (action === 'start') {
      ok = (await PatrolCommandUtils.startPatrol('pipeline_route_01')).sent;
    } else if (action === 'pause') {
      ok = (await PatrolCommandUtils.pausePatrol()).sent;
    } else if (action === 'return') {
      ok = (await PatrolCommandUtils.returnHome()).sent;
    }
    promptAction.showToast({ message: ok ? '请求已发送，等待 Jetson 确认' : '请求发送失败，请检查网络' });
  }
}

@Component
struct OverviewCard {
  @Prop title: string = '';
  @Prop value: string = '';
  @Prop bgColor: ResourceColor = $r('app.color.card_background');
  @Prop icon: string = '';

  build() {
    Column({ space: '6vp' }) {
      Text(this.icon)
        .fontSize('22fp')
      Text(this.title)
        .fontSize('12fp')
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(this.value)
        .fontSize('14fp')
        .fontColor(Color.White)
        .backgroundColor(this.bgColor)
        .padding({ left: '8vp', right: '8vp', top: '5vp', bottom: '5vp' })
        .borderRadius('8vp')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .padding('12vp')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('12vp')
    .border({ width: '1vp', color: $r('app.color.divider') })
    .shadow(CardShadow)
    .alignItems(HorizontalAlign.Center)
  }
}

@Component
struct ModeButton {
  @Prop title: string = '';
  @Prop active: boolean = false;
  action: () => void = () => { };

  build() {
    Button(this.title)
      .width('100%')
      .height('38vp')
      .fontSize('14fp')
      .fontColor(this.active ? Color.White : $r('app.color.text'))
      .backgroundColor(this.active ? $r('app.color.module5_accent') : $r('app.color.card_elevated'))
      .borderRadius('19vp')
      .shadow(this.active ? ButtonShadow : CardShadow)
      .onClick(this.action)
  }
}

@Component
struct ControlButton {
  @Prop title: string = '';
  @Prop bgColor: ResourceColor = $r('app.color.button_primary');
  @Prop action: string = '';
  onAction: (action: string) => void = () => { };

  build() {
    Button(this.title)
      .width('100%')
      .height('38vp')
      .fontSize('14fp')
      .fontColor(Color.White)
      .backgroundColor(this.bgColor)
      .borderRadius('19vp')
      .shadow(ButtonShadow)
      .onClick((): void => {
        this.onAction(this.action);
      })
  }
}

@Component
struct NavButton {
  @Prop title: string = '';
  @Prop icon: string = '';
  @Prop url: string = '';

  build() {
    Button() {
      Column({ space: '4vp' }) {
        Text(this.icon)
          .fontSize('22fp')
        Text(this.title)
          .fontSize('13fp')
          .fontColor($r('app.color.text'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }
    .width('100%')
    .height('72vp')
    .backgroundColor($r('app.color.card_elevated'))
    .borderRadius('12vp')
    .shadow(CardShadow)
    .onClick((): void => {
      router.pushUrl({ url: this.url });
    })
  }
}
