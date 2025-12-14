import { BasicConstants } from "../viewmodel/BasicConstants"
import { router } from "@kit.ArkUI"

@Component
export struct SetUp {
  build() {
    Column() {
      Row() {
        Text('关于')
          .fontSize(BasicConstants.FONT_NORMAL)
          .padding({ left: 10 })

        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize($r('sys.float.Title_L'))
          .fontColor([$r('sys.color.icon_fourth')])
          .margin({ right: 10 })
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .long_list()
      .onClick(() => {
        router.pushUrl({
          url: "pages/set/Aboutapp"
        }).catch(() => {
        })
      })

    }
    .width('100%')
    .height('100%')
    .padding({ top: 50 })
  }

  @Styles
  long_list(){
    .width('100%')
    .height(60)
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .borderRadius($r('sys.float.corner_radius_level8'))
    .padding(10)
    .stateStyles({
      pressed:{.backgroundColor($r('sys.color.titlebar_icon_background_pressed_color'))}
    })
  }

}


