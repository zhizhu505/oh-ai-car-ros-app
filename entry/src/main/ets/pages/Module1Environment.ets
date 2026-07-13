import {
  AlertLevel,
  ALERT_CATEGORY_ENV,
  ENV_METRICS,
  ENV_THRESHOLDS,
  EnvHistoryRecord,
  EnvMetricMeta,
  EnvSnapshot,
  EnvThreshold,
  alertLevelText
} from '../model/PatrolModels';
import { PatrolStore } from '../store/PatrolStore';
import { ModuleTabBar, InfoCard } from '../components/PageHeader';
import { ModuleAlertList } from '../components/ModuleAlertList';
import { levelColor } from '../utils/PatrolUiUtils';
import { CardShadow, ElevatedShadow } from '../styles/styles';

@Entry
@Component
struct Module1Environment {
  @State currentTabIndex: number = 0;
  @State selectedMetric: string = 'temperature';
  @State updateTime: string = '-';
  @State level: AlertLevel = AlertLevel.Normal;
  @State temperature: number = 0;
  @State humidity: number = 0;
  @State gas: number = 0;
  @State light: number = 0;
  @State pm25: number = 0;
  @State history: EnvHistoryRecord[] = [];
  private tabs: string[] = ['实时数据', '阈值规则', '异常记录'];
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
    const env: EnvSnapshot = store.env;
    this.updateTime = env.updateTime;
    this.level = env.level;
    this.temperature = env.temperature;
    this.humidity = env.humidity;
    this.gas = env.gas;
    this.light = env.light;
    this.pm25 = env.pm25;
    this.history = store.envHistory.slice(-24) as EnvHistoryRecord[];
  }

  build() {
    Column({ space: '0vp' }) {
      ModuleTabBar({
        currentIndex: $currentTabIndex,
        tabs: this.tabs,
        accentColor: $r('app.color.module1_accent'),
        title: '环境感知',
        subtitle: '管廊环境实时监测'
      })

      Scroll() {
        Column() {
          if (this.currentTabIndex === 0) {
            this.LiveDataView()
          } else if (this.currentTabIndex === 1) {
            this.RuleView()
          } else {
            this.AlertView()
          }
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.window_background'))
  }

  @Builder
  LiveDataView() {
    Column({ space: '12vp' }) {
      Row({ space: '10vp' }) {
        Column({ space: '4vp' }) {
          Text('地下管廊环境总览')
            .fontSize('18fp')
            .fontColor($r('app.color.text'))
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
          Text(`统一采样时间 ${this.updateTime}`)
            .fontSize('11fp')
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(alertLevelText(this.level))
          .fontSize('12fp')
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(levelColor(this.level))
          .padding({ left: '12vp', right: '12vp', top: '6vp', bottom: '6vp' })
          .borderRadius('12vp')
      }
      .width('100%')
      .padding({ left: '14vp', right: '14vp', top: '12vp', bottom: '12vp' })
      .backgroundColor($r('app.color.card_background'))
      .borderRadius('16vp')
      .border({ width: '1vp', color: $r('app.color.divider') })
      .shadow(CardShadow)

      EnvTrendChart({
        selectedMetric: this.selectedMetric,
        history: this.history,
        threshold: this.getThreshold(this.selectedMetric),
        value: this.getCurrentValue(this.selectedMetric),
        meta: this.getMetricMeta(this.selectedMetric)
      })
        .width('100%')

      Column({ space: '10vp' }) {
        Row({ space: '10vp' }) {
          MetricCard({
            meta: ENV_METRICS[0],
            value: this.temperature,
            threshold: ENV_THRESHOLDS[0],
            selected: this.selectedMetric === 'temperature',
            onSelect: (): void => {
              this.selectedMetric = 'temperature';
            }
          })
            .layoutWeight(1)
          MetricCard({
            meta: ENV_METRICS[1],
            value: this.humidity,
            threshold: ENV_THRESHOLDS[1],
            selected: this.selectedMetric === 'humidity',
            onSelect: (): void => {
              this.selectedMetric = 'humidity';
            }
          })
            .layoutWeight(1)
        }
        .width('100%')

        Row({ space: '10vp' }) {
          MetricCard({
            meta: ENV_METRICS[2],
            value: this.gas,
            threshold: ENV_THRESHOLDS[2],
            selected: this.selectedMetric === 'gas',
            onSelect: (): void => {
              this.selectedMetric = 'gas';
            }
          })
            .layoutWeight(1)
          MetricCard({
            meta: ENV_METRICS[3],
            value: this.pm25,
            threshold: ENV_THRESHOLDS[3],
            selected: this.selectedMetric === 'pm25',
            onSelect: (): void => {
              this.selectedMetric = 'pm25';
            }
          })
            .layoutWeight(1)
        }
        .width('100%')

        MetricCard({
          meta: ENV_METRICS[4],
          value: this.light,
          threshold: ENV_THRESHOLDS[4],
          selected: this.selectedMetric === 'light',
          onSelect: (): void => {
            this.selectedMetric = 'light';
          }
        })
          .width('100%')
      }
      .width('100%')
    }
    .padding({ left: '14vp', right: '14vp', top: '12vp', bottom: '14vp' })
    .width('100%')
  }

  @Builder
  RuleView() {
    Column({ space: '12vp' }) {
      InfoCard({ title: '管廊环境阈值策略' }) {
        Column({ space: '8vp' }) {
          Text('实时趋势图中的红线为预警阈值，连续多次超线才写入异常记录。')
            .fontSize('12fp')
            .fontColor($r('app.color.text_secondary'))
            .lineHeight('18fp')
          Text('当前 mock 数据默认保持正常波动，历史异常用于演示处置闭环。')
            .fontSize('12fp')
            .fontColor($r('app.color.text_secondary'))
            .lineHeight('18fp')
        }
      }

      ForEach(ENV_METRICS, (meta: EnvMetricMeta, index: number) => {
        EnvRuleCard({
          meta: meta,
          threshold: ENV_THRESHOLDS[index]
        })
      }, (meta: EnvMetricMeta) => meta.key)
    }
    .padding({ left: '14vp', right: '14vp', top: '12vp', bottom: '14vp' })
    .width('100%')
  }

  @Builder
  AlertView() {
    Column() {
      ModuleAlertList({
        category: ALERT_CATEGORY_ENV,
        emptyHint: '暂无环境异常记录'
      })
    }
    .padding({ left: '14vp', right: '14vp', top: '12vp', bottom: '14vp' })
    .width('100%')
  }

  private getMetricMeta(key: string): EnvMetricMeta {
    const meta = ENV_METRICS.find((item: EnvMetricMeta): boolean => item.key === key);
    return meta ? meta : ENV_METRICS[0];
  }

  private getThreshold(key: string): EnvThreshold {
    const index = ENV_METRICS.findIndex((item: EnvMetricMeta): boolean => item.key === key);
    return index >= 0 ? ENV_THRESHOLDS[index] : ENV_THRESHOLDS[0];
  }

  private getCurrentValue(key: string): number {
    if (key === 'humidity') {
      return this.humidity;
    }
    if (key === 'gas') {
      return this.gas;
    }
    if (key === 'pm25') {
      return this.pm25;
    }
    if (key === 'light') {
      return this.light;
    }
    return this.temperature;
  }
}

@Component
struct EnvTrendChart {
  @Prop selectedMetric: string = 'temperature';
  @Prop history: EnvHistoryRecord[] = [];
  @Prop threshold: EnvThreshold = ENV_THRESHOLDS[0];
  @Prop value: number = 0;
  @Prop meta: EnvMetricMeta = ENV_METRICS[0];

  build() {
    Column({ space: '12vp' }) {
      Row() {
        Column({ space: '3vp' }) {
          Row({ space: '8vp' }) {
            Text(`${this.meta.name}实时趋势`)
              .fontSize('16fp')
              .fontColor($r('app.color.text'))
              .fontWeight(FontWeight.Bold)
            Text('3秒/次')
              .fontSize('10fp')
              .fontColor($r('app.color.module1_accent'))
              .fontWeight(FontWeight.Bold)
              .padding({ left: '8vp', right: '8vp', top: '3vp', bottom: '3vp' })
              .backgroundColor($r('app.color.module1_accent') + '18')
              .borderRadius('8vp')
          }
          .alignItems(VerticalAlign.Center)
          Text(`最近 ${this.history.length} 次采样，红线为预警阈值`)
            .fontSize('10fp')
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Column({ space: '2vp' }) {
          Text(`${this.value}`)
            .fontSize('22fp')
            .fontColor($r('app.color.module1_accent'))
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
          Text(this.meta.unit)
            .fontSize('10fp')
            .fontColor($r('app.color.text_secondary'))
            .textAlign(TextAlign.End)
            .width('100%')
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Stack() {
        Column() {
          Divider()
            .color($r('app.color.divider'))
            .strokeWidth('1vp')
            .opacity(0.35)
          Blank()
          Divider()
            .color($r('app.color.divider'))
            .strokeWidth('1vp')
            .opacity(0.28)
          Blank()
          Divider()
            .color($r('app.color.divider'))
            .strokeWidth('1vp')
            .opacity(0.22)
          Blank()
          Divider()
            .color($r('app.color.divider'))
            .strokeWidth('1vp')
            .opacity(0.18)
        }
        .height('160vp')
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        Column() {
          Blank()
            .layoutWeight(this.getThresholdTopWeight())
          Row({ space: '6vp' }) {
            Text('预警线')
              .fontSize('9fp')
              .fontColor($r('app.color.alert_critical'))
            Divider()
              .color($r('app.color.alert_critical'))
              .strokeWidth('1vp')
              .layoutWeight(1)
          }
          .width('100%')
          .opacity(0.95)
          Blank()
            .layoutWeight(this.getThresholdBottomWeight())
        }
        .height('160vp')
        .width('100%')

        Row({ space: '4vp' }) {
          ForEach(this.history, (item: EnvHistoryRecord, index: number) => {
            TrendColumn({
              value: this.getRecordValue(item),
              percent: this.getPercent(this.getRecordValue(item)),
              active: index === this.history.length - 1,
              label: index === this.history.length - 1 ? item.time.slice(3) : ''
            })
              .layoutWeight(1)
          }, (item: EnvHistoryRecord, index: number) => `${item.time}_${index}`)
        }
        .width('100%')
        .height('160vp')
        .alignItems(VerticalAlign.Bottom)

        Row() {
          Blank()
          Text(this.meta.name === '光照' ? '低于红线需处理' : '超过红线需处理')
            .fontSize('9fp')
            .fontColor($r('app.color.text_secondary'))
            .padding({ left: '8vp', right: '8vp', top: '3vp', bottom: '3vp' })
            .backgroundColor($r('app.color.card_background') + 'DD')
            .borderRadius('8vp')
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
      }
      .width('100%')
      .height('160vp')
      .padding({ left: '4vp', right: '4vp', top: '4vp', bottom: '4vp' })
      .backgroundColor($r('app.color.window_background') + '78')
      .borderRadius('14vp')

      Row({ space: '8vp' }) {
        ChartMetaPill({ label: '当前', value: `${this.value}${this.meta.unit}` })
          .layoutWeight(1)
        ChartMetaPill({ label: '阈值', value: `${this.threshold.warningMax}${this.meta.unit}` })
          .layoutWeight(1)
        ChartMetaPill({ label: '样本', value: `${this.history.length}组` })
          .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding('14vp')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('16vp')
    .border({ width: '1vp', color: $r('app.color.module1_accent') + '45' })
    .shadow(ElevatedShadow)
    .animation({ duration: 220, curve: Curve.EaseOut })
  }

  private getRecordValue(record: EnvHistoryRecord): number {
    if (this.selectedMetric === 'humidity') {
      return record.humidity;
    }
    if (this.selectedMetric === 'gas') {
      return record.gas;
    }
    if (this.selectedMetric === 'pm25') {
      return record.pm25;
    }
    if (this.selectedMetric === 'light') {
      return record.light;
    }
    return record.temperature;
  }

  private getScaleMax(): number {
    if (this.selectedMetric === 'light') {
      return Math.max(this.threshold.max, 500);
    }
    return Math.max(this.threshold.criticalMax * 1.2, this.value * 1.2, 1);
  }

  private getPercent(value: number): number {
    const percent = value / this.getScaleMax() * 100;
    return Math.max(8, Math.min(96, percent));
  }

  private getThresholdPercent(): number {
    return Math.max(8, Math.min(92, this.threshold.warningMax / this.getScaleMax() * 100));
  }

  private getThresholdTopWeight(): number {
    return Math.max(1, 100 - this.getThresholdPercent());
  }

  private getThresholdBottomWeight(): number {
    return Math.max(1, this.getThresholdPercent());
  }
}

@Component
struct ChartMetaPill {
  @Prop label: string = '';
  @Prop value: string = '';

  build() {
    Row({ space: '5vp' }) {
      Text(this.label)
        .fontSize('10fp')
        .fontColor($r('app.color.text_secondary'))
      Text(this.value)
        .fontSize('11fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .justifyContent(FlexAlign.Center)
    .padding({ top: '7vp', bottom: '7vp', left: '6vp', right: '6vp' })
    .backgroundColor($r('app.color.card_elevated') + 'AA')
    .borderRadius('10vp')
  }
}

@Component
struct TrendColumn {
  @Prop value: number = 0;
  @Prop percent: number = 10;
  @Prop active: boolean = false;
  @Prop label: string = '';

  build() {
    Column({ space: '3vp' }) {
      Blank()
        .layoutWeight(Math.max(1, 100 - this.percent))
      if (this.active) {
        Text(`${this.value}`)
          .fontSize('8fp')
          .fontColor($r('app.color.module1_accent'))
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
      }
      Column()
        .width('100%')
        .layoutWeight(Math.max(1, this.percent))
        .backgroundColor(this.active ? $r('app.color.module1_accent') : $r('app.color.module1_accent') + '88')
        .borderRadius('5vp')
        .shadow(this.active ? {
          radius: 8,
          offsetX: 0,
          offsetY: 0,
          color: '#22D3EE66'
        } : {
          radius: 0,
          offsetX: 0,
          offsetY: 0,
          color: '#00000000'
        })
      Text(this.label)
        .height('10vp')
        .fontSize('8fp')
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
    }
    .height('154vp')
    .justifyContent(FlexAlign.End)
    .alignItems(HorizontalAlign.Center)
    .animation({ duration: 260, curve: Curve.EaseOut })
  }
}

@Component
struct MetricCard {
  @Prop meta: EnvMetricMeta = ENV_METRICS[0];
  @Prop value: number = 0;
  @Prop threshold: EnvThreshold = ENV_THRESHOLDS[0];
  @Prop selected: boolean = false;
  onSelect: () => void = (): void => {};

  build() {
    Column({ space: '8vp' }) {
      Row() {
        Text(this.meta.name)
          .fontSize('13fp')
          .fontColor($r('app.color.text_secondary'))
          .layoutWeight(1)
          .maxLines(1)
        Text(this.getStateText())
          .fontSize('10fp')
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .padding({ left: '8vp', right: '8vp', top: '3vp', bottom: '3vp' })
          .backgroundColor(levelColor(this.getLevel()))
          .borderRadius('8vp')
      }
      .width('100%')

      Row({ space: '3vp' }) {
        Text(`${this.value}`)
          .fontSize('21fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
        Text(this.meta.unit)
          .fontSize('11fp')
          .fontColor($r('app.color.text_secondary'))
      }
      .alignItems(VerticalAlign.Bottom)

      Text(`预警 ${this.meta.name === '光照' ? '<' : '≥'}${this.threshold.warningMax}${this.meta.unit}`)
        .fontSize('10fp')
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
    }
    .width('100%')
    .padding('12vp')
    .backgroundColor(this.selected ? $r('app.color.module1_accent') + '18' : $r('app.color.card_background'))
    .borderRadius('14vp')
    .border({ width: this.selected ? '2vp' : '1vp', color: this.selected ? $r('app.color.module1_accent') : $r('app.color.divider') })
    .shadow(this.selected ? ElevatedShadow : CardShadow)
    .scale({ x: this.selected ? 1.01 : 1, y: this.selected ? 1.01 : 1 })
    .animation({ duration: 180, curve: Curve.EaseOut })
    .onClick((): void => {
      this.onSelect();
    })
  }

  private getLevel(): AlertLevel {
    if (this.meta.name === '光照') {
      if (this.value < this.threshold.criticalMax) {
        return AlertLevel.Critical;
      }
      if (this.value < this.threshold.warningMax) {
        return AlertLevel.Warning;
      }
      return AlertLevel.Normal;
    }
    if (this.value >= this.threshold.criticalMax) {
      return AlertLevel.Critical;
    }
    if (this.value >= this.threshold.warningMax) {
      return AlertLevel.Warning;
    }
    return AlertLevel.Normal;
  }

  private getStateText(): string {
    return alertLevelText(this.getLevel());
  }
}

@Component
struct EnvRuleCard {
  @Prop meta: EnvMetricMeta = ENV_METRICS[0];
  @Prop threshold: EnvThreshold = ENV_THRESHOLDS[0];

  build() {
    Column({ space: '10vp' }) {
      Row() {
        Text(this.meta.name)
          .fontSize('16fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(this.meta.unit)
          .fontSize('11fp')
          .fontColor($r('app.color.text_secondary'))
          .padding({ left: '8vp', right: '8vp', top: '4vp', bottom: '4vp' })
          .backgroundColor($r('app.color.card_elevated'))
          .borderRadius('8vp')
      }
      .width('100%')

      Row({ space: '8vp' }) {
        RulePill({ label: '正常范围', value: this.normalRange(), color: $r('app.color.status_success') })
          .layoutWeight(1)
        RulePill({ label: '预警', value: this.warningRange(), color: $r('app.color.alert_warning') })
          .layoutWeight(1)
        RulePill({ label: '严重', value: this.criticalRange(), color: $r('app.color.alert_critical') })
          .layoutWeight(1)
      }
      .width('100%')

      Text(this.suggestion())
        .fontSize('12fp')
        .fontColor($r('app.color.text_secondary'))
        .lineHeight('18fp')
    }
    .width('100%')
    .padding('14vp')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('16vp')
    .border({ width: '1vp', color: $r('app.color.divider') })
    .shadow(CardShadow)
  }

  private normalRange(): string {
    if (this.meta.name === '光照') {
      return `≥${this.threshold.warningMax}${this.meta.unit}`;
    }
    return `${this.threshold.min}-${this.threshold.warningMax}${this.meta.unit}`;
  }

  private warningRange(): string {
    if (this.meta.name === '光照') {
      return `<${this.threshold.warningMax}${this.meta.unit}`;
    }
    return `≥${this.threshold.warningMax}${this.meta.unit}`;
  }

  private criticalRange(): string {
    if (this.meta.name === '光照') {
      return `<${this.threshold.criticalMax}${this.meta.unit}`;
    }
    return `≥${this.threshold.criticalMax}${this.meta.unit}`;
  }

  private suggestion(): string {
    if (this.meta.name === '温度') {
      return '处置建议：复核通风设备与热源区域，必要时开启强制通风。';
    }
    if (this.meta.name === '湿度') {
      return '处置建议：检查渗水、排水和除湿设备，防止设备凝露。';
    }
    if (this.meta.name === '可燃气体') {
      return '处置建议：立即复核气体传感器，联动通风并限制人员进入。';
    }
    if (this.meta.name === 'PM2.5') {
      return '处置建议：排查扬尘或施工影响，必要时加强过滤通风。';
    }
    return '处置建议：检查照明回路和灯具状态，保障管廊通行照度。';
  }
}

@Component
struct RulePill {
  @Prop label: string = '';
  @Prop value: string = '';
  @Prop color: ResourceColor = $r('app.color.status_success');

  build() {
    Column({ space: '4vp' }) {
      Text(this.label)
        .fontSize('10fp')
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
      Text(this.value)
        .fontSize('12fp')
        .fontColor(this.color)
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .alignItems(HorizontalAlign.Center)
    .padding({ top: '9vp', bottom: '9vp', left: '4vp', right: '4vp' })
    .backgroundColor(this.color + '14')
    .borderRadius('12vp')
  }
}
