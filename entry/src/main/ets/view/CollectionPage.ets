import { AppUtil } from '@pura/harmony-utils'
import { FetchImagePrimary, FetchServerUrl } from '../apis/AuxiliaryApi'
import { FetchCollectionApi } from '../apis/ProductApi'
import { LoadingView } from '../common/LoadingView'
import { BasicConstants } from '../viewmodel/BasicConstants'
import { NewViewsList, ViewingRecord, VRItems } from '../viewmodel/DataConstraints'

@Component
struct CollectionPage{
  @Consume pageInfo: NavPathStack
  @State data: VRItems[] = []
  @State serverUrl: string = ''
  @State isLoading: boolean = false

  aboutToAppear(): void {
    this.fetchCollection()
    this.fetchServerUrl()
  }

  fetchCollection = async ()=>{
    this.isLoading = true
    const res = await FetchCollectionApi<ViewingRecord>()
    this.data = res.Items
  }
  fetchServerUrl = async () => {
    const res = await FetchServerUrl()
    this.serverUrl = res
  }

  build() {
    NavDestination(){
      Stack() {
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
                        .alt($r('app.media.Image_loading_failed'))
                    }
                    .width('100%')
                    .borderRadius(10)
                    .clip(true)
                    .onClick(() => {
                      this.pageInfo.pushPathByName('Details', { Id: item.Id, Type: item.Type } as NewViewsList)
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
                  .onAppear(() => {
                    this.isLoading = false
                  })
                }

              }, (item: VRItems) => item.Id)
            }

          }
          .padding({ top: 10, left: 10, right: 10, bottom:20 })
        }
        .scrollBar(BarState.Off)

        if (this.isLoading) {
          LoadingView()
        }
      }
    }
    .title('收藏')
    .padding({ top: px2vp(AppUtil.getStatusBarHeight()) })
    .backgroundColor($r('sys.color.background_secondary'))
  }
}

@Builder
export function CollectionPageBuilder(){
  CollectionPage()
}