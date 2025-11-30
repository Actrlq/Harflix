import { router } from '@kit.ArkUI'
import { ImportantInformation, SystemInfo } from '../viewmodel/DataConstraints'
import { FetchAuthenticateApi, FetchServerInfoApi } from '../apis/ProductApi'
import { BasicConstants } from '../viewmodel/BasicConstants'
import { KvUtil, ObjectUtil } from '@pura/harmony-utils'
import { UserInfo } from '../viewmodel/DataConstraints'

@Entry
@Component
struct AddEmby {
  private data:UserInfo = router.getParams() as UserInfo
  private servername: string = this.data.servername
  private serverUrl: string = this.data.serverUrl
  private username: string = this.data.username
  private password: string = ""
  private userdata: UserInfo = new UserInfo

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

      Column({ space: 15 }){

        Column() {
          TextInput({ placeholder: "服务器名称自动获取（选填）", text: $$this.servername })
        }

        Column() {
          TextInput({ placeholder: "服务器地址 : 端口", text: $$this.serverUrl })
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
          const res = await FetchAuthenticateApi<ImportantInformation>(this.serverUrl,{
            Username: this.username,
            Password: this.password,
            Pw: this.password
          })
          this.userdata = {
            serverUrl: this.serverUrl,
            username: this.username,
            token: res.AccessToken,
            serverId: res.ServerId,
            servername: this.servername,
            userId: ObjectUtil.getValue<string>(res.User, "Id")
          }
          if (res) {
            let keyPrefix = "emby_"
            KvUtil.put(keyPrefix + ObjectUtil.getValue<string>(res.User,'Id'), JSON.stringify(this.userdata)).then(()=>{
              KvUtil.put('FirstLoad',keyPrefix + ObjectUtil.getValue<string>(res.User,'Id'))
              if (!this.servername) {
                FetchServerInfoApi<SystemInfo>().then((name)=>{
                  this.userdata = {
                    serverUrl: this.serverUrl,
                    username: this.username,
                    token: res.AccessToken,
                    serverId: res.ServerId,
                    servername: name.ServerName,
                    userId: ObjectUtil.getValue<string>(res.User, "Id")
                  }
                  let keyPrefix = "emby_"
                  KvUtil.put(keyPrefix + ObjectUtil.getValue<string>(res.User,'Id'), JSON.stringify(this.userdata))
                })
              }
              router.replaceUrl({
                url:"pages/Index"
              }).catch(() => {
              })
              router.clear()
            })
          }

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