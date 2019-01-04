import {Neovim, NvimPlugin} from 'neovim';

import {BasicFrontTalker} from './basic_fronttalker';
import {DapperAnyMsg, DapperReport, typenameOf} from './messages';

// tslint:disable:no-any

/**
 * Full implementation of FrontTalker that allows for communication with nvim.
 */
export class NvimFrontTalker extends BasicFrontTalker {
  static readonly VIM_RECEIVE_FUNC = 'dapper#receive';

  /**
   * For manipulating the user-facing neovim instance.
   */
  private nvim: Neovim;

  constructor(api: NvimPlugin) {
    super();
    this.nvim = api.nvim;
  }

  send(msg: DapperAnyMsg): void {
    try {
      this.nvim.call(NvimFrontTalker.VIM_RECEIVE_FUNC, msg);
    } catch (e) {
      if (msg.type === 'report') {
        console.log(
            '(NvimFrontTalker) Failed to send report: ' + JSON.stringify(msg));
        return;
      }
      this.report(
          'error', 'Sending ' + msg.vim_msg_typename + ' failed!', e.toString(),
          false, JSON.stringify(msg));
    }
  }

  report(kind: string, brief: string, long: string, alert = false, other?: any):
      Promise<void> {
    const msg: DapperReport = {
      seq: 0,
      vim_id: 0,
      vim_msg_typename: '',
      type: 'report',
      kind,
      brief,
      long,
      alert,
      other
    };
    msg.vim_msg_typename = typenameOf(msg);
    console.log('(NvimFrontTalker) Sending report: ' + JSON.stringify(msg));
    return Promise.resolve(this.send(msg));
  }
}
