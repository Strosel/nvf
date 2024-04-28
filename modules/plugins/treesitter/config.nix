{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.lists) optional optionals;
  inherit (lib.trivial) boolToString;
  inherit (lib.nvim.binds) mkSetBinding addDescriptionsToMappings;
  inherit (lib.nvim.lua) toLuaObject;
  inherit (lib.nvim.dag) entryBefore entryAfter;

  cfg = config.vim.treesitter;
  usingNvimCmp = config.vim.autocomplete.enable && config.vim.autocomplete.type == "nvim-cmp";

  self = import ./treesitter.nix {inherit pkgs lib;};
  mappingDefinitions = self.options.vim.treesitter.mappings;
  mappings = addDescriptionsToMappings cfg.mappings mappingDefinitions;
in {
  config = mkIf cfg.enable {
    vim = {
      startPlugins = ["nvim-treesitter"] ++ optional usingNvimCmp "cmp-treesitter";

      autocomplete.sources = {"treesitter" = "[Treesitter]";};
      treesitter.grammars = optionals cfg.addDefaultGrammars cfg.defaultGrammars;

      maps = {
        # HACK: Using mkSetLuaBinding and putting the lua code does not work for some reason: It just selects the whole file.
        # This works though, and if it ain't broke, don't fix it.
        normal = mkSetBinding mappings.incrementalSelection.init ":lua require('nvim-treesitter.incremental_selection').init_selection()<CR>";

        visualOnly = mkMerge [
          (mkSetBinding mappings.incrementalSelection.incrementByNode ":lua require('nvim-treesitter.incremental_selection').node_incremental()<CR>")
          (mkSetBinding mappings.incrementalSelection.incrementByScope ":lua require('nvim-treesitter.incremental_selection').scope_incremental()<CR>")
          (mkSetBinding mappings.incrementalSelection.decrementByNode ":lua require('nvim-treesitter.incremental_selection').node_decremental()<CR>")
        ];
      };

      # For some reason treesitter highlighting does not work on start if this is set before syntax on
      configRC.treesitter-fold = mkIf cfg.fold (entryBefore ["basic"] ''
        " This is required by treesitter-context to handle folds
        set foldmethod=expr
        set foldexpr=nvim_treesitter#foldexpr()

        " This is optional, but is set rather as a sane default.
        " If unset, opened files will be folded by automatically as
        " the files are opened
        set nofoldenable
      '');

      luaConfigRC.treesitter = entryAfter ["basic"] ''
        require('nvim-treesitter.configs').setup {
          -- Disable imperative treesitter options that would attempt to fetch
          -- grammars into the read-only Nix store. To add additional grammars here
          -- you must use the `config.vim.treesitter.grammars` option.
          auto_install = false,
          sync_install = false,
          ensure_installed = {},

          -- Indentation module for Treesitter
          indent = {
            enable = true,
            disable = {},
          },

          -- Highlight module for Treesitter
          highlight = {
            enable = ${boolToString cfg.highlight.enable},
            disable = ${toLuaObject cfg.highlight.disable},
            additional_vim_regex_highlighting = false,
          },

          -- Indentation module for Treesitter
          -- Keymaps are set to false here as they are
          -- handled by `vim.maps` entries calling lua
          -- functions achieving the same functionality.
          incremental_selection = {
            enable = true,
            disable = {},
            keymaps = {
              init_selection = false,
              node_incremental = false,
              scope_incremental = false,
              node_decremental = false,
            },
          },
        }
      '';
    };
  };
}
