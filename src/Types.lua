--[[
TheNexusAvenger

Common types of the system.
--]]
--!strict

local Event = require(script.Parent:WaitForChild("Event"))

export type ScopedSettings = {
    SettingChanged: Event.Event<string, any?>,
    Scopes: {[string]: SettingsScope},
    OuterScope: SettingsScope?,
    new: () -> (ScopedSettings),
    CreatePlayerDefault: (SerializationData: {[string]: any}?) -> (ScopedSettings),
    GetSettingChangedEvent: (self: ScopedSettings, Key: string) -> (Event.Event<any?>),
    Get: (self: ScopedSettings, Key: string, ...any) -> (any?),
    Set: (self: ScopedSettings, Scope: string, Key: string, Value: any?, ...any) -> (),
    AddScope: (self: ScopedSettings, ScopeName: string, Scope: SettingsScope) -> (),
    Serialize: (self: ScopedSettings) -> ({[string]: any}),
    Destroy: (self: ScopedSettings) -> (),
}

export type SettingsScope = {
    Get: (self: SettingsScope, Key: string, ...any?) -> (any?),
    Set: (self: SettingsScope, Key: string, Value: any?, ...any?) -> (),
    Serialize: (self: SettingsScope) -> (any?),
}

export type SettingsRepository<T> = {
    Get: (self: SettingsRepository<T>, Key: T) -> (ScopedSettings),
    Clear: (self: SettingsRepository<T>, Key: T) -> (),
}

return {}