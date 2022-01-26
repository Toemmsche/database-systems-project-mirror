enum RequestStatusEnum {
  IDLE = "IDLE",
  WAITING = "WAITING",
  SUCCESS = "SUCCESS",
  FAILURE = "FAILURE"
}

export class RequestStatus {
  private readonly status: RequestStatusEnum;

  constructor(status: RequestStatusEnum) {
    this.status = status;
  }


  isIdle(): boolean {
    return this.status === RequestStatusEnum.IDLE;
  }

  isWaiting(): boolean {
    return this.status === RequestStatusEnum.WAITING;
  }

  isSuccess(): boolean {
    return this.status === RequestStatusEnum.SUCCESS;

  }

  isFailure(): boolean {
    return this.status === RequestStatusEnum.FAILURE;
  }

  isResultStatus() : boolean {
    return this.isSuccess() || this.isFailure();
  }
}

// 4 basic request statuses is enough for our purposes
const RS = {
  IDLE   : new RequestStatus(RequestStatusEnum.IDLE),
  WAITING: new RequestStatus(RequestStatusEnum.WAITING),
  SUCCESS: new RequestStatus(RequestStatusEnum.SUCCESS),
  FAILURE: new RequestStatus(RequestStatusEnum.FAILURE)
}

export default RS;

