{
  description = "Flake to manage grub2 themes from vinceliuice";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in
    with nixpkgs.lib; {
      nixosModules.default = {config, ...}: let
        cfg = config.boot.loader.grub2-theme;

        hasBootMenuConfig = cfg.bootMenuConfig != null;
        hasTerminalConfig = cfg.terminalConfig != null;

        grub2-theme = pkgs.stdenv.mkDerivation {
          name = "grub2-theme";
          src = "${self}";
          installPhase = ''
            mkdir -p $out/grub/themes;
            cp -a --no-preserve=ownership config/theme.txt $out/grub/themes/g2theme
            cp -a --no-preserve=ownership common/*.png $out/grub/themes/g2theme
            cp -a --no-preserve=ownership common/*.pf2 $out/grub/themes/g2theme

            cp -a --no-preserve=ownership assets/assets-${cfg.icon}/icons-2k $out/grub/themes/g2theme/icons
            cp -a --no-preserve=ownership assets/assets-select/select-2k/*.png $out/grub/themes/g2theme

            if [ ${pkgs.lib.trivial.boolToString hasBootMenuConfig} == "true" ]; then
              sed -i ':again;$!N;$!b again; s/\+ boot_menu {[^}]*}//g' $out/grub/themes/g2theme/theme.txt;
              cat << EOF >> $out/grub/themes/g2theme/theme.txt
              + boot_menu {
                ${
              if cfg.bootMenuConfig == null
              then ""
              else cfg.bootMenuConfig
            }
              }
            EOF
            fi;

            if [ ${pkgs.lib.trivial.boolToString hasTerminalConfig} == "true" ]; then
              sed -i 's/^terminal-.*$//g' $out/grub/themes/g2theme/theme.txt
              cat << EOF >> $out/grub/themes/g2theme/theme.txt
                ${
              if cfg.terminalConfig == null
              then ""
              else cfg.terminalConfig
            }
              EOF
            fi;
          '';
        };
      in {
        options = {
          boot.loader.grub2-theme = {
            enable = mkOption {
              default = true;
              example = true;
              type = types.bool;
              description = ''
                Enable grub2 theming
              '';
            };
            icon = mkOption {
              default = "white";
              example = "white";
              type = types.enum ["color" "white" "whitesur"];
              description = ''
                The icon to use for grub2.
              '';
            };
            resolution = mkOption {
              default = "1920x1080";
              example = "2560x1440";
              type = types.str;
              description = ''
                The screen resolution to use for grub2.
              '';
            };
            bootMenuConfig = mkOption {
              default = null;
              example = "left = 30%";
              type = types.nullOr types.str;
              description = ''
                Grub theme definition for boot_menu.
                Refer to config/theme-*.txt for reference.
              '';
            };
            terminalConfig = mkOption {
              default = null;
              example = "terminal-font: \"Terminus Regular 18\"";
              type = types.nullOr types.str;
              description = ''
                Replaces grub theme definition for terminial-*.
                Refer to config/theme-*.txt for reference.
              '';
            };
          };
        };
        config = mkIf cfg.enable (mkMerge [
          {
            environment.systemPackages = [grub2-theme];
            boot.loader.grub = {
              theme = "${grub2-theme}/grub/themes/g2theme";
              gfxmodeEfi = "${cfg.resolution},auto";
              gfxmodeBios = "${cfg.resolution},auto";
              extraConfig = ''
                insmod gfxterm
                insmod png
                set icondir=($root)/theme/icons
              '';
            };
          }
        ]);
      };
    };
}
