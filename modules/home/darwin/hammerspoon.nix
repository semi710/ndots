{ pkgs, ... }:
{
  home.packages = with pkgs; [ hammerspoon ];

  home.file.".hammerspoon/init.lua".text = # lua
    ''
      hs.allowAppleScript(true)
      hs.console.darkMode(true)

      -- SKHD Special Mode Indicator
      skhdmode = {}
      skhdmode.canvas = nil

      function skhdmode.createIndicator()
        local canvas = hs.canvas.new({ w = 110, h = 32, x = 0, y = 0 })

        canvas:insertElement({
          type = 'rectangle',
          action = 'fill',
          roundedRectRadii = { xRadius = 8, yRadius = 8 },
          fillColor = { red = 0.2, green = 0.2, blue = 0.2, alpha = 0.85 },
          strokeColor = { white = 1.0, alpha = 0.5 },
          strokeWidth = 1.0,
          frame = { x = 0, y = 0, h = 32, w = 110 },
          withShadow = true
        })

        canvas:insertElement({
          type = 'text',
          action = 'fill',
          frame = { x = 4, y = 6, h = 24, w = 102 },
          text = hs.styledtext.new("SPECIAL", {
            font = { size = 14 },
            color = { white = 1.0 },
            paragraphStyle = { alignment = 'center' }
          })
        })

        return canvas
      end

      function skhdmode.targetScreen()
        local win = hs.window.focusedWindow()
        if win then return win:screen() end
        return hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
      end

      function skhdmode.show()
        if not skhdmode.canvas then
          skhdmode.canvas = skhdmode.createIndicator()
        end
        local frame = skhdmode.targetScreen():frame()
        skhdmode.canvas:topLeft({
          x = frame.x + frame.w - 130,
          y = frame.y + frame.h - 50
        })
        skhdmode.canvas:level("overlay")
        skhdmode.canvas:show()
      end

      function skhdmode.hide()
        if skhdmode.canvas then
          skhdmode.canvas:hide()
        end
      end

      hs.urlevent.bind("skhd-special-on", skhdmode.show)
      hs.urlevent.bind("skhd-special-off", skhdmode.hide)
      hs.urlevent.bind("hs-reload", function() hs.reload() end)

      -- VIM MODE
      local VimMode = hs.loadSpoon('VimMode')
      local vim = VimMode:new()

      vim:shouldDimScreenInNormalMode(false)
      vim:disableForApp('zoom.us')
      vim:disableForApp('kitty')
      vim:disableForApp('.zathura-wrapped')
      vim:enterWithSequence('jk', 300)
      vim:shouldShowAlertInNormalMode(true)

      -- Spotlight support: re-enable vim mode when Spotlight opens
      vim.spotlightWatcher = hs.window.filter.new(function(win)
        if not win then return false end
        local app = win:application()
        return app and app:name() == "Spotlight"
      end)

      vim.spotlightWatcher:subscribe(hs.window.filter.windowCreated, function()
        if vim.enabled == false then
          vim.vimWasDisabledForApp = true
          vim:enable()
        end
      end)

      vim.spotlightWatcher:subscribe(hs.window.filter.windowDestroyed, function()
        if vim.vimWasDisabledForApp then
          vim.vimWasDisabledForApp = false
          vim:disable()
        end
      end)

      -- Password field guard
      vim.inPasswordField = false

      vim.passwordChecker = hs.timer.doEvery(0.3, function()
        local ax = require("hs.axuielement")
        local systemElement = ax.systemWideElement()
        if not systemElement then return end

        local currentElement = systemElement:attributeValue("AXFocusedUIElement")
        if not currentElement then
          if vim.inPasswordField then
            vim.inPasswordField = false
            vim:enable()
          end
          return
        end

        local role = currentElement:attributeValue("AXRole") or ""
        local isSecure = currentElement:attributeValue("AXSecure") or false

        if role == "AXSecureTextField" or isSecure then
          if not vim.inPasswordField then
            vim.inPasswordField = true
            vim:disable()
          end
        else
          if vim.inPasswordField then
            vim.inPasswordField = false
            vim:enable()
          end
        end
      end)

      -- Exit normal mode with 'q'
      vim.modal:bind({}, 'q', function()
        vim:exitAsync()
      end)

      -- Exit normal mode with 'Escape'
      vim.modal:bind({}, 'escape', function()
        vim:exitAsync()
      end)

      -- Custom glass-style indicator for Normal/Visual mode
      local originalRender = nil

      local function getStaticPosition()
        local win = hs.window.focusedWindow()
        if win then
          local frame = win:frame()
          return {
            x = math.floor(frame.x + (frame.w / 2) - 20),
            y = math.floor(frame.y + frame.h - 38)
          }
        end

        local screen = hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
        if screen then
          local frame = screen:fullFrame()
          return {
            x = math.floor(frame.x + (frame.w / 2) - 20),
            y = math.floor(frame.y + frame.h - 68)
          }
        end

        return { x = 500, y = 800 }
      end

      local function getCursorPosition()
        local ax = require("hs.axuielement")
        local systemElement = ax.systemWideElement()
        if not systemElement then return nil end

        local currentElement = systemElement:attributeValue("AXFocusedUIElement")
        if not currentElement then return nil end

        local role = currentElement:attributeValue("AXRole")

        local textRoles = {
          ["AXTextField"] = true,
          ["AXTextArea"] = true,
          ["AXComboBox"] = true,
          ["AXSearchField"] = true
        }

        if not textRoles[role] then return nil end

        local position = currentElement:attributeValue('AXPosition')
        if not position then return nil end
        if position.x < 0 or position.y < 0 then return nil end

        return {
          x = position.x + 3,
          y = position.y - 31
        }
      end

      local function customRender(self)
        local canvas = vim.stateIndicator.canvas
        if not canvas then
          if originalRender then return originalRender(self) end
          return false
        end

        if not vim.config.shouldShowAlertInNormalMode then
          canvas:hide()
          return false
        end

        local mode = vim.mode
        if mode ~= 'normal' and mode ~= 'visual' then
          canvas:hide()
          return false
        end

        local pos = getCursorPosition() or getStaticPosition()
        canvas:topLeft(pos)
        canvas:level("overlay")

        local fillColor = { red = 0.12, green = 0.12, blue = 0.12, alpha = 0.9 }
        local strokeColor = { white = 1.0, alpha = 0.4 }
        local textLabel = "N"

        if mode == 'visual' then
          fillColor = { red = 0.18, green = 0.12, blue = 0.08, alpha = 0.9 }
          strokeColor = { red = 0.82, green = 0.60, blue = 0.38, alpha = 0.6 }
          textLabel = "V"
        end

        canvas:elementAttribute(1, 'fillColor', fillColor)
        canvas:elementAttribute(1, 'strokeColor', strokeColor)
        canvas:elementAttribute(1, 'strokeWidth', 1.0)
        canvas:elementAttribute(1, 'roundedRectRadii', { xRadius = 8, yRadius = 8 })
        canvas:size({ w = 40, h = 28 })
        canvas:elementAttribute(2, 'text', hs.styledtext.new(textLabel, {
          font = { size = 16 },
          color = { white = 1.0 },
          paragraphStyle = { alignment = 'center' }
        }))
        canvas:show()
        return true
      end

      local function applyDarkCanvas(canvas)
        if not canvas then return end
        local mode = vim.mode
        local fillColor = { red = 0.12, green = 0.12, blue = 0.12, alpha = 0.9 }
        local strokeColor = { white = 1.0, alpha = 0.4 }
        if mode == 'visual' then
          fillColor = { red = 0.18, green = 0.12, blue = 0.08, alpha = 0.9 }
          strokeColor = { red = 0.82, green = 0.60, blue = 0.38, alpha = 0.6 }
        end
        canvas:elementAttribute(1, 'fillColor', fillColor)
        canvas:elementAttribute(1, 'strokeColor', strokeColor)
        canvas:elementAttribute(1, 'strokeWidth', 1.0)
        canvas:elementAttribute(1, 'roundedRectRadii', { xRadius = 8, yRadius = 8 })
      end

      local originalUpdate = nil

      local function customUpdate(self)
        local shouldShow = customRender(self)
        if shouldShow then
          if not self.showing then
            applyDarkCanvas(self.canvas)
            self.canvas:show()
            self.canvas:level("overlay")
            self.showing = true
          end
        else
          if self.showing then
            self.canvas:hide()
            self.showing = false
          end
        end
        return self
      end

      local hookAttempts = 0
      hs.timer.doEvery(0.5, function()
        hookAttempts = hookAttempts + 1

        if not vim.stateIndicator then
          if hookAttempts > 20 then
            print("ERROR: vim.stateIndicator never created after 10 seconds")
            return false
          end
          return
        end

        applyDarkCanvas(vim.stateIndicator.canvas)

        if vim.stateIndicator.render ~= customRender then
          originalRender = vim.stateIndicator.render
          vim.stateIndicator.render = customRender
        end

        if vim.stateIndicator.update ~= customUpdate then
          originalUpdate = vim.stateIndicator.update
          vim.stateIndicator.update = customUpdate
        end

        return false
      end)
    '';

  home.file.".hammerspoon/Spoons/VimMode.spoon".source = pkgs.fetchgit {
    url = "https://github.com/dbalatero/VimMode.spoon.git";
    rev = "a428e1ae9cc5d937fa6d148da6e2a779c7594abd";
    sha256 = "1xpjkbcz2qq0ga3d7pjzhvqjf376fj66aasy1pp4q5s3qnj8718b";
  };
}
