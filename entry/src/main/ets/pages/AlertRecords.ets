import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AlertRecord, alertLevelText, categoryLabel } from '../model/PatrolModels';
import { PatrolStore } from '../store/PatrolStore';
import { levelColor } from '../utils/PatrolUiUtils';
import { PageHeader, InfoCard } from '../components/PageHeader';
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
    Column({ space: '12vp' }) {
      Stack() {
        PageHeader({
          title: '异常告警记录',
          subtitle: `共 ${this.alerts.length} 条记录`,
          accentColor: $r('app.color.alert_warning')
        })
        Button('清空')
          .width('68vp')
          .height('34vp')
          .fontSize('13fp')
          .fontColor($r('app.color.text'))
          .backgroundColor($r('app.color.button_secondary'))
          .borderRadius('17vp')
          .shadow(ButtonShadow)
          .onClick((): void => {
            PatrolStore.getInstance().clearAlerts();
            promptAction.showToast({ message: '告警记录已清空' });
          })
          .alignSelf(ItemAlign.End)
          .margin({ right: '32vp', top: '22vp' })
      }
      .width('100%')

      if (this.alerts.length === 0) {
        InfoCard({ title: '' }) {
          Column({ space: '12vp' }) {
            Text('📋')
              .fontSize('48fp')
            Text('暂无异常记录')
              .fontSize('16fp')
              .fontColor($r('app.color.text'))
              .fontWeight(FontWeight.Medium)
            Text('小车巡检过程中检测到的环境、雷达、视觉异常会显示在这里')
              .fontSize('14fp')
              .fontColor($r('app.color.text_secondary'))
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .padding({ top: '40vp', bottom: '40vp' })
        }
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
    .padding({ left: '20vp', right: '20vp', bottom: '20vp' })
  }
}