import router from '@ohos.router';
import { PatrolStore } from '../store/PatrolStore';
import { AlertRecord, AlertLevel } from '../model/PatrolModels';
import { CardShadow, CardShadowHover, ElevatedShadow } from '../styles/styles';
import { onlineColor } from '../utils/PatrolUiUtils';

@Entry
@Component
struct Index {
  @State online: boolean = false;
  private refreshHandler: () => void = (): void => {
    this.online = PatrolStore.getInstance().vehicle.online;
  };

  aboutToAppear(): void {
    this.online = PatrolStore.getInstance().vehicle.online;
    PatrolStore.getInstance().subscribe(this.refreshHandler);
  }

  aboutToDisappear(): void {
    PatrolStore.getInstance().unsubscribe(this.refreshHandler);
  }

  build() {
    Column({ space: '0vp' }) {
this.Header()

      Scroll() {
        Column({ space: '14vp' }) {
          Row({ space: '12vp' }) {
            ModuleEntry({
              moduleNo: '01',
              title: '环境感知',
              desc: '温湿度 / 烟雾 / 气体',
              metric: '实时采集',
              accent: $r('app.color.module1_accent'),
              url: 'pages/Module1Environment'
            })
              .layoutWeight(1)
            ModuleEntry({
              moduleNo: '02',
              title: 'SLAM导航',
              desc: '建图 / 路线 / 巡检点',
              metric: '路线巡检',
              accent: $r('app.color.module2_accent'),
              url: 'pages/Module2Navigation'
            })
              .layoutWeight(1)
            ModuleEntry({
              moduleNo: '03',
              title: '激光雷达',
              desc: '避障 / 通道占用检测',
              metric: '通道安全',
              accent: $r('app.color.module3_accent'),
              url: 'pages/Module3Lidar'
            })
              .layoutWeight(1)
            ModuleEntry({
              moduleNo: '04',
              title: '视觉识别',
              desc: '人员 / 货物异常',
              metric: '异常识别',
              accent: $r('app.color.module4_accent'),
              url: 'pages/Module4Vision'
            })
              .layoutWeight(1)
          }
          .height('118vp')

          Row({ space: '14vp' }) {
            ControlCard()
              .layoutWeight(1)
            AlertPreviewCard()
              .layoutWeight(1.25)
          }

          PatrolSummary()
        }
        .padding({ left: '24vp', right: '24vp', top: '18vp', bottom: '24vp' })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.window_background'))
  }

  @Builder
  Header() {
    Row({ space: '12vp' }) {
      Column({ space: '4vp' }) {
        Text('狭域巡航')
          .fontSize('30fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
        Text('Narrow-Space Intelligent Patrol System')
          .fontSize('12fp')
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      NetworkButton()

      Row({ space: '10vp' }) {
        Stack() {
          Column()
            .width('12vp')
            .height('12vp')
            .backgroundColor(onlineColor(this.online))
            .borderRadius('6vp')
        }
        .shadow({
          radius: 12,
          offsetX: 0,
          offsetY: 0,
          color: onlineColor(this.online) + '60'
        })
        Text(this.online ? '已连接' : '离线预览')
          .fontSize('13fp')
          .fontColor($r('app.color.text_secondary'))
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: '24vp', right: '24vp', top: '20vp', bottom: '16vp' })
    .backgroundColor($r('app.color.header_background'))
    .shadow(CardShadow)
  }
}

@Component
struct SectionTitle {
  @Prop title: string = '';

  build() {
    Row({ space: '12vp' }) {
      Column()
        .width('5vp')
        .height('24vp')
        .backgroundColor($r('app.color.button_primary'))
        .borderRadius('3vp')
      Text(this.title)
        .fontSize('20fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
  }
}

@Component
struct NetworkButton {
  @State isHover: boolean = false;

  build() {
    Button() {
      Stack() {
        Column()
          .width('36vp')
          .height('36vp')
          .backgroundColor(this.isHover ? $r('app.color.button_primary') : $r('app.color.card_elevated'))
          .borderRadius('18vp')
        Text('⌁')
          .fontSize('23fp')
          .fontColor(this.isHover ? $r('app.color.text_on_accent') : $r('app.color.button_primary'))
          .fontWeight(FontWeight.Bold)
      }
    }
    .width('44vp')
    .height('44vp')
    .backgroundColor(Color.Transparent)
    .borderRadius('22vp')
    .onHover((isHover: boolean): void => {
      this.isHover = isHover;
    })
    .onClick((): void => {
      router.pushUrl({ url: 'pages/NetworkSettings' });
    })
  }
}

@Component
struct ModuleEntry {
  @Prop moduleNo: string = '01';
  @Prop title: string = '';
  @Prop desc: string = '';
  @Prop metric: string = '';
  @Prop accent: ResourceColor = $r('app.color.button_primary');
  @Prop url: string = '';
  @State isHover: boolean = false;

  build() {
    Column({ space: '8vp' }) {
      Row() {
        Text(`M${this.moduleNo}`)
          .fontSize('11fp')
          .fontColor($r('app.color.text_on_accent'))
          .fontWeight(FontWeight.Bold)
          .backgroundColor(this.accent)
          .padding({ left: '9vp', right: '9vp', top: '3vp', bottom: '3vp' })
          .borderRadius('10vp')
        Blank()
        Text('进入')
          .fontSize('11fp')
          .fontColor(this.accent)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row({ space: '10vp' }) {
        Column()
          .width('4vp')
          .height('44vp')
          .backgroundColor(this.accent)
          .borderRadius('2vp')
        Column({ space: '5vp' }) {
          Text(this.title)
            .fontSize('18fp')
            .fontColor($r('app.color.text'))
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
          Text(this.desc)
            .fontSize('12fp')
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .alignItems(VerticalAlign.Center)

      Row() {
        Text(this.metric)
          .fontSize('11fp')
          .fontColor(this.accent)
          .backgroundColor(this.accent + '18')
          .padding({ left: '8vp', right: '8vp', top: '4vp', bottom: '4vp' })
          .borderRadius('10vp')
        Blank()
        Text(this.title)
          .fontSize('11fp')
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .padding({ left: '14vp', right: '14vp', top: '12vp', bottom: '12vp' })
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('16vp')
    .border({ width: '1vp', color: this.isHover ? this.accent + '55' : $r('app.color.divider') })
    .shadow(this.isHover ? CardShadowHover : CardShadow)
    .scale({ x: this.isHover ? 1.01 : 1, y: this.isHover ? 1.01 : 1 })
    .animation({ duration: 180, curve: Curve.EaseOut })
    .onClick((): void => {
      router.pushUrl({ url: this.url });
    })
    .onHover((isHover: boolean): void => {
      this.isHover = isHover;
    })
  }
}

@Component
struct ControlCard {
  build() {
    Column({ space: '12vp' }) {
      SectionTitle({ title: '手动接管' })
      Row({ space: '12vp' }) {
        Stack() {
          Column()
            .width('42vp')
            .height('42vp')
            .backgroundColor($r('app.color.module5_accent') + '18')
            .borderRadius('14vp')
          Image($r('app.media.vector'))
            .width('24vp')
            .height('24vp')
        }
        .alignContent(Alignment.Center)
        Column({ space: '4vp' }) {
          Text('摇杆遥控')
            .fontSize('17fp')
            .fontColor($r('app.color.text'))
            .fontWeight(FontWeight.Bold)
          Text('视频预览 / 轮速调节 / 实时接管')
            .fontSize('12fp')
            .fontColor($r('app.color.text_secondary'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text('进入')
          .fontSize('13fp')
          .fontColor($r('app.color.button_primary'))
      }
      .height('82vp')
      .padding({ left: '16vp', right: '16vp' })
      .backgroundColor($r('app.color.card_background'))
      .borderRadius('16vp')
      .border({ width: '1vp', color: $r('app.color.divider') })
      .shadow(CardShadow)
      .onClick((): void => {
        router.pushUrl({ url: 'pages/RemoteControl' });
      })
    }
  }
}

@Component
struct AlertPreviewCard {
  @State isHover: boolean = false;
  @State alerts: AlertRecord[] = [];
  private refreshHandler: () => void = (): void => {
    this.loadAlerts();
  };

  aboutToAppear(): void {
    this.loadAlerts();
    PatrolStore.getInstance().subscribe(this.refreshHandler);
  }

  aboutToDisappear(): void {
    PatrolStore.getInstance().unsubscribe(this.refreshHandler);
  }

  loadAlerts(): void {
    this.alerts = PatrolStore.getInstance().alerts.slice(0, 1) as AlertRecord[];
  }

  build() {
    Column({ space: '12vp' }) {
      Row() {
        SectionTitle({ title: '告警预览' })
          .layoutWeight(1)
        Text('查看记录')
          .fontSize('13fp')
          .fontColor($r('app.color.button_primary'))
      }
      if (this.alerts.length > 0) {
        this.AlertContent(this.alerts[0])
      } else {
        Column({ space: '10vp' }) {
          Row({ space: '10vp' }) {
            Text('正常')
              .fontSize('12fp')
              .fontColor($r('app.color.text_on_accent'))
              .backgroundColor($r('app.color.status_success'))
              .padding({ left: '10vp', right: '10vp', top: '4vp', bottom: '4vp' })
              .borderRadius('12vp')
            Text('暂无告警')
              .fontSize('16fp')
              .fontColor($r('app.color.text'))
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
          }
          Text('小车巡检过程中检测到的异常会显示在这里')
            .fontSize('12fp')
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
        }
        .width('100%')
        .padding('14vp')
        .backgroundColor($r('app.color.card_background'))
        .borderRadius('16vp')
        .border({ width: '1vp', color: $r('app.color.divider') })
        .shadow(CardShadow)
      }
    }
  }

  @Builder
  AlertContent(alert: AlertRecord) {
    Column({ space: '10vp' }) {
      Row({ space: '10vp' }) {
        Text(alert.level === AlertLevel.Critical ? '严重异常' : alert.level === AlertLevel.Warning ? '预警' : '提示')
          .fontSize('12fp')
          .fontColor($r('app.color.text_on_accent'))
          .backgroundColor(alert.level === AlertLevel.Critical ? $r('app.color.alert_critical') : alert.level === AlertLevel.Warning ? $r('app.color.alert_warning') : $r('app.color.status_success'))
          .padding({ left: '10vp', right: '10vp', top: '4vp', bottom: '4vp' })
          .borderRadius('12vp')
        Text(`${alert.point}：${alert.message}`)
          .fontSize('16fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .maxLines(1)
        if (alert.aiAnalyzing) {
          Text('AI分析中...')
            .fontSize('11fp')
            .fontColor($r('app.color.button_primary'))
        }
      }
      Text(`[${alert.time}] ${alert.point}`)
        .fontSize('12fp')
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
      if (alert.aiAnalysis) {
        Column({ space: '8vp' }) {
          Row({ space: '6vp' }) {
            Text('AI分析')
              .fontSize('11fp')
              .fontColor($r('app.color.button_primary'))
              .fontWeight(FontWeight.Bold)
            Text(alert.aiAnalysis.summary)
              .fontSize('13fp')
              .fontColor($r('app.color.text'))
              .layoutWeight(1)
              .maxLines(1)
          }
          .width('100%')
          Column({ space: '4vp' }) {
            Row({ space: '6vp' }) {
              Text('风险')
                .fontSize('11fp')
                .fontColor($r('app.color.alert_critical'))
              Text(alert.aiAnalysis.risk)
                .fontSize('12fp')
                .fontColor($r('app.color.text_secondary'))
                .layoutWeight(1)
                .maxLines(1)
            }
            .width('100%')
            if (alert.aiAnalysis.solve && alert.aiAnalysis.solve.length > 0) {
              Column({ space: '3vp' }) {
                Text('处置建议')
                  .fontSize('11fp')
                  .fontColor($r('app.color.button_primary'))
                ForEach(alert.aiAnalysis.solve.slice(0, 2), (step: string, index: number) => {
                  Row({ space: '6vp' }) {
                    Text(`${index + 1}.`)
                      .fontSize('12fp')
                      .fontColor($r('app.color.text_secondary'))
                    Text(step)
                      .fontSize('12fp')
                      .fontColor($r('app.color.text_secondary'))
                      .layoutWeight(1)
                      .maxLines(1)
                  }
                  .width('100%')
                })
              }
              .width('100%')
            }
          }
          .width('100%')
          .padding('8vp')
          .backgroundColor($r('app.color.card_elevated'))
          .borderRadius('10vp')
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding('14vp')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('16vp')
    .border({ width: '1vp', color: this.isHover ? (alert.level === AlertLevel.Critical ? $r('app.color.alert_critical') : alert.level === AlertLevel.Warning ? $r('app.color.alert_warning') : $r('app.color.divider')) : $r('app.color.divider') })
    .shadow(this.isHover ? ElevatedShadow : CardShadow)
    .onClick((): void => {
      router.pushUrl({ url: 'pages/AlertRecords' });
    })
    .onHover((isHover: boolean): void => {
      this.isHover = isHover;
    })
  }
}

@Component
struct PatrolSummary {
  build() {
    Row({ space: '12vp' }) {
      SummaryItem({ label: '当前点位', value: 'P2 A区货架' })
      SummaryItem({ label: '下一点位', value: 'P3 窄通道' })
      SummaryItem({ label: '巡检状态', value: '待启动' })
      SummaryItem({ label: '闭环流程', value: '采集 → 识别 → 告警' })
    }
    .width('100%')
  }
}

@Component
struct SummaryItem {
  @Prop label: string = '';
  @Prop value: string = '';

  build() {
    Column({ space: '5vp' }) {
      Text(this.label)
        .fontSize('11fp')
        .fontColor($r('app.color.text_secondary'))
      Text(this.value)
        .fontSize('15fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
    }
    .layoutWeight(1)
    .padding('12vp')
    .backgroundColor($r('app.color.card_elevated'))
    .borderRadius('12vp')
  }
}
