require "preload"
local modal = require "modal"
require "preview-app"

hs.hints.style = "vimperator"
hs.hints.showTitleThresh = 4
hs.hints.titleMaxSize = 10
hs.hints.fontSize = 30

hs.hints.hintChars = {"S","A","D","F","J","K","L","E","W","C","M","P","G","H"}

local filterAllowedApps = function(w)
  if (not w:isStandard()) and (not utils.contains(allowedApps, w:application():name())) then
    return false;
  end
  return true;
end

modals = {
  main = {
    init = function(self, fsm) 
      if self.modal then
        self.modal:enter()
      else
        self.modal = hs.hotkey.modal.new({"cmd"}, "space")
      end
      self.modal:bind("","space", nil, function() fsm:toIdle(); windows.activateApp("Alfred 3") end)
      self.modal:bind("","w", nil, function() fsm:toWindows() end)
      self.modal:bind("","a", nil, function() fsm:toApps() end)
      self.modal:bind("","j", nil, function()
                        local wns = hs.fnutils.filter(hs.window.allWindows(), filterAllowedApps)
                        hs.hints.windowHints(wns, nil, true)
                        fsm:toIdle()
      end)
      self.modal:bind("","escape", function() fsm:toIdle() end)
      function self.modal:entered() displayModalText "w - windows\na - apps\n j - jump" end
    end 
  },
  windows = {
    init = function(self, fsm)
      self.modal = hs.hotkey.modal.new()
      displayModalText "cmd + hjkl \t jumping\nhjkl \t\t\t\t halves\nalt + hjkl \t\t increments\nshift + hjkl \t resize\nn, p \t next, prev screen\ng \t\t\t\t\t grid\nm \t\t\t\t maximize\nu \t\t\t\t\t undo"
      self.modal:bind("","escape", function() fsm:toIdle() end)
      self.modal:bind({"cmd"}, "space", nil, function() fsm:toMain() end)
      windows.bind(self.modal, fsm)
      self.modal:enter()
    end
  },
  apps = {
    init = function(self, fsm)
      self.modal = hs.hotkey.modal.new()
      displayModalText "e \t emacs\nc \t chrome\na \t Android Studio\nb \t brave\nf \t Finder"
      self.modal:bind("","escape", function() fsm:toIdle() end)
      self.modal:bind({"cmd"}, "space", nil, function() fsm:toMain() end)
      hs.fnutils.each({
          { key = "t", app = "iTerm" },
          { key = "c", app = "Google Chrome" },
          { key = "b", app = "Brave" },
          { key = "a", app = "Android Studio" },
          { key = "f", app = "Finder" },
          { key = "e", app = "Emacs" },
          { key = "g", app = "Gitter" }}, function(item)

          self.modal:bind("", item.key, function() windows.activateApp(item.app); fsm:toIdle()  end)
      end)

      slack.bind(self.modal, fsm)

      self.modal:enter()
    end
  }
}

local initModal = function(state, fsm)
  local m = modals[state]
  m.init(m, fsm)
end

exitAllModals = function()
  utils.each(modals, function(m)
               if m.modal then
                 m.modal:exit()
               end
  end)
end

require("windows").addState(modal)
require("apps").addState(modal)
require("multimedia").addState(modal)
require("emacs").addState(modal)

local stateMachine = modal.createMachine()
stateMachine:toMain()

hs.alert.show("Config Loaded")
