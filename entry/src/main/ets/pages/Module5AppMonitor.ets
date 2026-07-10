import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import {
  ControlMode,
  PatrolPoint,
  PatrolStatus,
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
        subtitle: '巡检状态展示 / 异常告警 / 手动与自动模式切换',
        accentColor: $r('app.color.module5_accent')
      })

      ModuleTabBar({ currentIndex: $currentTabIndex, tabs: this.tabs, accentColor: $r('app.color.module5_accent') })

      if (this.currentTabIndex === 0) {
        this.OverviewView()
      } else if (this.currentTabIndex === 1) {
        this.AllAlertView()
      } else {
        this.ControlView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.window_background'))
  }

  @Builder
  OverviewView() {
    Column({ space: '16vp' }) {
      Row({ space: '12vp' }) {
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
      .padding({ left: '20vp', right: '20vp' })

      InfoCard({ title: '巡检进度' }) {
        Column({ space: '8vp' }) {
          Row({ space: '20vp' }) {
            Column({ space: '2vp' }) {
              Text('当前点位')
                .fontSize('13fp')
                .fontColor($r('app.color.text_secondary'))
              Text(this.currentPoint)
                .fontSize('16fp')
                .fontColor($r('app.color.text'))
                .fontWeight(FontWeight.Medium)
            }
            .alignItems(HorizontalAlign.Start)
            Column({ space: '2vp' }) {
              Text('下一点位')
                .fontSize('13fp')
                .fontColor($r('app.color.text_secondary'))
              Text(this.nextPoint)
                .fontSize('16fp')
                .fontColor($r('app.color.text'))
                .fontWeight(FontWeight.Medium)
            }
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          Column({ space: '4vp' }) {
            Row({ space: '12vp' }) {
              Text('进度')
                .fontSize('13fp')
                .fontColor($r('app.color.text_secondary'))
              Text(`${this.progress}%`)
                .fontSize('16fp')
                .fontColor($r('app.color.text'))
                .fontWeight(FontWeight.Medium)
            }
            Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
              .width('100%')
              .height('8vp')
              .color($r('app.color.module5_accent'))
              .backgroundColor($r('app.color.divider'))
              .borderRadius('4vp')
          }
          Text(this.message)
            .fontSize('14fp')
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
        }
      }

      InfoCard({ title: '巡检闭环流程' }) {
        Column({ space: '8vp' }) {
          Text('建图 → 路线巡检 → 环境采集 → 雷达避障 → 视觉识别 → APP告警 → 返回巡检')
            .fontSize('14fp')
            .fontColor($r('app.color.text'))
            .width('100%')
          Scroll() {
            Row({ space: '10vp' }) {
              ForEach(this.patrolPoints, (point: PatrolPoint) => {
                Column({ space: '4vp' }) {
                  Text(point.id)
                    .fontSize('14fp')
                    .fontColor(Color.White)
                    .backgroundColor(point.abnormal ? $r('app.color.alert_critical') :
                      (point.visited ? $r('app.color.alert_normal') : $r('app.color.button_primary')))
                    .width('80vp')
                    .height('44vp')
                    .textAlign(TextAlign.Center)
                    .borderRadius('10vp')
                  Text(point.name)
                    .fontSize('12fp')
                    .fontColor($r('app.color.text'))
                    .maxLines(1)
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

      Blank()
    }
    .layoutWeight(1)
  }

  @Builder
  AllAlertView() {
    Column() {
      Row() {
        Blank()
        Button('清空告警')
          .width('100vp')
          .height('40vp')
          .fontSize('14fp')
          .fontColor($r('app.color.text'))
          .backgroundColor($r('app.color.button_secondary'))
          .borderRadius('20vp')
          .shadow(ButtonShadow)
          .onClick((): void => {
            PatrolStore.getInstance().clearAlerts();
            promptAction.showToast({ message: '告警已清空' });
          })
      }
      .width('100%')
      .padding({ left: '20vp', right: '20vp', top: '8vp' })

      ModuleAlertList({
        category: '',
        emptyHint: '暂无异常告警，巡检数据将实时显示在这里'
      })
    }
    .layoutWeight(1)
    .padding({ left: '20vp', right: '20vp' })
  }

  @Builder
  ControlView() {
    Column({ space: '16vp' }) {
      InfoCard({ title: '模式切换' }) {
        Row({ space: '12vp' }) {
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

      InfoCard({ title: '巡检控制' }) {
        Column({ space: '12vp' }) {
          Row({ space: '10vp' }) {
            ControlButton({ title: '开始巡检', bgColor: $r('app.color.alert_normal'), action: 'start', sendCommand: this.sendCommand })
            ControlButton({ title: '暂停', bgColor: $r('app.color.alert_warning'), action: 'pause', sendCommand: this.sendCommand })
            ControlButton({ title: '返回起点', bgColor: $r('app.color.button_primary'), action: 'return', sendCommand: this.sendCommand })
          }
        }
      }

      InfoCard({ title: '遥控入口' }) {
        Row({ space: '12vp' }) {
          NavButton({ title: '手动遥控', icon: '🎮', url: 'pages/RemoteControl' })
          NavButton({ title: '麦科朗姆轮', icon: '⚙️', url: 'pages/MecanumWheel' })
        }
      }

      Blank()
    }
    .layoutWeight(1)
  }

  private async switchMode(mode: ControlMode): Promise<void> {
    const cmdMode = mode === ControlMode.Auto ? 'auto' : 'manual';
    const ok = await PatrolCommandUtils.setControlMode(cmdMode);
    PatrolStore.getInstance().updateVehicle({ controlMode: mode });
    promptAction.showToast({
      message: ok ? (mode === ControlMode.Auto ? '已切换自动巡检' : '已切换手动遥控') : '模式已切换（请检查网络）'
    });
  }

  private async sendCommand(action: string): Promise<void> {
    const store = PatrolStore.getInstance();
    let ok = false;
    if (action === 'start') {
      ok = await PatrolCommandUtils.startPatrol('warehouse_A');
      store.updateVehicle({ controlMode: ControlMode.Auto, patrolStatus: PatrolStatus.Patrolling, message: '巡检已启动' });
      store.resetPatrolPoints();
    } else if (action === 'pause') {
      ok = await PatrolCommandUtils.pausePatrol();
      store.updateVehicle({ patrolStatus: PatrolStatus.Paused, message: '巡检已暂停' });
    } else if (action === 'return') {
      ok = await PatrolCommandUtils.returnHome();
      store.updateVehicle({ patrolStatus: PatrolStatus.Returning, message: '正在返回起点' });
    }
    promptAction.showToast({ message: ok ? '命令发送成功' : '命令已记录，请检查网络' });
  }
}

@Component
struct OverviewCard {
  @Prop title: string = '';
  @Prop value: string = '';
  @Prop bgColor: ResourceColor = $r('app.color.card_background');
  @Prop icon: string = '';

  build() {
    Column({ space: '8vp' }) {
      Text(this.icon)
        .fontSize('24fp')
      Text(this.title)
        .fontSize('13fp')
        .fontColor($r('app.color.text_secondary'))
      Text(this.value)
        .fontSize('15fp')
        .fontColor(Color.White)
        .backgroundColor(this.bgColor)
        .padding({ left: '10vp', right: '10vp', top: '6vp', bottom: '6vp' })
        .borderRadius('10vp')
    }
    .layoutWeight(1)
    .padding('14vp')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('14vp')
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
      .height('48vp')
      .fontSize('15fp')
      .fontColor(this.active ? Color.White : $r('app.color.text'))
      .backgroundColor(this.active ? $r('app.color.module5_accent') : $r('app.color.card_elevated'))
      .borderRadius('24vp')
      .shadow(this.active ? ButtonShadow : CardShadow)
      .onClick(this.action)
  }
}

@Component
struct ControlButton {
  @Prop title: string = '';
  @Prop bgColor: ResourceColor = $r('app.color.button_primary');
  @Prop action: string = '';
  @Link sendCommand: (action: string) => void;

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
        this.sendCommand(this.action);
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
      Column({ space: '6vp' }) {
        Text(this.icon)
          .fontSize('24fp')
        Text(this.title)
          .fontSize('14fp')
          .fontColor($r('app.color.text'))
      }
    }
    .width('100%')
    .height('80vp')
    .backgroundColor($r('app.color.card_elevated'))
    .borderRadius('16vp')
    .shadow(CardShadow)
    .onClick((): void => {
      router.pushUrl({ url: this.url });
    })
  }
}