import { BasicConstants } from "../viewmodel/BasicConstants"
import { MediaQueryUtil } from '../utils/MediaQueryUtil'
import { router } from '@kit.ArkUI'
import { DialogAction, DialogUtil, KvUtil } from "@pura/harmony-utils"
import { distributedKVStore } from "@kit.ArkData"
import { UserInfo } from "../viewmodel/DataConstraints"

@Component
export struct EmbyList {
  private MediaInformation = new MediaQueryUtil();
  @StorageProp('MediaQueryText') MediaQueryText: string = 'sm'
  @State embyList: UserInfo[] = []
  //弹窗状态
  @State isShow: number = -1
  @State firstLoad: string = ''

  aboutToAppear(): void {
    this.MediaInformation.register()
    this.fetchKeydata()
  }

  aboutToDisappear(): void {
    this.MediaInformation.unregister()
  }

  fetchKeydata = () => {
    const keyPrefix = "emby"
    KvUtil.getEntries(keyPrefix).then((res) => {
      res.forEach((entry: distributedKVStore.Entry) => {
        this.embyList.push(JSON.parse(entry.value.value as string))
      })
    })
  }

  // 弹框内容
  @Builder
  dialogBuilder(kv: string) {
    Column() {
      Column() {
        Text('删除')
          .fontSize(BasicConstants.FONT_NORMAL)
      }
      .width('80%')
      .padding(10)
      .onClick(() => {
        this.isShow = -1
        DialogUtil.showPrimaryDialog({
          title: '删除',
          message: '确认删除吗！！！',
          primaryButton: "取消",
          secondaryButton: "确认",
          onAction: (action) => {
            if (action == DialogAction.TWO) {
              KvUtil.delete(kv)
              this.embyList = []
              const keyPrefix = "emby"
              KvUtil.getEntries(keyPrefix).then((res) => {
                if (res) {
                  this.firstLoad = res[0].key
                  KvUtil.put('FirstLoad', this.firstLoad)
                  this.fetchKeydata()
                }
              }).catch(()=>{
                KvUtil.delete('FirstLoad')
              })
            }
          }
        })
      })
    }
    .padding(10)
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center }) {
      //标题
      Flex({ justifyContent: FlexAlign.SpaceBetween }) {
        Text("服务器")
          .fontSize(BasicConstants.FONT_BIG)
          .fontWeight(FontWeight.Bold)
          .height("100%")
        Image($r('app.media.tianjia'))
          .height('70%')
          .padding({ top: 5 })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/AddEmby',
              params:{servername:'',serverUrl:'',username:''}
            }).catch()
          })
      }
      .width("100%")
      .height(50)
      .padding({ left: 10, right: 10 })
      .margin({ top: 40 })

      //服务器列表
      Scroll() {
        Column() {
          ForEach(this.embyList, (item: UserInfo, index: number) => {
            Column() {
              Row() {
                Column() {
                  Image($r("app.media.emby"))
                    .height("80%")
                }
                .width("20%")

                Column() {
                  Text(item.servername ? item.servername : '无名称')
                    .fontSize(20)
                    .height("100%")
                }
                .width("60%")
                .onClick(()=>{
                  router.pushUrl({
                    url: 'pages/AddEmby',
                    params:{servername:item.servername,serverUrl:item.serverUrl,username:item.username}
                  }).catch()
                })

                Column() {
                  Text('编辑')
                    .fontSize(BasicConstants.FONT_BIG)
                }
                .width("20%")
                .onClick(() => {
                  this.isShow = index
                })
                .bindPopup(this.isShow === index ? true : false, {
                  builder: this.dialogBuilder('emby_' + item.userId),
                  width: 100,
                  enableArrow: false,
                  placement: Placement.BottomLeft,
                  radius: 10,
                  onStateChange: (e) => {
                    if (!e.isVisible) {
                      this.isShow = -1
                    }
                  }
                })
              }
              .width("100%")
            }
            .width(this.MediaQueryText == 'sm' ? '100%' : '60%')
            .height(50)
            .backgroundColor(Color.White)
            .borderRadius(10)
            .margin({ bottom: 5 })
          }, (item: UserInfo) => item.token)
        }
        .width("100%")
      }
      .padding({ left: 15, right: 15 })
      .scrollBarWidth(0)
    }
    .width('100%')
    .height('100%')

  }
}