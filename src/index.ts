import {NvimPlugin} from 'neovim';

import * as Config from './config';
import * as dapper from './dapper';

const PLUGIN_OPTIONS = {
  dev: false,
  alwaysInit: false
};

module.exports = (api: NvimPlugin) => {
  api.setOptions(PLUGIN_OPTIONS);
  dapper.initialize(api);

  api.registerFunction(
      'DapperStart',
      async (
          startArgs: Config.StartArgs, bpArgs: Config.InitialBreakpoints) => {
        await dapper.start(startArgs);
        await dapper.configure(bpArgs);
      },
      dapper.FN_START_OPTIONS);

  api.registerFunction(
      'DapperRequest', dapper.request, dapper.FN_REQUEST_OPTIONS);
};
