dapper.nvim
================================================================================
A language-agnostic debugger plugin frontend for neovim; a fancy client for the
[debug adapter protocol!](https://microsoft.github.io/debug-adapter-protocol/)
WIP.


Requirements
--------------------------------------------------------------------------------
dapper.nvim requires:

- **Node.js,** with the following packages as runtime dependencies:
  - typescript
  - vscode-debugadapter
- **neovim 0.1.6** or newer.
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

#### neovim Node.js Client

Install [neovim's node client](https://github.com/neovim/node-client) by running
the following:

```bash
npm install -g neovim
```

### Plugin Installation
We recommend installing dapper.nvim using [vim-plug.](https://github.com/junegunn/vim-plug)

```vim
" .vimrc
call plug#begin('~/.vim/bundle')
" ...
Plug 'Yilin-Yang/dapper.nvim', { 'do': 'npm install --production && npm run compile', }
" ...
call plug#end()
```
And then run `:PlugInstall`.

Other package managers (like Vundle) are usable, so long as you make sure to
install the plugin's Node.js package dependencies. For instance, you might do
the following:

```vim
" .vimrc
call vundle#begin('~/.vim/bundle')
" ...
Plugin 'Yilin-Yang/dapper.nvim'
" ...
call vundle#end()
```

And then,
```bash
cd ~/.vim/bundle # or wherever you've installed the plugin
cd dapper.nvim
npm install --production
npm run compile
```

Contribution
--------------------------------------------------------------------------------

### Prerequisites
Install development dependencies using:

```bash
npm install   # without --production flag
```

### Coding Style
This repository has an [EditorConfig](https://editorconfig.org/) file in its
top-level directory. If contributing from vim, you can use
[editorconfig-vim](https://editorconfig.org/) to load settings from this file
automatically.

This repository is written in a mixture of VimL and TypeScript. For the latter,
try to follow Google's style wherever possible, as enforced by the
[ts-style](https://github.com/google/ts-style) tool.

`ts-style` provides the following commands, among others:

```bash
gts check # lint and check for formatting problems
gts fix   # fix style/formatting errors, wherever possible
gts clean # remove output files, analogous to `make clean`
```

If the EditorConfig and `ts-style` conflict, prefer `ts-style` and (if possible)
open a pull request after changing the EditorConfig to match.

License
--------------------------------------------------------------------------------
MIT
