
-- Import libraries
local GUI = require("GUI")
local system = require("System")

---------------------------------------------------------------------------------

-- Add a new window to MineOS workspace
local workspace, window, menu = system.addWindow(GUI.filledWindow(1, 1, 60, 20, 0xE1E1E1))

-- Get localization table dependent of current system language
local localization = system.getCurrentScriptLocalization()

-- Add single cell layout to window
local layout = window:addChild(GUI.layout(1, 1, window.width, window.height, 1, 1))

-- Add nice gray text object to layout
layout:addChild(GUI.text(1, 1, 0x4B4B4B, "Sveiki, " .. system.getUser()))

-- Customize MineOS menu for this application by your will
local contextMenu = menu:addContextMenuItem("File")
contextMenu:addItem("Close").onTouch = function()
	window:remove()
end

-- Create callback function with resizing rules when window changes its' size
window.onResize = function(newWidth, newHeight)
  window.backgroundPanel.width, window.backgroundPanel.height = newWidth, newHeight
  layout.width, layout.height = newWidth, newHeight
end

---------------------------------------------------------------------------------

-- Draw changes on screen after customizing your window
workspace:draw()
