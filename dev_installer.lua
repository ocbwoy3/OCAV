local sys = require("System")
local fs = require("Filesystem")
local inet = require("Internet")
local GUI = require("GUI")
local function dl(path,file)
  inet.download("https://raw.githubusercontent.com/ocboy3/OCAV/dev" .. tostring(path),file)
end

fs.makeDirectory("/.OCAV/")
fs.makeDirectory("/.OCAV/Libraries/")
dl("/OS.lua","/OS.lua")
dl("/Antivirus.lua","/.OCAV/Libraries/Antivirus.lua")
GUI.alert("Sucessfully installed OCAV developer beta.\nA full system reboot is required in order to start the anti-virus.")
