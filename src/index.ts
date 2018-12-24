import {NvimPlugin} from 'neovim';
import * as dapper from './dapper';

const PLUGIN_OPTIONS = {
  dev: false,
  alwaysInit: false
};

module.exports = (api: NvimPlugin) => {
  api.setOptions(PLUGIN_OPTIONS);
  dapper.initialize(api);
  api.registerCommand('DapperStart', dapper.start, dapper.CM_START_OPTIONS);
  api.registerFunction(
      'DapperRequest', dapper.request, dapper.FN_REQUEST_OPTIONS);
};
