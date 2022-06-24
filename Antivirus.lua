local av = {}

-- Neļaut OCAV ielādēties vēlreiz
if computer["\xFFOCAV_LOADED\xFF"] and computer["\xFFOCAV_LOADED\xFF"] == true then return {load = function() return false end} end

av.load = function(consent,fs,efi,inet)
	local fsf = {} for a,b in pairs(fs) do fsf[a] = b end
  	local eff = {} for a,b in pairs(efi) do eff[a] = b end
	local inf = {} for a,b in pairs(inet) do inf[a] = b end

	computer["\xFFOCAV_LOADED\xFF"] = true

	-- Noņem OCAV no package.loaded
	package.loaded["antivirus"] = nil
	
	local systemFiles = {
		"/";
		"/OCTOP";
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
		if path == "/" then
			for i,v in ipairs(list) do
				if v == ".OCAV" then
				table.remove(list,i)
				break
				end
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

		if mustAskForConsent == true then
			-- nejautāt priekš atļaujas, ja mode ir r vai rb
			local allowed = false
			if mode == "r" or mode == "rb" then
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

	if inet ~= nil then
		
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

		inet.connect = function(address, port)
			-- Pārbaudīt, vai adress sākas ar jeb ko no blockedRootURLs
			for i,v in pairs(blockedRootURLs) do
				if string.sub(address,1,#v[1]) == v[1] then
					-- Jautāt, priekš atļaujas
					local allowed = consent("Programma mēģina lejuplādēt " .. tostring(v[2]) .. "failus. Vai atļaut?")
					if allowed == true then
						return inf.connect(address, port)
					else
						error("Blocked by OCAV")
					end
				end
			end
		end

	end

	-- tā pat ar inet.request
	inet.request = function(url, postdata, headers)
		-- Pārbaudīt, vai adress sākas ar jeb ko no blockedRootURLs
		for i,v in pairs(blockedRootURLs) do
			if string.sub(url,1,#v[1]) == v[1] then
				-- Jautāt, priekš atļaujas
				local allowed = consent("Programma mēģina lejuplādēt " .. tostring(v[2]) .. "failus. Vai atļaut?")
				if allowed == true then
					return inf.request(url, postdata, headers)
				else
					error("Blocked by OCAV")
				end
			end
		end
	end

	return true
end

return av