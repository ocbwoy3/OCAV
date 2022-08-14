
------------------------------------------------------------------------------- OCAV antivīruss --------------------------------------------------------------------------------

-- Dabūt video karti un displeja izmēru
local GPU = component.proxy(component.list("gpu")())
local resX,resY = GPU.getResolution()
local res = {resX,resY}

-- Definēt funkciju, kas jautā lietotājam. Atbilžu varianti: Ļaut, Neļaut
-- Jautājums rādās uz ekrāna, lietotājam jāuzklikšķina uz atbiles, atgriežot true vai false
local function consent(question)
  -- Saglabāt fonta krāsu un fona krāsu
  local fontColor,backColor = GPU.getForeground(),GPU.getBackground()
  -- Izvēlēties fontu un fonu
  -- Teksta krāsa - Balta
  -- Fona krāsa - Sarkana
  GPU.setForeground(0xFFFFFF)
  GPU.setBackground(0xFF0000)
  -- Saglabāt pirmo līniju tabulā
  local line1 = {}
  -- funkcija GPU.get(x,y) atgriež tekstu, teksta krāsu un fona krāsu
  for i=1,resX do
    line1[i] = {GPU.get(i,1)}
  end
  -- Fons
  GPU.fill(1,1,resX,1," ")
  -- Teksts
  GPU.set(1,1,question)
  -- Atbilžu varianti  
  local variants = {"Y","N"}
  GPU.set(resX-1,1,variants[2])
  GPU.set(resX-3,1,variants[1])
  -- Gaidīt signālu "touch" izmantojot computer.pullSignal(timeout), jo zems līmenis, nav os implementēts.
  -- Signāla nosaukums, komponenta adrese, x,y koordinātes, peles poga, spēlētāja IGN
  local choice = nil
  repeat
    local pulled = {computer.pullSignal(0.1)}
    if pulled[1] == "touch" then
      if pulled[4] == 1 then
        -- Pārbaudīt vai x ir atbilstoša atbilžu varianta pozīcija no positions_true un positions_false
        if pulled[3] == resX-1 then choice = false end
        if pulled[3] == resX-3 then choice = true end
      end
    end
  until choice == true or choice == false

  -- Atgriezt 1. līniju uz ekrāna
  for i=1,resX do
    -- krāsa
    GPU.setBackground(line1[i][3])
    GPU.setForeground(line1[i][2])
    -- teksts
    GPU.set(i,1,line1[i][1])
  end

  -- Atgriezt fonta un fona krāsu
  GPU.setForeground(fontColor)
  GPU.setBackground(backColor)

  -- Atgriezt atbilstošo vērtību
  return choice
end

---------------------------------------- System initialization ----------------------------------------

-- Obtaining boot filesystem component proxy
local bootFilesystemProxy = component.proxy(component.proxy(component.list("eeprom")()).getData())

-- Executes file from boot HDD during OS initialization (will be overriden in filesystem library later)
function dofile(path)
	local stream, reason = bootFilesystemProxy.open(path, "r")
	
	if stream then
		local data, chunk = ""
		
		while true do
			chunk = bootFilesystemProxy.read(stream, math.huge)
			
			if chunk then
				data = data .. chunk
			else
				break
			end
		end

		bootFilesystemProxy.close(stream)

		local result, reason = load(data, "=" .. path)
		
		if result then
			return result()
		else
			error(reason)
		end
	else
		error(reason)
	end
end

-- Initializing global package system
package = {
	paths = {
		["/Libraries/"] = true
	},
	loaded = {},
	loading = {}
}

-- Checks existense of specified path. It will be overriden after filesystem library initialization
local requireExists = bootFilesystemProxy.exists

-- Works the similar way as native Lua require() function
function require(module)
	-- For non-case-sensitive filesystems
	local lowerModule = unicode.lower(module)

	if package.loaded[lowerModule] then
		return package.loaded[lowerModule]
	elseif package.loading[lowerModule] then
		error("recursive require() call found: library \"" .. module .. "\" is trying to require another library that requires it\n" .. debug.traceback())
	else
		local errors = {}

		local function checkVariant(variant)
			if requireExists(variant) then
				return variant
			else
				table.insert(errors, "  variant \"" .. variant .. "\" not exists")
			end
		end

		local function checkVariants(path, module)
			return
				checkVariant(path .. module .. ".lua") or
				checkVariant(path .. module) or
				checkVariant(module)
		end

		local modulePath
		for path in pairs(package.paths) do
			modulePath =
				checkVariants(path, module) or
				checkVariants(path, unicode.upper(unicode.sub(module, 1, 1)) .. unicode.sub(module, 2, -1))
			
			if modulePath then
				package.loading[lowerModule] = true
				local result = dofile(modulePath)
				package.loaded[lowerModule] = result or true
				package.loading[lowerModule] = nil
				
				return result
			end
		end

		error("unable to locate library \"" .. module .. "\":\n" .. table.concat(errors, "\n"))
	end
end

local GPUAddress = component.list("gpu")()
local screenWidth, screenHeight = component.invoke(GPUAddress, "getResolution")

-- Displays title and currently required library when booting OS
local UIRequireTotal, UIRequireCounter = 14, 1

local function UIRequire(module)
	local function centrize(width)
		return math.floor(screenWidth / 2 - width / 2)
	end
	
	local title, width, total = "MineOS", 26, 14
	local x, y, part = centrize(width), math.floor(screenHeight / 2 - 1), math.ceil(width * UIRequireCounter / UIRequireTotal)
	UIRequireCounter = UIRequireCounter + 1
	
	-- Title
	component.invoke(GPUAddress, "setForeground", 0x2D2D2D)
	component.invoke(GPUAddress, "set", centrize(#title), y, title)

	-- Progressbar
	component.invoke(GPUAddress, "setForeground", 0x878787)
	component.invoke(GPUAddress, "set", x, y + 2, string.rep("─", part))

	component.invoke(GPUAddress, "setForeground", 0xC3C3C3)
	component.invoke(GPUAddress, "set", x + part, y + 2, string.rep("─", width - part))

	return require(module)
end

-- Preparing screen for loading libraries
component.invoke(GPUAddress, "setBackground", 0xE1E1E1)
component.invoke(GPUAddress, "fill", 1, 1, screenWidth, screenHeight, " ")

-- Loading libraries
bit32 = bit32 or UIRequire("Bit32")
-- consent("OCAV is still in development - Report bugs and issues on GitHub repository: ocboy3/OCAV")
local paths = UIRequire("Paths")
local event = UIRequire("Event")
local filesystem = UIRequire("Filesystem")

-- Setting main filesystem proxy to what are we booting from
filesystem.setProxy(bootFilesystemProxy)

-- Replacing requireExists function after filesystem library initialization
requireExists = filesystem.exists

-- Loading other libraries
UIRequire("Component")
UIRequire("Keyboard")
UIRequire("Color")
UIRequire("Text")
UIRequire("Number")
local image = UIRequire("Image")
local screen = UIRequire("Screen")

-- Setting currently chosen GPU component as screen buffer main one
local success,reason = pcall(function()
	screen.setGPUAddress(GPUAddress)
end)
if not success then error("Setting GPU proxy failed, are you using an old version of the Screen library?") end

local GUI = UIRequire("GUI")
local system = UIRequire("System")
UIRequire("Network")

-- Filling package.loaded with default global variables for OpenOS bitches
package.loaded.bit32 = bit32
package.loaded.computer = computer
package.loaded.component = component
package.loaded.unicode = unicode

---------------------------------------- Main loop ----------------------------------------

-- Creating OS workspace, which contains every window/menu/etc.
local workspace = GUI.workspace()
system.setWorkspace(workspace)

-- "double_touch" event handler
local doubleTouchInterval, doubleTouchX, doubleTouchY, doubleTouchButton, doubleTouchUptime, doubleTouchcomponentAddress = 0.3
event.addHandler(
	function(signalType, componentAddress, x, y, button, user)
		if signalType == "touch" then
			local uptime = computer.uptime()
			
			if doubleTouchX == x and doubleTouchY == y and doubleTouchButton == button and doubleTouchcomponentAddress == componentAddress and uptime - doubleTouchUptime <= doubleTouchInterval then
				computer.pushSignal("double_touch", componentAddress, x, y, button, user)
				event.skip("touch")
			end

			doubleTouchX, doubleTouchY, doubleTouchButton, doubleTouchUptime, doubleTouchcomponentAddress = x, y, button, uptime, componentAddress
		end
	end
)

-- Screen component attaching/detaching event handler
event.addHandler(
	function(signalType, componentAddress, componentType)
		if (signalType == "component_added" or signalType == "component_removed") and componentType == "screen" then
			local GPUAddress = screen.getGPUAddress()

			local function bindScreen(address)
				screen.setScreenAddress(address, false)
				screen.setColorDepth(screen.getMaxColorDepth())

				workspace:draw()
			end

			if signalType == "component_added" then
				if not component.invoke(GPUAddress, "getScreen") then
					bindScreen(componentAddress)
				end
			else
				if not component.invoke(GPUAddress, "getScreen") then
					local address = component.list("screen")()
					
					if address then
						bindScreen(address)
					end
				end
			end
		end
	end
)

-- Logging in
system.authorize()

-- Main loop with UI regeneration after errors 
while true do
	local success, path, line, traceback = system.call(workspace.start, workspace, 0)
	
	if success then
		break
	else
		system.updateWorkspace()
		system.updateDesktop()
		workspace:draw()
		
		system.error(path, line, traceback)
		workspace:draw()
	end
end
