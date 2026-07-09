import { carApi } from '../CarUtill/CarApi'
import { CarEncode } from '../CarUtill/CarEncode';
import { RockerComponent, RockerOptions } from "rocker"

@Component
struct CarRockerComponents {
  tiltStyle: ImageBitmap = new ImageBitmap("img/remote.svg");
  backgroundStyle: ImageBitmap = new ImageBitmap("img/remote_background.svg");
  private rockerOptions: RockerOptions = new RockerOptions()

  aboutToAppear(): void {
    this.rockerOptions.tiltWidth = 0.6
    this.rockerOptions.getTiltStyle = (): ImageBitmap => this.tiltStyle
    this.rockerOptions.getBackgroundStyle = (): ImageBitmap => this.backgroundStyle
    this.rockerOptions.tiltEvent = (tiltX: number, tiltY: number, event?: TouchEvent): void => {
      carApi.send(CarEncode.CtrlCarEncode(tiltX, tiltY));
    }
  }

  build(): void {
    RockerComponent({
      rockerOptions: this.rockerOptions
    })
  }
}

export { CarRockerComponents }
