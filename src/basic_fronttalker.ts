import {isUndefined} from 'util';

import {FrontTalker} from './fronttalker';
import {DapperAnyMsg, DapperRequest} from './messages';

// tslint:disable:no-any
type Callback = (req: DapperAnyMsg) => any;
interface CallbackOrArr {
  cb: Callback|Callback[]|undefined;
}

type ReqCallback = (req: DapperRequest) => any;

function isCallback(arg: any): arg is Callback {
  // note:  doesn't check whether arg has the Callback function signature,
  //        only that it *is* a function
  return typeof arg as string === 'function';
}
function isCallbackArr(arg: any): arg is Callback[] {
  // note:  not robust; doesn't check the *entire* array for type homogeneity
  return arg.length !== undefined && (!arg.length || isCallback(arg[0]));
}

/**
 * Basic implementation of FrontTalker event emission only.
 */
export class BasicFrontTalker implements FrontTalker {
  private typesToCbs: {[name: string]: CallbackOrArr};
  private strToRegexCbs: {[regexStr: string]: {regex: RegExp}&CallbackOrArr};

  constructor() {
    this.typesToCbs = {};
    this.strToRegexCbs = {};
  }

  send(msg: DapperAnyMsg): void {
    throw Error('send() not implemented in basic superclass');
  }

  on(reqType: string|RegExp, callback: ReqCallback): FrontTalker {
    if (typeof reqType === 'string') {
      return this.onStr(reqType, callback);
    } else if (reqType instanceof RegExp) {
      return this.onReg(reqType, callback);
    } else {
      throw new TypeError('Bad type on given reqType: ' + reqType);
    }
  }

  private onStr(reqType: string, callback: ReqCallback): FrontTalker {
    let cbs: CallbackOrArr = this.typesToCbs[reqType];
    if (isUndefined(cbs)) {
      cbs = {cb: undefined};
      this.typesToCbs[reqType] = this.addCallback(cbs, callback);
    } else {
      this.addCallback(cbs, callback);
    }
    return this;
  }

  private onReg(regex: RegExp, callback: ReqCallback): FrontTalker {
    const regStr = regex.toString();
    let regAndCbs = this.strToRegexCbs[regStr];
    if (isUndefined(regAndCbs)) {
      regAndCbs = {regex, cb: undefined};
      regAndCbs.cb = this.addCallback({cb: undefined}, callback).cb;
      this.strToRegexCbs[regStr] = regAndCbs;
    } else {
      this.addCallback(regAndCbs, callback);
    }
    return this;
  }

  /**
   * Append the given callback `toAdd` to the given `CallbackOrArr`.
   *
   * Also, return a reference to it.
   */
  private addCallback(cbs: CallbackOrArr, toAdd: ReqCallback): CallbackOrArr {
    if (isUndefined(cbs) || isUndefined(cbs.cb)) {
      cbs.cb = toAdd as Callback;
    } else if (isCallback(cbs.cb)) {
      cbs.cb = [cbs.cb, toAdd] as Callback[];
    } else if (isCallbackArr(cbs.cb)) {
      cbs.cb.push(toAdd as Callback);
    }
    return cbs;
  }

  off(reqType: string|RegExp, callback: ReqCallback): FrontTalker {
    if (typeof reqType === 'string') {
      return this.offStr(reqType, callback);
    } else if (reqType instanceof RegExp) {
      return this.offReg(reqType, callback);
    } else {
      throw new TypeError('Bad type on given reqType: ' + reqType);
    }
  }

  private offStr(reqType: string, callback: ReqCallback): FrontTalker {
    const cbs: CallbackOrArr = this.typesToCbs[reqType];
    this.removeCallback(cbs, callback);
    return this;
  }

  private offReg(regex: RegExp, callback: ReqCallback): FrontTalker {
    const regStr = regex.toString();
    const regAndCbs = this.strToRegexCbs[regStr];
    this.removeCallback(regAndCbs, callback);
    return this;
  }

  private removeCallback(cbs: CallbackOrArr, toRem: ReqCallback):
      CallbackOrArr {
    if (isUndefined(cbs) || isUndefined(cbs.cb)) {
    } else if (isCallback(cbs.cb)) {
      if (cbs.cb.toString() === toRem.toString()) {
        delete cbs.cb;
      }
    } else if (isCallbackArr(cbs.cb)) {
      const cbArr = cbs.cb;
      for (let i = 0; i < cbArr.length; ++i) {
        const storedCb = cbArr[i];
        if (storedCb.toString() === toRem.toString()) {
          cbArr.splice(i, 1);
          break;
        }
      }
    }
    return cbs;
  }

  emit(reqType: string, request: DapperRequest): boolean {
    let reqSent = false;
    if (reqType in this.typesToCbs) {
      // callback "string subscribers"
      const cbs = this.typesToCbs[reqType];
      reqSent = this.callback(cbs, request);
    }
    if (Object.keys(this.strToRegexCbs).length) {
      // test with regex subscribers
      for (const regStr of Object.keys(this.strToRegexCbs)) {
        const regexCb = this.strToRegexCbs[regStr];
        if (regexCb.regex.test(reqType)) {
          const sent = this.callback(regexCb, request);
          if (!reqSent) reqSent = sent;
        }
      }
    }
    return reqSent;
  }

  private callback(cbs: CallbackOrArr, request: DapperRequest): boolean {
    if (isUndefined(cbs) || (!isUndefined(cbs) && isUndefined(cbs.cb))) {
      return false;
    } else if (isCallback(cbs.cb)) {
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
          'Object with unexpected type in callbacks dictionary: ' +
          JSON.stringify(cbs));
    }
  }
}
