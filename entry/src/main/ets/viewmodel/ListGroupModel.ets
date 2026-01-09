export class ListGroupData {
  id: number = 0
  group: Array<ListGroup> = []
}

export interface ListGroup {
  symbolSrc?: ResourceStr
  textContent: ResourceStr
  subTextContent?: ResourceStr
  onclick:() => void
}