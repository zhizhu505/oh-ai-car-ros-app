import { ButtonShadow } from '../styles/styles';

@Component
export struct ActionButton {
  @Prop label: string = '';
  @Prop bgColor: ResourceColor = $r('app.color.button_primary');
  @Prop fullWidth: boolean = false;
  onTap: () => void = (): void => {
  };

  build() {
    Button(this.label)
      .fontSize('14fp')
      .fontColor($r('app.color.text_on_accent'))
      .backgroundColor(this.bgColor)
      .borderRadius('20vp')
      .height('40vp')
      .width(this.fullWidth ? '100%' : undefined)
      .shadow(ButtonShadow)
      .onClick((): void => {
        this.onTap();
      })
  }
}
