import { BasicConstants } from "../viewmodel/BasicConstants"
import { router } from "@kit.ArkUI"

@Component
export struct SetUp {
  build() {
    Column() {
      Row() {
        Text('关于')
          .fontSize(BasicConstants.FONT_NORMAL)
          .padding({ left: 20 })
        Image($r('app.media.fanhuijiantou'))
          .height('60%')
          .rotate({ angle: 180 })
          .margin({ right: 20 })
      }
      .width('100%')
      .height(50)
      .backgroundColor(Color.White)
      .borderRadius(10)
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .onClick(()=>{
        router.pushUrl({
          url:"pages/Aboutapp"
        }).catch(() => {
        })
      })

    }
    .width('100%')
    .height('100%')
    .padding({ top: 50 })
  }
}