-- http://luacheck.readthedocs.io/en/stable/config.html
stds.wow = {
   globals = {"BQuestSavedVariables"}, -- these globals can be set and accessed.
   read_globals = {"GetItemInfo", "GetRealmName", "UnitName", "hooksecurefunc", "tinsert", "date", "time", "GetContainerNumSlots", "GetContainerItemID", "GetContainerItemInfo", "CreateFrame", "getglobal", "UIParent", "tremove", "ShowUIPanel", "HideUIPanel"} -- these globals can only be accessed.
}

std = "min+wow"
