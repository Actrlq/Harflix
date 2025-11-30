import { FetchSearchApi } from '../apis/ProductApi'
import { BasicConstants } from '../viewmodel/BasicConstants'
import { ViewingRecord, VRItems } from '../viewmodel/DataConstraints'
import { router } from '@kit.ArkUI'
import { KeyboardUtil } from '@pura/harmony-utils'
import { FetchImagePrimary, FetchServerUrl } from '../apis/AuxiliaryApi'

@Entry
@Component
struct SearchPage {
  @State data: VRItems[] = []
  private name: string = ''
  @State imageSrc: PixelMap | ResourceStr = $r('app.media.Image_loading_failed')
  @State serverUrl: string = ''

  aboutToAppear(): void {
    this.fetchServerUrl()
  }
  fetchSearch = async () => {
    const res = await FetchSearchApi<ViewingRecord>(encodeURIComponent(this.name))
    this.data = res.Items
  }
  fetchServerUrl = async () => {
    const res = await FetchServerUrl()
    this.serverUrl = res
  }

  build() {
    Flex({ direction: FlexDirection.Column }) {
      Row() {
        Column() {
          Image($r('app.media.fanhuijiantou'))
            .width('80%')
        }
        .width('10%')
        .onClick(() => {
          router.back()
        })

        Column() {
          TextInput({ placeholder: "输入影片名称", text: $$this.name })
        }
        .layoutWeight(1)
        .margin({ right: 5 })

        Column() {
          Text('搜索')
        }
        .width('10%')
        .onClick(() => {
          this.fetchSearch()
          KeyboardUtil.hide()
        })
      }

      Scroll() {
        Column() {
          GridRow({
            columns: 3,
            gutter: { x: 10, y: 10 },
            direction: GridRowDirection.Row
          }) {
            ForEach(this.data, (item: VRItems) => {
              GridCol() {
                Flex({ direction: FlexDirection.Column }) {
                  Column() {
                    Image(this.serverUrl + FetchImagePrimary(item.Id) + '?maxWidth=400')
                  }
                  .width('100%')
                  .borderRadius(10)
                  .clip(true)
                  .onClick(() => {
                    router.pushUrl({
                      url: 'pages/Details',
                      params: { Id: item.Id, Type: item.Type }
                    }).catch(() => {
                    })
                  })

                  Column() {
                    Text(item.Name)
                      .fontSize(BasicConstants.FONT_NORMAL)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('100%')
                }
                .height(200)
              }

            }, (item: VRItems) => item.Id)
          }
          .width("100%")
          .height("100%")
        }
        .width('100%')
        .height('100%')
        .margin({ top: 10, left: 5, right: 5 })
      }
      .scrollBar(BarState.Off)
    }
    .padding({ left: 10, right: 10, top: 40 })
  }
}