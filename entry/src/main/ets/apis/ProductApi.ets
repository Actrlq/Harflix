import { KvUtil } from '@pura/harmony-utils'
import { AuthenticateHttp, MyRequestHttp, MyPostHttp } from '../utils/HttpUtil'
import { AuthenticateByName, PlayInfo, Progress } from '../viewmodel/RequestParms'
import { UserInfo } from '../viewmodel/DataConstraints'

interface ObjectInterface {
  id: string;
  url: string;
}

const getUserInfo = async () => {
  const key = await KvUtil.get('FirstLoad') as string
  const res = await KvUtil.get(key)
  const UserInfo:UserInfo = JSON.parse(res as string)
  return ({
    id: UserInfo.userId,
    url: UserInfo.serverUrl
  } as ObjectInterface)
}

//登录验证
export function FetchAuthenticateApi<T>(url:string,params: AuthenticateByName): Promise<T> {
  return AuthenticateHttp<T, AuthenticateByName>(`${url}/emby/Users/AuthenticateByName`, params)
}

//获取服务器信息
export async function FetchServerInfoApi<T>(): Promise<T> {
  const userInfo = await getUserInfo()
  return MyRequestHttp<T>('FetchServerInfoApi',`${userInfo.url}/emby/System/Info`)
}

//获取媒体库列表
export async function FetchServerViewsApi<T>(): Promise<T> {
  const userInfo = await getUserInfo()
  return MyRequestHttp<T>('FetchServerViewsApi',`${userInfo.url}/emby/Users/${userInfo.id}/Views?IncludeExternalContent=false`)
}

//获取最新影视剧集
export async function FetchNewViewsListApi<T>(Id: string): Promise<T> {
  const userInfo = await getUserInfo()
  return MyRequestHttp<T>('FetchNewViewsListApi',`${userInfo.url}/emby/Users/${userInfo.id}/Items/Latest?EnableImageTypes=Primary,Backdrop,Thumb&Fields=PrimaryImageAspectRatio,CanDelete,CanDownload,BasicSyncInfo,ProductionYear,Status,EndDate,Path,CommunityRating,OfficialRating&Groupltems=ture&MediaTypes=Video&Limit=15&ParentId=${Id}`)
}

//获取观看记录
export async function FetchViewingRecordApi<T>(): Promise<T> {
  const userInfo = await getUserInfo()
  return MyRequestHttp<T>('FetchViewingRecordApi',`${userInfo.url}/emby/Users/${userInfo.id}/Items/Resume?EnableImageTypes=Primary,Backdrop,Thumb&Fields=PrimaryImageAspectRatio,BasicSyncInfo,ProductionYear,OfficialRating&MediaTypes=Video&Limit=30&StartIndex=0&Recursive=true&ParentId&EnableTotalRecordCount=true`)
}

//获取剧集列表
export async function FetchEpisodeListApi<T>(Id: string): Promise<T> {
  const userInfo = await getUserInfo()
  return MyRequestHttp<T>('FetchEpisodeListApi',`${userInfo.url}/emby/Users/${userInfo.id}/Items?SortBy=DateLastContentAdded,SortName&SortOrder=Descending&ParentId=${Id}&IncludeItemTypes=Series,Movie&Recursive=true&ImageTypeLimit=1&StartIndex=0&EnableImageTypes=Primary,Backdrop,Thumb,Banner&Fields=BasicSyncInfo,CanDelete,CanDownload,Container,PrimaryImageAspectRatio,ProductionYear,CommunityRating,OfficialRating,Status,CriticRating,EndDate,Path&EnableUserData=true`)
}

//获取详情页
export async function FetchDetailsApi<T>(id:string): Promise<T> {
  const userInfo = await getUserInfo()
  return MyRequestHttp<T>('FetchDetailsApi',`${userInfo.url}/emby/Users/${userInfo.id}/Items/${id}`)
}

//获取季
export async function FetchSeasonApi<T>(id:string): Promise<T> {
  const userInfo = await getUserInfo()
  return MyRequestHttp<T>('FetchSeasonApi',`${userInfo.url}/emby/Shows/${id}/Seasons`)
}

//获取季列表
export async function FetchSeasonListApi<T>(id:string,SeasonId:string): Promise<T> {
  const userInfo = await getUserInfo()
  return MyRequestHttp<T>('FetchSeasonListApi',`${userInfo.url}/emby/Shows/${id}/Episodes?UserId=${userInfo.id}&SeasonId=${SeasonId}&EnableUserData=true`)
}

//获取播放信息
export async function FetchPlaybackInfoApi<T>(id:string): Promise<T> {
  const userInfo = await getUserInfo()
  return MyPostHttp<T, PlayInfo>('FetchPlaybackInfoApi',`${userInfo.url}/emby/Items/${id}/PlaybackInfo`,new PlayInfo)
}

//获取未观看列表
export async function FetchUnWatchedApi<T>(id:string): Promise<T> {
  const userInfo = await getUserInfo()
  return MyRequestHttp<T>('FetchUnWatchedApi',`${userInfo.url}/emby/Shows/NextUp?SeriesId=${id}&Limit=1`)
}

//搜索
export async function FetchSearchApi<T>(name:string): Promise<T> {
  const userInfo = await getUserInfo()
  return MyRequestHttp<T>('FetchSearchApi',`${userInfo.url}/emby/Users/${userInfo.id}/Items?Fields=PremiereDate,ProductionYear,CommunityRating,ProductionLocations,CanDownload&IncludeItemTypes=Movie,Series&StartIndex=0&Limit=20&Recursive=true&SearchTerm=${name}`)
}

//播放记录回传
export async function ReturnProgressApi<T>(progress:Progress): Promise<boolean> {
  const userInfo = await getUserInfo()
  MyPostHttp<T, Progress>('ReturnProgressApi',`${userInfo.url}/emby/Sessions/Playing/Progress`,progress)
  return true
}

//获取收藏列表
export async function FetchCollectionApi<T>(): Promise<T> {
  const userInfo = await getUserInfo()
  return MyRequestHttp<T>('FetchCollectionApi',`${userInfo.url}/emby/Users/${userInfo.id}/Items?SortBy=SortName&SortOrder=Ascending&Fields=BasicSyncInfo,Container,PrimaryImageAspectRatio,ProductionYear,Status,EndDate,CommunityRating,OfficialRating&Recursive=true&Filters=IsFavorite&IncludeItemTypes=Series,Movie`)
}