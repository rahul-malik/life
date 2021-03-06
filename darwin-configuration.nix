{ config, pkgs, ... }:
let
  yabai = pkgs.callPackage ./src/yabai/c.nix {
    inherit (pkgs.darwin.apple_sdk.frameworks) Carbon Cocoa CoreServices IOKit ScriptingBridge;
  };
in
let
  barbq =
    let
      src = pkgs.fetchFromGitHub {
        owner = "bkase";
        repo = "barbq";
        rev = "50a75b51e7cfb98c697c7a7ce320ea6acb699c72";
        sha256 = "0d1rfgz64kc7z4cxyasxm8rlaw8shfr1r7jqikjpragi0zlr2r1y";
      };
    in
      (import "${src}/release.nix").barbq;
in
  let
    screenshots-folder = "/Users/bkase/screenshots";
  in
    {
      imports = [
        ./src/yabai/service.nix
        ./src/dotconfig/c.nix
        ./src/common.nix
        ./src/zsh/c.nix
        ./src/vim/c.nix
      ];

      launchd.user.agents.barbq =
        let
          script = pkgs.writeScriptBin "statusbar" ''
            #!${pkgs.stdenv.shell}

            ${yabai}/bin/yabai -m rule --add app=Alacritty sticky=on

            /Users/bkase/Applications/Nix\ Apps/Alacritty.app/Contents/MacOS/alacritty -d 180 1 --position 0 0 -e ${barbq}/bin/barbq
          '';
        in
          {
            path = [ "${barbq}/bin" config.environment.systemPath ];
            serviceConfig.ProgramArguments = [ "${script}/bin/statusbar" ];
            serviceConfig.RunAtLoad = true;
            serviceConfig.KeepAlive = true;
          };

      system.activationScripts.postActivation.text = ''
        # Regenerate ~/.config files
        /etc/dotconfig/bin/generate

        # Ensure screenshots folder exists
        mkdir -p ${screenshots-folder}

        # Regenerate .gitignore
        echo "regenerating global .gitignore..."
        cat ${./src/gitignore} > ~/.gitignore
        git config --global core.excludesfile ~/.gitignore

        # Regenerate ~/.vim files
        echo "regenerating ~/.vim files..."
        mkdir -p ~/.vim
        cat ${./src/vim/coc-settings.json} > ~/.vim/coc-settings.json
      '';

      environment.systemPackages = [
        config.programs.vim.package
        yabai
        pkgs.kitty
        pkgs.alacritty
        barbq
      ];

      environment.extraOutputsToInstall = [ "man" ];

      system.defaults.NSGlobalDomain.InitialKeyRepeat = 12;
      system.defaults.NSGlobalDomain.KeyRepeat = 1;
      system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = false;
      system.defaults.dock.autohide = true;
      system.defaults.dock.orientation = "left";
      system.defaults.dock.showhidden = true;
      system.defaults.dock.mru-spaces = false;
      system.defaults.screencapture.location = "${screenshots-folder}";
      system.defaults.finder.AppleShowAllExtensions = true;
      system.defaults.finder.QuitMenuItem = true;
      system.defaults.finder.FXEnableExtensionChangeWarning = false;

      system.keyboard.enableKeyMapping = true;
      system.keyboard.remapCapsLockToControl = true;

      services.skhd.enable = true;

      #programs.nix-index.enable = true;

      services.nix-daemon.enable = true;
      #  nix.package = pkgs.nixUnstable;

      # SKHD
      services.skhd.skhdConfig = builtins.readFile ./src/skhdrc;

      environment.variables.LANG = "en_US.UTF-8";

      nixpkgs.config.allowUnfree = true;
      nixpkgs.overlays = [
        (
          self: super: {
            my_vim_configurable = super.vim_configurable.override {
              guiSupport = "no";
            };

            darwin-zsh-completions = super.runCommandNoCC "darwin-zsh-completions-0.0.0"
              { preferLocalBuild = true; }
              ''
                mkdir -p $out/share/zsh/site-functions
                cat <<-'EOF' > $out/share/zsh/site-functions/_darwin-rebuild
                #compdef darwin-rebuild
                #autoload
                _nix-common-options
                local -a _1st_arguments
                _1st_arguments=(
                  'switch:Build, activate, and update the current generation'\
                  'build:Build without activating or updating the current generation'\
                  'check:Build and run the activation sanity checks'\
                  'changelog:Show most recent entries in the changelog'\
                )
                _arguments \
                  '--list-generations[Print a list of all generations in the active profile]'\
                  '--rollback[Roll back to the previous configuration]'\
                  {--switch-generation,-G}'[Activate specified generation]'\
                  '(--profile-name -p)'{--profile-name,-p}'[Profile to use to track current and previous system configurations]:Profile:_nix_profiles'\
                  '1:: :->subcmds' && return 0
                case $state in
                  subcmds)
                    _describe -t commands 'darwin-rebuild subcommands' _1st_arguments
                  ;;
                esac
                EOF
              '';

          }
        )
      ];

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 3;

      nix.maxJobs = 8;
      nix.buildCores = 8;
    }
