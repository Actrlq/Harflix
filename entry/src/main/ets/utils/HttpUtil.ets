import { http } from "@kit.NetworkKit";
import { BusinessError } from "@kit.BasicServicesKit";
import { promptAction } from "@kit.ArkUI";
import { AppUtil, DeviceUtil, KvUtil } from "@pura/harmony-utils"
import { UserInfo } from "../viewmodel/DataConstraints";

const getToken = async () => {
  const key = await KvUtil.get('FirstLoad') as string
  const res = await KvUtil.get(key)
  const UserInfo: UserInfo = JSON.parse(res as string)
  return UserInfo.token
}

//登录请求
export function AuthenticateHttp<T, K>(url: string, requestData: K) {

  const httpRequest = http.createHttp()

  return new Promise((resolve: (value: T) => void, reject: (value?: string) => void) => {
    httpRequest.request(
      url,
      {
        method: http.RequestMethod.POST,
        header: {
          'X-Emby-Authorization': `Emby Client=${$r('app.string.app_name')},Device=${DeviceUtil.getBrandModel()},DeviceId=${DeviceUtil.getDeviceId()},Version=${AppUtil.getVersionName()}`,
          'Content-Type': 'application/json; charset=UTF-8',
          'user-agent': 'Harflix',
        },
        // 当使用POST请求时此字段用于传递请求体内容
        extraData: JSON.stringify(requestData),
        connectTimeout: 60000,
        readTimeout: 60000
      }, (err: BusinessError, data: http.HttpResponse) => {
      if (!err && data.responseCode === 200) {
        // data.result为HTTP响应内容，可根据业务需要进行解析。
        // console.log(`成功：${JSON.stringify(data.result)}`);
        // console.info('code:' + JSON.stringify(data.responseCode));
        // 将响应结果解析为JSON对象并返回
        resolve(JSON.parse(data.result as string))
        httpRequest.destroy()
      } else {
        console.error('请求错误信息:' + JSON.stringify(err));
        try {
          promptAction.showToast({ message: `${data.responseCode}：${data.result}` })
        } catch (error) {

        }
        reject(JSON.stringify(err))
        // 当该请求使用完毕时，调用destroy方法主动销毁。
        httpRequest.destroy()
      }
    }
    )
  })

}

//GET请求
export async function MyRequestHttp<T>(name: string, url: string) {

  const httpRequest = http.createHttp()
  let token = await getToken()

  return new Promise((resolve: (value: T) => void, reject: (value?: string) => void) => {

    httpRequest.request(
      url,
      {
        method: http.RequestMethod.GET,
        header: {
          'X-Emby-Authorization': `Emby Client=${$r('app.string.app_name')},DeviceId=${DeviceUtil.getDeviceId()},Version=${AppUtil.getVersionName()}`,
          'Content-Type': 'application/json',
          'X-Emby-Token': token,
          'Accept-Encoding': 'gzip',
        },
        // expectDataType: http.HttpDataType.ARRAY_BUFFER,
        connectTimeout: 60000,
        readTimeout: 60000
      }, (err: BusinessError, data: http.HttpResponse) => {
      if (!err && data.responseCode === 200) {
        // data.result为HTTP响应内容，可根据业务需要进行解析。
        // console.info('code:' + JSON.stringify(data.responseCode));
        resolve(JSON.parse(data.result as string))
        httpRequest.destroy();
      } else {
        console.error(`${name}请求错误信息:` + JSON.stringify(err));
        try {
          promptAction.showToast({ message: `${data.responseCode}：${data.result}` })
        } catch (error) {

        }
        // reject(JSON.stringify(err))
        // 当该请求使用完毕时，调用destroy方法主动销毁。
        httpRequest.destroy()
      }
    }
    )
  })

}

//POST请求
export async function MyPostHttp<T, K>(name: string, url: string, requestData?: K) {

  const httpRequest = http.createHttp()
  let token = await getToken()

  return new Promise((resolve: (value: T) => void, reject: (value?: string) => void) => {
    httpRequest.request(
      url,
      {
        method: http.RequestMethod.POST,
        header: {
          'X-Emby-Authorization': `Emby Client=${$r('app.string.app_name')},DeviceId=${DeviceUtil.getDeviceId()},Version=${AppUtil.getVersionName()}`,
          'Content-Type': 'application/json; charset=UTF-8',
          'X-Emby-Token': token,
          'Accept-Encoding': 'gzip',
        },
        // 当使用POST请求时此字段用于传递请求体内容
        extraData: JSON.stringify(requestData),
        connectTimeout: 60000,
        readTimeout: 60000
      }, (err: BusinessError, data: http.HttpResponse) => {
      if (!err && data.responseCode === 200 || data.responseCode === 204) {
        // data.result为HTTP响应内容，可根据业务需要进行解析。
        // console.log(`成功：${JSON.stringify(data.result)}`);
        // console.info('code:' + JSON.stringify(data.responseCode));
        // 将响应结果解析为JSON对象并返回
        if (data.result) {
          resolve(JSON.parse(data.result as string))
        }

        httpRequest.destroy()
      } else {
        console.error(`${name}请求错误信息:` + JSON.stringify(err));
        try {
          promptAction.showToast({ message: `${data.responseCode}：${data.result}` })
        } catch (eer) {

        }
        // reject(JSON.stringify(err))
        // 当该请求使用完毕时，调用destroy方法主动销毁。
        httpRequest.destroy()
      }
    }
    )
  })

}

//GET请求
export async function StringHttp(name: string, url: string) {

  const httpRequest = http.createHttp()
  let token = await getToken()

  return new Promise((resolve: (value: string) => void, reject: (value?: string) => void) => {

    httpRequest.request(
      url,
      {
        method: http.RequestMethod.GET,
        header: {
          'X-Emby-Authorization': `Emby Client=${$r('app.string.app_name')},DeviceId=${DeviceUtil.getDeviceId()},Version=${AppUtil.getVersionName()}`,
          'Content-Type': 'application/json',
          'X-Emby-Token': token,
          'Accept-Encoding': 'gzip',
        },
        // expectDataType: http.HttpDataType.ARRAY_BUFFER,
        connectTimeout: 60000,
        readTimeout: 60000,
      }, (err: BusinessError, data: http.HttpResponse) => {
      if (!err && data.responseCode === 200) {
        // data.result为HTTP响应内容，可根据业务需要进行解析。
        // console.info('code:' + JSON.stringify(data.responseCode));
        resolve(data.result as string);
        httpRequest.destroy();
      } else {
        console.error(`${name}请求错误信息:` + JSON.stringify(err));
        try {
          promptAction.showToast({ message: `${data.responseCode}：${data.result}` })
        } catch (error) {

        }
        // reject(JSON.stringify(err))
        // 当该请求使用完毕时，调用destroy方法主动销毁。
        httpRequest.destroy()
      }
    }
    )
  })

}