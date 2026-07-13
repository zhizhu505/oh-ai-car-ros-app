import { AlertLevel, AlertRecord, alertLevelText, categoryLabel } from '../model/PatrolModels';
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
      List({ space: '10vp' }) {
        ForEach(this.alerts, (item: AlertRecord) => {
          ListItem() {
            Column({ space: '9vp' }) {
              Row({ space: '8vp' }) {
                Text(item.time)
                  .fontSize('12fp')
                  .fontColor($r('app.color.text_secondary'))
                Text(categoryLabel(item.category))
                  .fontSize('11fp')
                  .fontColor($r('app.color.text_on_accent'))
                  .backgroundColor($r('app.color.status_active'))
                  .padding({ left: '9vp', right: '9vp', top: '3vp', bottom: '3vp' })
                  .borderRadius('10vp')
                Blank()
                Text(alertLevelText(item.level))
                  .fontSize('11fp')
                  .fontColor($r('app.color.text_on_accent'))
                  .backgroundColor(levelColor(item.level))
                  .padding({ left: '10vp', right: '10vp', top: '3vp', bottom: '3vp' })
                  .borderRadius('12vp')
              }
              .width('100%')

              Text(this.getIssueText(item))
                .fontSize('15fp')
                .fontColor($r('app.color.text'))
                .width('100%')
                .fontWeight(FontWeight.Bold)
                .lineHeight('20fp')
                .maxLines(2)

              Row({ space: '8vp' }) {
                AlertInfoPill({ label: '对象', value: this.getSourceText(item) })
                  .layoutWeight(1)
                AlertInfoPill({ label: '读数', value: this.getReadingText(item), highlight: item.level !== AlertLevel.Normal })
                  .layoutWeight(1)
              }
              .width('100%')

              if (item.imageUrl.length > 0) {
                Text(`截图已保存`)
                  .fontSize('12fp')
                  .fontColor($r('app.color.status_active'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
            }
            .width('100%')
            .padding({ left: '14vp', right: '14vp', top: '13vp', bottom: '13vp' })
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

  private getCleanMessage(item: AlertRecord): string {
    let text = item.message;
    text = text.replace('地下管廊环境监测：', '');
    text = text.replace('历史测试：', '');
    text = text.replace('地下管廊环境监测:', '');
    text = text.replace('历史测试:', '');
    return text;
  }

  private getIssueText(item: AlertRecord): string {
    const text = this.getCleanMessage(item);
    const index = text.indexOf('，当前');
    return index >= 0 ? text.substring(0, index) : text;
  }

  private getReadingText(item: AlertRecord): string {
    const text = this.getCleanMessage(item);
    const index = text.indexOf('，当前');
    return index >= 0 ? text.substring(index + 1) : '待复核';
  }

  private getSourceText(item: AlertRecord): string {
    if (item.point.includes('环境监测')) {
      return '管廊环境';
    }
    return item.point;
  }
}

@Component
struct AlertInfoPill {
  @Prop label: string = '';
  @Prop value: string = '';
  @Prop highlight: boolean = false;

  build() {
    Row({ space: '6vp' }) {
      Text(this.label)
        .fontSize('11fp')
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
      Text(this.value)
        .fontSize('12fp')
        .fontColor(this.highlight ? $r('app.color.alert_warning') : $r('app.color.text'))
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .height('30vp')
    .padding({ left: '9vp', right: '9vp' })
    .backgroundColor($r('app.color.card_elevated') + 'AA')
    .borderRadius('10vp')
    .alignItems(VerticalAlign.Center)
  }
}
