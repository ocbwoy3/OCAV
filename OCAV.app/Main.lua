
-- Import libraries
local GUI = require("GUI")
local system = require("System")
local fs = require("Filesystem")
local inet = require("internet")

local function download(file,where)
	inet.download("https://raw.githubusercontent.com/ocboy3/OCAV/main" .. tostring(file),where)
end

local function downloadbeta(file,where)
	inet.download("https://raw.githubusercontent.com/ocboy3/OCAV/dev" .. tostring(file),where)
end



---------------------------------------------------------------------------------

-- Add a new window to MineOS workspace
local workspace, window, menu = system.addWindow(GUI.filledWindow(1, 1, 60, 20, 0xE1E1E1))

-- Get localization table dependent of current system language
--local localization = system.getCurrentScriptLocalization()

-- Add single cell layout to window
local layout = window:addChild(GUI.layout(1, 1, window.width, window.height, 1, 1))

-- Add nice gray text object to layout
layout:addChild(GUI.text(1, 1, 0x4B4B4B, "Welcome, " .. system.getUser()))
layout:addChild(GUI.text(1, 1, 0x4B4B4B, "Click the button below to install OCAV."))

layout:addChild(GUI.roundedButton(2, 18, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, "Install")).onTouch = function()
	fs.makeDirectory("/.OCAV/")
	fs.makeDirectory("/.OCAV/Libraries/")
	download("/OS.lua","/OS.lua")
	download("/Antivirus.lua","/.OCAV/Libraries/Antivirus.lua")
	GUI.alert("Sucessfully installed OCAV.\nA full system reboot is required in order to start the anti-virus.")
end

layout:addChild(GUI.roundedButton(2, 18, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, "Install developer beta")).onTouch = function()
	downloadbeta("/dev_installer.lua","/OCAV_DEV.lua")
	system.execute("/OCAV_DEV.lua")
	fs.remove("/OCAV_DEV.lua")
end


-- Create callback function with resizing rules when window changes its' size
window.onResize = function(newWidth, newHeight)
  window.backgroundPanel.width, window.backgroundPanel.height = newWidth, newHeight
  layout.width, layout.height = newWidth, newHeight
end

---------------------------------------------------------------------------------

-- Draw changes on screen after customizing your window
workspace:draw()
