import {isUndefined} from 'util';

import {FrontTalker} from './fronttalker';
import {DapperAnyMsg, DapperRequest} from './messages';

// tslint:disable-next-line:no-any
type Callback = (req: DapperAnyMsg) => any;
interface CallbackOrArr {
  cb: Callback|Callback[];
}
// tslint:disable-next-line:no-any
function isCallback(arg: any): arg is Callback {
  // note:  doesn't check whether arg has the Callback function signature,
  //        only that it *is* a function
  return typeof arg as string === 'function';
}
// tslint:disable-next-line:no-any
function isCallbackArr(arg: any): arg is Callback[] {
  // note:  not robust; doesn't check the *entire* array for type homogeneity
  return arg.length !== undefined && (!arg.length || isCallback(arg[0]));
}

/**
 * Basic implementation of FrontTalker event emission only.
 */
export class BasicFrontTalker implements FrontTalker {
  private typesToCbs: {[name: string]: CallbackOrArr};

  constructor() {
    this.typesToCbs = {};
  }

  send(msg: DapperAnyMsg): void {
    throw Error('send() not implemented in basic superclass');
  }

  // tslint:disable-next-line:no-any
  on(reqType: string, callback: (req: DapperRequest) => any): FrontTalker {
    const cbs: CallbackOrArr = this.typesToCbs[reqType];
    if (isUndefined(cbs)) {
      this.typesToCbs[reqType] = {cb: callback as Callback};
    } else if (isCallback(cbs.cb)) {
      const cb = cbs.cb;
      cbs.cb = [cb, callback] as Callback[];
    } else if (isCallbackArr(cbs.cb)) {
      cbs.cb.push(callback as Callback);
    } else {
      throw new TypeError(
          'Object with unexpected type in callbacks dictionary: ' + cbs.cb);
    }
    return this;
  }

  // tslint:disable-next-line:no-any
  off(reqType: string, callback: (req: DapperRequest) => any): FrontTalker {
    const cbs: CallbackOrArr = this.typesToCbs[reqType];
    if (isUndefined(cbs)) {
    } else if (isCallback(cbs.cb)) {
      delete this.typesToCbs[reqType];
    } else if (isCallbackArr(cbs.cb)) {
      const cbArr = cbs.cb;
      for (let i = 0; i < cbArr.length; ++i) {
        const storedCb = cbArr[i];
        if (storedCb.toString() === callback.toString()) {
          cbArr.splice(i, 1);
          break;
        }
      }
    } else {
      throw new TypeError(
          'Object with unexpected type in callbacks dictionary: ' + cbs.cb);
    }
    return this;
  }

  emit(reqType: string, request: DapperRequest): boolean {
    if (!(reqType in this.typesToCbs)) return false;
    const cbs = this.typesToCbs[reqType];
    if (isCallback(cbs.cb)) {
      cbs.cb(request);
      return true;
    } else if (isCallbackArr(cbs.cb)) {
      if (!cbs.cb.length) return false;
      cbs.cb.forEach((callbackFunction: Callback) => {
        callbackFunction(request);
      });
      return true;
    } else {
      throw new TypeError(
          'Object with unexpected type in callbacks dictionary: ' + cbs.cb);
    }
  }
}
