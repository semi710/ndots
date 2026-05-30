{ ... }:
{
  programs.zen-browser.profiles.default.keyboardShortcuts = [
    {
      id = "zen-compact-mode-toggle";
      key = "k";
      modifiers = {
        control = false;
        alt = false;
        shift = true;
        meta = true;
        accel = false;
      };
    }
    {
      id = "zen-compact-mode-show-sidebar";
      key = "l";
      modifiers = {
        control = false;
        alt = false;
        shift = true;
        meta = true;
        accel = false;
      };
    }
    {
      id = "zen-workspace-forward";
      key = "]";
      modifiers = {
        control = true;
        alt = true;
        shift = false;
        meta = true;
        accel = false;
      };
    }
    {
      id = "zen-workspace-backward";
      key = "[";
      modifiers = {
        control = true;
        alt = true;
        shift = false;
        meta = true;
        accel = false;
      };
    }
    {
      id = "zen-split-view-grid";
      key = "g";
      modifiers = {
        control = false;
        alt = true;
        shift = false;
        meta = false;
        accel = true;
      };
    }
    {
      id = "zen-split-view-vertical";
      key = "«";
      modifiers = {
        control = false;
        alt = true;
        shift = false;
        meta = true;
        accel = false;
      };
    }
    {
      id = "zen-split-view-horizontal";
      key = "–";
      modifiers = {
        control = false;
        alt = true;
        shift = false;
        meta = true;
        accel = false;
      };
    }
    {
      id = "zen-split-view-unsplit";
      key = "u";
      modifiers = {
        control = false;
        alt = true;
        shift = false;
        meta = false;
        accel = true;
      };
    }
    {
      id = "zen-new-empty-split-view";
      key = "*";
      modifiers = {
        control = false;
        alt = false;
        shift = true;
        meta = false;
        accel = true;
      };
    }
    {
      id = "zen-toggle-pin-tab";
      key = "d";
      modifiers = {
        control = false;
        alt = false;
        shift = true;
        meta = false;
        accel = true;
      };
    }
    {
      id = "zen-close-all-unpinned-tabs";
      key = "k";
      modifiers = {
        control = false;
        alt = false;
        shift = true;
        meta = false;
        accel = true;
      };
    }
    {
      id = "zen-glance-expand";
      key = "o";
      modifiers = {
        control = false;
        alt = false;
        shift = false;
        meta = false;
        accel = true;
      };
    }
    {
      id = "zen-copy-url";
      key = "c";
      modifiers = {
        control = false;
        alt = false;
        shift = true;
        meta = false;
        accel = true;
      };
    }
    {
      id = "zen-copy-url-markdown";
      key = "c";
      modifiers = {
        control = false;
        alt = true;
        shift = true;
        meta = false;
        accel = true;
      };
    }
    {
      id = "zen-new-unsynced-window";
      key = "n";
      modifiers = {
        control = false;
        alt = false;
        shift = true;
        meta = false;
        accel = true;
      };
    }
    {
      id = "zen-toggle-sidebar";
      key = "b";
      modifiers = {
        control = false;
        alt = true;
        shift = false;
        meta = false;
        accel = false;
      };
    }
  ];
}
