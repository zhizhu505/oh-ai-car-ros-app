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
        Column({ space: '12vp' }) {
          PatrolLaunchCard()
            .width('100%')

          Row({ space: '10vp' }) {
            ModuleEntry({
              title: '环境感知',
              desc: '温湿度 / 烟雾 / 光照',
              metric: '异常阈值',
              accent: $r('app.color.module1_accent'),
              url: 'pages/Module1Environment'
            })
              .layoutWeight(1)
            ModuleEntry({
              title: 'SLAM导航',
              desc: '建图 / 路线 / 返回',
              metric: '巡检路线',
              accent: $r('app.color.module2_accent'),
              url: 'pages/Module2Navigation'
            })
              .layoutWeight(1)
          }

          Row({ space: '10vp' }) {
            ModuleEntry({
              title: '激光雷达',
              desc: '避障 / 占用 / 停车',
              metric: '通道占用',
              accent: $r('app.color.module3_accent'),
              url: 'pages/Module3Lidar'
            })
              .layoutWeight(1)
            ModuleEntry({
              title: '视觉识别',
              desc: '人员 / 货物 / 截图',
              metric: '视觉告警',
              accent: $r('app.color.module4_accent'),
              url: 'pages/Module4Vision'
            })
              .layoutWeight(1)
          }

          ControlCard()
            .width('100%')

          AlertPreviewCard()
            .width('100%')

          PatrolSummary()
            .width('100%')
        }
        .padding({ left: '14vp', right: '14vp', top: '12vp', bottom: '16vp' })
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
    Row({ space: '10vp' }) {
      Row({ space: '8vp' }) {
        Text('狭域巡航')
          .fontSize('20fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
        Text('AI PATROL')
          .fontSize('9fp')
          .fontColor($r('app.color.module1_accent'))
          .fontWeight(FontWeight.Bold)
          .padding({ left: '6vp', right: '6vp', top: '2vp', bottom: '2vp' })
          .backgroundColor($r('app.color.module1_accent') + '18')
          .borderRadius('6vp')
      }
      .alignItems(VerticalAlign.Center)
      .layoutWeight(1)

      Row({ space: '6vp' }) {
        Stack() {
          Column()
            .width('8vp')
            .height('8vp')
            .backgroundColor(onlineColor(this.online))
            .borderRadius('4vp')
        }
        .shadow({
          radius: 8,
          offsetX: 0,
          offsetY: 0,
          color: onlineColor(this.online) + '60'
        })
        Text(this.online ? '已连接' : '离线')
          .fontSize('12fp')
          .fontColor($r('app.color.text_secondary'))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
      }
      .alignItems(VerticalAlign.Center)
      .padding({ left: '10vp', right: '12vp', top: '6vp', bottom: '6vp' })
      .backgroundColor($r('app.color.card_elevated'))
      .borderRadius('14vp')
      .border({ width: '1vp', color: $r('app.color.divider') })

      NetworkButton()
    }
    .width('100%')
    .height('56vp')
    .padding({ left: '14vp', right: '14vp', top: '6vp', bottom: '6vp' })
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.header_background'))
    .shadow({
      radius: 6,
      offsetX: 0,
      offsetY: 2,
      color: '#00000030'
    })
  }
}

@Component
struct PatrolLaunchCard {
  build() {
    Column({ space: '12vp' }) {
      Row({ space: '12vp' }) {
        Stack() {
          Column()
            .width('46vp')
            .height('46vp')
            .backgroundColor($r('app.color.module2_accent') + '28')
            .borderRadius('14vp')
          Text('⌁')
            .fontSize('27fp')
            .fontColor($r('app.color.module2_accent'))
            .fontWeight(FontWeight.Bold)
        }
        .alignContent(Alignment.Center)

        Column({ space: '4vp' }) {
          Text('地下管廊智能巡检')
            .fontSize('16fp')
            .fontColor($r('app.color.text'))
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
          Text('预设路线 P0 → P6 · 环境感知 · 异常避障')
            .fontSize('11fp')
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Button('开始管廊巡检')
        .width('100%')
        .height('42vp')
        .fontSize('15fp')
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .backgroundColor($r('app.color.module2_accent'))
        .borderRadius('21vp')
        .shadow({ radius: 10, offsetX: 0, offsetY: 4, color: $r('app.color.module2_accent') + '55' })
        .onClick((): void => {
          router.pushUrl({ url: 'pages/Module2Navigation' });
        })
    }
    .width('100%')
    .padding('14vp')
    .backgroundColor($r('app.color.card_background'))
    .border({ width: '1vp', color: $r('app.color.module2_accent') + '70' })
    .borderRadius('16vp')
    .shadow(CardShadow)
  }
}

@Component
struct SectionTitle {
  @Prop title: string = '';

  build() {
    Row({ space: '8vp' }) {
      Column()
        .width('4vp')
        .height('18vp')
        .backgroundColor($r('app.color.button_primary'))
        .borderRadius('2vp')
      Text(this.title)
        .fontSize('16fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
    }
  }
}

@Component
struct NetworkButton {
  @State isHover: boolean = false;

  build() {
    Button() {
      Stack() {
        Column()
          .width('40vp')
          .height('40vp')
          .backgroundColor(this.isHover ? $r('app.color.module1_accent') + '22' : $r('app.color.card_elevated'))
          .borderRadius('20vp')
        Image($r('app.media.patrol_logo'))
          .width('34vp')
          .height('34vp')
          .borderRadius('17vp')
          .objectFit(ImageFit.Cover)
      }
      .alignContent(Alignment.Center)
    }
    .width('44vp')
    .height('44vp')
    .backgroundColor(Color.Transparent)
    .borderRadius('22vp')
    .border({ width: '1vp', color: this.isHover ? $r('app.color.module1_accent') : $r('app.color.divider') })
    .shadow({
      radius: this.isHover ? 12 : 6,
      offsetX: 0,
      offsetY: this.isHover ? 0 : 3,
      color: this.isHover ? $r('app.color.module1_accent') + '45' : '#00000045'
    })
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
  @Prop title: string = '';
  @Prop desc: string = '';
  @Prop metric: string = '';
  @Prop accent: ResourceColor = $r('app.color.button_primary');
  @Prop url: string = '';
  @State isHover: boolean = false;

  build() {
    Column({ space: '8vp' }) {
      Row({ space: '8vp' }) {
        Column()
          .width('4vp')
          .height('28vp')
          .backgroundColor(this.accent)
          .borderRadius('2vp')
        Column({ space: '2vp' }) {
          Text(this.title)
            .fontSize('15fp')
            .fontColor($r('app.color.text'))
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Column({ space: '6vp' }) {
        Text(this.desc)
          .fontSize('11fp')
          .fontColor($r('app.color.text_secondary'))
          .textAlign(TextAlign.Center)
          .maxLines(1)
        Text(this.metric)
          .fontSize('10fp')
          .fontColor(this.accent)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .padding({ left: '10vp', right: '10vp', top: '3vp', bottom: '3vp' })
          .backgroundColor(this.accent + '18')
          .borderRadius('10vp')
          .maxLines(1)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('110vp')
    .padding({ left: '12vp', right: '12vp', top: '10vp', bottom: '10vp' })
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('14vp')
    .border({ width: this.isHover ? '2vp' : '1vp', color: this.isHover ? this.accent : $r('app.color.divider') })
    .shadow(this.isHover ? {
      radius: 12,
      offsetX: 0,
      offsetY: 0,
      color: this.accent + '55'
    } : CardShadow)
    .scale({ x: this.isHover ? 1.02 : 1, y: this.isHover ? 1.02 : 1 })
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
    Column({ space: '10vp' }) {
      Row() {
        SectionTitle({ title: '手动接管' })
          .layoutWeight(1)
      }
      .width('100%')

      Row({ space: '10vp' }) {
        Stack() {
          Column()
            .width('36vp')
            .height('36vp')
            .backgroundColor($r('app.color.module5_accent') + '18')
            .borderRadius('12vp')
          Image($r('app.media.vector'))
            .width('20vp')
            .height('20vp')
        }
        .alignContent(Alignment.Center)
        Column({ space: '3vp' }) {
          Text('摇杆遥控')
            .fontSize('14fp')
            .fontColor($r('app.color.text'))
            .fontWeight(FontWeight.Bold)
          Text('视频预览 / 轮速调节 / 实时接管')
            .fontSize('11fp')
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Button('进入')
          .height('30vp')
          .fontSize('12fp')
          .fontColor($r('app.color.text_on_accent'))
          .backgroundColor($r('app.color.button_primary'))
          .borderRadius('15vp')
          .onClick((): void => {
            router.pushUrl({ url: 'pages/RemoteControl' });
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding('14vp')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('14vp')
    .border({ width: '1vp', color: $r('app.color.divider') })
    .shadow(CardShadow)
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
    Column({ space: '8vp' }) {
      Row() {
        SectionTitle({ title: '告警预览' })
          .layoutWeight(1)
        Text('查看记录')
          .fontSize('12fp')
          .fontColor($r('app.color.button_primary'))
          .fontWeight(FontWeight.Bold)
          .padding({ left: '10vp', right: '10vp', top: '4vp', bottom: '4vp' })
          .backgroundColor($r('app.color.button_primary') + '16')
          .borderRadius('10vp')
      }
      .width('100%')

      if (this.alerts.length > 0) {
        this.AlertContent(this.alerts[0])
      } else {
        Column({ space: '8vp' }) {
          Row({ space: '8vp' }) {
            Text('正常')
              .fontSize('11fp')
              .fontColor($r('app.color.text_on_accent'))
              .backgroundColor($r('app.color.status_success'))
              .padding({ left: '8vp', right: '8vp', top: '3vp', bottom: '3vp' })
              .borderRadius('8vp')
            Text('暂无告警')
              .fontSize('15fp')
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
        .padding('12vp')
        .backgroundColor($r('app.color.card_background'))
        .borderRadius('12vp')
        .border({ width: '1vp', color: $r('app.color.divider') })
        .shadow(CardShadow)
      }
    }
    .width('100%')
    .padding('12vp')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('14vp')
    .border({ width: '1vp', color: this.isHover ? $r('app.color.alert_warning') : $r('app.color.divider') })
    .shadow(this.isHover ? ElevatedShadow : CardShadow)
  }

  @Builder
  AlertContent(alert: AlertRecord) {
    Column({ space: '6vp' }) {
      Row({ space: '6vp' }) {
        Text(alert.level === AlertLevel.Critical ? '严重' : alert.level === AlertLevel.Warning ? '预警' : '提示')
          .fontSize('10fp')
          .fontColor($r('app.color.text_on_accent'))
          .backgroundColor(alert.level === AlertLevel.Critical ? $r('app.color.alert_critical') : alert.level === AlertLevel.Warning ? $r('app.color.alert_warning') : $r('app.color.status_success'))
          .padding({ left: '6vp', right: '6vp', top: '3vp', bottom: '3vp' })
          .borderRadius('6vp')
        Text(alert.message)
          .fontSize('13fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (alert.aiAnalyzing) {
          Text('AI分析中...')
            .fontSize('10fp')
            .fontColor($r('app.color.button_primary'))
            .maxLines(1)
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row({ space: '6vp' }) {
        Text(`[${alert.time}]`)
          .fontSize('10fp')
          .fontColor($r('app.color.text_secondary'))
        Text(alert.point)
          .fontSize('10fp')
          .fontColor($r('app.color.text_secondary'))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')

      if (alert.aiAnalysis) {
        Row({ space: '6vp' }) {
          Text('AI:')
            .fontSize('10fp')
            .fontColor($r('app.color.button_primary'))
            .fontWeight(FontWeight.Bold)
          Text(alert.aiAnalysis.summary)
            .fontSize('11fp')
            .fontColor($r('app.color.text'))
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding('12vp')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('12vp')
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
    Column({ space: '8vp' }) {
      Row({ space: '8vp' }) {
        SummaryItem({ label: '当前点位', value: 'P2 A区货架' })
          .layoutWeight(1)
        SummaryItem({ label: '下一点位', value: 'P3 窄通道' })
          .layoutWeight(1)
      }
      .width('100%')
      Row({ space: '8vp' }) {
        SummaryItem({ label: '巡检状态', value: '待启动' })
          .layoutWeight(1)
        SummaryItem({ label: '闭环流程', value: '采集 → 识别 → 告警' })
          .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
  }
}

@Component
struct SummaryItem {
  @Prop label: string = '';
  @Prop value: string = '';

  build() {
    Column({ space: '4vp' }) {
      Text(this.label)
        .fontSize('10fp')
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
      Text(this.value)
        .fontSize('13fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .padding({ left: '10vp', right: '10vp', top: '10vp', bottom: '10vp' })
    .backgroundColor($r('app.color.card_elevated'))
    .borderRadius('10vp')
  }
}
