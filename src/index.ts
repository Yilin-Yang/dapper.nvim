import {NvimPlugin} from 'neovim';
import * as dapper from './dapper';

const PLUGIN_OPTIONS = {
  dev: false,
  alwaysInit: false
};

module.exports = (api: NvimPlugin) => {
  api.registerFunction('DapperStart', dapper.start, dapper.FN_START_OPTIONS);
};
