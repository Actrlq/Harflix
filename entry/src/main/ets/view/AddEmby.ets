import { router } from '@kit.ArkUI'
import { ImportantInformation, SystemInfo } from '../viewmodel/DataConstraints'
import { FetchAuthenticateApi, FetchServerInfoApi } from '../apis/ProductApi'
import { BasicConstants } from '../viewmodel/BasicConstants'
import { AppUtil, KvUtil, ObjectUtil } from '@pura/harmony-utils'
import { UserInfo } from '../viewmodel/DataConstraints'

@Component
struct AddEmby {
  private pageInfo: NavPathStack | null = null
  private data: UserInfo = new UserInfo
  private servername: string = ''
  private address: string = ''
  @State http: string = 'https'
  private port: string = ''
  private username: string = ''
  private password: string = ''
  private userdata: UserInfo = new UserInfo
  //弹窗状态
  @State isShow: boolean = false
  @State isLoading: boolean = false

  @Builder
  dialogBuilder() {
    Column() {
      Column() {
        Text('HTTPS')
          .fontSize(BasicConstants.FONT_BIG)
      }
      .width('90%')
      .height('50%')
      .borderWidth({ bottom: 1 })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        this.http = 'https'
        this.isShow = false
      })

      Column() {
        Text('HTTP')
          .fontSize(BasicConstants.FONT_BIG)
      }
      .width('90%')
      .height('50%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        this.http = 'http'
        this.isShow = false
      })
    }
    .padding(10)
    .width('90%')
    .height(100)
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          Column({ space: 15 }) {
            Column() {
              TextInput({ placeholder: "服务器名称自动获取（选填）", text: $$this.servername })
            }

            Column() {
              TextInput({ placeholder: "服务器地址", text: $$this.address })
            }

            Row() {
              Row() {
                Text(this.http + '://')
                  .fontSize(BasicConstants.FONT_BIG)
                  .textAlign(TextAlign.Center)
                  .width('80%')
                Image($r('app.media.fanhuijiantou'))
                  .height(15)
                  .layoutWeight(1)
                  .rotate({ angle: -90, centerX: 0, centerY: 10 })
              }
              .height(40)
              .borderRadius(10)
              .border({ width: 1.5 })
              .layoutWeight(1)
              .margin({ right: 10 })
              .onClick(() => {
                this.isShow = true
              })
              .bindPopup(this.isShow, {
                builder: this.dialogBuilder(),
                width: 150,
                enableArrow: false,
                placement: Placement.Bottom,
                radius: 10,
                onStateChange: (e) => {
                  if (!e.isVisible) {
                    this.isShow = false
                  }
                }
              })

              Column() {
                TextInput({ placeholder: '端口（选填）', text: $$this.port })
                  .width('50%')
              }
            }

            Column() {
              TextInput({ placeholder: "用户名", text: $$this.username })
            }

            Column() {
              TextInput({ placeholder: "密码", text: $$this.password }
              )
                .type(InputType.Password)
            }

            Button("连接").onClick(async () => {
              if (this.address && this.username) {
                this.isLoading = true
                const url = this.http + '://' + this.address + (this.port ? `:${this.port}` : '')
                const res = await FetchAuthenticateApi<ImportantInformation>(url, {
                  Username: this.username,
                  Password: this.password,
                  Pw: this.password
                }).finally(() => {
                  setTimeout(() => {
                    this.isLoading = false
                  }, 1000)
                })
                this.userdata = {
                  serverUrl: url,
                  username: this.username,
                  token: res.AccessToken,
                  serverId: res.ServerId,
                  servername: this.servername,
                  userId: ObjectUtil.getValue<string>(res.User, "Id"),
                  address: this.address,
                  http: this.http,
                  port: this.port,
                }
                let keyPrefix = "emby_"
                KvUtil.put(keyPrefix + ObjectUtil.getValue<string>(res.User, 'Id'), JSON.stringify(this.userdata))
                KvUtil.put('FirstLoad', keyPrefix + ObjectUtil.getValue<string>(res.User, 'Id')).then(() => {
                  if (res) {
                    let keyPrefix = "emby_"
                    if (!this.servername) {
                      FetchServerInfoApi<SystemInfo>().then((name) => {
                        this.userdata = {
                          serverUrl: url,
                          username: this.username,
                          token: res.AccessToken,
                          serverId: res.ServerId,
                          servername: name.ServerName,
                          userId: ObjectUtil.getValue<string>(res.User, "Id"),
                          address: this.address,
                          http: this.http,
                          port: this.port,
                        }
                        KvUtil.put(keyPrefix + ObjectUtil.getValue<string>(res.User, 'Id'),
                          JSON.stringify(this.userdata)).then(() => {
                          router.replaceUrl({
                            url: "pages/Index"
                          })
                            .catch(() => {
                            })
                          router.clear()
                        })
                      })
                    } else {
                      router.replaceUrl({
                        url: "pages/Index"
                      })
                        .catch(() => {
                        })
                      router.clear()
                    }
                  }
                })
              }

            })
              .width("60%")
          }
          .width('100%')
          .backgroundColor(Color.White)
          .padding(20)
          .borderRadius(20)
        }
        .width('100%')
        .height('100%')
        .padding({ left: 20, right: 20 })

        if (this.isLoading) {
          Column() {
            Column() {
              LoadingProgress()
                .color(Color.Green)
                .width(64)

              Text('加载中...')
                .fontSize($r('sys.float.Body_L'))
                .fontColor($r('sys.color.white'))
            }
            .width(100)
            .aspectRatio(1)
            .borderRadius(10)
            .backgroundColor('rgba(0, 0, 0, 0.8)')

          }
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .height('100%')
          .width('100%')
        }

      }

    }
    .title('添加服务器')
    .onReady((context) => {
      this.pageInfo = context.pathStack
      this.data = context.pathInfo.param as UserInfo
      this.servername = this.data.servername
      this.address = this.data.address
      this.http =  this.data.http
      this.port = this.data.port
      this.username = this.data.username
    })
    .padding({ top: px2vp(AppUtil.getStatusBarHeight()) })
    .backgroundColor($r('sys.color.background_secondary'))

  }
}

@Builder
export function AddEmbyBuilder() {
  AddEmby()
}