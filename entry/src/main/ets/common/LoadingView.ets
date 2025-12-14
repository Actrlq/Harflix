
@Builder
export function LoadingView() {
  Column() {
    Row() {
      LoadingProgress()
        .color(Color.Green)
    }
    .width(64)
    .aspectRatio(1)

    Text('加载中...')
      .fontSize($r('sys.float.Body_L'))
      .fontColor($r('sys.color.font_secondary'))
  }
  .alignItems(HorizontalAlign.Center)
  .justifyContent(FlexAlign.Center)
  .backgroundColor($r('sys.color.background_secondary'))
  .height('100%')
  .width('100%')
  .transition(
    TransitionEffect.asymmetric(
      TransitionEffect.opacity(1),
      TransitionEffect.opacity(0).animation({ duration: 1200, curve: Curve.Ease })
    )
  )
}