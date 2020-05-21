local addonName, addonTable = ...

-- Globals
DRET = addonTable

SLASH_DRET1 = "/dret"
SLASH_DRET2 = "/defiancerecruitmenttools"

DRET_LOADED = false

-- Locals
local frameCount = 0
local currentlyEditing = nil

function DRET.OnLoad(self)
	self:RegisterEvent("ADDON_LOADED")

	tinsert(UISpecialFrames, self:GetName())

	seterrorhandler(DRET.ErrorWithStack)
end

function DRET.HandleEvent(self, event, ...)
	if event == "ADDON_LOADED" then
		local name = ...
		
		if name == addonName then
			-- Holds all the messages
			DRET_MESSAGES = DRET_MESSAGES or {}

			-- Holds indexes of sent messages
			DRET_SENT = DRET_SENT or {}

			DRET_LOADED = true

			DRET.Initialize()

			print("|cffff0000Defiance Recruitment Tools|r |cff999999" .. GetAddOnMetadata(addonName, "Version") .. "|r has been loaded.")
		end
	end
end

function DRET.Initialize()
	DRET_FrameBottomEditBox:ClearFocus()
	DRET_FrameBottomEditBox:Disable()

	DRET_FrameBottomButtonNew:Enable()
	DRET_FrameBottomButtonCancel:Disable()
	DRET_FrameBottomButtonSave:Disable()

	-- Load existing messages
	if #DRET_MESSAGES > 0 then
		DRET.LoadAllMessages()
	end
end

function DRET.HandleButtonClick(name, index)
	if name == "new" then
		DRET_FrameBottomEditBox:Enable()
		DRET_FrameBottomEditBox:SetFocus()

		DRET_FrameBottomButtonNew:Disable()
		DRET_FrameBottomButtonCancel:Enable()
		DRET_FrameBottomButtonSave:Enable()

		DRET.DisableAllMessageButtons()
	end

	if name == "cancel" then
		DRET_FrameBottomEditBox:SetText("")
		DRET_FrameBottomEditBox:ClearFocus()
		DRET_FrameBottomEditBox:Disable()

		DRET_FrameBottomButtonNew:Enable()
		DRET_FrameBottomButtonCancel:Disable()
		DRET_FrameBottomButtonSave:Disable()

		DRET.EnableAllMessageButtons()

		currentlyEditing = nil
	end

	if name == "save" then
		local message = DRET_FrameBottomEditBox:GetText()

		if trim(message) ~= "" then
			if currentlyEditing then
				DRET_MESSAGES[currentlyEditing].message = message

				_G["DRET_FrameMessage" .. DRET_MESSAGES[currentlyEditing].frameNo].TextContent:SetText(message)

				print("|cffff0000Defiance Recruitment Tools|r |cff999999INFO:|r Successfully edited message #" .. currentlyEditing .. " (total: " .. #DRET_MESSAGES .. ").")
			else
				-- Add to table
				DRET_MESSAGES[#DRET_MESSAGES + 1] = {
					["frameNo"] = frameCount + 1,
					["enabled"] = true,
					["message"] = message 
				}

				-- Create frame
				DRET_FrameTopScrollContent:SetHeight(75 * #DRET_MESSAGES + (#DRET_MESSAGES - 1) * 10)

				DRET.CreateMessageFrame(#DRET_MESSAGES, message, true)

				print("|cffff0000Defiance Recruitment Tools|r |cff999999INFO:|r Added new message (total: " .. #DRET_MESSAGES .. ").")
			end

			DRET.HandleButtonClick("cancel")
		end
	end

	if name == "disable" then
		DRET_MESSAGES[index].enabled = not DRET_MESSAGES[index].enabled
	end

	if name == "edit" then
		currentlyEditing = index

		DRET.HandleButtonClick("new")

		DRET_FrameBottomEditBox:SetText(DRET_MESSAGES[index].message)
	end

	if name == "delete" then
		DRET.DestroyAllFrames()

		-- Fix DRET_SENT to match new indexes
		local indexInSent = nil

		for i, v in ipairs(DRET_SENT) do
			if v == index then
				indexInSent = i

				break
			end
		end

		if indexInSent then
			for i = 1, #DRET_SENT do
				if DRET_SENT[i] > indexInSent then
					DRET_SENT[i] = DRET_SENT[i] - 1
				end
			end

			table.remove(DRET_SENT, indexInSent)
		end

		table.remove(DRET_MESSAGES, index)

		DRET.LoadAllMessages(true)

		print("|cffff0000Defiance Recruitment Tools|r |cff999999INFO:|r Deleted message #" .. index .. " (total: " .. #DRET_MESSAGES .. ").")
	end
end

function DRET.LoadAllMessages(reload)
	reload = reload or false

	DRET_FrameTopScrollContent:SetHeight(75 * #DRET_MESSAGES + (#DRET_MESSAGES - 1) * 10)

	for i = 1, #DRET_MESSAGES do
		-- Fix reference frameNo to be in sync
		if reload then
			DRET_MESSAGES[i].frameNo = frameCount + 1
		else
			DRET_MESSAGES[i].frameNo = i
		end
		
		DRET.CreateMessageFrame(i, DRET_MESSAGES[i].message, DRET_MESSAGES[i].enabled)
	end
end

function DRET.CreateMessageFrame(index, message, enabled)
	local frame = CreateFrame("Frame", "DRET_FrameMessage" .. frameCount + 1, DRET_FrameTopScrollContent, "DRET_FrameMessageTemplate")

	frameCount = frameCount + 1

	frame:SetPoint("TOPLEFT", 0, -(index - 1) * 85)
	frame.TextContent:SetText(message)

	DRET.HandleMessageStatus(frame, enabled)

	frame.ButtonDisable:SetScript("OnClick",
		function(self)
			DRET.HandleButtonClick("disable", index)
			DRET.HandleMessageStatus(self:GetParent(), DRET_MESSAGES[index].enabled)
		end
	)

	frame.ButtonEdit:SetScript("OnClick",
		function()
			DRET.HandleButtonClick("edit", index)
		end
	)

	frame.ButtonDelete:SetScript("OnClick",
		function()
			DRET.HandleButtonClick("delete", index)
		end
	)
end

function DRET.HandleMessageStatus(frame, status)
	if status then
		frame.ButtonDisable:SetText("Disable")
		frame.BackgroundTexture:SetColorTexture(0, 1, 0, 0.1)
	else
		frame.ButtonDisable:SetText("Enable")
		frame.BackgroundTexture:SetColorTexture(1, 0, 0, 0.1)
	end
end

function DRET.DisableAllMessageButtons()
	if #DRET_MESSAGES > 0 then
		for i = 1, #DRET_MESSAGES do
			_G["DRET_FrameMessage" .. DRET_MESSAGES[i].frameNo].ButtonDisable:Disable()
			_G["DRET_FrameMessage" .. DRET_MESSAGES[i].frameNo].ButtonEdit:Disable()
			_G["DRET_FrameMessage" .. DRET_MESSAGES[i].frameNo].ButtonDelete:Disable()
		end
	end
end

function DRET.EnableAllMessageButtons()
	if #DRET_MESSAGES > 0 then
		for i = 1, #DRET_MESSAGES do
			_G["DRET_FrameMessage" .. DRET_MESSAGES[i].frameNo].ButtonDisable:Enable()
			_G["DRET_FrameMessage" .. DRET_MESSAGES[i].frameNo].ButtonEdit:Enable()
			_G["DRET_FrameMessage" .. DRET_MESSAGES[i].frameNo].ButtonDelete:Enable()
		end
	end
end

function DRET.DestroyAllFrames()
	for i = 1, #DRET_MESSAGES do
		local message = DRET_MESSAGES[i]

		_G["DRET_FrameMessage" .. message.frameNo]:Hide();
		_G["DRET_FrameMessage" .. message.frameNo]:SetParent(nil);
	end
end

function DRET.ResetMessageCycle()
	DRET_SENT = {}

	print("|cffff0000Defiance Recruitment Tools|r |cff999999INFO:|r Message cycle has been reset.")
end

-- TODO Not sure if this even works
function DRET.ErrorWithStack(msg)
	msg = msg .. "\n" .. debugstack()

	_ERRORMESSAGE(msg)
end

-- Reigster and handle / commands
function SlashCmdList.DRET(msg)
	if DRET_LOADED then
		local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")

		if cmd == "show" then
			DRET_Frame:Show()
		elseif cmd == "hide" then
			DRET_Frame:Hide()
		elseif cmd == "spam" then
			local available = 0
			local disabled = 0

			for i = 1, #DRET_MESSAGES do
				if DRET_MESSAGES[i].enabled then
					available = available + 1
				else
					disabled = disabled + 1
				end
			end

			if available > 0 then
				local channel = tonumber(args)

				if args ~= "" and channel then
					-- Pick a random message out of a pool of messages that are enabled and not sent in this cycle
					-- If number of messages sent and number of total messages (available to send?) is same restart cycle
					if #DRET_SENT - disabled == available - disabled then
						DRET.ResetMessageCycle()
					end

					local indexes = {}

					for i = 1, #DRET_MESSAGES do
						local message = DRET_MESSAGES[i]
						local sent = false

						for j, index in ipairs(DRET_SENT) do
							if i == index then
								sent = true

								break
							end
						end

						if message.enabled and not sent then
							table.insert(indexes, i)
						end
					end

					-- Pick random and send
					local randomIndex = math.random(1, #indexes)

					-- Send
					SendChatMessage(DRET_MESSAGES[indexes[randomIndex]].message, "CHANNEL", nil, tonumber(channel));

					table.insert(DRET_SENT, indexes[randomIndex])
				else
					print("|cffff0000Defiance Recruitment Tools|r |cff999999ERROR:|r Invalid channel number specified.")
				end
			else
				print("|cffff0000Defiance Recruitment Tools|r |cff999999ERROR:|r There are no available messages to send or all messages are disabled.")
			end
		elseif cmd == "reset" then
			DRET.ResetMessageCycle()
		elseif cmd == "destroy" then
			if #DRET_MESSAGES > 0 then
				DRET.HandleButtonClick("cancel")

				-- Destroy frames
				DRET.DestroyAllFrames()

				DRET_MESSAGES = {}
				DRET_SENT = {}

				print("|cffff0000Defiance Recruitment Tools|r |cff999999INFO:|r Removed all messages (total: " .. #DRET_MESSAGES .. ").")
			else
				print("|cffff0000Defiance Recruitment Tools|r |cff999999ERROR:|r Nothign to remove.")
			end
		else
			print("|cffff0000Defiance Recruitment Tools|r usage:")
			print("/dret show: |cff999999Show DRET")
			print("/dret hide: |cff999999Hide DRET")
			print("/dret spam <channel>: |cff999999Sends random message to channel")
			print("/dret reset: |cff999999Reset sent messages cycle")
			print("/dret destroy: |cff999999Deletes all messages (use with caution)")
		end
	end
end

-- Utils

function trim(s)
	return s:match("^%s*(.-)%s*$")
end
