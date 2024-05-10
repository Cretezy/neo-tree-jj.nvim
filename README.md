# neo-tree-jj.nvim

A [Neo-tree](https://github.com/nvim-neo-tree/neo-tree.nvim) source for [Jujutsu/jj](https://github.com/martinvonz/jj).

Features:
* Shows changes files like `jj status`
* Shows different status for added/modified/deleted files
* Ability to add/move/delete/rename files/directories and copy/cut/paste

![Screenshot](.github/screenshot.png)

## Quickstart

Lazy.nvim:
```lua
{
  "Cretezy/neo-tree-jj.nvim",
  dependencies = {
    {
      "nvim-neo-tree/neo-tree.nvim",
      opts = function(_, opts)
        -- Register the source
        table.insert(opts.sources, "jj")
        -- Optional: Register the tab in neo-tree
        table.insert(opts.source_selector.sources, {
          display_name = "󰊢 JJ",
          source = "jj",
        })
      end,
    },
  },
},
```

After installing, open Neo-tree and navigate to the tab, or run `:Neotree jj`

