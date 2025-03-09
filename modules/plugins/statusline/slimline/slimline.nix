{
  config,
  lib,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.nvim.types) mkPluginSetupOption;
in {
  options.vim.statusline.slimline = {
    enable = mkEnableOption "slimline";
    setupOpts = mkPluginSetupOption "slimline" {};
  };
}
