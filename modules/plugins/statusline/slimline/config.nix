{
  config,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.nvim.dag) entryAnywhere;
  inherit (lib.nvim.lua) toLuaObject;

  cfg = config.vim.statusline.slimline;
in {
  vim = mkIf cfg.enable {
    startPlugins = ["slimline-nvim"];

    pluginRC.slimline-nvim = entryAnywhere ''
      require("slimline").setup(${toLuaObject cfg.setupOpts})
    '';
  };
}
