{
  config,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;

  cfg = config.vim.fzf-lua;
in {
  vim.lazy.plugins."fzf-lua" = mkIf cfg.enable {
    package = "fzf-lua";
    cmd = ["FzfLua"];
    setupModule = "fzf-lua";
    inherit (cfg) setupOpts;
  };
}
