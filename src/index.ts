import {NvimPlugin} from 'neovim';

import * as Config from './config';
import * as dapper from './dapper';
import {NvimFrontTalker} from './nvim_fronttalker';

const PLUGIN_OPTIONS = {
  dev: false,
  alwaysInit: false
};

module.exports = (api: NvimPlugin) => {
  api.setOptions(PLUGIN_OPTIONS);
  dapper.initialize(new NvimFrontTalker(api));

  api.registerFunction(
      'DapperStart', dapper.startAndConfigureUnpack,
      dapper.FN_START_AND_CONFIGURE_OPTIONS);

  api.registerFunction(
      'DapperStop', dapper.terminateUnpack, dapper.FN_TERMINATE_OPTIONS);

  api.registerFunction(
      'DapperRequest', dapper.requestUnpack, dapper.FN_REQUEST_OPTIONS);
};
