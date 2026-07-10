import {
  AlertLevel,
  ALERT_CATEGORY_ENV,
  ENV_THRESHOLDS,
  EnvSnapshot,
  PRESSURE_THRESHOLD,
  alertLevelText
} from '../model/PatrolModels';
import { PatrolStore } from '../store/PatrolStore';
import { PageHeader, ModuleTabBar, InfoCard } from '../components/PageHeader';
import { EnvCard, ThresholdTable } from '../components/EnvCard';
import { ModuleAlertList } from '../components/ModuleAlertList';
import { levelColor } from '../utils/PatrolUiUtils';
import { CardShadow } from '../styles/styles';

@Entry
@Component
struct Module1Environment {
  @State currentTabIndex: number = 0;
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
    Column({ space: '0vp' }) {
      PageHeader({
        title: '模块1：环境感知',
        subtitle: '温湿度 / 烟雾 / 气体 / 光照 / PM2.5 仓储异常监测',
        accentColor: $r('app.color.module1_accent')
      })

      ModuleTabBar({ currentIndex: $currentTabIndex, tabs: this.tabs, accentColor: $r('app.color.module1_accent') })

      if (this.currentTabIndex === 0) {
        this.LiveDataView()
      } else if (this.currentTabIndex === 1) {
        this.RuleView()
      } else {
        this.AlertView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.window_background'))
  }

  @Builder
  LiveDataView() {
    Column({ space: '12vp' }) {
      Row({ space: '16vp' }) {
        Column({ space: '8vp' }) {
          Row({ space: '12vp' }) {
            Column({ space: '2vp' }) {
              Text('巡检点位')
                .fontSize('13fp')
                .fontColor($r('app.color.text_secondary'))
              Text(this.point)
                .fontSize('16fp')
                .fontColor($r('app.color.text'))
                .fontWeight(FontWeight.Medium)
            }
            .alignItems(HorizontalAlign.Start)
            Blank()
            Text(alertLevelText(this.level))
              .fontSize('14fp')
              .fontColor(Color.White)
              .backgroundColor(levelColor(this.level))
              .padding({ left: '12vp', right: '12vp', top: '8vp', bottom: '8vp' })
              .borderRadius('12vp')
          }
          .width('100%')
          Row({ space: '12vp' }) {
            Column({ space: '2vp' }) {
              Text('更新时间')
                .fontSize('13fp')
                .fontColor($r('app.color.text_secondary'))
              Text(this.updateTime)
                .fontSize('14fp')
                .fontColor($r('app.color.text'))
            }
            .alignItems(HorizontalAlign.Start)
          }
        }
        .layoutWeight(1)
        .padding('16vp')
        .backgroundColor($r('app.color.card_background'))
        .borderRadius('16vp')
        .border({ width: '1vp', color: $r('app.color.divider') })
        .shadow(CardShadow)
      }
      .padding({ left: '20vp', right: '20vp' })

      Scroll() {
        Column({ space: '12vp' }) {
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
      .padding({ left: '20vp', right: '20vp' })
    }
    .layoutWeight(1)
  }

  @Builder
  RuleView() {
    Scroll() {
      Column({ space: '16vp' }) {
        ThresholdTable()
        InfoCard({ title: '异常判断流程' }) {
          Column({ space: '8vp' }) {
            Text('1. 多次采样取平均，去除突变值')
              .fontSize('14fp')
              .fontColor($r('app.color.text'))
            Text('2. 连续 3 次超阈值才触发报警')
              .fontSize('14fp')
              .fontColor($r('app.color.text'))
            Text('3. 绑定当前巡检点位写入日志')
              .fontSize('14fp')
              .fontColor($r('app.color.text'))
            Text('4. 按等级分为：正常 / 预警 / 严重异常')
              .fontSize('14fp')
              .fontColor($r('app.color.text'))
          }
        }
      }
      .padding({ left: '20vp', right: '20vp', bottom: '16vp' })
    }
    .layoutWeight(1)
  }

  @Builder
  AlertView() {
    Column() {
      ModuleAlertList({
        category: ALERT_CATEGORY_ENV,
        emptyHint: '暂无环境异常记录'
      })
    }
    .layoutWeight(1)
    .padding({ left: '20vp', right: '20vp' })
  }
}

