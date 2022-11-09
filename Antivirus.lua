local av = {}

-- Neļaut OCAV ielādēties vēlreiz
if computer["\xFFOCAV_LOADED\xFF"] and computer["\xFFOCAV_LOADED\xFF"] == true then return {load = function() return false end} end

av.load = function(consent,fs,efi,inet)
	-- Experimental consent
	_G.consent = consent
	
	local fsf = {} for a,b in pairs(fs) do fsf[a] = b end
  	local eff = {} for a,b in pairs(efi) do eff[a] = b end
	inet = nil --if inet ~= nil then local inf = {} for a,b in pairs(inet) do inf[a] = b end end

	local ocav_getver = function() return "1" end

	local oldpull = computer.pullEvent
	local oldpush = computer.pushEvent

	local x = function()

	local newpull = function(...)
		local a, b = pcall(function()
			x()
			if _G.OCAV_GetVersion ~= ocav_getver then computer.pushEvent("ocav","functionOverwrite","getVersion") _G.OCAV_GetVersion = ocav_getver end
			return oldpull(...)
		end)
		if a ~= nil then return b else return {"ocav", "error", b} end
	end

	x = function()
		if computer.pullEvent ~= newpull then computer.pushEvent("ocav","functionOverwrite","pullEvent") computer.pullEvent = newpull end
		if computer.pushEvent ~= oldpush then computer.pushEvent("ocav","functionOverwrite","pushEvent") computer.pullEvent = oldpush end
	end	

	computer["\xFFOCAV_LOADED\xFF"] = true

	-- The system file protection is broken
	-- Procastinating too much lol, Send pull requests or issues or something
	
	-- Noņem OCAV no package.loaded
	package.loaded["antivirus"] = nil
	
	local systemFiles = {
		"/.OCAV";
		"/OS.lua";
		"/Libraries";
		"/Users";
		"/MineOS";
		"/Icons";
		"/Extensions";
		"/Localizations";
		"/Mounts/" .. tostring(fsf.address);
	}
	local exclusions = {
		"/Applications";
		"/Versions.cfg";
	}

	local methodMap = {
		{"CreateDirectory", "OCAV detected an attempt create directory '%s'. Allow?"};
		{"open_w", "OCAV detected that file '%s' is open for writing. Allow?"};
		{"remove", "OCAV detected that file '%s' is being deleted. Allow?"};
		{"rename", "OCAV detected that file '%s' is renamed to '%s'. Allow?"};
		{"eeprom_set","OCAV detected that the EEPROM code is changed. Allow?"};
		{"eeprom_makereadonly", "OCAV detected that EEPROM is being made readonly. Allow?"};
	}

	-- Funkcija, kas pārbauda, vai drīkst darīt šo un to
	local function checkIfAllowed(what,method,other)
		-- Pārbaudīt, vai fails ir systemFiles bet ne no exclusions
		local allowed = true
		for _, v in pairs(systemFiles) do
			-- Pārbaudīt, vai v sākas ar what
			if string.sub(v,1,string.len(what)) == what then
				-- Pārbaudīt, vai v nav no exclusions
				for _, v in pairs(exclusions) do
					if string.sub(v,1,string.len(what)) == what then
						allowed = false
					end
				end
			end
		end
		if what == "" or what == "/" then allowed = false end
		-- Jautāt lietotājam priekš atļaujas
		if not allowed then
			local question = string.format(methodMap[method][2], what, other)
			if not consent(question) then
				return false
			end
		end
		return true
	end


	-- Aizsargāt datoru no OCHammer 2 un citu vīrusu lejupielādes

	local blockedRootURLs = {
		{"https://raw.githubusercontent.com/ocboy3/OC/main/OCHammer.app","OCHammer"};
		{"https://raw.githubusercontent.com/ocboy3/OC/main/OCHammer2.app","OCHammer 2"};
		{"https://raw.githubusercontent.com/KKosty4ka/Solaris", "Solaris virus"};
		{"https://raw.githubusercontent.com/KKosty4ka/ScamDisk", "ScamDisk"};
		{"https://raw.githubusercontent.com/Jack5079/opencomputers/master/SysFucked%20Slient.app", "SysFucked Silent"};
		{"https://raw.githubusercontent.com/Jack5079/opencomputers/master/SysFucked.app", "SysFucked"};
	}

	local fakeTCPObject = {
		read = function(n)
			return "Blocked by OCAV"
		end;
		close = function()
			return
		end;
		write = function(s)
			return
		end;
		finishConnect = function()
			error("Blocked by OCAV")
		end;
		id = function()
			return -1
		end;
	}

	local fakeHTTPObject = {
		read = function(n)
			return "Blocked by OCAV"
		end;
		close = function()
			return
		end;
		response = function()
			return 404
		end;
		finishConnect = function()
			error("Blocked by OCAV")
		end;
	}

	local lastVirusDownloadTime = -9999
	local virusDownloadTime = 5

	if inet ~= nil then
		
		local function isDownloadAllowed()
			-- atgriezt true, ja starpība lastVirusDownloadTime un os.time() ir mazāka vai vienāda par 5 sekundēm
			return (os.time() - lastVirusDownloadTime) >= virusDownloadTime
		end

		inet.connect = function(adress, port)
			-- pārbaudīt, vai adress nav bloķēts/a
			local blocked = false
			local virus = ""
			for i,v in pairs(blockedRootURLs) do
				if string.sub(adress,1,#v[1]) == v[1] then
					virus = v[2]
					blocked = true
					break
				end
			end
			-- ja adress ir bloķēta, tad jautāt lietotājam, vai atļaut lejupielādi
			if blocked == true then
				if isDownloadAllowed() == true then
					-- atļaut lejupielādi
					return inf.connect(adress, port)
				else
					-- jautāt lietotājam, vai atļaut lejupielādi
					local allowed = consent("Programma mēģina lejupielādēt "..virus..". Vai atļaut?")
					if allowed == true then
						-- atļaut lejupielādi
						lastVirusDownloadTime = os.time()
						return inf.connect(adress, port)
					else
						-- neatļaut lejupielādi
						error("Blocked by OCAV")
					end
				end
			else
				-- adress nav bloķēta
				return inf.connect(adress, port)
			end
		end

		inet.request = function(url, postdata, headers)
			-- pārbaudīt, vai url nav bloķēta/a
			local blocked = false
			local virus = ""
			for i,v in pairs(blockedRootURLs) do
				if string.sub(url,1,#v[1]) == v[1] then
					virus = v[2]
					blocked = true
					break
				end
			end
			-- ja url ir bloķēta, tad jautāt lietotājam, vai atļaut lejupielādi
			if blocked == true then
				if isDownloadAllowed() == true then
					-- atļaut lejupielādi
					return inf.request(url, postdata, headers)
				else
					-- jautāt lietotājam, vai atļaut lejupielādi
					local allowed = consent("Program tried to download "..virus..". Allow?")
					if allowed == true then
						-- atļaut lejupielādi
						lastVirusDownloadTime = os.time()
						return inf.request(url, postdata, headers)
					else
						-- neatļaut lejupielādi
						error("Blocked by OCAV")
					end
				end
			else
				-- adress nav bloķēta
				return inf.request(url, postdata, headers)
			end
		end

	end

	return true
end

return av
