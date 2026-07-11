import {
  AlertLevel,
  ENV_THRESHOLDS,
  EnvThreshold,
  alertLevelText
} from '../model/PatrolModels';
import { levelColor } from '../utils/PatrolUiUtils';
import { CardShadow } from '../styles/styles';

@Component
export struct EnvCard {
  @Prop title: string = '';
  @Prop value: string = '0';
  @Prop unit: string = '';
  @Prop threshold: EnvThreshold = ENV_THRESHOLDS[0];

  private getLevel(): AlertLevel {
    const num = Number.parseFloat(this.value);
    if (Number.isNaN(num)) {
      return AlertLevel.Normal;
    }
    if (this.title === '光照') {
      if (num < this.threshold.criticalMax) {
        return AlertLevel.Critical;
      }
      if (num < this.threshold.warningMax) {
        return AlertLevel.Warning;
      }
      return AlertLevel.Normal;
    }
    if (num >= this.threshold.criticalMax) {
      return AlertLevel.Critical;
    }
    if (num >= this.threshold.warningMax) {
      return AlertLevel.Warning;
    }
    return AlertLevel.Normal;
  }

  build() {
    Row({ space: '16vp' }) {
      Column({ space: '4vp' }) {
        Text(this.title)
          .fontSize('15fp')
          .fontColor($r('app.color.text_secondary'))
        Text(`${this.value}`)
          .fontSize('30fp')
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text'))
        Text(this.unit)
          .fontSize('14fp')
          .fontColor($r('app.color.text_secondary'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column({ space: '8vp' }) {
        Text(alertLevelText(this.getLevel()))
          .fontSize('13fp')
          .fontColor($r('app.color.text_on_accent'))
          .backgroundColor(levelColor(this.getLevel()))
          .padding({ left: '12vp', right: '12vp', top: '8vp', bottom: '8vp' })
          .borderRadius('14vp')
        Text(`预警≥${this.threshold.warningMax}  严重≥${this.threshold.criticalMax}`)
          .fontSize('11fp')
          .fontColor($r('app.color.text_secondary'))
          .maxLines(2)
          .textAlign(TextAlign.Center)
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding('16vp')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('16vp')
    .border({ width: '1vp', color: $r('app.color.divider') })
    .shadow(CardShadow)
  }
}

@Component
export struct ThresholdTable {
  build() {
    Column({ space: '12vp' }) {
      Text('仓库环境阈值表')
        .fontSize('17fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Bold)
        .width('100%')
      ForEach(ENV_THRESHOLDS, (item: EnvThreshold) => {
        Row({ space: '12vp' }) {
          Text(item.name)
            .fontSize('15fp')
            .fontColor($r('app.color.text'))
            .fontWeight(FontWeight.Medium)
            .width('80vp')
          Text(`${item.min}~${item.max}${item.unit}`)
            .fontSize('14fp')
            .fontColor($r('app.color.text_secondary'))
            .layoutWeight(1)
          Text(`≥${item.warningMax}`)
            .fontSize('13fp')
            .fontColor($r('app.color.alert_warning'))
            .width('60vp')
          Text(`≥${item.criticalMax}`)
            .fontSize('13fp')
            .fontColor($r('app.color.alert_critical'))
            .width('60vp')
        }
        .width('100%')
        .padding('12vp')
        .backgroundColor($r('app.color.card_elevated'))
        .borderRadius('12vp')
      }, (item: EnvThreshold) => item.name)
      Text('多次采样取平均 → 去除突变值 → 连续超阈值才报警')
        .fontSize('13fp')
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .lineHeight('20fp')
    }
    .width('100%')
  }
}