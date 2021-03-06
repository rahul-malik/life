{ config, pkgs, ... }:
let
  yabai = pkgs.callPackage ./c.nix {
    inherit (pkgs.darwin.apple_sdk.frameworks) Carbon Cocoa CoreServices IOKit ScriptingBridge;
  };
in
{
  # yabai
  # TODO: Refactor this to be cleaner
  environment.etc."yabairc".source = pkgs.writeScript "etc-yabairc" (
    ''
      #!/usr/bin/env sh

      # bar settings
      yabai -m config status_bar                   off
      yabai -m config status_bar_text_font         "Helvetica Neue:Bold:12.0"
      yabai -m config status_bar_icon_font         "FontAwesome:Regular:12.0"
      yabai -m config status_bar_background_color  0xff202020
      yabai -m config status_bar_foreground_color  0xffa8a8a8
      yabai -m config status_bar_space_icon_strip  I II III IV V VI VII VIII IX X
      yabai -m config status_bar_power_icon_strip   
      yabai -m config status_bar_space_icon        
      yabai -m config status_bar_clock_icon        

      # global settings
      yabai -m config mouse_follows_focus          on
      yabai -m config focus_follows_mouse          autofocus
      yabai -m config window_placement             second_child
      yabai -m config window_topmost               off
      yabai -m config window_opacity               off
      yabai -m config window_opacity_duration      0.0
      yabai -m config window_shadow                off
      yabai -m config window_border                on
      yabai -m config window_border_placement      inset
      yabai -m config window_border_width          4
      yabai -m config window_border_radius         0
      yabai -m config active_window_border_topmost off
      yabai -m config active_window_border_color   0xff268bd2
      yabai -m config normal_window_border_color   0x00505050
      yabai -m config insert_window_border_color   0xffd75f5f
      yabai -m config active_window_opacity        1.0
      yabai -m config normal_window_opacity        0.90
      yabai -m config split_ratio                  0.50
      yabai -m config auto_balance                 off
      yabai -m config mouse_modifier               fn
      yabai -m config mouse_action1                move
      yabai -m config mouse_action2                resize

      # general space settings
      yabai -m config layout                       bsp
      yabai -m config top_padding                  30
      yabai -m config bottom_padding               5
      yabai -m config left_padding                 5
      yabai -m config right_padding                5
      yabai -m config window_gap                   5
    ''
  );

  launchd.user.agents.yabai = {
    path = [ "${yabai}/bin" config.environment.systemPath ];
    serviceConfig.ProgramArguments = [
      "${yabai}/bin/yabai"
      "-c"
      "/etc/yabairc"
    ];
    serviceConfig.RunAtLoad = true;
    serviceConfig.KeepAlive = true;
    serviceConfig.ProcessType = "Interactive";
  };
}
