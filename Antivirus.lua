local av = {}

-- Neļaut OCAV ielādēties vēlreiz
if computer["\xFFOCAV_LOADED\xFF"] and computer["\xFFOCAV_LOADED\xFF"] == true then return {load = function() return false end} end

av.load = function(consent,fs,efi,inet)
	-- Experimental consent
	_G.consent = consent
	
	local fsf = {} for a,b in pairs(fs) do fsf[a] = b end
  	local eff = {} for a,b in pairs(efi) do eff[a] = b end
	inet = nil --if inet ~= nil then local inf = {} for a,b in pairs(inet) do inf[a] = b end end

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
		{"CreateDirectory", "OCAV noteica, ka tiek izveidota mape '%s'. Vai atļaut?"};
		{"open_w", "OCAV noteica, ka tiek rakstīts uz '%s'. Vai atļaut?"};
		{"remove", "OCAV noteica, ka tiek dzēsts '%s'. Vai atļaut?"};
		{"rename", "OCAV noteica, ka '%s' tiek pārdēvēts uz '%s'. Vai atļaut?"};
		{"eeprom_set","OCAV noteica, ka tiek rakstīts EEPROM kods. Vai atļaut?"};
		{"eeprom_makereadonly", "OCAV noteica, ka EEPROM tiek padarīts tikai lasāms. Vai atļaut?"};
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
