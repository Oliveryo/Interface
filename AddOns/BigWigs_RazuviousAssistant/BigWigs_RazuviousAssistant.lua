--[[
--
-- Big Wigs Strategy Module for Instructor Razuvious in Naxxramas.
--
-- Adds timer bars and warning messages for the Understudies
-- Mind Exhaustion debuff, so priests know exactly when they are ready.
--
-- Also adds a timer bar for Taunt.
--
--]]

------------------------------
--      Are you local?      --
------------------------------

local myname = "Razuvious Assistant"
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..myname)
local boss = AceLibrary("Babble-Boss-2.2")["Instructor Razuvious"]
local understudy = AceLibrary("Babble-Boss-2.2")["Deathknight Understudy"]

local times = nil

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "RazAssist",

	debuff_cmd = "debuff",
	debuff_name = "Mind Exhaustion Timer",
	debuff_desc = "Show timer bar for the Mind Exhaustion debuff",

	taunt_cmd = "taunt",
	taunt_name = "Taunt",
	taunt_desc = "Show timer bar for Taunt",

	broadcast_cmd = "broadcast",
	broadcast_name = "Broadcast debuff states",
	broadcast_desc = "Broadcasts the debuff gone in 5 seconds messages to raid warning",

	taunt_bar = "Taunt",
	taunt_trigger = "Razuvious is afflicted by Taunt",

	mindexhaustion_bar = "%s - Exhaustion",
	mindexhaustion = "Mind Exhaustion",
	mindexhaustion_5sec = "%s is ready in 5sec!",

	["rtPath1"] = "Interface\\AddOns\\BigWigs_RazuviousAssistant\\icons\\Star",
	["rtPath2"] = "Interface\\AddOns\\BigWigs_RazuviousAssistant\\icons\\Circle",
	["rtPath3"] = "Interface\\AddOns\\BigWigs_RazuviousAssistant\\icons\\Diamond",
	["rtPath4"] = "Interface\\AddOns\\BigWigs_RazuviousAssistant\\icons\\Triangle",
	["rtPath5"] = "Interface\\AddOns\\BigWigs_RazuviousAssistant\\icons\\Moon",
	["rtPath6"] = "Interface\\AddOns\\BigWigs_RazuviousAssistant\\icons\\Square",
	["rtPath7"] = "Interface\\AddOns\\BigWigs_RazuviousAssistant\\icons\\Cross",
	["rtPath8"] = "Interface\\AddOns\\BigWigs_RazuviousAssistant\\icons\\Skull",

	["raidIcon0"] = "Unknown",
	["raidIcon1"] = "Star",
	["raidIcon2"] = "Circle",
	["raidIcon3"] = "Diamond",
	["raidIcon4"] = "Triangle",
	["raidIcon5"] = "Moon",
	["raidIcon6"] = "Square",
	["raidIcon7"] = "Cross",
	["raidIcon8"] = "Skull",

	["raidColor0"] = "Red",
	["raidColor1"] = "Yellow",
	["raidColor2"] = "Orange",
	["raidColor3"] = "Purple",
	["raidColor4"] = "Green",
	["raidColor5"] = "White",
	["raidColor6"] = "Blue",
	["raidColor7"] = "Red",
	["raidColor8"] = "White",

} end )

----------------------------------
--      Module Declaration      --
----------------------------------

BigWigsRazuviousAssistant = BigWigs:NewModule(myname)
BigWigsRazuviousAssistant.synctoken = myname
BigWigsRazuviousAssistant.zonename = AceLibrary("Babble-Zone-2.2")["Naxxramas"]
BigWigsRazuviousAssistant.enabletrigger = { boss }
BigWigsRazuviousAssistant.toggleoptions = { "broadcast", "debuff", "taunt" }
BigWigsRazuviousAssistant.revision = tonumber(string.sub("$Revision: 17256 $", 12, -3))
BigWigsRazuviousAssistant.external = true

------------------------------
--      Initialization      --
------------------------------

function BigWigsRazuviousAssistant:OnEnable()
	times = {}

	self:RegisterEvent("SpecialEvents_UnitDebuffGained")

	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE")
	self:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
end

------------------------------
--      Utility             --
------------------------------

function BigWigsRazuviousAssistant:GetRaidIconName(unitid)
	local iconIndex = GetRaidTargetIndex(unitid)
	if not iconIndex or not UnitExists(unitid) then return L["raidIcon0"], 0 end
	return L["raidIcon"..iconIndex], iconIndex
end

function BigWigsRazuviousAssistant:GetRaidIconColor(raidIconIndex)
	if L:HasTranslation("raidColor"..raidIconIndex) then
		return L["raidColor"..raidIconIndex]
	end
	return "Red"
end

function BigWigsRazuviousAssistant:GetRaidIconPath(raidIconIndex)
	if L:HasTranslation("rtPath"..raidIconIndex) then
		return L["rtPath"..raidIconIndex]
	end
	return "Interface\\Icons\\Spell_Shadow_Teleport"
end

------------------------------
--      Event Handlers      --
------------------------------

function BigWigsRazuviousAssistant:CHAT_MSG_COMBAT_HOSTILE_DEATH(msg)
	if msg == string.format(UNITDIESOTHER, boss) then
		self.core:ToggleModuleActive(self, false)
	end
end

function BigWigsRazuviousAssistant:CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE(msg)
	if not self.db.profile.taunt then return end
	if string.find(msg, L["taunt_trigger"]) then
		self:TriggerEvent("BigWigs_StartBar", self, L["taunt_bar"], 20, "Interface\\Icons\\Spell_Nature_Reincarnation", "Green", "Yellow", "Orange")
	end
end

function BigWigsRazuviousAssistant:SpecialEvents_UnitDebuffGained(unitid, debuffName, applications, debuffType, texture)
	if self.db.profile.debuff and debuffName == L["mindexhaustion"] and UnitName(unitid) == understudy then
		local iconName, iconIndex = self:GetRaidIconName(unitid)

		-- Throttle by iconIndex. We will get many UnitDebuffGained events.
		if not times[iconIndex] or (times[iconIndex] + 5) <= GetTime() then
			self:TriggerEvent("BigWigs_StartBar", self, string.format(L["mindexhaustion_bar"], iconName), 60, self:GetRaidIconPath(iconIndex), self:GetRaidIconColor(iconIndex))
			self:ScheduleEvent("bwrazassmcreadysoon"..iconIndex, "BigWigs_Message", 55, string.format(L["mindexhaustion_5sec"], iconName), "Green", not self.db.profile.broadcast)
			times[iconIndex] = GetTime()
		end
	end
end

