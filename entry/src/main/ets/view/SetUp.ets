import { ListGroup, ListGroupData } from "../viewmodel/ListGroupModel"

@Component
export struct SetUp {
  @Consume pageInfo: NavPathStack
  private setList: ListGroupData[] = [
    {
      id: 0,
      group: [
        {
          textContent: '默认播放器',
          onclick:()=>{ this.pageInfo.pushPathByName('DefaultPlayer',null) }
        },
        {
          textContent: '关于',
          onclick:()=>{ this.pageInfo.pushPathByName('AboutApp',null) }
        }
      ]
    }
  ]

  build() {
    NavDestination() {
      Column() {
        ForEach(this.setList, (groupData: ListGroupData) => {
          Flex({ direction: FlexDirection.Row, wrap:FlexWrap.Wrap }) {
            ForEach(groupData.group, (item: ListGroup, index: number) => {
              Row() {
                Column() {
                  Text(item.textContent)
                    .padding({ left: 10 })
                }
                .alignItems(HorizontalAlign.Start)

                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize($r('sys.float.Title_L'))
                  .fontColor([$r('sys.color.icon_fourth')])
                  .margin({ right: 10 })
              }
              .justifyContent(FlexAlign.SpaceBetween)
              .stateStyles({
                pressed: {
                  .backgroundColor($r('sys.color.comp_background_secondary'))
                },
                normal: {
                  .backgroundColor($r('sys.color.comp_background_primary'))
                }
              })
              .width('100%')
              .height(50)
              .borderRadius($r('sys.float.corner_radius_level8'))
              .onClick(item.onclick)
            })
          }
          .backgroundColor($r('sys.color.comp_background_list_card'))
          .borderRadius($r('sys.float.corner_radius_level8'))
          .padding($r('sys.float.padding_level2'))
          .margin({ top: 10, bottom: 10, })
        })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 20, right: 20 })
    }
    .title('设置')
    .padding({ top: 40 })
    .backgroundColor($r('sys.color.background_secondary'))

  }

}


