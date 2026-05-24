{...}: {
  config.flake.modules.homeManager.station = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.azos.suites.station.enable = lib.mkOption {
      default = false;
      type = lib.types.bool;
    };
    config = lib.mkIf config.azos.suites.base.enable {
      home.keyboard = {
        options = ["grp:alt_shift_toggle"];
        layout = "us,il";
      };

      services.flameshot = {
        enable = true;
        settings = {
          General = {
            disabledTrayIcon = true;
            showStartupLaunchMessage = false;
          };
        };
      };

      services.dunst = {
        enable = true;
        settings = {
          global = {
            monitor = 0;
            follow = "keyboard";
            geometry = "300x5-30+20";
            progress_bar = true;
            progress_bar_height = 10;
            progress_bar_frame_width = 1;
            progress_bar_min_width = 150;
            progress_bar_max_width = 300;
            indicate_hidden = "yes";
            shrink = "no";
            transparency = 0;
            notification_height = 0;
            separator_height = 1;
            padding = 3;
            horizontal_padding = 4;
            text_icon_padding = 0;
            frame_width = 1;
            separator_color = "frame";
            background = "#cdcbb4";
            sort = "yes";
            idle_threshold = 120;
            font = "Iosevka Term 10";
            line_height = 0;
            markup = "full";
            format = "%s\n%b";
            alignment = "left";
            vertical_alignment = "center";
            show_age_threshold = 60;
            word_wrap = "yes";
            ignore_newline = "no";
            stack_duplicates = true;
            hide_duplicate_count = false;
            show_indicators = "yes";
            icon_position = "left";
            min_icon_size = 0;
            max_icon_size = 32;
            sticky_history = "yes";
            history_length = 20;
            always_run_script = "true";
            title = "Dunst";
            class = "Dunst";
            startup_notification = false;
            verbosity = "mesg";
            corner_radius = 0;
            ignore_dbusclose = false;
            force_xwayland = false;
            force_xinerama = false;
            mouse_left_click = "close_current";
            mouse_middle_click = "do_action, close_current";
            mouse_right_click = "close_all";
          };
          experimental = {per_monitor_dpi = false;};
          shortcuts = {};
          urgency_low = {
            foreground = "#2f4f4f";
            frame_color = "#cdcdb4";
            timeout = 10;
          };
          urgency_normal = {
            foreground = "#00cd00";
            frame_color = "#9aff9a";
            timeout = 10;
          };
          urgency_critical = {
            foreground = "#cd0000";
            frame_color = "#cd0000";
            timeout = 0;
          };
        };
      };

      home.activation.mk-downloads = lib.hm.dag.entryAfter ["writeBoundary"] ''
        mkdir -p $HOME/downloads
      '';

      home.packages = with pkgs; [
        mpv
        upower
        pass
        reaper
        exfatprogs
        e2fsprogs
      ];
    };
  };
}
