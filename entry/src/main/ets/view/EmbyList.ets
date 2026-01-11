import { BasicConstants } from "../viewmodel/BasicConstants"
import { MediaQueryUtil } from '../utils/MediaQueryUtil'
import { AppUtil, DialogAction, DialogUtil, KvUtil, PreferencesUtil } from "@pura/harmony-utils"
import { distributedKVStore } from "@kit.ArkData"
import { UserInfo } from "../viewmodel/DataConstraints"
import { LengthMetrics } from "@kit.ArkUI"

@Component
export struct EmbyList {
  @Consume pageInfo: NavPathStack
  private MediaInformation = new MediaQueryUtil();
  @StorageProp('MediaQueryText') MediaQueryText: string = 'sm'
  @StorageLink('embyList') embyList: UserInfo[] = []
  //弹窗状态
  @State firstLoad: string = ''
  @State showUsername: string = '不显示用户名'

  aboutToAppear(): void {
    this.showUsername = PreferencesUtil.getStringSync('showUsername','不显示用户名')
    this.MediaInformation.register()
    this.fetchKeydata()
  }

  aboutToDisappear(): void {
    this.MediaInformation.unregister()
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

  private addTool:NavigationMenuItem = {
    value: "添加",
    icon: $r('sys.media.ohos_ic_public_add'),
    action: ()=>{
      this.pageInfo.pushPathByName('AddEmby', { servername: '', address: '', username: '' } as UserInfo)
    }
  }

  // 弹框内容
  @Builder
  editMenu(kv: string) {
    Menu() {
      MenuItem({
        content: '删除'
      })
        .onClick(() => {
          DialogUtil.showPrimaryDialog({
            title: '删除',
            message: '确认删除吗！！！',
            primaryButton: "取消",
            secondaryButton: "确认",
            onAction: (action) => {
              if (action == DialogAction.TWO) {
                KvUtil.delete(kv)
                const keyPrefix = "emby"
                KvUtil.getEntries(keyPrefix).then((res) => {
                  if (res) {
                    this.firstLoad = res[0].key
                    KvUtil.put('FirstLoad', this.firstLoad)
                    this.fetchKeydata()
                  }
                })
              }
            }
          })
        })

      MenuItem({ content: this.showUsername })
        .onClick(() => {
          if (this.showUsername === '显示用户名') {
            this.showUsername = '不显示用户名'
            PreferencesUtil.putSync('showUsername', '不显示用户名')
          } else {
            this.showUsername = '显示用户名'
            PreferencesUtil.putSync('showUsername', '显示用户名')
          }
        })
    }
    .menuItemDivider({
      strokeWidth: LengthMetrics.vp(1.5),
      color: '#d5d5d5',
    })
  }

  build() {
    NavDestination(){
        //服务器列表
        Scroll() {
          Column() {
            ForEach(this.embyList, (item: UserInfo) => {
              Column() {
                Row() {
                  Column() {
                    Image($r("app.media.emby"))
                      .height("80%")
                  }
                  .width("20%")

                  Column() {
                    Text(item.servername ? item.servername : '无名称')
                      .fontSize(BasicConstants.FONT_BIG)
                      .margin({ top: 5, bottom: 5 })
                    Text(item.username)
                      .fontSize(BasicConstants.FONT_SMALL)
                      .borderWidth(1)
                      .borderRadius(5)
                      .padding(2)
                      .visibility(this.showUsername === '不显示用户名' ? Visibility.Visible : Visibility.None)
                  }
                  .width("60%")
                  .alignItems(HorizontalAlign.Start)
                  .onClick(() => {
                    this.pageInfo.pushPathByName('AddEmby', {
                      servername: item.servername,
                      serverUrl: item.serverUrl,
                      username: item.username,
                      address: item.address,
                      http: item.http,
                      port: item.port,
                    } as UserInfo)
                  })

                  Column() {
                    Text('编辑')
                      .fontSize(BasicConstants.FONT_BIG)
                  }
                  .width("20%")
                  .bindMenu(this.editMenu('emby_' + item.userId))
                }
                .width("100%")
              }
              .width(this.MediaQueryText == 'sm' ? '100%' : '60%')
              .height(60)
              .backgroundColor(Color.White)
              .borderRadius(10)
              .margin({ bottom: 5 })
              .justifyContent(FlexAlign.Center)
            }, (item: UserInfo) => item.token)
          }
          .width("100%")
        }
        .padding({ left: 15, right: 15, bottom:70 })
        .scrollBarWidth(0)
    }
    .title('服务器')
    .menus([this.addTool])
    .padding({ top: px2vp(AppUtil.getStatusBarHeight()) })
    .backgroundColor($r('sys.color.background_secondary'))

  }
}