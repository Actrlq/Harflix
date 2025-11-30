import { BasicDataSource } from "./BasicDataSource";

export class MyDataSource<T> extends BasicDataSource<T> {
  private dataArray: T[] = [];

  public totalCount(): number {
    return this.dataArray.length;
  }

  public getData(index: number): T {
    return this.dataArray[index];
  }

  public pushData(data: T): void {
    this.dataArray.push(data);
    this.notifyDataAdd(this.dataArray.length - 1);
  }

  public pushAllData(date:T[]):void{
    for (let index = 0; index < date.length; index++) {
      this.pushData(date[index])
    }
  }
}
