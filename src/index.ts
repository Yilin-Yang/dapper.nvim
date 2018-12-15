import * as neovim from 'neovim';
import { startDapper } from './start_dapper';
module.exports = (init: neovim.NvimPlugin) => {
  init.registerFunction('DapperStart', startDapper);
};
