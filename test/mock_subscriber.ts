import {DapperRequest} from '../src/messages';

/**
 * Utility class for testing EventEmitter subscription.
 */
export class MockSubscriber {
  private lastRequest: DapperRequest;

  constructor() {
    this.lastRequest = {} as DapperRequest;
  }

  /**
   * Callback function; receives an emitted event and stores it.
   *
   * `receive` is "hard-bound" to `this` MockSubscriber object, and can
   * be safely used in subscriptions without use of `bind`, e.g.
   * `emitter.on('requestType', mockSub.receive)` will make `emitter`
   * effectively invoke `mockSub.receiveImpl()` instead of (incorrectly)
   * invoking `emitter.receiveImpl()`.
   */
  readonly receive = this.receiveImpl.bind(this);
  private receiveImpl(msg: DapperRequest): void {
    this.lastRequest = {...msg} as DapperRequest;
  }

  /**
   * "Empty" the contents of this MockSubscriber.
   */
  reset(): void {
    this.lastRequest = {} as DapperRequest;
  }

  /**
   * Return a copy of the request provided by the most recent callback.
   */
  getLast(): DapperRequest {
    return {...this.lastRequest};
  }

  /**
   * Get a copy of the most recent request and reset the object state.
   *
   * Meant to be used when the same MockSubscriber is used across multiple test
   * cases.
   */
  getLastAndReset(): DapperRequest {
    const toReturn = {...this.lastRequest};
    this.reset();
    return toReturn;
  }
}
