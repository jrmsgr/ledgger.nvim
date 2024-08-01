# Leddger.nvim

My own plugin to take notes. Use at your own risk, code is not guaranteed to work.

Requires [gitlab-ls](https://github.com/jrmsgr/gitlab-ls) to work

## Config

With `lazy.nvim`:

```lua
  {
    'jrmsgr/leddger.nvim',

    -- gitlab-ls opts
    opts = {
      name = 'gitlab-ls',
      cmd = {  'path/to/gitlab-ls/gitlab-ls.sh' },
      init_options = {
        url = '<gitlab server base url>',
        private_token = '<Your private read-only token',
        projects = { 'projects/project1', 'projects/project2' }, -- List of projects to fetch
      },
    },
    dependencies = { 'nvim-lua/plenary.nvim' },
  },
```
