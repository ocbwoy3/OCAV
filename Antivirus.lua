local av = {}

-- Neļaut OCAV ielādēties vēlreiz
if computer["\xFFOCAV_LOADED\xFF"] and computer["\xFFOCAV_LOADED\xFF"] == true then return {load = function() return false end} end

av.load = function(consent,fs,efi,inet)
	local fsf = {} for a,b in pairs(fs) do fsf[a] = b end
  	local eff = {} for a,b in pairs(efi) do eff[a] = b end
	inet = nil --if inet ~= nil then local inf = {} for a,b in pairs(inet) do inf[a] = b end end

	computer["\xFFOCAV_LOADED\xFF"] = true

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

	-- Ielikt exclusions tabulā visas mapes mapē /Users
	for i = 1, #fsf.list("/Users/") do
		table.insert(exclusions, "/Users/" .. fsf.list("/Users/")[i])
	end

  	-- Padarīt tā, ka fs.list "/" atgriež visu izņemot ".OCAV"
	fs.list = function(path)
		local list = fsf.list(path)

		for i,v in ipairs(list) do
			if v == ".OCAV" then
				table.remove(list,i)
				break
			end
		end
		return list
	end

	fs.open = function(path,mode)
		local mustAskForConsent = false
		-- Ja path sākas ar jebko no systemFiles, bet ne no exclusions, tad mustAskForConsent = true
		for i,v in pairs(systemFiles) do
			if string.sub(path,1,#v) == v then
				mustAskForConsent = true
				break
			end
		end

		for i,v in pairs(exclusions) do
			if string.sub(path,1,#v) == v then
				mustAskForConsent = false
				break
			end
		end

		local allowed = true

		if path == "" or "/" then mustAskForConsent = true end
		
		if mustAskForConsent == true then
			-- nejautāt priekš atļaujas, ja mode ir r vai rb
			local allowed = false
			if mode == "r" then
				allowed = true
			else
				allowed = false
				allowed = consent("Programma mēģina rakstīt failā "..path..". Vai atļaut?")
			end
		end
		
		if allowed == true then
			return fsf.open(path,mode)
		else
			return nil
		end
	end

	-- Tā pat ar fs.makeDirectory
	fs.makeDirectory = function(path)
		local mustAskForConsent = false
		-- Ja path sākas ar jebko no systemFiles, bet ne no exclusions, tad mustAskForConsent = true
		for i,v in pairs(systemFiles) do
			if string.sub(path,1,#v) == v then
				mustAskForConsent = true
				break
			end
		end

		if path == "/" or "" then mustAskForConsent = true end
		
		for i,v in pairs(exclusions) do
			if string.sub(path,1,#v) == v then
				mustAskForConsent = false
				break
			end
		end

		local allowed = true

		if mustAskForConsent == true then
			-- nejautāt priekš atļaujas, ja mode ir r vai rb
			local allowed = false
			-- pārbaudīt, vai mape jau eksistē izmantojot fsf.isDirectory(path)
			if fsf.isDirectory(path) == true then
				allowed = true
			else
				allowed = false
				allowed = consent("Programma mēģina izveidot mapi "..path..". Vai atļaut?")
			end
		end

		if allowed == true then
			return fsf.makeDirectory(path)
		else
			return nil
		end

	end
	
	-- un fs.remove
	fs.remove = function(file)
		local mustAskForConsent = false
		-- Ja path sākas ar jebko no systemFiles, bet ne no exclusions, tad mustAskForConsent = true
		for i,v in pairs(systemFiles) do
			if string.sub(file,1,#v) == v then
				mustAskForConsent = true
				break
			end
		end
		
		for i,v in pairs(exclusions) do
			if string.sub(file,1,#v) == v then
				mustAskForConsent = false
				break
			end
		end
	
		local allowed = true
			
		if path == "" or "/" then mustAskForConsent = true end
		
		if mustAskForConsent == true then
			-- nejautāt priekš atļaujas, ja mode ir r vai rb
			local allowed = false
			allowed = consent("Programma mēģina dzēst failu "..file..". Vai atļaut?")
		end
		
		if allowed == true then
			return fsf.remove(file)
		else
			return nil
		end
	end
	
	-- un fs.rename
	fs.rename = function(oldName,newName)
		local mustAskForConsent = false
		-- Ja path sākas ar jebko no systemFiles, bet ne no exclusions, tad mustAskForConsent = true
		for i,v in pairs(systemFiles) do
			if string.sub(oldName,1,#v) == v then
				mustAskForConsent = true
				break
			end
		end
	
		if path == "/" or "" then mustAskForConsent = true end
		
		for i,v in pairs(exclusions) do
			if string.sub(oldName,1,#v) == v then
				mustAskForConsent = false
				break
			end
		end
	
		local allowed = true
	
		if mustAskForConsent == true then
			-- nejautāt priekš atļaujas, ja mode ir r vai rb
			local allowed = false
			allowed = consent("Programma mēģina pārdēvēt failu "..oldName.." uz "..newName..". Vai atļaut?")
		end
	
		if allowed == true then
			return fsf.rename(oldName,newName)
		else
			return nil
		end
	end

	-- Aizsargāt EEPROM
	efi.set = function(value)
		-- Jautāt, priekš atļaujas
		local allowed = consent("Programma mēģina ierakstīt EEPROM kodu. Vai atļaut?")
		if allowed == true then
			return eff.set(value)
		else
			return nil
		end
	end

	-- tā pat ar efi.setLabel
	efi.setLabel = function(value)
		-- Jautāt, priekš atļaujas
		local allowed = consent("Programma mēģina ierakstīt EEPROM nosaukumu. Vai atļaut?")
		if allowed == true then
			return eff.setLabel(value)
		else
			return nil
		end
	end

	-- un efi.makeReadonly
	efi.makeReadonly = function(checksum)
		-- Jautāt, priekš atļaujas
		local allowed = consent("Programma mēģina padarīt EEPROM tikai lasāmu. Vai atļaut?")
		if allowed == true then
			return eff.makeReadonly(checksum)
		else
			return nil
		end
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
					local allowed = consent("Programma mēģina lejupielādēt "..virus..". Vai atļaut?")
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
