import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { ControlMode, patrolStatusText } from '../model/PatrolModels';
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
  @State route: string = 'pipeline_route_01';
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
            Text(`当前路线：${this.route === 'warehouse_B' ? '管廊支线' : '管廊主线'}`)
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

  private async sendPatrolCommand(action: string): Promise<void> {
    let ok = false;
    if (action === 'start') {
      ok = (await PatrolCommandUtils.startPatrol(this.route)).sent;
    } else if (action === 'pause') {
      ok = (await PatrolCommandUtils.pausePatrol()).sent;
    } else if (action === 'resume') {
      ok = (await PatrolCommandUtils.resumePatrol()).sent;
    } else if (action === 'return') {
      ok = (await PatrolCommandUtils.returnHome()).sent;
    } else if (action === 'stop') {
      ok = (await PatrolCommandUtils.stopPatrol()).sent;
    }

    promptAction.showToast({
      message: ok ? '请求已发送，等待 Jetson 确认' : '请求发送失败，请检查网络连接'
    });
  }
}
