import router from '@ohos.router';
import {
  PatrolPoint,
  channelStatusText,
  patrolStatusText
} from '../model/PatrolModels';
import { PatrolStore } from '../store/PatrolStore';
import { channelStatusColor, levelColor, onlineColor, patrolStatusColor } from '../utils/PatrolUiUtils';
import { PageHeader, InfoCard, StatusBadge } from '../components/PageHeader';
import { CardShadow, ButtonShadow } from '../styles/styles';

@Entry
@Component
struct PatrolDashboard {
  @State online: boolean = false;
  @State patrolStatusTextValue: string = '空闲';
  @State currentPoint: string = 'P1';
  @State nextPoint: string = 'P2';
  @State progress: number = 0;
  @State route: string = 'pipeline_route_01';
  @State lidarMessage: string = '等待数据';
  @State visionMessage: string = '等待数据';
  @State patrolPoints: PatrolPoint[] = [];
  @State latestAlert: string = '暂无异常';
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
    this.route = store.vehicle.route;
    this.lidarMessage = store.lidar.message;
    this.visionMessage = store.vision.message;
    this.patrolPoints = store.patrolPoints.map((p: PatrolPoint): PatrolPoint => {
      return { id: p.id, name: p.name, visited: p.visited, abnormal: p.abnormal };
    });
    if (store.alerts.length > 0) {
      const latest = store.alerts[0];
      this.latestAlert = `[${latest.time}] ${latest.point}：${latest.message}`;
    } else {
      this.latestAlert = '暂无异常';
    }
  }

  build() {
    Column({ space: '10vp' }) {
      Row({ space: '10vp' }) {
        PageHeader({
          title: '狭域巡航监控',
          subtitle: this.online ? '设备在线' : '设备离线',
          accentColor: $r('app.color.button_primary')
        })
        .layoutWeight(1)
        StatusBadge({
          text: this.online ? '在线' : '离线',
          bgColor: onlineColor(this.online)
        })
      }
      .width('100%')
      .padding({ left: '14vp', right: '14vp' })

      Scroll() {
        Column({ space: '10vp' }) {
          Row({ space: '10vp' }) {
            Column() {
              InfoCard({ title: '巡检状态' }) {
                Column({ space: '8vp' }) {
                  StatusBadge({
                    text: this.patrolStatusTextValue,
                    bgColor: patrolStatusColor(PatrolStore.getInstance().vehicle.patrolStatus)
                  })
                  Text(`路线：${this.route === 'warehouse_B' ? '管廊支线' : '管廊主线'}`)
                    .fontSize('13fp')
                    .fontColor($r('app.color.text_secondary'))
                    .maxLines(1)
                  Row({ space: '12vp' }) {
                    Column({ space: '3vp' }) {
                      Text('当前点')
                        .fontSize('12fp')
                        .fontColor($r('app.color.text_secondary'))
                      Text(this.currentPoint)
                        .fontSize('16fp')
                        .fontColor($r('app.color.text'))
                        .fontWeight(FontWeight.Bold)
                        .maxLines(1)
                    }
                    .layoutWeight(1)
                    Column({ space: '3vp' }) {
                      Text('下一点')
                        .fontSize('12fp')
                        .fontColor($r('app.color.text_secondary'))
                      Text(this.nextPoint)
                        .fontSize('16fp')
                        .fontColor($r('app.color.text'))
                        .fontWeight(FontWeight.Bold)
                        .maxLines(1)
                    }
                    .layoutWeight(1)
                  }
                  .width('100%')
                  Column({ space: '4vp' }) {
                    Row({ space: '8vp' }) {
                      Text('巡检进度')
                        .fontSize('12fp')
                        .fontColor($r('app.color.text_secondary'))
                      Text(`${this.progress}%`)
                        .fontSize('12fp')
                        .fontColor($r('app.color.text'))
                        .fontWeight(FontWeight.Medium)
                    }
                    Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
                      .width('100%')
                      .height('6vp')
                      .color($r('app.color.button_primary'))
                      .backgroundColor($r('app.color.card_elevated'))
                      .borderRadius('3vp')
                  }
                  .width('100%')
                }
              }
            }
            .layoutWeight(1)

            Column() {
              InfoCard({ title: '通道与视觉' }) {
                Column({ space: '8vp' }) {
                  StatusBadge({
                    text: channelStatusText(PatrolStore.getInstance().lidar.channelStatus),
                    bgColor: channelStatusColor(PatrolStore.getInstance().lidar.channelStatus)
                  })
                  Row({ space: '10vp' }) {
                    Column({ space: '3vp' }) {
                      Text('雷达')
                        .fontSize('12fp')
                        .fontColor($r('app.color.text_secondary'))
                      Text(this.lidarMessage)
                        .fontSize('13fp')
                        .fontColor($r('app.color.text'))
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    .layoutWeight(1)
                    Column({ space: '3vp' }) {
                      Text('视觉')
                        .fontSize('12fp')
                        .fontColor($r('app.color.text_secondary'))
                      Text(this.visionMessage)
                        .fontSize('13fp')
                        .fontColor($r('app.color.text'))
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    .layoutWeight(1)
                  }
                  .width('100%')
                  Column({ space: '4vp' }) {
                    Text('最新告警')
                      .fontSize('13fp')
                      .fontColor($r('app.color.text'))
                      .fontWeight(FontWeight.Medium)
                    Text(this.latestAlert)
                      .fontSize('12fp')
                      .fontColor(PatrolStore.getInstance().alerts.length > 0 ?
                        $r('app.color.alert_warning') : $r('app.color.text_secondary'))
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('100%')
                }
              }
            }
            .layoutWeight(1)
          }
          .width('100%')
          .padding({ left: '14vp', right: '14vp' })

          Column() {
            InfoCard({ title: '巡检路线' }) {
              Scroll() {
                Row({ space: '10vp' }) {
                  ForEach(this.patrolPoints, (point: PatrolPoint) => {
                    Column({ space: '4vp' }) {
                      Text(point.id)
                        .fontSize('16fp')
                        .fontColor($r('app.color.text_on_accent'))
                        .fontWeight(FontWeight.Bold)
                      Text(point.name)
                        .fontSize('11fp')
                        .fontColor(point.abnormal ? $r('app.color.text_on_accent') : $r('app.color.text'))
                        .maxLines(2)
                        .textAlign(TextAlign.Center)
                    }
                    .width('80vp')
                    .height('72vp')
                    .justifyContent(FlexAlign.Center)
                    .backgroundColor(point.abnormal ? $r('app.color.alert_critical') :
                      (point.visited ? $r('app.color.alert_normal') : $r('app.color.card_elevated')))
                    .borderRadius('12vp')
                    .border({ width: '1vp', color: $r('app.color.divider') })
                  }, (point: PatrolPoint) => point.id)
                }
              }
              .scrollable(ScrollDirection.Horizontal)
              .scrollBar(BarState.Off)
              .width('100%')
            }
          }
          .padding({ left: '14vp', right: '14vp' })

          Row({ space: '10vp' }) {
            Button('环境数据')
              .layoutWeight(1)
              .height('38vp')
              .fontSize('13fp')
              .fontColor($r('app.color.text'))
              .backgroundColor($r('app.color.button_secondary'))
              .borderRadius('19vp')
              .shadow(ButtonShadow)
              .onClick((): void => {
                router.pushUrl({ url: 'pages/EnvironmentMonitor' });
              })
            Button('异常告警')
              .layoutWeight(1)
              .height('38vp')
              .fontSize('13fp')
              .fontColor($r('app.color.text'))
              .backgroundColor($r('app.color.button_secondary'))
              .borderRadius('19vp')
              .shadow(ButtonShadow)
              .onClick((): void => {
                router.pushUrl({ url: 'pages/AlertRecords' });
              })
            Button('巡检控制')
              .layoutWeight(1)
              .height('38vp')
              .fontSize('13fp')
              .fontColor($r('app.color.text'))
              .backgroundColor($r('app.color.button_secondary'))
              .borderRadius('19vp')
              .shadow(ButtonShadow)
              .onClick((): void => {
                router.pushUrl({ url: 'pages/PatrolControl' });
              })
            Button('返回首页')
              .layoutWeight(1)
              .height('38vp')
              .fontSize('13fp')
              .fontColor($r('app.color.text'))
              .backgroundColor($r('app.color.card_elevated'))
              .borderRadius('19vp')
              .border({ width: '1vp', color: $r('app.color.divider') })
              .onClick((): void => {
                router.back();
              })
          }
          .width('100%')
          .padding({ left: '14vp', right: '14vp', bottom: '12vp' })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.window_background'))
    .padding({ top: '10vp' })
  }
}
