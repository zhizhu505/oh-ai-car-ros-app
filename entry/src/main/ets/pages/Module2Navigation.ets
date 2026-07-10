import promptAction from '@ohos.promptAction';
import {
  ALERT_CATEGORY_PATROL,
  ControlMode,
  PatrolPoint,
  PatrolStatus,
  patrolStatusText
} from '../model/PatrolModels';
import { PatrolStore } from '../store/PatrolStore';
import { PatrolCommandUtils } from '../tcp/PatrolCommandUtils';
import { PageHeader, ModuleTabBar, InfoCard } from '../components/PageHeader';
import { ModuleAlertList } from '../components/ModuleAlertList';
import { patrolStatusColor } from '../utils/PatrolUiUtils';
import { ButtonShadow, CardShadow } from '../styles/styles';

@Entry
@Component
struct Module2Navigation {
  @State currentTabIndex: number = 0;
  @State patrolStatusTextValue: string = '空闲';
  @State currentPoint: string = 'P1';
  @State nextPoint: string = 'P2';
  @State progress: number = 0;
  @State route: string = 'warehouse_A';
  @State message: string = '等待连接';
  @State patrolPoints: PatrolPoint[] = [];
  private tabs: string[] = ['巡检路线', '导航控制', '异常点位'];
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
    this.patrolStatusTextValue = patrolStatusText(store.vehicle.patrolStatus);
    this.currentPoint = store.getPointName(store.vehicle.currentPoint);
    this.nextPoint = store.getPointName(store.vehicle.nextPoint);
    this.progress = store.vehicle.progress;
    this.route = store.vehicle.route;
    this.message = store.vehicle.message;
    this.patrolPoints = store.patrolPoints.map((p: PatrolPoint): PatrolPoint => {
      return { id: p.id, name: p.name, visited: p.visited, abnormal: p.abnormal };
    });
  }

  build() {
    Column({ space: '0vp' }) {
      PageHeader({
        title: '模块2：SLAM 建图与导航',
        subtitle: '仓库地图 / 固定巡检点 / 多点自动导航',
        accentColor: $r('app.color.module2_accent')
      })

      ModuleTabBar({ currentIndex: $currentTabIndex, tabs: this.tabs, accentColor: $r('app.color.module2_accent') })

      if (this.currentTabIndex === 0) {
        this.RouteView()
      } else if (this.currentTabIndex === 1) {
        this.ControlView()
      } else {
        this.AbnormalView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.window_background'))
  }

  @Builder
  RouteView() {
    Column({ space: '16vp' }) {
      Row({ space: '16vp' }) {
        Column({ space: '8vp' }) {
          Row({ space: '12vp' }) {
            Text(this.patrolStatusTextValue)
              .fontSize('18fp')
              .fontColor(Color.White)
              .backgroundColor(patrolStatusColor(PatrolStore.getInstance().vehicle.patrolStatus))
              .padding({ left: '14vp', right: '14vp', top: '10vp', bottom: '10vp' })
              .borderRadius('12vp')
          }
          .width('100%')
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
              Text('巡检进度')
                .fontSize('13fp')
                .fontColor($r('app.color.text_secondary'))
              Text(`${this.progress}%`)
                .fontSize('14fp')
                .fontColor($r('app.color.text'))
                .fontWeight(FontWeight.Medium)
            }
            Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
              .width('100%')
              .height('6vp')
              .color($r('app.color.button_primary'))
              .backgroundColor($r('app.color.divider'))
              .borderRadius('3vp')
          }
        }
        .layoutWeight(1)
        .padding('16vp')
        .backgroundColor($r('app.color.card_background'))
        .borderRadius('16vp')
        .border({ width: '1vp', color: $r('app.color.divider') })
        .shadow(CardShadow)
      }
      .padding({ left: '20vp', right: '20vp' })

      Column({ space: '8vp' }) {
        Text('仓库巡检点列表')
          .fontSize('17fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .padding({ left: '20vp' })

        Scroll() {
          Column({ space: '10vp' }) {
            ForEach(this.patrolPoints, (point: PatrolPoint) => {
              PatrolPointCard({ point: point })
            }, (point: PatrolPoint) => point.id)
          }
          .width('100%')
          .padding({ left: '20vp', right: '20vp' })
        }
        .layoutWeight(1)
      }
    }
    .layoutWeight(1)
  }

  @Builder
  ControlView() {
    Column({ space: '16vp' }) {
      InfoCard({ title: '当前状态' }) {
        Column({ space: '8vp' }) {
          Text(this.message)
            .fontSize('15fp')
            .fontColor($r('app.color.text'))
          Text(`当前路线：${this.route}`)
            .fontSize('14fp')
            .fontColor($r('app.color.text_secondary'))
        }
      }

      InfoCard({ title: '导航策略' }) {
        Column({ space: '8vp' }) {
          StrategyItem({ icon: '📏', text: '窄通道自动降速' })
          StrategyItem({ icon: '🛡️', text: '靠近货架保持安全距离' })
          StrategyItem({ icon: '🔄', text: '导航失败重新规划或跳过当前点' })
          StrategyItem({ icon: '📸', text: '到点停留采集环境/视觉数据' })
        }
      }

      Column({ space: '12vp' }) {
        Text('控制指令')
          .fontSize('17fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .padding({ left: '20vp' })

        Row({ space: '10vp' }) {
          ActionButton({ title: '开始巡检', bgColor: $r('app.color.alert_normal'), action: 'start', sendCommand: this.sendCommand })
          ActionButton({ title: '暂停', bgColor: $r('app.color.alert_warning'), action: 'pause', sendCommand: this.sendCommand })
          ActionButton({ title: '继续', bgColor: $r('app.color.button_primary'), action: 'resume', sendCommand: this.sendCommand })
        }
        .padding({ left: '20vp', right: '20vp' })

        Row({ space: '10vp' }) {
          ActionButton({ title: '返回起点', bgColor: $r('app.color.button_primary'), action: 'return', sendCommand: this.sendCommand })
          ActionButton({ title: '停止巡检', bgColor: $r('app.color.alert_critical'), action: 'stop', sendCommand: this.sendCommand })
        }
        .padding({ left: '20vp', right: '20vp' })
      }

      Blank()
    }
    .layoutWeight(1)
  }

  @Builder
  AbnormalView() {
    Column() {
      ModuleAlertList({
        category: ALERT_CATEGORY_PATROL,
        emptyHint: '暂无巡检异常点位记录'
      })
    }
    .layoutWeight(1)
    .padding({ left: '20vp', right: '20vp' })
  }

  private async sendCommand(action: string): Promise<void> {
    const store = PatrolStore.getInstance();
    let ok = false;
    if (action === 'start') {
      ok = await PatrolCommandUtils.startPatrol('warehouse_A');
      store.updateVehicle({
        controlMode: ControlMode.Auto,
        patrolStatus: PatrolStatus.Patrolling,
        message: '已发送开始巡检命令'
      });
      store.resetPatrolPoints();
    } else if (action === 'pause') {
      ok = await PatrolCommandUtils.pausePatrol();
      store.updateVehicle({ patrolStatus: PatrolStatus.Paused, message: '已发送暂停命令' });
    } else if (action === 'resume') {
      ok = await PatrolCommandUtils.resumePatrol();
      store.updateVehicle({ patrolStatus: PatrolStatus.Patrolling, message: '已发送继续命令' });
    } else if (action === 'return') {
      ok = await PatrolCommandUtils.returnHome();
      store.updateVehicle({ patrolStatus: PatrolStatus.Returning, message: '已发送返回起点命令' });
    } else if (action === 'stop') {
      ok = await PatrolCommandUtils.stopPatrol();
      store.updateVehicle({ patrolStatus: PatrolStatus.Idle, message: '已发送停止命令' });
    }
    promptAction.showToast({ message: ok ? '命令发送成功' : '命令已记录，请检查网络' });
  }
}

@Component
struct PatrolPointCard {
  @Prop point: PatrolPoint = { id: '', name: '', visited: false, abnormal: false };

  build() {
    Row({ space: '12vp' }) {
      Column({ space: '4vp' }) {
        Text(this.point.id)
          .fontSize('16fp')
          .fontColor(Color.White)
          .backgroundColor(this.point.abnormal ? $r('app.color.alert_critical') :
            (this.point.visited ? $r('app.color.alert_normal') : $r('app.color.button_primary')))
          .width('48vp')
          .height('48vp')
          .textAlign(TextAlign.Center)
          .borderRadius('12vp')
          .fontWeight(FontWeight.Bold)
      }
      .alignItems(HorizontalAlign.Center)
      Column({ space: '4vp' }) {
        Text(this.point.name)
          .fontSize('16fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Medium)
        Text(this.point.abnormal ? '异常' : (this.point.visited ? '已巡检' : '待巡检'))
          .fontSize('13fp')
          .fontColor(this.point.abnormal ? $r('app.color.alert_critical') :
            (this.point.visited ? $r('app.color.alert_normal') : $r('app.color.text_secondary')))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      if (this.point.abnormal) {
        Text('⚠')
          .fontSize('20fp')
      } else if (this.point.visited) {
        Text('✓')
          .fontSize('20fp')
          .fontColor($r('app.color.alert_normal'))
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

@Component
struct StrategyItem {
  @Prop icon: string = '';
  @Prop text: string = '';

  build() {
    Row({ space: '10vp' }) {
      Text(this.icon)
        .fontSize('18fp')
      Text(this.text)
        .fontSize('14fp')
        .fontColor($r('app.color.text'))
    }
    .width('100%')
  }
}

interface CommandHandler {
  sendCommand: (action: string) => void;
}

@Component
struct ActionButton {
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