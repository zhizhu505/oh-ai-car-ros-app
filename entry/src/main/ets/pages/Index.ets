import router from '@ohos.router';
import { PatrolStore } from '../store/PatrolStore';
import { CardShadow, CardShadowHover, ElevatedShadow } from '../styles/styles';
import { onlineColor } from '../utils/PatrolUiUtils';

@Entry
@Component
struct Index {
  @State online: boolean = false;
  @State showAnimation: boolean = false;
  private refreshHandler: () => void = (): void => {
    this.online = PatrolStore.getInstance().vehicle.online;
  };

  aboutToAppear(): void {
    this.online = PatrolStore.getInstance().vehicle.online;
    PatrolStore.getInstance().subscribe(this.refreshHandler);
    setTimeout(() => {
      this.showAnimation = true;
    }, 100);
  }

  aboutToDisappear(): void {
    PatrolStore.getInstance().unsubscribe(this.refreshHandler);
  }

  build() {
    Column({ space: '0vp' }) {
      Column({ space: '8vp' }) {
        Row() {
          Column({ space: '4vp' }) {
            Text('智慧仓储巡检')
              .fontSize('28fp')
              .fontColor($r('app.color.text'))
              .fontWeight(FontWeight.Bold)
            Text('Warehouse Intelligent Patrol')
              .fontSize('13fp')
              .fontColor($r('app.color.text_secondary'))
          }
          .alignItems(HorizontalAlign.Start)
          Blank()
          Row({ space: '8vp' }) {
            Column()
              .width('10vp')
              .height('10vp')
              .backgroundColor(onlineColor(this.online))
              .borderRadius('5vp')
              .animation({
                duration: 1000,
                iterations: -1,
                curve: Curve.EaseInOut
              })
            Text(this.online ? '已连接' : '离线预览')
              .fontSize('14fp')
              .fontColor($r('app.color.text_secondary'))
          }
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')

        Text('建图 → 巡检 → 环境采集 → 雷达避障 → 视觉识别 → 告警 → 返回')
          .fontSize('13fp')
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .opacity(0.8)
      }
      .width('100%')
      .padding({ left: '24vp', right: '24vp', top: '20vp', bottom: '16vp' })
      .backgroundColor($r('app.color.header_background'))

      Scroll() {
        Column({ space: '24vp' }) {
          SectionTitle({ title: '五大功能模块' })

          Row({ space: '16vp' }) {
            ModuleEntry({
              moduleNo: '01', title: '环境感知', desc: '温湿度/烟雾/气体',
              accent: $r('app.color.module1_accent'), icon: $r('app.media.tire'),
              url: 'pages/Module1Environment', index: 0
            })
            ModuleEntry({
              moduleNo: '02', title: 'SLAM导航', desc: '建图/巡检/导航',
              accent: $r('app.color.module2_accent'), icon: $r('app.media.vector'),
              url: 'pages/Module2Navigation', index: 1
            })
            ModuleEntry({
              moduleNo: '03', title: '激光雷达', desc: '避障/通道检测',
              accent: $r('app.color.module3_accent'), icon: $r('app.media.tire'),
              url: 'pages/Module3Lidar', index: 2
            })
          }

          Row({ space: '16vp' }) {
            ModuleEntry({
              moduleNo: '04', title: '视觉识别', desc: '人员/货物异常',
              accent: $r('app.color.module4_accent'), icon: $r('app.media.vector'),
              url: 'pages/Module4Vision', index: 3
            })
            ModuleEntry({
              moduleNo: '05', title: 'APP监控', desc: '总览/告警/控制',
              accent: $r('app.color.module5_accent'), icon: $r('app.media.tire'),
              url: 'pages/Module5AppMonitor', index: 4
            })
            Blank().layoutWeight(1)
          }

          SectionTitle({ title: '手动控制' })

          Column({ space: '12vp' }) {
            QuickEntry({
              title: '麦科朗姆轮', icon: $r('app.media.tire'),
              url: 'pages/MecanumWheel'
            })
            QuickEntry({
              title: '单独遥控', icon: $r('app.media.vector'),
              url: 'pages/RemoteControl'
            })
          }

          SectionTitle({ title: '系统设置' })

          Column({ space: '12vp' }) {
            QuickEntry({
              title: '网络设置', icon: $r('app.media.vector'),
              url: 'pages/NetworkSettings'
            })
            QuickEntry({
              title: '环境监测', icon: $r('app.media.tire'),
              url: 'pages/EnvironmentMonitor'
            })
            QuickEntry({
              title: '巡检控制', icon: $r('app.media.vector'),
              url: 'pages/PatrolControl'
            })
            QuickEntry({
              title: '告警记录', icon: $r('app.media.tire'),
              url: 'pages/AlertRecords'
            })
          }
        }
        .padding({ left: '24vp', right: '24vp', top: '20vp', bottom: '32vp' })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.window_background'))
  }
}

@Component
struct SectionTitle {
  @Prop title: string = '';

  build() {
    Row({ space: '10vp' }) {
      Column()
        .width('4vp')
        .height('20vp')
        .backgroundColor($r('app.color.button_primary'))
        .borderRadius('2vp')
      Text(this.title)
        .fontSize('18fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .margin({ bottom: '8vp' })
  }
}

@Component
struct ModuleEntry {
  @Prop moduleNo: string = '01';
  @Prop title: string = '';
  @Prop desc: string = '';
  @Prop accent: ResourceColor = $r('app.color.button_primary');
  @Prop icon: Resource = $r('app.media.app_icon');
  @Prop url: string = '';
  @Prop index: number = 0;
  @State isHover: boolean = false;

  build() {
    Column({ space: '10vp' }) {
      Row() {
        Text(`M${this.moduleNo}`)
          .fontSize('11fp')
          .fontColor($r('app.color.text_on_accent'))
          .backgroundColor(this.accent)
          .padding({ left: '10vp', right: '10vp', top: '4vp', bottom: '4vp' })
          .borderRadius('12vp')
        Blank()
      }
      .width('100%')

      Image(this.icon)
        .width('52vp')
        .height('52vp')
        .opacity(this.isHover ? 1 : 0.9)
        .animation({
          duration: 200,
          curve: Curve.EaseOut
        })

      Text(this.title)
        .fontSize('18fp')
        .fontColor($r('app.color.text'))
        .fontWeight(FontWeight.Bold)

      Text(this.desc)
        .fontSize('13fp')
        .fontColor($r('app.color.text_secondary'))
        .maxLines(2)
        .textAlign(TextAlign.Center)
    }
    .layoutWeight(1)
    .height('160vp')
    .justifyContent(FlexAlign.Center)
    .padding('16vp')
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('18vp')
    .border({ width: '1vp', color: $r('app.color.divider') })
    .shadow(this.isHover ? CardShadowHover : CardShadow)
    .scale({ x: this.isHover ? 1.02 : 1, y: this.isHover ? 1.02 : 1 })
    .animation({
      duration: 200,
      curve: Curve.EaseOut
    })
    .onClick((): void => {
      router.pushUrl({ url: this.url });
    })
    .onHover((isHover: boolean): void => {
      this.isHover = isHover;
    })
  }
}

@Component
struct QuickEntry {
  @Prop title: string = '';
  @Prop icon: Resource = $r('app.media.app_icon');
  @Prop url: string = '';
  @State isHover: boolean = false;

  build() {
    Row({ space: '14vp' }) {
      Image(this.icon)
        .width('40vp')
        .height('40vp')
        .opacity(this.isHover ? 1 : 0.8)
      Column({ space: '2vp' }) {
        Text(this.title)
          .fontSize('16fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Medium)
      }
      .alignItems(HorizontalAlign.Start)
      Blank()
      Row({ space: '4vp' }) {
        Text('查看')
          .fontSize('13fp')
          .fontColor($r('app.color.text_secondary'))
        Text('→')
          .fontSize('16fp')
          .fontColor($r('app.color.button_primary'))
      }
    }
    .layoutWeight(1)
    .height('72vp')
    .padding({ left: '18vp', right: '18vp' })
    .backgroundColor($r('app.color.card_background'))
    .borderRadius('16vp')
    .border({ width: '1vp', color: $r('app.color.divider') })
    .shadow(this.isHover ? CardShadowHover : CardShadow)
    .onClick((): void => {
      router.pushUrl({ url: this.url });
    })
    .onHover((isHover: boolean): void => {
      this.isHover = isHover;
    })
  }
}