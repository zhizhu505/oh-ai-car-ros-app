import router from '@ohos.router';
import { ButtonShadow, CardShadow, GlowShadow } from '../styles/styles';

@Component
export struct PageHeader {
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop accentColor: ResourceColor = $r('app.color.button_primary');
  backEvent: () => void = (): void => {
    router.back();
  };

  build() {
    Column({ space: '12vp' }) {
      Row({ space: '16vp' }) {
        Row({ space: '14vp' }) {
          Stack() {
            Column()
              .width('6vp')
              .height('40vp')
              .backgroundColor(this.accentColor)
              .borderRadius('3vp')
          }
          .shadow({
            radius: 10,
            offsetX: 0,
            offsetY: 0,
            color: this.accentColor + '40'
          })

          Column({ space: '6vp' }) {
            Text(this.title)
              .fontSize('26fp')
              .fontColor($r('app.color.text'))
              .fontWeight(FontWeight.Bold)
            if (this.subtitle.length > 0) {
              Text(this.subtitle)
                .fontSize('14fp')
                .fontColor($r('app.color.text_secondary'))
                .opacity(0.8)
            }
          }
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)

        Button('返回')
          .width('80vp')
          .height('40vp')
          .fontSize('15fp')
          .fontColor($r('app.color.text'))
          .backgroundColor($r('app.color.button_secondary'))
          .borderRadius('20vp')
          .onClick((): void => {
            this.backEvent();
          })
      }
      .width('100%')

      Divider()
        .color($r('app.color.divider'))
        .strokeWidth('1vp')
        .opacity(0.5)
    }
    .width('100%')
    .padding({ left: '24vp', right: '24vp', top: '20vp', bottom: '12vp' })
    .backgroundColor($r('app.color.header_background'))
    .shadow(CardShadow)
  }
}

@Component
export struct ModuleTabBar {
  @Link currentIndex: number;
  @Prop tabs: string[] = [];
  @Prop accentColor: ResourceColor = $r('app.color.button_primary');
  @Prop title: string = '';
  @Prop subtitle: string = '';

  build() {
    if (this.title.length > 0) {
      Row({ space: '18vp' }) {
        Column({ space: '6vp' }) {
          Text(this.title)
            .fontSize('26fp')
            .fontColor($r('app.color.text'))
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
          Text(this.subtitle.length > 0 ? this.subtitle : '实时数据、规则与异常记录')
            .fontSize('13fp')
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .opacity(0.86)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Row({ space: '10vp' }) {
          ForEach(this.tabs, (tab: string, index: number) => {
            Text(tab)
              .fontSize('13fp')
              .fontColor(this.currentIndex === index ?
                $r('app.color.text_on_accent') : $r('app.color.text'))
              .fontWeight(FontWeight.Bold)
              .width('82vp')
              .height('38vp')
              .textAlign(TextAlign.Center)
              .backgroundColor(this.currentIndex === index ? this.accentColor : $r('app.color.button_secondary'))
              .borderRadius('19vp')
              .border({ width: '1vp', color: this.currentIndex === index ? this.accentColor : $r('app.color.divider') })
              .shadow(this.currentIndex === index ? {
                radius: 14,
                offsetX: 0,
                offsetY: 4,
                color: this.accentColor + '45'
              } : ButtonShadow)
              .onClick((): void => {
                this.currentIndex = index;
              })
          }, (tab: string, index: number) => `${tab}_${index}`)

          Button('返回')
            .width('72vp')
            .height('38vp')
            .fontSize('13fp')
            .fontColor($r('app.color.text'))
            .backgroundColor($r('app.color.button_secondary'))
            .borderRadius('19vp')
            .border({ width: '1vp', color: $r('app.color.divider') })
            .shadow(ButtonShadow)
            .onClick((): void => {
              router.back();
            })
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height('94vp')
      .padding({ left: '28vp', right: '28vp', top: '18vp', bottom: '18vp' })
      .backgroundColor($r('app.color.header_background'))
      .borderRadius('18vp')
      .border({ width: '1vp', color: $r('app.color.divider') })
      .shadow(CardShadow)
      .margin({ left: '20vp', right: '20vp', top: '18vp', bottom: '14vp' })
    } else {
      Row() {
        Scroll() {
          Row({ space: '10vp' }) {
            ForEach(this.tabs, (tab: string, index: number) => {
              Text(tab)
                .fontSize('15fp')
                .fontColor(this.currentIndex === index ?
                  $r('app.color.text_on_accent') : $r('app.color.text_secondary'))
                .fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Medium)
                .padding({ left: '26vp', right: '26vp', top: '10vp', bottom: '10vp' })
                .backgroundColor(this.currentIndex === index ? this.accentColor : $r('app.color.card_elevated'))
                .borderRadius('18vp')
                .border({ width: '1vp', color: this.currentIndex === index ? this.accentColor : $r('app.color.divider') })
                .shadow(this.currentIndex === index ? {
                  radius: 16,
                  offsetX: 0,
                  offsetY: 0,
                  color: this.accentColor + '45'
                } : CardShadow)
                .onClick((): void => {
                  this.currentIndex = index;
                })
            }, (tab: string, index: number) => `${tab}_${index}`)
          }
          .height('42vp')
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: '20vp', right: '20vp', top: '12vp', bottom: '12vp' })
      .backgroundColor($r('app.color.header_background'))
    }
  }
}

@Component
export struct InfoCard {
  @Prop title: string = '';
  @BuilderParam content: () => void = this.defaultContent;

  @Builder
  defaultContent() {
    Text('')
  }

  build() {
    Column({ space: '12vp' }) {
      if (this.title.length > 0) {
        Text(this.title)
          .fontSize('17fp')
          .fontColor($r('app.color.text'))
          .fontWeight(FontWeight.Bold)
          .width('100%')
      }
      this.content()
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
export struct StatusBadge {
  @Prop text: string = '';
  @Prop bgColor: ResourceColor = $r('app.color.button_secondary');

  build() {
    Text(this.text)
      .fontSize('13fp')
      .fontColor($r('app.color.text_on_accent'))
      .backgroundColor(this.bgColor)
      .padding({ left: '12vp', right: '12vp', top: '6vp', bottom: '6vp' })
      .borderRadius('16vp')
  }
}
