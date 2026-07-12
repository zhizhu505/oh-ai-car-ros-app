import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AlertRecord, alertLevelText, categoryLabel } from '../model/PatrolModels';
import { PatrolStore } from '../store/PatrolStore';
import { levelColor } from '../utils/PatrolUiUtils';
import { CardShadow, ButtonShadow } from '../styles/styles';

@Entry
@Component
struct AlertRecords {
  @State alerts: AlertRecord[] = [];
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
    this.alerts = PatrolStore.getInstance().alerts.map((item: AlertRecord): AlertRecord => {
      return {
        id: item.id,
        time: item.time,
        point: item.point,
        category: item.category,
        message: item.message,
        level: item.level,
        imageUrl: item.imageUrl
      };
    });
  }

  build() {
    Column({ space: '16vp' }) {
      Row({ space: '16vp' }) {
        Column({ space: '8vp' }) {
          Text('异常告警记录')
            .fontSize('28fp')
            .fontColor($r('app.color.text'))
            .fontWeight(FontWeight.Bold)
          Text(`共 ${this.alerts.length} 条记录`)
            .fontSize('14fp')
            .fontColor($r('app.color.text_secondary'))
            .opacity(0.85)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Row({ space: '12vp' }) {
          Button('清空')
            .width('76vp')
            .height('38vp')
            .fontSize('14fp')
            .fontColor($r('app.color.text'))
            .backgroundColor($r('app.color.card_elevated'))
            .borderRadius('19vp')
            .border({ width: '1vp', color: $r('app.color.divider') })
            .shadow(ButtonShadow)
            .onClick((): void => {
              PatrolStore.getInstance().clearAlerts();
              promptAction.showToast({ message: '告警记录已清空' });
            })

          Button('返回')
            .width('82vp')
            .height('38vp')
            .fontSize('14fp')
            .fontColor($r('app.color.text'))
            .backgroundColor($r('app.color.button_secondary'))
            .borderRadius('19vp')
            .shadow(ButtonShadow)
            .onClick((): void => {
              router.back();
            })
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding({ left: '28vp', right: '28vp', top: '22vp', bottom: '18vp' })
      .backgroundColor($r('app.color.header_background'))
      .borderRadius('18vp')
      .border({ width: '1vp', color: $r('app.color.divider') })
      .shadow(CardShadow)

      if (this.alerts.length === 0) {
        Column() {
          Column({ space: '14vp' }) {
            Text('📋')
              .fontSize('54fp')
            Text('暂无异常记录')
              .fontSize('18fp')
              .fontColor($r('app.color.text'))
              .fontWeight(FontWeight.Bold)
            Text('小车巡检过程中检测到的环境、雷达、视觉异常会显示在这里')
              .fontSize('14fp')
              .fontColor($r('app.color.text_secondary'))
              .textAlign(TextAlign.Center)
              .maxLines(2)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .padding({ left: '24vp', right: '24vp' })
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('app.color.card_background'))
        .borderRadius('18vp')
        .border({ width: '1vp', color: $r('app.color.divider') })
        .shadow(CardShadow)
      } else {
        List({ space: '12vp' }) {
          ForEach(this.alerts, (item: AlertRecord) => {
            ListItem() {
              Column({ space: '10vp' }) {
                Row({ space: '12vp' }) {
                  Text(item.time)
                    .fontSize('13fp')
                    .fontColor($r('app.color.text_secondary'))
                  Text(categoryLabel(item.category))
                    .fontSize('12fp')
                    .fontColor($r('app.color.text_on_accent'))
                    .backgroundColor($r('app.color.status_active'))
                    .padding({ left: '10vp', right: '10vp', top: '4vp', bottom: '4vp' })
                    .borderRadius('10vp')
                  Blank()
                  Text(alertLevelText(item.level))
                    .fontSize('12fp')
                    .fontColor($r('app.color.text_on_accent'))
                    .backgroundColor(levelColor(item.level))
                    .padding({ left: '12vp', right: '12vp', top: '4vp', bottom: '4vp' })
                    .borderRadius('12vp')
                }
                .width('100%')
                Text(`${item.point}：${item.message}`)
                  .fontSize('16fp')
                  .fontColor($r('app.color.text'))
                  .width('100%')
                  .fontWeight(FontWeight.Medium)
                if (item.imageUrl.length > 0) {
                  Text(`截图已保存`)
                    .fontSize('12fp')
                    .fontColor($r('app.color.status_active'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
              }
              .width('100%')
              .padding('16vp')
              .backgroundColor($r('app.color.card_background'))
              .borderRadius('16vp')
              .border({ width: '1vp', color: $r('app.color.divider') })
              .shadow(CardShadow)
            }
          }, (item: AlertRecord) => item.id)
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.window_background'))
    .padding({ left: '24vp', right: '24vp', top: '18vp', bottom: '24vp' })
  }
}
