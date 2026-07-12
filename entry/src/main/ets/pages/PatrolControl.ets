import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { ControlMode, PatrolStatus, patrolStatusText } from '../model/PatrolModels';
import { PatrolStore } from '../store/PatrolStore';
import { PatrolCommandUtils } from '../tcp/PatrolCommandUtils';
import { VideoComponents } from '../components/VideoComponents';
import { PageHeader, InfoCard, StatusBadge } from '../components/PageHeader';
import { CardShadow, ButtonShadow } from '../styles/styles';

@Entry
@Component
struct PatrolControl {
  @State controlMode: ControlMode = ControlMode.Manual;
  @State patrolStatusTextValue: string = '空闲';
  @State statusMessage: string = '等待连接';
  @State route: string = 'warehouse_A';
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
    this.controlMode = store.vehicle.controlMode;
    this.patrolStatusTextValue = patrolStatusText(store.vehicle.patrolStatus);
    this.statusMessage = store.vehicle.message;
    this.route = store.vehicle.route;
  }

  build() {
    Row({ space: '12vp' }) {
      Column({ space: '10vp' }) {
        PageHeader({
          title: '巡检控制',
          subtitle: this.statusMessage,
          accentColor: $r('app.color.button_primary')
        })

        InfoCard({ title: '当前状态' }) {
          Column({ space: '10vp' }) {
            Row({ space: '16vp' }) {
              Column({ space: '4vp' }) {
                Text('控制模式')
                  .fontSize('13fp')
                  .fontColor($r('app.color.text_secondary'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.controlMode === ControlMode.Auto ? '自动巡检' : '手动遥控')
                  .fontSize('16fp')
                  .fontColor($r('app.color.text'))
                  .fontWeight(FontWeight.Medium)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              Blank()
              StatusBadge({
                text: this.patrolStatusTextValue,
                bgColor: $r('app.color.status_active')
              })
            }
            Text(`当前路线：${this.route}`)
              .fontSize('14fp')
              .fontColor($r('app.color.text_secondary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }

        InfoCard({ title: '模式切换' }) {
          Row({ space: '12vp' }) {
            Button('手动模式')
              .width('120vp')
              .height('38vp')
              .fontSize('14fp')
              .fontColor($r('app.color.text'))
              .backgroundColor(this.controlMode === ControlMode.Manual ?
                $r('app.color.button_primary') : $r('app.color.card_elevated'))
              .borderRadius('19vp')
              .border({ width: '1vp', color: $r('app.color.divider') })
              .shadow(ButtonShadow)
              .onClick((): void => {
                this.switchMode(ControlMode.Manual);
              })
            Button('自动巡检')
              .width('120vp')
              .height('38vp')
              .fontSize('14fp')
              .fontColor($r('app.color.text'))
              .backgroundColor(this.controlMode === ControlMode.Auto ?
                $r('app.color.button_primary') : $r('app.color.card_elevated'))
              .borderRadius('19vp')
              .border({ width: '1vp', color: $r('app.color.divider') })
              .shadow(ButtonShadow)
              .onClick((): void => {
                this.switchMode(ControlMode.Auto);
              })
          }
        }

        InfoCard({ title: '巡检操作' }) {
          Column({ space: '10vp' }) {
            Row({ space: '10vp' }) {
              Button('开始巡检')
                .width('100vp')
                .height('38vp')
                .fontSize('13fp')
                .fontColor($r('app.color.text_on_accent'))
                .backgroundColor($r('app.color.alert_normal'))
                .borderRadius('19vp')
                .shadow(ButtonShadow)
                .onClick((): void => {
                  this.sendPatrolCommand('start');
                })
              Button('暂停巡检')
                .width('100vp')
                .height('38vp')
                .fontSize('13fp')
                .fontColor($r('app.color.text_on_accent'))
                .backgroundColor($r('app.color.alert_warning'))
                .borderRadius('19vp')
                .shadow(ButtonShadow)
                .onClick((): void => {
                  this.sendPatrolCommand('pause');
                })
              Button('继续巡检')
                .width('100vp')
                .height('38vp')
                .fontSize('13fp')
                .fontColor($r('app.color.text'))
                .backgroundColor($r('app.color.button_secondary'))
                .borderRadius('19vp')
                .shadow(ButtonShadow)
                .onClick((): void => {
                  this.sendPatrolCommand('resume');
                })
            }
            Row({ space: '10vp' }) {
              Button('返回起点')
                .width('100vp')
                .height('38vp')
                .fontSize('13fp')
                .fontColor($r('app.color.text'))
                .backgroundColor($r('app.color.button_secondary'))
                .borderRadius('19vp')
                .shadow(ButtonShadow)
                .onClick((): void => {
                  this.sendPatrolCommand('return');
                })
              Button('停止巡检')
                .width('100vp')
                .height('38vp')
                .fontSize('13fp')
                .fontColor($r('app.color.text_on_accent'))
                .backgroundColor($r('app.color.alert_critical'))
                .borderRadius('19vp')
                .shadow(ButtonShadow)
                .onClick((): void => {
                  this.sendPatrolCommand('stop');
                })
              Button('手动遥控')
                .width('100vp')
                .height('38vp')
                .fontSize('13fp')
                .fontColor($r('app.color.text'))
                .backgroundColor($r('app.color.button_secondary'))
                .borderRadius('19vp')
                .shadow(ButtonShadow)
                .onClick((): void => {
                  router.pushUrl({ url: 'pages/RemoteControl' });
                })
            }
          }
        }
      }
      .layoutWeight(1)
      .padding({ left: '15vp', right: '10vp', bottom: '15vp' })
      .backgroundColor($r('app.color.window_background'))

      Column() {
        VideoComponents()
      }
      .layoutWeight(1)
      .padding({ right: '15vp', bottom: '15vp' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.window_background'))
  }

  private async switchMode(mode: ControlMode): Promise<void> {
    const cmdMode = mode === ControlMode.Auto ? 'auto' : 'manual';
    const ok = await PatrolCommandUtils.setControlMode(cmdMode);
    if (ok) {
      PatrolStore.getInstance().updateVehicle({ controlMode: mode });
      promptAction.showToast({ message: mode === ControlMode.Auto ? '已切换自动巡检' : '已切换手动遥控' });
    } else {
      PatrolStore.getInstance().updateVehicle({ controlMode: mode });
      promptAction.showToast({ message: '命令已发送（本地模式已切换）' });
    }
  }

  private async sendPatrolCommand(action: string): Promise<void> {
    const store = PatrolStore.getInstance();
    let ok = false;
    if (action === 'start') {
      ok = await PatrolCommandUtils.startPatrol(this.route as 'warehouse_A' | 'warehouse_B');
      store.updateVehicle({
        controlMode: ControlMode.Auto,
        patrolStatus: PatrolStatus.Patrolling,
        message: '已发送开始巡检命令'
      });
      store.resetPatrolPoints();
    } else if (action === 'pause') {
      ok = await PatrolCommandUtils.pausePatrol();
      store.updateVehicle({ patrolStatus: PatrolStatus.Paused, message: '已发送暂停巡检命令' });
    } else if (action === 'resume') {
      ok = await PatrolCommandUtils.resumePatrol();
      store.updateVehicle({ patrolStatus: PatrolStatus.Patrolling, message: '已发送继续巡检命令' });
    } else if (action === 'return') {
      ok = await PatrolCommandUtils.returnHome();
      store.updateVehicle({ patrolStatus: PatrolStatus.Returning, message: '已发送返回起点命令' });
    } else if (action === 'stop') {
      ok = await PatrolCommandUtils.stopPatrol();
      store.updateVehicle({ patrolStatus: PatrolStatus.Idle, message: '已发送停止巡检命令' });
    }

    promptAction.showToast({
      message: ok ? '命令发送成功' : '命令已记录，请检查网络连接'
    });
  }
}