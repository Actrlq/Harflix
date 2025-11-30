export class IjkplayerMapManager {
  private static instance: IjkplayerMapManager;

  private constructor() {
  }

  public static getInstance(): IjkplayerMapManager {
    if (!IjkplayerMapManager.instance) {
      IjkplayerMapManager.instance = new IjkplayerMapManager();
    }
    return IjkplayerMapManager.instance;
  }

  //xcomponentId唯一标识
  private static id: number = 1;
  //记录是否播放过的状态
  private _playStatusMap: Map<string, boolean> = new Map();
  //记录是否销毁过的状态
  private _destroyStatusMap: Map<string, boolean> = new Map();

  public get playStatusMap(): Map<string, boolean> {
    return this._playStatusMap;
  }

  public get destroyStatusMap(): Map<string, boolean> {
    return this._destroyStatusMap;
  }

  public clearAll() {
    this._playStatusMap.clear();
    this._destroyStatusMap.clear()
  }

  public static generateId(): number {
    return IjkplayerMapManager.id++
  }
}