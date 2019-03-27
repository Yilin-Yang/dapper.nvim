dapper.nvim (PRE-ALPHA)
================================================================================
A language-agnostic debugger plugin frontend for neovim, implemented as a client
for the [debug adapter protocol.](https://microsoft.github.io/debug-adapter-protocol/)

**Work In Progress.**


Requirements
--------------------------------------------------------------------------------
dapper.nvim requires:

- A recent version of **Node.js**.
- **neovim,** and the neovim Node.js provider.
<!-- TODO update requirements based on nvim api functions -->
<!-- TODO update Node requirements -->

Installation
--------------------------------------------------------------------------------

### Prerequisites

#### Node.js
If you haven't done so already, install Node.js and the Node package manager. On
Ubuntu, we recommend following the instructions [here](https://websiteforstudents.com/install-the-latest-node-js-and-nmp-packages-on-ubuntu-16-04-18-04-lts/)
to install a recent **LTS** version of Node.js.

Alternatively, you might just install Node.js through apt.
```bash
sudo apt install nodejs
```

#### yarn
While it should be possible to install dapper.nvim's Node dependencies using
npm, we strongly recommend using yarn instead. In our experience, yarn is much
more reliable.

Find installation instructions for yarn [here.](https://yarnpkg.com/lang/en/docs/install/)

#### neovim Node.js Client

Install [neovim's node client](https://github.com/neovim/node-client) by running
the following:

```bash
sudo npm install -g neovim

# OR, if you use yarn,

yarn add global neovim
```

### Plugin Installation
We recommend installing dapper.nvim using [vim-plug.](https://github.com/junegunn/vim-plug)

```vim
" .vimrc
call plug#begin('~/.vim/bundle')
" ...
Plug 'Yilin-Yang/dapper.nvim', { 'do': 'yarn install', }

  " dependencies
  Plug 'Google/vim-maktaba'
  Plug 'Yilin-Yang/VSCrib.vim'
  Plug 'Yilin-Yang/TypeVim'
" ...
call plug#end()
```
And then run `:PlugInstall`, followed by `:UpdateRemotePlugins`.

Other package managers (like Vundle) are usable, so long as you make sure to
install the plugin's Node.js package dependencies. For instance, you might do
the following:

```vim
" .vimrc
call vundle#begin('~/.vim/bundle')
" ...
Plugin 'Yilin-Yang/dapper.nvim'

  " dependencies
  Plugin 'Google/vim-maktaba'
  Plugin 'Yilin-Yang/VSCrib.vim'
  Plugin 'Yilin-Yang/TypeVim'
" ...
call vundle#end()
```

And then,
```bash
cd ~/.vim/bundle # or wherever you've installed the plugin
cd dapper.nvim
yarn install
```

Contribution
--------------------------------------------------------------------------------

### Prerequisites
Install development dependencies and compile the TypeScript source using:

```bash
yarn install
```

### Running Tests

#### vim Frontend Test Cases (vader)

```bash
# from project root,
cd test
./run_tests_nvim [-v | --visible] [-i | --international] [--file=<TESTFILE.vader>]
```

dapper.nvim uses [vader.vim](https://github.com/junegunn/vader.vim) as its
testing framework; you must have vader.vim installed to run the vim tests. (See
`.travis_vimrc` in the project root for the necessary installation path.)

Specifying `--visible` will run the tests in an active neovim GUI. Specifying
`--international` will re-run the same test suites in other locales (e.g.
in German, in Spanish), to catch bugs that only occur when running neovim in
a [non-English language.](https://github.com/Yilin-Yang/vim-markbar/issues/5)
International test cases require that those other locales be installed on your
machine; see `.travis.yml` for (Debian/Ubuntu) installation instructions.

#### TypeScript "Middle-end" Test Cases (mocha)

```bash
# from project root
./clone_node_dap.sh  # "install" vscode-mock-debug into node_modules
npm run test
```
dapper.nvim uses [mocha](https://mochajs.org/) as its testing library. `yarn
install` should also install mocha, and all necessary dependencies for running
it.

Note that, since the Debug Adapter Protocol (and dapper.nvim, by extension) rely
heavily on inter-process communication (e.g. launching debug adapters in the
background, terminating those adapters after tests are complete), it's possible
for tests to fail by timing out; the test case timeouts are generously long
(5000ms, as of the time of writing) for this reason. This is probably only an
issue on slower machines/environments (e.g. thin-and-light notebooks, WSL), but
if you encounter it, try setting your computer to a "High performance" power
state.

If `npm run test` does not terminate (e.g. if all tests pass, but mocha hangs,
and the command doesn't get to run `npx gts check`), this means that [one of the
test cases failed to "clean up",](https://boneskull.com/mocha-v4-nears-release/#mochawontforceexit)
which should be treated as a failure.

### Coding Style
This repository has an [EditorConfig](https://editorconfig.org/) file in its
top-level directory. If contributing using vim, you can use [editorconfig-vim](https://editorconfig.org/)
to load settings from `.editorconfig` automatically.

This repository is written in a mixture of VimL and TypeScript, and
tries to follow Google's style guides wherever possible.

A link to Google's VimL style guide can be found [here.](https://google.github.io/styleguide/vimscriptguide.xml)

Adherence to Google's TypeScript style guide can be easily checked/fixed by the
[ts-style](https://github.com/google/ts-style) tool.

`ts-style` provides the following commands, among others:

```bash
[npx] gts check # lint and check for formatting problems
[npx] gts fix   # fix style/formatting errors, wherever possible
[npx] gts clean # remove output files, analogous to `make clean`
```

(The [`npx` program](https://www.npmjs.com/package/npx) will run `gts` from
`dapper.nvim/node_modules.bin`, if it is not installed globally.)

If the EditorConfig and `ts-style` conflict, prefer `ts-style` and (if possible)
open a pull request after changing the EditorConfig to match.

License
--------------------------------------------------------------------------------
MIT
