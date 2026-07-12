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
    Column({ space: '10vp' }) {
      Row({ space: '12vp' }) {
        Row({ space: '12vp' }) {
          Stack() {
            Column()
              .width('5vp')
              .height('36vp')
              .backgroundColor(this.accentColor)
              .borderRadius('3vp')
          }
          .shadow({
            radius: 8,
            offsetX: 0,
            offsetY: 0,
            color: this.accentColor + '40'
          })

          Column({ space: '4vp' }) {
            Text(this.title)
              .fontSize('22fp')
              .fontColor($r('app.color.text'))
              .fontWeight(FontWeight.Bold)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            if (this.subtitle.length > 0) {
              Text(this.subtitle)
                .fontSize('13fp')
                .fontColor($r('app.color.text_secondary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .opacity(0.85)
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .layoutWeight(1)

        Button('返回')
          .width('68vp')
          .height('36vp')
          .fontSize('13fp')
          .fontColor($r('app.color.text'))
          .backgroundColor($r('app.color.button_secondary'))
          .borderRadius('18vp')
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
    .padding({ left: '16vp', right: '16vp', top: '14vp', bottom: '10vp' })
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
    Column({ space: '10vp' }) {
      if (this.title.length > 0) {
        Row({ space: '12vp' }) {
          Stack() {
            Column()
              .width('5vp')
              .height('36vp')
              .backgroundColor(this.accentColor)
              .borderRadius('3vp')
          }
          .shadow({
            radius: 8,
            offsetX: 0,
            offsetY: 0,
            color: this.accentColor + '40'
          })

          Column({ space: '4vp' }) {
            Text(this.title)
              .fontSize('22fp')
              .fontColor($r('app.color.text'))
              .fontWeight(FontWeight.Bold)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.subtitle.length > 0 ? this.subtitle : '实时数据、规则与异常记录')
              .fontSize('12fp')
              .fontColor($r('app.color.text_secondary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .opacity(0.85)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button('返回')
            .width('68vp')
            .height('36vp')
            .fontSize('13fp')
            .fontColor($r('app.color.text'))
            .backgroundColor($r('app.color.button_secondary'))
            .borderRadius('18vp')
            .border({ width: '1vp', color: $r('app.color.divider') })
            .shadow(ButtonShadow)
            .onClick((): void => {
              router.back();
            })
        }
        .width('100%')
      }

      Row() {
        Scroll() {
          Row({ space: '8vp' }) {
            ForEach(this.tabs, (tab: string, index: number) => {
              Text(tab)
                .fontSize('13fp')
                .fontColor(this.currentIndex === index ?
                  $r('app.color.text_on_accent') : $r('app.color.text'))
                .fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Medium)
                .padding({ left: '16vp', right: '16vp', top: '8vp', bottom: '8vp' })
                .backgroundColor(this.currentIndex === index ? this.accentColor : $r('app.color.card_elevated'))
                .borderRadius('16vp')
                .border({ width: '1vp', color: this.currentIndex === index ? this.accentColor : $r('app.color.divider') })
                .shadow(this.currentIndex === index ? {
                  radius: 10,
                  offsetX: 0,
                  offsetY: 3,
                  color: this.accentColor + '40'
                } : CardShadow)
                .onClick((): void => {
                  this.currentIndex = index;
                })
            }, (tab: string, index: number) => `${tab}_${index}`)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: '16vp', right: '16vp', top: '14vp', bottom: '10vp' })
    .backgroundColor($r('app.color.header_background'))
    .shadow(CardShadow)
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
    Column({ space: '10vp' }) {
      if (this.title.length > 0) {
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
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
      }
      this.content()
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
export struct StatusBadge {
  @Prop text: string = '';
  @Prop bgColor: ResourceColor = $r('app.color.button_secondary');

  build() {
    Text(this.text)
      .fontSize('12fp')
      .fontColor($r('app.color.text_on_accent'))
      .backgroundColor(this.bgColor)
      .padding({ left: '10vp', right: '10vp', top: '5vp', bottom: '5vp' })
      .borderRadius('12vp')
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
  }
}
