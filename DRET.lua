local TOCNAME, DRET = ...

-- Globals
SLASH_DRET1 = "/dret"
SLASH_DRET2 = "/defiancerecruitmenttools"
DRET_LOADED = false

-- Frame to register events
local frame = CreateFrame("Frame")

frame:RegisterEvent("ADDON_LOADED")

function frame:OnEvent(event, ...)
	if (event == "ADDON_LOADED") then
		local addOnName = ...
		
		if (addOnName == "Defiance Recruitment Tools") then
			DRT_LOADED = true

			print("Defiance Recruitment Tools has been loaded.")
		end
	end
end

frame:SetScript("OnEvent", frame.OnEvent)

function SlashCmdList.DRET(msg)
	if (DRET_LOADED) then
		if (msg == "") then
			print("Defiance Recruitment Tools usage:")
			print(" - No commands have been implemented yet.")
		end
	end
end
