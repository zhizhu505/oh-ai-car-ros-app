import router from '@ohos.router';
import {
  AlertLevel,
  ENV_THRESHOLDS,
  EnvSnapshot,
  EnvThreshold,
  PRESSURE_THRESHOLD,
  alertLevelText
} from '../model/PatrolModels';
import { PatrolStore } from '../store/PatrolStore';
import { levelColor } from '../utils/PatrolUiUtils';
import { PageHeader, InfoCard, StatusBadge } from '../components/PageHeader';
import { CardShadow } from '../styles/styles';

@Entry
@Component
struct EnvironmentMonitor {
  @State point: string = '-';
  @State updateTime: string = '-';
  @State level: AlertLevel = AlertLevel.Normal;
  @State temperature: number = 0;
  @State humidity: number = 0;
  @State smoke: number = 0;
  @State gas: number = 0;
  @State light: number = 0;
  @State pm25: number = 0;
  @State pressure: number = 0;
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
    const env: EnvSnapshot = PatrolStore.getInstance().env;
    this.point = env.point;
    this.updateTime = env.updateTime;
    this.level = env.level;
    this.temperature = env.temperature;
    this.humidity = env.humidity;
    this.smoke = env.smoke;
    this.gas = env.gas;
    this.light = env.light;
    this.pm25 = env.pm25;
    this.pressure = env.pressure;
  }

  build() {
    Column({ space: '10vp' }) {
      PageHeader({
        title: '环境数据监测',
        subtitle: `当前点位：${this.point}`,
        accentColor: $r('app.color.button_primary')
      })

      InfoCard({ title: '实时状态' }) {
        Column({ space: '10vp' }) {
          Row({ space: '16vp' }) {
            Column({ space: '4vp' }) {
              Text('更新时间')
                .fontSize('14fp')
                .fontColor($r('app.color.text_secondary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(this.updateTime)
                .fontSize('16fp')
                .fontColor($r('app.color.text'))
                .fontWeight(FontWeight.Medium)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            Blank()
            StatusBadge({
              text: alertLevelText(this.level),
              bgColor: levelColor(this.level)
            })
          }
        }
      }

      Scroll() {
        Column({ space: '10vp' }) {
          EnvCard({ title: '温度', value: `${this.temperature}`, unit: '℃', threshold: ENV_THRESHOLDS[0] })
          EnvCard({ title: '湿度', value: `${this.humidity}`, unit: '%', threshold: ENV_THRESHOLDS[1] })
          EnvCard({ title: '烟雾', value: `${this.smoke}`, unit: 'ppm', threshold: ENV_THRESHOLDS[2] })
          EnvCard({ title: '可燃气体', value: `${this.gas}`, unit: 'ppm', threshold: ENV_THRESHOLDS[3] })
          EnvCard({ title: '光照', value: `${this.light}`, unit: 'lux', threshold: ENV_THRESHOLDS[4] })
          EnvCard({ title: 'PM2.5', value: `${this.pm25}`, unit: 'μg/m³', threshold: ENV_THRESHOLDS[5] })
          EnvCard({ title: '气压', value: `${this.pressure}`, unit: 'hPa', threshold: PRESSURE_THRESHOLD })
        }
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.window_background'))
    .padding({ left: '15vp', right: '15vp', bottom: '15vp' })
  }
}

@Component
struct EnvCard {
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
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`${this.value}`)
          .fontSize('32fp')
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.unit)
          .fontSize('14fp')
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column({ space: '8vp' }) {
        Text(alertLevelText(this.getLevel()))
          .fontSize('13fp')
          .fontColor($r('app.color.text_on_accent'))
          .backgroundColor(levelColor(this.getLevel()))
          .padding({ left: '12vp', right: '12vp', top: '6vp', bottom: '6vp' })
          .borderRadius('12vp')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`预警≥${this.threshold.warningMax}  严重≥${this.threshold.criticalMax}`)
          .fontSize('11fp')
          .fontColor($r('app.color.text_secondary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding('13vp')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('12vp')
    .border({ width: '1vp', color: $r('app.color.divider') })
    .shadow(CardShadow)
  }
}