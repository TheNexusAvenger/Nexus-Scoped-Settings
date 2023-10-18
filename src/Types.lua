--[[
TheNexusAvenger

Common types of the system.
--]]
--!strict

export type SettingsScope = {
    new: (SerializationData: any?, ParentScope: SettingsScope?) -> (SettingsScope),
    Get: (self: SettingsScope, Key: string, ...any?) -> (any?),
    Set: (self: SettingsScope, Key: string, Value: any?, ...any?) -> (),
    Serialize: (self: SettingsScope) -> (any?),
}

return {}