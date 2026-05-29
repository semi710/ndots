{ pkgs, ... }:
{
  home.packages = with pkgs; [ hammerspoon ];

  home.file.".hammerspoon/init.lua".text = # lua
    ''
      hs.allowAppleScript(true)
      hs.console.darkMode(true)

      -- ============================================
      -- HAMMERSPOON MODE (Ctrl+Option+Shift+H)
      -- ============================================
      local hsmode = {}
      hsmode.active = false
      hsmode.canvas = nil
      hsmode.timers = {}

      function hsmode.keyboardBrightness(direction)
        local event = require("hs.eventtap").event
        local key = (direction == "up") and "ILLUMINATION_UP" or "ILLUMINATION_DOWN"
        event.newSystemKeyEvent(key, true):post()
        hs.timer.usleep(10000)
        event.newSystemKeyEvent(key, false):post()
      end

      function hsmode.startBrightnessRepeat(direction)
        hsmode.stopBrightnessRepeat()
        hsmode.keyboardBrightness(direction)
        hsmode.timers[direction] = hs.timer.doEvery(0.1, function()
          hsmode.keyboardBrightness(direction)
        end)
      end

      function hsmode.stopBrightnessRepeat()
        for _, timer in pairs(hsmode.timers) do
          if timer then timer:stop() end
        end
        hsmode.timers = {}
      end

      function hsmode.createIndicator()
        local canvas = hs.canvas.new { w = 40, h = 28, x = 100, y = 100 }

        canvas:insertElement({
          type = 'rectangle',
          action = 'fill',
          roundedRectRadii = { xRadius = 8, yRadius = 8 },
          fillColor = { red = 0.2, green = 0.2, blue = 0.2, alpha = 0.85 },
          strokeColor = { white = 1.0, alpha = 0.4 },
          strokeWidth = 1.0,
          frame = { x = 0, y = 0, h = 28, w = 40 },
          withShadow = true
        })

        canvas:insertElement({
          type = 'text',
          action = 'fill',
          frame = { x = 4, y = 4, h = 20, w = 32 },
          text = hs.styledtext.new("🔨", {
            font = { size = 16 },
            color = { white = 1.0 },
            paragraphStyle = { alignment = 'center' }
          })
        })

        return canvas
      end

      function hsmode.showIndicator()
        if not hsmode.canvas then
          hsmode.canvas = hsmode.createIndicator()
        end

        local screen = hs.screen.mainScreen()
        local frame = screen:frame()
        hsmode.canvas:topLeft({
          x = frame.x + (frame.w / 2) - 20,
          y = frame.y + frame.h - 40
        })
        hsmode.canvas:level("overlay")
        hsmode.canvas:show()
      end

      function hsmode.hideIndicator()
        if hsmode.canvas then
          hsmode.canvas:hide()
        end
      end

      hsmode.bindings = {}

      function hsmode.enter()
        hsmode.active = true
        hsmode.showIndicator()

        hsmode.bindings['comma'] = hs.hotkey.bind({ "shift" }, 43, function()
          hsmode.startBrightnessRepeat("down")
        end, function()
          hsmode.stopBrightnessRepeat()
        end)

        hsmode.bindings['period'] = hs.hotkey.bind({ "shift" }, 47, function()
          hsmode.startBrightnessRepeat("up")
        end, function()
          hsmode.stopBrightnessRepeat()
        end)

        hsmode.bindings['r'] = hs.hotkey.bind({}, "r", function()
          hs.reload()
          hsmode.exit()
        end)

        hsmode.bindings['q'] = hs.hotkey.bind({}, "q", function()
          hsmode.exit()
        end)

        hsmode.bindings['escape'] = hs.hotkey.bind({}, "escape", function()
          hsmode.exit()
        end)

        hs.alert.show("Hammerspoon Mode", 0.5)
      end

      function hsmode.exit()
        hsmode.active = false
        hsmode.hideIndicator()

        for _, binding in pairs(hsmode.bindings) do
          binding:delete()
        end
        hsmode.bindings = {}
      end

      hs.hotkey.bind({ "ctrl", "option", "shift" }, "H", function()
        if not hsmode.active then
          hsmode.enter()
        end
      end)

      -- ============================================
      -- SKHD Special Mode Indicator
      -- ============================================
      local skhdmode = {}
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

      -- ============================================
      -- VIM MODE
      -- ============================================
      local VimMode = hs.loadSpoon('VimMode')
      local vim = VimMode:new()

      vim:shouldDimScreenInNormalMode(false)
      vim:disableForApp('Code')
      vim:disableForApp('MacVim')
      vim:disableForApp('zoom.us')
      vim:disableForApp('kitty')
      vim:disableForApp('Maccy')
      vim:disableForApp('Homerow')
      vim:enterWithSequence('jk')
      vim:shouldShowAlertInNormalMode(true)

      -- ============================================
      -- Homerow scroll conflict guard
      -- ============================================
      -- Homerow sends real j/k key events when scrolling, which triggers
      -- the jk enter sequence. We patch the key sequence event handler
      -- to skip detection when Homerow's scroll overlay is visible.
      vim.homerowScrollActive = false

      vim.homerowWatcher = hs.window.filter.new(function(win)
        if not win then return false end
        local app = win:application()
        return app and app:name() == "Homerow"
      end)

      vim.homerowWatcher:subscribe(hs.window.filter.windowCreated, function()
        vim.homerowScrollActive = true
        if vim.sequence and vim.sequence.enabled then
          vim.sequence:disable()
        end
      end)

      vim.homerowWatcher:subscribe(hs.window.filter.windowDestroyed, function()
        vim.homerowScrollActive = false
        if vim.sequence and vim.enabled then
          vim.sequence:enable()
        end
      end)

      -- ============================================
      -- Password field guard
      -- ============================================
      -- Disable vim mode when a password field is focused to avoid
      -- swallowing keystrokes meant for authentication.
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

      -- ============================================
      -- Firenvim guard
      -- ============================================
      -- Disable vim mode when a Firenvim iframe is focused inside the browser,
      -- so Hammerspoon doesn't swallow keystrokes meant for the embedded Neovim.
      -- Detection: Firenvim creates an AXWebArea with moz-extension:// in its
      -- AXDescription, which does not appear in normal web content iframes.
      vim.inFirenvim = false

      vim.firenvimChecker = hs.timer.doEvery(0.3, function()
        local ax = require("hs.axuielement")
        local systemElement = ax.systemWideElement()
        if not systemElement then return end

        local currentElement = systemElement:attributeValue("AXFocusedUIElement")
        if not currentElement then
          if vim.inFirenvim then
            vim.inFirenvim = false
            vim:enable()
          end
          return
        end

        -- Walk up the AX tree looking for a moz-extension:// AXWebArea (Firenvim iframe)
        local el = currentElement
        local isFirenvim = false
        for _ = 1, 10 do
          if not el then break end
          local role = el:attributeValue("AXRole") or ""
          local desc = el:attributeValue("AXDescription") or ""
          if role == "AXWebArea" and desc:find("moz%-extension://") then
            isFirenvim = true
            break
          end
          el = el:attributeValue("AXParent")
        end

        if isFirenvim then
          if not vim.inFirenvim then
            vim.inFirenvim = true
            vim:disable()
          end
        else
          if vim.inFirenvim then
            vim.inFirenvim = false
            vim:enable()
          end
        end
      end)

      -- ============================================
      -- Spotlight support for vim mode
      -- ============================================
      vim.spotlightWatcher = hs.window.filter.new(function(win)
        if not win then return false end
        local app = win:application()
        return app and app:name() == "Spotlight"
      end)

      vim.spotlightWatcher:subscribe(hs.window.filter.windowCreated, function()
        -- Spotlight opened - enable vim mode temporarily
        if vim.enabled == false then
          vim.vimWasDisabledForApp = true
          vim:enable()
        end
      end)

      vim.spotlightWatcher:subscribe(hs.window.filter.windowDestroyed, function()
        -- Spotlight closed - restore previous vim state
        if vim.vimWasDisabledForApp then
          vim.vimWasDisabledForApp = false
          vim:disable()
        end
      end)

      -- ============================================
      -- Emoji Picker support for vim mode
      -- ============================================
      -- Detect emoji picker by monitoring all visible windows
      vim.emojiEnabled = false
      vim.emojiWasDisabled = false

      vim.emojiChecker = hs.timer.doEvery(0.2, function()
        local isEmojiVisible = false
        local ax = require("hs.axuielement")

        -- Check if any window looks like emoji picker
        for _, win in ipairs(hs.window.allWindows()) do
          local app = win:application()
          local appName = app and app:name() or ""
          local title = win:title() or ""
          local role = win:role() or ""
          local subrole = win:subrole() or ""

          -- Print debug info for floating/panel windows
          if subrole:lower():match("panel") or subrole:lower():match("floating") or subrole:lower():match("system") then
            print("WINDOW CHECK - App: '" .. appName .. "', Title: '" .. title .. "', Subrole: '" .. subrole .. "'")
          end

          -- Detect emoji picker: owned by "Emoji & Symbols" or "Dock" with system dialog characteristics
          if (appName == "Emoji & Symbols") or
             (appName == "Dock" and (subrole:lower():match("floating") or subrole:lower():match("panel"))) or
             (subrole:lower():match("systemdialog")) then
            isEmojiVisible = true
            print("EMOJI WINDOW FOUND - App: '" .. appName .. "', Title: '" .. title .. "', Subrole: '" .. subrole .. "'")
            break
          end

          -- Alternative: Check focused element for emoji picker characteristics
          local systemElement = ax.systemWideElement()
          if systemElement then
            local currentElement = systemElement:attributeValue("AXFocusedUIElement")
            if currentElement then
              local elSubrole = currentElement:attributeValue("AXSubrole") or ""
              if elSubrole:lower():match("popover") then
                isEmojiVisible = true
                print("EMOJI POPOVER FOUND in focused element")
                break
              end
            end
          end
        end

        -- Handle state transitions
        if isEmojiVisible and not vim.emojiEnabled then
          if vim.enabled == false then
            vim.emojiWasDisabled = true
            vim:enable()
            vim.emojiEnabled = true
            print(">>> Vim mode ENABLED for emoji picker")
          end
        elseif not isEmojiVisible and vim.emojiEnabled then
          if vim.emojiWasDisabled then
            vim:disable()
            vim.emojiWasDisabled = false
            print(">>> Vim mode restored after emoji picker")
          end
          vim.emojiEnabled = false
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
      -- Hook into the first render call to apply custom styling
      local originalRender = nil

      -- Function to get static position at bottom center of focused window
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

      -- Function to get position near cursor if in text field
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

      -- Custom render function
      local function customRender(self)
        local canvas = vim.stateIndicator.canvas
        if not canvas then
          -- Canvas not ready yet, call original
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

        -- Choose position
        local pos = getCursorPosition() or getStaticPosition()
        canvas:topLeft(pos)
        canvas:level("overlay")

        -- Glass styling — subtle tint per mode
        local fillColor = {
          red = 0.12, green = 0.12, blue = 0.12, alpha = 0.9
        }
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

      -- Override the canvas fill color immediately so blue never flashes
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

      -- Hook both render AND update to ensure styling always wins
      local originalUpdate = nil

      local function customUpdate(self)
        -- Call render first to set text/visibility
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

      -- Watch for stateIndicator and hook both render and update
      local hookAttempts = 0
      hs.timer.doEvery(0.5, function()
        hookAttempts = hookAttempts + 1

        -- Check if stateIndicator exists
        if not vim.stateIndicator then
          if hookAttempts > 20 then
            print("ERROR: vim.stateIndicator never created after 10 seconds")
            return false
          end
          return -- continue polling
        end

        -- Apply dark styling immediately on the canvas
        applyDarkCanvas(vim.stateIndicator.canvas)

        -- Hook render
        if vim.stateIndicator.render ~= customRender then
          originalRender = vim.stateIndicator.render
          vim.stateIndicator.render = customRender
          print("Custom UI render hooked (attempt " .. hookAttempts .. ")")
        end

        -- Hook update to fully control show/hide + styling
        if vim.stateIndicator.update ~= customUpdate then
          originalUpdate = vim.stateIndicator.update
          vim.stateIndicator.update = customUpdate
          print("Custom UI update hooked (attempt " .. hookAttempts .. ")")
        end

        return false -- stop the timer
      end)
    '';

  home.file.".hammerspoon/Spoons/VimMode.spoon".source = pkgs.fetchgit {
    url = "https://github.com/dbalatero/VimMode.spoon.git";
    rev = "a428e1ae9cc5d937fa6d148da6e2a779c7594abd";
    sha256 = "1xpjkbcz2qq0ga3d7pjzhvqjf376fj66aasy1pp4q5s3qnj8718b";
  };
}
