import { router } from '@kit.ArkUI'
import { ImportantInformation, SystemInfo } from '../viewmodel/DataConstraints'
import { FetchAuthenticateApi, FetchServerInfoApi } from '../apis/ProductApi'
import { BasicConstants } from '../viewmodel/BasicConstants'
import { KvUtil, ObjectUtil } from '@pura/harmony-utils'
import { UserInfo } from '../viewmodel/DataConstraints'

@Entry
@Component
struct AddEmby {
  private data: UserInfo = router.getParams() as UserInfo
  private servername: string = this.data.servername
  private serverUrl: string = ''
  private address: string = this.data.address
  @State http: string = 'https' || this.data.http
  private port: string = this.data.port
  private username: string = this.data.username
  private password: string = ""
  private userdata: UserInfo = new UserInfo
  //弹窗状态
  @State isShow: boolean = false

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
    Column({ space: 15 }) {
      Row() {
        Column() {
          Image($r('app.media.fanhuijiantou'))
            .height(25)
        }
        .width('10%')
        .onClick(() => {
          router.back()
        })

        Column() {
          Text("添加服务器")
            .fontSize(BasicConstants.FONT_BIG)
            .fontWeight(FontWeight.Bold)
        }
        .width('80%')
      }
      .width('100%')

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
          const url = this.http + '://' + this.address + (this.port ? `:${this.port}` : '')
          const res = await FetchAuthenticateApi<ImportantInformation>(url, {
            Username: this.username,
            Password: this.password,
            Pw: this.password
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
          KvUtil.put('FirstLoad', keyPrefix + ObjectUtil.getValue<string>(res.User, 'Id')).then(()=>{
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
                  KvUtil.put(keyPrefix + ObjectUtil.getValue<string>(res.User, 'Id'), JSON.stringify(this.userdata)).then(()=>{
                    router.replaceUrl({
                      url: "pages/Index"
                    })
                      .catch(() => {
                      })
                    router.clear()
                  })
                })
              }else {
                router.replaceUrl({
                  url: "pages/Index"
                })
                  .catch(() => {
                  })
                router.clear()
              }
            }
          })

        })
          .width("60%")
      }
      .width('100%')
      .backgroundColor(Color.White)
      .padding(15)
      .borderRadius(20)

    }
    .backgroundColor($r("app.color.theme_background_1"))
    .width("100%")
    .height("100%")
    .padding({
      top: 40,
      left: 20,
      right: 20
    })
  }
}