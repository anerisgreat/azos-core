{ lib, config, pkgs, options, azos-utils, ... }:
let
  isEnabled = config.azos.suites.base.enable;
in
{
  options.azos.suites.station.enable = azos-utils.mkSuiteEnableOption {};

  imports = [
    ./emacs
  ];

  config = lib.mkIf isEnabled {
    #Input!
    home.keyboard = {
        options = [
            "grp:alt_shift_toggle"
        ];
        layout = "us,il";
    };

    #Flameshot
    services.flameshot = {
      enable = true;
      settings = {
        General = {
            disabledTrayIcon = true;
            showStartupLaunchMessage = false;
        };
      };
    };

    #DUNST
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

            ### Text ###

            font = "Iosevka Term 10";
            line_height = 0;

            markup = "full";

            format = "%s\n%b";

            # Alignment of message text.
            alignment = "left";

            # Vertical alignment of message text and icon.
            # Possible values are "top", "center" and "bottom".
            vertical_alignment = "center";

            # Show age of message if message is older than show_age_threshold
            # seconds.
            show_age_threshold = 60;

            # Split notifications into multiple lines if they don't fit into
            # geometry.
            word_wrap = "yes";

            # Ignore newlines '\n' in notifications.
            ignore_newline = "no";

            # Stack together notifications with the same content
            stack_duplicates = true;

            # Hide the count of stacked notifications with the same content
            hide_duplicate_count = false;

            # Display indicators for URLs (U) and actions (A).
            show_indicators = "yes";

            ### Icons ###

            # Align icons left/right/off
            icon_position = "left";

            # Scale small icons up to this size, set to 0 to disable. Helpful
            # for e.g. small files or high-dpi screens. In case of conflict,
            # max_icon_size takes precedence over this.
            min_icon_size = 0;

            # Scale larger icons down to this size, set to 0 to disable
            max_icon_size = 32;

            ### History ###
            # Should a notification popped up from history be sticky or timeout
            # as if it would normally do.
            sticky_history = "yes";

            # Maximum amount of notifications kept in history
            history_length = 20;

            ### Misc/Advanced ###

            # Browser for opening urls in context menu.
            # browser = /usr/bin/firefox -new-tab

            # Always run rule-defined scripts, even if the notification is suppressed
            always_run_script = "true";

            # Define the title of the windows spawned by dunst
            title = "Dunst";

            # Define the class of the windows spawned by dunst
            class = "Dunst";

            # Print a notification on startup.
            # This is mainly for error detection, since dbus (re-)starts dunst
            # automatically after a crash.
            startup_notification = false;

            # Manage dunst's desire for talking
            # Can be one of the following values:
            #  crit: Critical features. Dunst aborts
            #  warn: Only non-fatal warnings
            #  mesg: Important Messages
            #  info: all unimportant stuff
            # debug: all less than unimportant stuff
            verbosity = "mesg";

            # Define the corner radius of the notification window
            # in pixel size. If the radius is 0, you have no rounded
            # corners.
            # The radius will be automatically lowered if it exceeds half of the
            # notification height to avoid clipping text and/or icons.
            corner_radius = 0;

            # Ignore the dbus closeNotification message.
            # Useful to enforce the timeout set by dunst configuration. Without this
            # parameter, an application may close the notification sent before the
            # user defined timeout.
            ignore_dbusclose = false;

            ### Wayland ###
            # These settings are Wayland-specific. They have no effect when using X11

            # Uncomment this if you want to let notications appear under fullscreen
            # applications (default: overlay)
            # layer = top

            # Set this to true to use X11 output on Wayland.
            force_xwayland = false;

            ### Legacy

            # Use the Xinerama extension instead of RandR for multi-monitor support.
            # This setting is provided for compatibility with older nVidia drivers that
            # do not support RandR and using it on systems that support RandR is highly
            # discouraged.
            #
            # By enabling this setting dunst will not be able to detect when a monitor
            # is connected or disconnected which might break follow mode if the screen
            # layout changes.
            force_xinerama = false;

            ### mouse

            # Defines list of actions for each mouse event
            # Possible values are:
            # * none: Don't do anything.
            # * do_action: If the notification has exactly one action, or one is marked as default,
            #              invoke it. If there are multiple and no default, open the context menu.
            # * close_current: Close current notification.
            # * close_all: Close all notifications.
            # These values can be strung together for each mouse event, and
            # will be executed in sequence.
            mouse_left_click = "close_current";
            mouse_middle_click = "do_action, close_current";
            mouse_right_click = "close_all";
        };

        # Experimental features that may or may not work correctly. Do not expect them
        # to have a consistent behaviour across releases.
        experimental = {
            # Calculate the dpi to use on a per-monitor basis.
            # If this setting is enabled the Xft.dpi value will be ignored and instead
            # dunst will attempt to calculate an appropriate dpi value for each monitor
            # using the resolution and physical size. This might be useful in setups
            # where there are multiple screens with very different dpi values.
            per_monitor_dpi = false;
        };

        # The internal keyboard shortcut support in dunst is now considered deprecated
        # and should be replaced by dunstctl calls. You can use the configuration of your
        # WM or DE to bind these to shortcuts of your choice.
        # Check the dunstctl manual page for more info.
        shortcuts = {
            # Shortcuts are specified as [modifier+][modifier+]...key
            # Available modifiers are "ctrl", "mod1" (the alt-key), "mod2",
            # "mod3" and "mod4" (windows-key).
            # Xev might be helpful to find names for keys.

            # Close notification. Equivalent dunstctl command:
            # dunstctl close
            # close = ctrl+space

            # Close all notifications. Equivalent dunstctl command:
            # dunstctl close-all
            # close_all = ctrl+shift+space

            # Redisplay last message(s). Equivalent dunstctl command:
            # dunstctl history-pop
            # history = ctrl+grave

            # Context menu. Equivalent dunstctl command:
            # dunstctl context
            # context = ctrl+shift+period

        };

        urgency_low = {
            foreground = "#2f4f4f";
            frame_color = "#cdcdb4";
            timeout = 10;
            # Icon for notifications with low urgency, uncomment to enable
            #icon = /path/to/icon
        };

        urgency_normal = {
            foreground = "#00cd00";
            frame_color = "#9aff9a";
            timeout = 10;
            #icon = /path/to/icon
        };

        urgency_critical = {
            foreground = "#cd0000";
            frame_color = "#cd0000";
            timeout = 0;
            #icon = /path/to/icon
        };
      };
    };

    home.packages = with pkgs; [
      qutebrowser
      mpv
      upower
      pass
      reaper
    ];
  };
}
