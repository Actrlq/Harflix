import { FetchSearchApi } from '../apis/ProductApi'
import { BasicConstants } from '../viewmodel/BasicConstants'
import { NewViewsList, ViewingRecord, VRItems } from '../viewmodel/DataConstraints'
import { FetchImagePrimary, FetchServerUrl } from '../apis/AuxiliaryApi'
import { LoadingView } from '../common/LoadingView'

@Component
struct SearchPage {
  @Consume pageInfo: NavPathStack
  @State data: VRItems[] = []
  private name: string = ''
  @State serverUrl: string = ''
  @State isLoading: boolean = false

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

  @Builder
  buildSearchBar() {
    Column() {
      Search({ value: this.name })
        .searchButton('搜索')
        .placeholderColor(Color.Gray)
        .placeholderFont({ size: 16 })
        .onSubmit((value: string) => {
          this.isLoading = true
          this.name = value
          this.fetchSearch()
        })
    }
    .width('80%')
    .margin({ right: 15 })
  }

  build() {
    NavDestination() {
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
                      this.pageInfo.replacePathByName('Details', { Id: item.Id, Type: item.Type } as NewViewsList)
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
                  .onAppear(()=> {
                    this.isLoading = false
                  })
                }

              }, (item: VRItems) => item.Id)
            }

          }
          .padding({ top: 10, left: 10, right: 10 })
        }
        .scrollBar(BarState.Off)

        if (this.isLoading) {
          LoadingView()
        }
      }

    }
    .menus(this.buildSearchBar())
    .padding({ top: 40 })
    .backgroundColor($r('sys.color.background_secondary'))

  }
}

@Builder
export function SearchPageBuilder() {
  SearchPage()
}