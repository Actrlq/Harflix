import { BasicConstants } from "../viewmodel/BasicConstants"
import { ServerViews, SVItems, NewViewsList, VRItems, ViewingRecord } from "../viewmodel/DataConstraints"
import { FetchNewViewsListApi, FetchServerViewsApi, FetchViewingRecordApi } from "../apis/ProductApi"
import { LengthMetrics } from "@kit.ArkUI"
import { AppUtil, KvUtil, NetworkUtil, ToastUtil } from "@pura/harmony-utils"
import { FetchImageBackdrop, FetchImagePrimary, FetchServerUrl } from "../apis/AuxiliaryApi"
import { distributedKVStore } from "@kit.ArkData"
import { UserInfo } from "../viewmodel/DataConstraints"
import { LoadingView } from "../common/LoadingView"

@Component
export struct MediaLibrary {
  @Consume pageInfo: NavPathStack
  @State ViewList: Array<NewViewsList>[][] = []
  @State MediaList: Array<SVItems> = []
  @State ListId: string[] = []
  @State WatchList: Array<VRItems> = []
  @State serverUrl: string = ''
  @StorageProp('embyList') @Watch('onEmbyList') embyList: UserInfo[] = []
  @State servername: string = ''
  @State token: string = ''
  @State isLoading: boolean = true
  @State refreshing: boolean = false

  @Builder
  ListUtils(name: string, index: number, id: string) {
    Flex({ direction: FlexDirection.Column }) {
      Flex({ justifyContent: FlexAlign.SpaceBetween }) {
        Text(name)
          .fontSize(BasicConstants.FONT_BIG)
          .fontWeight(FontWeight.Bold)
        Text('更多')
          .fontSize(BasicConstants.FONT_NORMAL)
          .onClick(() => {
            this.pageInfo.pushPathByName('EpisodeView', { Name: name, Id: id } as SVItems)
          })
      }
      .height(25)

      List({ space: 5 }) {
        ForEach(this.ViewList[index], (item: NewViewsList) => {
          ListItem() {
            Flex({ direction: FlexDirection.Column }) {
              Column() {
                Image(this.serverUrl + FetchImagePrimary(item.Id) + '?maxWidth=400')
                  .alt($r('app.media.Image_loading_failed'))
              }
              .width('100%')
              .borderRadius(10)
              .clip(true)

              Column() {
                Text(item.Name)
                  .fontSize(BasicConstants.FONT_NORMAL)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .height(20)
            }
            .margin({ top: 5, bottom: 5 })

          }
          .height('100%')
          .width(120)
          .onClick(() => {
            this.pageInfo.pushPathByName('Details', { Id: item.Id, Type: item.Type } as NewViewsList)
          })
        }, (item: NewViewsList) => item.Id)

      }
      .width('100%')
      .height('100%')
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)

    }
    .width('100%')
    .height('100%')
  }

  @Builder
  serverMenu() {
    Menu() {
      ForEach(this.embyList, (item: UserInfo) => {
        MenuItem({
          content: item.servername ? item.servername : '无名称'
        })
          .backgroundColor(this.token == item.token ? 'rgba(144,238,144,1)' : Color.Transparent)
          .onClick(() => {
            this.isLoading = true
            KvUtil.put('FirstLoad', 'emby_' + item.userId).then(() => {
              this.fetchServerViews().then(() => {
                this.AddonData()
              })
              this.fetchViewingRecord()
              this.fetchServerUrl()
              this.getServername()
            })
          })
      })
    }
    .menuItemDivider({
      strokeWidth: LengthMetrics.vp(1.5),
      color: '#d5d5d5',
    })
  }

  aboutToAppear(): void {
    this.ViewList = []
    this.MediaList = []
    this.WatchList = []
    this.ListId = []
    setTimeout(() => {
      this.isLoading = false
    }, 30000)
    if (NetworkUtil.isNetworkAvailable()) {
      this.fetchServerViews().then(() => {
        this.AddonData()
      })
      this.fetchViewingRecord()
      this.fetchServerUrl()
      this.fetchKeydata()
      this.getServername()
    } else {
      ToastUtil.showToast('网络不可用')
    }

  }

  fetchServerViews = async () => {
    // this.MediaList = []
    // this.ListId = []
    const res = await FetchServerViewsApi<ServerViews>()
    this.MediaList = res.Items
    this.ListId = res.Items.filter(items => items.Name !== '播放列表').map((item: SVItems) => item.Id)
  }
  fetchNewViewsList = async (id: string) => {
    try {
      const res = await FetchNewViewsListApi<Array<NewViewsList>[]>(id)
      return res ?? []
    } catch (err) {
      console.error(`Fetch failed for fetchNewViewsList ${id}:`, err)
      return []
    }
  }
  AddonData = async () => {
    // this.ViewList = []
    // 使用 Promise.all 并行处理异步请求
    const fetchPromises = this.ListId.map((item): Promise<NewViewsList[][]> => this.fetchNewViewsList(item))
    const results = await Promise.all(fetchPromises)

    // 直接赋值代替 push 操作
    this.ViewList = results.filter(item => item.length > 0)
    setTimeout(() => {
      this.isLoading = false
    }, 1000)
  }
  fetchViewingRecord = async () => {
    // this.WatchList = []
    const res = await FetchViewingRecordApi<ViewingRecord>()
    this.WatchList = res.Items
  }
  fetchServerUrl = async () => {
    this.serverUrl = ''
    const res = await FetchServerUrl()
    this.serverUrl = res
  }
  fetchKeydata = () => {
    this.embyList = []
    const keyPrefix = "emby"
    KvUtil.getEntries(keyPrefix).then((res) => {
      res.forEach((entry: distributedKVStore.Entry) => {
        this.embyList.push(JSON.parse(entry.value.value as string))
      })
    })
  }
  getServername = async () => {
    const key = await KvUtil.get('FirstLoad') as string
    const res = await KvUtil.get(key)
    const UserInfo: UserInfo = JSON.parse(res as string)
    this.servername = UserInfo.servername
    this.token = UserInfo.token
  }

  onEmbyList() {
    if (this.embyList.length > 0) {
      this.fetchServerViews().then(() => {
        this.AddonData()
      })
      this.fetchViewingRecord()
      this.fetchServerUrl()
      this.getServername()
    } else {
      this.ViewList = []
      this.MediaList = []
      this.WatchList = []
      this.ListId = []
    }
  }

  build() {
    Refresh({ refreshing: $$this.refreshing,promptText:'正在刷新...'}) {
      Scroll() {
        Column() {
          //顶部状态栏
          Row() {
            Column() {
              Image($r('app.media.emby'))
                .height('70%')
            }
            .width('25%')
            .alignItems(HorizontalAlign.Start)
            .bindMenu(this.serverMenu())

            Column() {
              Text(this.servername ? this.servername : 'Harflix')
                .fontSize(BasicConstants.FONT_NORMAL)
                .fontSize(BasicConstants.FONT_BIG)
            }
            .width('50%')
            .justifyContent(FlexAlign.Center)

            Column() {
              SymbolGlyph($r('sys.symbol.magnifyingglass'))
                .fontSize(25)
            }
            .width('15%')
            .onClick(() => {
              this.pageInfo.pushPathByName('SearchPage', null)
            })

            Column() {
              SymbolGlyph($r('sys.symbol.star_badge_list'))
                .fontSize(25)
            }
            .width('10%')
            .onClick(() => {
              this.pageInfo.pushPathByName('CollectionPage', null)
            })

          }
          .width('100%')
          .height(50)
          .padding({ left: 10, right: 10 })

          Blank().layoutWeight(1)

          Stack() {
            //主页内容
            Column() {

              //继续观看
              Flex({ direction: FlexDirection.Column }) {
                if (this.WatchList.length > 0) {
                  Text('继续观看')
                    .fontSize(BasicConstants.FONT_BIG)
                    .height(25)
                    .fontWeight(FontWeight.Bold)
                  List({ space: 5 }) {
                    ForEach(this.WatchList, (item: VRItems) => {
                      ListItem() {
                        Flex({ direction: FlexDirection.Column }) {
                          Column() {
                            Image(this.serverUrl + FetchImageBackdrop(item.SeriesId))
                              .alt($r('app.media.Image_loading_failed'))
                          }
                          .width('100%')
                          .borderRadius(10)
                          .clip(true)
                          .onClick(() => {
                            this.pageInfo.pushPathByName('Details',
                              { Id: item.SeriesId, Type: item.Type } as NewViewsList)
                          })

                          Column() {
                            Text(`${item.SeriesName}: S${item.ParentIndexNumber}E${item.IndexNumber}`)
                              .fontSize(BasicConstants.FONT_NORMAL)
                          }
                          .width('100%')
                          .justifyContent(FlexAlign.Center)
                        }
                      }
                      .height('100%')
                      .width(240)
                    }, (item: VRItems) => item.Id)

                  }
                  .width('100%')
                  .height(150)
                  .listDirection(Axis.Horizontal)
                  .scrollBar(BarState.Off)
                }
              }

              //媒体库列表
              Flex({ direction: FlexDirection.Column }) {
                if (this.MediaList.length > 0) {
                  Text('媒体库')
                    .fontSize(BasicConstants.FONT_BIG)
                    .height(25)
                    .fontWeight(FontWeight.Bold)
                    .textAlign(TextAlign.Start)
                  List({ space: 5 }) {
                    ForEach(this.MediaList.filter(items => items.Name !== '播放列表'), (item: SVItems) => {
                      ListItem() {
                        Flex({ direction: FlexDirection.Column }) {
                          Flex({ justifyContent: FlexAlign.Center }) {
                            Image(this.serverUrl + FetchImagePrimary(item.Id) + '?maxWidth=400')
                              .alt($r('app.media.Image_loading_failed'))
                          }
                          .width('100%')
                          .borderRadius(10)
                          .clip(true)

                          Flex({ justifyContent: FlexAlign.Center }) {
                            Text(item.Name)
                              .fontSize(BasicConstants.FONT_NORMAL)
                          }
                          .width('100%')
                        }
                      }
                      .height('100%')
                      .width(150)
                      .onClick(() => {
                        this.pageInfo.pushPathByName('EpisodeView', { Name: item.Name, Id: item.Id } as SVItems)
                      })
                    }, (item: SVItems) => item.Guid)

                  }
                  .width('100%')
                  .height('100%')
                  .margin({ top: 10 })
                  .listDirection(Axis.Horizontal)
                  .scrollBar(BarState.Off)
                }

              }
              .width('100%')
              .height(140)
              .margin({ top: 10 })

              //媒体库
              Column() {
                ForEach(this.MediaList.filter(items => items.Name !== '播放列表'), (item: SVItems, index: number) => {
                  Column() {
                    this.ListUtils(item.Name, index, item.Id)
                  }
                  .width('100%')
                  .height(240)
                }, (item: SVItems) => item.Guid)

              }
              .width('100%')
              .margin({ top: 10 })

            }
            .visibility(this.isLoading ? Visibility.None : Visibility.Visible)

            if (this.isLoading) {
              LoadingView()
            }

          }

        }
        .padding({
          left: 10,
          right: 10,
          bottom: 70
        })
      }
      .scrollBar(BarState.Off)
    }
    .pullDownRatio(0.3)
    .onRefreshing(async () => {
      if (NetworkUtil.isNetworkAvailable()) {
        this.fetchServerViews().then(() => {
          this.AddonData().then(() => {
            this.refreshing = false
          })
        })
        this.fetchViewingRecord()
        this.fetchServerUrl()
        this.getServername()
      } else {
        ToastUtil.showToast('网络不可用')
        this.refreshing = false
      }
      setTimeout(() => {
        this.refreshing = false
      }, 30000)
    })
    .margin({ top: px2vp(AppUtil.getStatusBarHeight()) })
  }
}
