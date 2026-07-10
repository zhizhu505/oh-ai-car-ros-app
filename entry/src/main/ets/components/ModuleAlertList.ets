import { AlertRecord, alertLevelText, categoryLabel } from '../model/PatrolModels';
import { PatrolStore } from '../store/PatrolStore';
import { levelColor } from '../utils/PatrolUiUtils';
import { CardShadow } from '../styles/styles';

@Component
export struct ModuleAlertList {
  @Prop category: string = '';
  @Prop emptyHint: string = '暂无异常记录';
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
    const store = PatrolStore.getInstance();
    const source = this.category.length > 0 ?
      store.getAlertsByCategory(this.category) : store.alerts;
    this.alerts = source.map((item: AlertRecord): AlertRecord => {
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
    if (this.alerts.length === 0) {
      Column({ space: '12vp' }) {
        Text('📋')
          .fontSize('48fp')
        Text(this.emptyHint)
          .fontSize('15fp')
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
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
      .width('100%')
      .layoutWeight(1)
    }
  }
}