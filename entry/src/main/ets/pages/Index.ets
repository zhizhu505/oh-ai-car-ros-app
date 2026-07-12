import router from '@ohos.router';
import { PatrolStore } from '../store/PatrolStore';
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

      Column({ space: '8vp' }) {
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
        .height('96vp')

        Row({ space: '12vp' }) {
          ControlCard()
            .layoutWeight(1)
          AlertPreviewCard()
            .layoutWeight(1)
        }
        .height('98vp')

        PatrolSummary()
          .height('56vp')
      }
      .layoutWeight(1)
      .padding({ left: '22vp', right: '22vp', top: '8vp', bottom: '8vp' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.window_background'))
  }

  @Builder
  Header() {
    Row({ space: '16vp' }) {
      Column({ space: '4vp' }) {
        Row({ space: '10vp' }) {
          Text('狭域巡航')
            .fontSize('26fp')
            .fontColor($r('app.color.text'))
            .fontWeight(FontWeight.Bold)
            .maxLines(1)

          Text('AI PATROL')
            .fontSize('10fp')
            .fontColor($r('app.color.module1_accent'))
            .fontWeight(FontWeight.Bold)
            .letterSpacing(0)
            .padding({ left: '10vp', right: '10vp', top: '4vp', bottom: '4vp' })
            .backgroundColor($r('app.color.module1_accent') + '18')
            .borderRadius('10vp')
        }
        .alignItems(VerticalAlign.Center)

        Row({ space: '12vp' }) {
          Text('Narrow-Space Intelligent Patrol System')
            .fontSize('10fp')
            .fontColor($r('app.color.text_secondary'))
            .fontWeight(FontWeight.Medium)
            .maxLines(1)

          Column()
            .width('1vp')
            .height('12vp')
            .backgroundColor($r('app.color.divider'))
            .opacity(0.8)

          Text('智能巡检 · 环境感知 · 自主导航')
            .fontSize('10fp')
            .fontColor($r('app.color.text_secondary'))
            .opacity(0.85)
            .maxLines(1)
        }
        .alignItems(VerticalAlign.Center)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      NetworkButton()

      Row({ space: '10vp' }) {
        Stack() {
          Column()
            .width('10vp')
            .height('10vp')
            .backgroundColor(onlineColor(this.online))
            .borderRadius('5vp')
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
          .fontWeight(FontWeight.Medium)
      }
      .alignItems(VerticalAlign.Center)
      .padding({ left: '12vp', right: '14vp', top: '8vp', bottom: '8vp' })
      .backgroundColor($r('app.color.card_elevated'))
      .borderRadius('18vp')
      .border({ width: '1vp', color: $r('app.color.divider') })
    }
    .width('100%')
    .height('72vp')
    .padding({ left: '28vp', right: '28vp', top: '8vp', bottom: '8vp' })
    .backgroundColor($r('app.color.header_background'))
    .shadow({
      radius: 10,
      offsetX: 0,
      offsetY: 4,
      color: '#00000035'
    })
  }
}

@Component
struct SectionTitle {
  @Prop title: string = '';

  build() {
      Row({ space: '12vp' }) {
        Column()
          .width('5vp')
          .height('22vp')
          .backgroundColor($r('app.color.button_primary'))
          .borderRadius('3vp')
      Text(this.title)
        .fontSize('18fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Bold)
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
          .width('44vp')
          .height('44vp')
          .backgroundColor(this.isHover ? $r('app.color.module1_accent') + '22' : $r('app.color.card_elevated'))
          .borderRadius('22vp')
        Image($r('app.media.patrol_logo'))
          .width('38vp')
          .height('38vp')
          .borderRadius('19vp')
          .objectFit(ImageFit.Cover)
      }
      .alignContent(Alignment.Center)
    }
    .width('48vp')
    .height('48vp')
    .backgroundColor(Color.Transparent)
    .borderRadius('28vp')
    .border({ width: '1vp', color: this.isHover ? $r('app.color.module1_accent') : $r('app.color.divider') })
    .shadow({
      radius: this.isHover ? 14 : 8,
      offsetX: 0,
      offsetY: this.isHover ? 0 : 4,
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
    Column({ space: '6vp' }) {
      Row({ space: '10vp' }) {
        Column()
          .width('5vp')
          .height('32vp')
          .backgroundColor(this.accent)
          .borderRadius('3vp')
        Column({ space: '6vp' }) {
          Text(this.title)
            .fontSize('17fp')
            .fontColor($r('app.color.text'))
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Column({ space: '7vp' }) {
        Text(this.desc)
          .fontSize('12fp')
          .fontColor($r('app.color.text_secondary'))
          .textAlign(TextAlign.Center)
          .maxLines(1)
        Text(this.metric)
          .fontSize('11fp')
          .fontColor(this.accent)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .padding({ left: '12vp', right: '12vp', top: '3vp', bottom: '3vp' })
          .backgroundColor(this.accent + '18')
          .borderRadius('11vp')
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .padding({ left: '13vp', right: '13vp', top: '9vp', bottom: '9vp' })
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('16vp')
    .border({ width: this.isHover ? '2vp' : '1vp', color: this.isHover ? this.accent : $r('app.color.divider') })
    .shadow(this.isHover ? {
      radius: 16,
      offsetX: 0,
      offsetY: 0,
      color: this.accent + '55'
    } : CardShadow)
    .scale({ x: this.isHover ? 1.015 : 1, y: this.isHover ? 1.015 : 1 })
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
    Column({ space: '7vp' }) {
      Row() {
        SectionTitle({ title: '手动接管' })
          .layoutWeight(1)
      }
      .width('100%')

      Row({ space: '12vp' }) {
        Stack() {
          Column()
            .width('34vp')
            .height('34vp')
            .backgroundColor($r('app.color.module5_accent') + '18')
            .borderRadius('14vp')
          Image($r('app.media.vector'))
            .width('20vp')
            .height('20vp')
        }
        .alignContent(Alignment.Center)
        Column({ space: '4vp' }) {
          Text('摇杆遥控')
            .fontSize('14fp')
            .fontColor($r('app.color.text'))
            .fontWeight(FontWeight.Bold)
          Text('视频预览 / 轮速调节 / 实时接管')
            .fontSize('10fp')
            .fontColor($r('app.color.text_secondary'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text('进入')
          .fontSize('13fp')
          .fontColor($r('app.color.button_primary'))
          .fontWeight(FontWeight.Bold)
      }
      .layoutWeight(1)
      .width('100%')
      .onClick((): void => {
        router.pushUrl({ url: 'pages/RemoteControl' });
      })
    }
    .width('100%')
    .height('100%')
    .padding({ left: '16vp', right: '16vp', top: '10vp', bottom: '10vp' })
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('16vp')
    .border({ width: '1vp', color: $r('app.color.divider') })
    .shadow(CardShadow)
  }
}

@Component
struct AlertPreviewCard {
  @State isHover: boolean = false;

  build() {
    Column({ space: '7vp' }) {
      Row() {
        SectionTitle({ title: '告警预览' })
          .layoutWeight(1)
        Text('查看记录')
          .fontSize('12fp')
          .fontColor($r('app.color.button_primary'))
          .fontWeight(FontWeight.Bold)
          .padding({ left: '10vp', right: '10vp', top: '4vp', bottom: '4vp' })
          .backgroundColor($r('app.color.button_primary') + '16')
          .borderRadius('12vp')
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Column({ space: '10vp' }) {
        Row({ space: '10vp' }) {
          Text('预警')
            .fontSize('12fp')
            .fontColor($r('app.color.text_on_accent'))
            .backgroundColor($r('app.color.alert_warning'))
            .padding({ left: '10vp', right: '10vp', top: '4vp', bottom: '4vp' })
            .borderRadius('12vp')
          Text('A区货架2 湿度偏高')
            .fontSize('13fp')
            .fontColor($r('app.color.text'))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .maxLines(1)
        }
        Text('10:32 湿度 78%，建议复检通风')
          .fontSize('11fp')
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
      }
      .width('100%')
      .layoutWeight(1)
      .onClick((): void => {
        router.pushUrl({ url: 'pages/AlertRecords' });
      })
      .onHover((isHover: boolean): void => {
        this.isHover = isHover;
      })
    }
    .width('100%')
    .height('100%')
    .padding({ left: '16vp', right: '16vp', top: '10vp', bottom: '10vp' })
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('16vp')
    .border({ width: '1vp', color: this.isHover ? $r('app.color.alert_warning') : $r('app.color.divider') })
    .shadow(this.isHover ? ElevatedShadow : CardShadow)
  }
}

@Component
struct PatrolSummary {
  build() {
    Row({ space: '10vp' }) {
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
    Column({ space: '4vp' }) {
      Text(this.label)
        .fontSize('10fp')
        .fontColor($r('app.color.text_secondary'))
      Text(this.value)
        .fontSize('14fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ left: '12vp', right: '12vp', top: '8vp', bottom: '8vp' })
    .backgroundColor($r('app.color.card_elevated'))
    .borderRadius('12vp')
  }
}
