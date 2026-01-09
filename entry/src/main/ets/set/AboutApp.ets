import { AppUtil } from "@pura/harmony-utils"
import { BasicConstants } from "../viewmodel/BasicConstants"
import { common } from "@kit.AbilityKit"
import { BusinessError } from '@kit.BasicServicesKit'

@Component
struct AboutApp {
  Gitee() {
    let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
    let webUrl: string = "https://gitee.com/Actrlq/harflix"

    try {
      context.openLink(webUrl)
        .catch((err: BusinessError) => {
          console.error(`跳转失败，错误码: ${err.code}, 错误信息: ${err.message}`);
        });
    } catch (paramError) {
      console.error(`调用openLink失败，错误码: ${paramError.code}, 错误信息: ${paramError.message}`);
    }
  }

  Github() {
    let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
    let webUrl: string = "https://github.com/Actrlq/Harflix"

    try {
      context.openLink(webUrl)
        .catch((err: BusinessError) => {
          console.error(`跳转失败，错误码: ${err.code}, 错误信息: ${err.message}`);
        });
    } catch (paramError) {
      console.error(`调用openLink失败，错误码: ${paramError.code}, 错误信息: ${paramError.message}`);
    }
  }

  build() {
    NavDestination(){
      Column() {
        Column() {
          Image($r('app.media.app_logo'))
            .width('20%')
            .margin({ bottom: 10 })
          Text($r('app.string.app_name'))
            .fontSize(BasicConstants.FONT_BIG)
            .margin({ bottom: 5 })
          Text(`V ${AppUtil.getVersionName()}`)
            .fontSize(BasicConstants.FONT_NORMAL)
        }
        .height('40%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Row() {
            Text('Github仓库地址')
              .fontSize(BasicConstants.FONT_NORMAL)

            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize($r('sys.float.Title_L'))
              .fontColor([$r('sys.color.icon_fourth')])
              .margin({ right: 10 })

          }
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          .long_list()
          .onClick(() => {
            this.Github()
          })

          Row() {
            Text('Gitee仓库地址')
              .fontSize(BasicConstants.FONT_NORMAL)

            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize($r('sys.float.Title_L'))
              .fontColor([$r('sys.color.icon_fourth')])
              .margin({ right: 10 })
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          .long_list()
          .onClick(() => {
            this.Gitee()
          })

        }
        .width('100%')
        .backgroundColor($r('sys.color.comp_background_list_card'))
        .borderRadius($r('sys.float.corner_radius_level6'))
        .padding(5)
      }
      .width('100%')
      .height('100%')
      .padding({ left: 20, right: 20 })
    }
    .title('关于')
    .padding({top:40})
    .backgroundColor($r('sys.color.background_secondary'))

  }

  @Styles
  long_list(){
    .width('100%')
    .height(60)
    .padding(10)
    .borderRadius($r('sys.float.corner_radius_level8'))
    .stateStyles({
      pressed: {.backgroundColor($r('sys.color.comp_background_secondary'))},
      normal: {.backgroundColor($r('sys.color.comp_background_primary'))}
    })
  }

}

@Builder
export function AboutAppBuilder(){
  AboutApp()
}