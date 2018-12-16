import {NvimPlugin} from 'neovim';
import * as dapper from './dapper';

const PLUGIN_OPTIONS = {
  dev: false,
  alwaysInit: false
};

module.exports = (api: NvimPlugin) => {
  api.setOptions(PLUGIN_OPTIONS);
  api.registerCommand('DapperStart', dapper.start, dapper.FN_START_OPTIONS);
};
