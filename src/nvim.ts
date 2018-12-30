// tslint:disable:no-any
export declare type VimPrim = number | boolean | string;
export declare type VimDict = {
  [key: string]: any;
};
export declare type VimList = Array<VimPrim|VimDict|any>;
export declare type VimValue = VimDict | VimPrim | VimList;

export function isVimList(arg: any): arg is VimList {
  if (!arg.hasOwnProperty('length')) return false;
  for (let i = 0; i < arg.length; ++i) {
    const elt = arg[i];
    if (!isVimValue(elt)) return false;
  }
  return true;
}

export function isVimValue(arg: any): arg is VimValue {
  const typename = typeof arg;
  if (typename !== 'object') return true;
  if (arg.hasOwnProperty('length')) return isVimList(arg);
  // arg is a dictionary
  // apparently impossible to check for numerical keys, as far as I know, so
  // give up and return true
  return true;
}
