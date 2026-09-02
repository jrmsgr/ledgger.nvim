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
      note_dir = "~/.local/notes", -- directory where the notes are stored
    },
    dependencies={"ibhagwan/fzf-lua", "nvim-lua/plenary.nvim"},
  },
```
