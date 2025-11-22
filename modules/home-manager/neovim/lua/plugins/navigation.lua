return {
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      watch_for_changes = true,
      git = {
        -- Return true to automatically git add/mv/rm files
        add = function(path) return true end,
        mv = function(src_path, dest_path) return true end,
        rm = function(path) return true end,
      },

      keymaps = { ["<Esc>"] = { "actions.close", mode = "n" } },
    },
  },
  {
    "folke/flash.nvim",
    opts = {
      jump = { autojump = false },
      label = {
        uppercase = false,
        style = "inline",
        min_pattern_length = 2,
        rainbow = { enabled = true },
      },
      highlight = {
        backdrop = false,
      },
      modes = {
        search = { enabled = false },
        char = { enabled = false },
      },
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "scottmckendry/pick-resession.nvim",
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },
    opts = function()
      return {
        defaults = {
          layout_config = { prompt_position = "top" },
          sorting_strategy = "ascending",
          file_ignore_patterns = {
            -- images
            "%.jpe?g$", "%.png$", "%.gif$", "%.svg$",
            -- video / audio
            "%.mp4$", "%.mkv$", "%.webm$", "%.mp3$", "%.wav$", "%.ogg$",
            -- other heavies
            "%.pdf$", "%.zip$", "%.tar$", "%.7z$", "%.iso$",
            -- unwanted dirs
            "%.git/", "%.cache/",
          },
          mappings = {
            i = {
              ["<Esc>"] = require("telescope.actions").close,
              ["<C-d>"] = require("telescope.actions").delete_buffer,
            },
          },
        },

        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },

        pickers = {
          find_files = { hidden = true, follow = false },
          live_grep = { additional_args = function() return { "--hidden" } end },
        },
      }
    end,

    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      pcall(telescope.load_extension, "fzf")
      pcall(telescope.load_extension, "resession")
    end,
  },
}
