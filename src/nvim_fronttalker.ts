import {Neovim, NvimPlugin} from 'neovim';

import {BasicFrontTalker} from './basic_fronttalker';
import {DapperAnyMsg} from './messages';

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
    this.nvim.call(NvimFrontTalker.VIM_RECEIVE_FUNC, msg);
  }
}
