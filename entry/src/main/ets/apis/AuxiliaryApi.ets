import { KvUtil } from "@pura/harmony-utils";
import { StringHttp } from "../utils/HttpUtil";
import { UserInfo } from '../viewmodel/DataConstraints'


const getUserUrl = async () => {
  const key = await KvUtil.get('FirstLoad') as string
  const res = await KvUtil.get(key)
  const UserInfo: UserInfo = JSON.parse(res as string)
  return UserInfo.serverUrl
}

export async function FetchServerUrl(){
  const serverUrl = await getUserUrl()
  return serverUrl
}

//获取字幕
export async function FetchSubtitleApi(id: string, mediaSourceId: string, index: number, type: string): Promise<string> {
  const serverUrl = await getUserUrl()
  return StringHttp('FetchSubtitleApi',`${serverUrl}/Videos/${id}/${mediaSourceId}/Subtitles/${index}/Stream.${type}`)
}

//封面图
export function FetchImagePrimary(id: string) {
  return `/emby/Items/${id}/Images/Primary`
}

//背景图
export function FetchImageBackdrop(id: string) {
  return `/emby/Items/${id}/Images/Backdrop`
}

//logo图
export function FetchImageLogo(id: string) {
  return `/emby/Items/${id}/Images/Logo`
}