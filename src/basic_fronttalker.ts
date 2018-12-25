import {isUndefined} from 'util';

import {FrontTalker} from './fronttalker';
import {DapperAnyMsg, DapperRequest} from './messages';

type Callback = (req: DapperAnyMsg) => void;
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
  on(reqType: string, callback: (req: DapperRequest) => any): void {
    const cbs: CallbackOrArr = this.typesToCbs[reqType];
    if (isUndefined(cbs)) {
      this.typesToCbs[reqType] = {cb: callback};
    } else if (isCallback(cbs.cb)) {
      const cb = cbs.cb;
      cbs.cb = [cb, callback];
    } else if (isCallbackArr(cbs.cb)) {
      cbs.cb.push(callback);
    } else {
      throw new TypeError(
          'Object with unexpected type in callbacks dictionary: ' + cbs.cb);
    }
  }

  emit(reqType: string, request: DapperRequest): void {
    if (!(reqType in this.typesToCbs)) return;
    const cbs = this.typesToCbs[reqType];
    if (isCallback(cbs.cb)) {
      cbs.cb(request);
      return;
    } else if (isCallbackArr(cbs.cb)) {
      cbs.cb.forEach((callbackFunction: Callback) => {
        callbackFunction(request);
      });
    } else {
      throw new TypeError(
          'Object with unexpected type in callbacks dictionary: ' + cbs.cb);
    }
  }
}
