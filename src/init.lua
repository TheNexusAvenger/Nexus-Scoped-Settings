--[[
TheNexusAvenger

Main class for Scroped Settings.
--]]
--!strict

local GenericScope = require(script:WaitForChild("GenericScope"))
local PlatformScope = require(script:WaitForChild("PlatformScope"))
local UnserializedScope = require(script:WaitForChild("UnserializedScope"))
local Types = require(script:WaitForChild("Types"))

local ScopedSettings = {}
ScopedSettings.__index = ScopedSettings

export type ScopedSettings = {
    --TODO: Events
    Scopes: {[string]: Types.SettingsScope},
    OuterScope: Types.SettingsScope?,
    new: () -> (ScopedSettings),
    CreatePlayerDefault: (SerializationData: {[string]: any}?) -> (ScopedSettings),
    Get: (self: ScopedSettings, Key: string, ...any) -> (any?),
    Set: (self: ScopedSettings, Scope: string, Key: string, Value: any?, ...any) -> (),
    AddScope: (self: ScopedSettings, ScopeName: string, Scope: Types.SettingsScope) -> (),
    Serialize: (self: ScopedSettings) -> ({[string]: any}),
}



--[[
Creates a settings instance with the default scopes for a player.
--]]
function ScopedSettings.CreatePlayerDefault(SerializationData: {[string]: any}?): ScopedSettings
    local NewSerializationData = SerializationData or {} :: {[string]: any}

    --Create the scopes.
    local DefaultScope = UnserializedScope.new()
    local UserScope = GenericScope.new(NewSerializationData.User, DefaultScope)
    local SystemScope = PlatformScope.new(NewSerializationData.System, UserScope)
    local SessionScope = UnserializedScope.new(nil, SystemScope)

    --Create and return the settings.
    local Settings = ScopedSettings.new()
    Settings:AddScope("Default", DefaultScope)
    Settings:AddScope("User", UserScope)
    Settings:AddScope("System", SystemScope)
    Settings:AddScope("Session", SessionScope)
    return Settings
end

--[[
Creates a scoped settings instance without scopes.
--]]
function ScopedSettings.new(): ScopedSettings
    return (setmetatable({
        Scopes = {},
    }, ScopedSettings) :: any) :: ScopedSettings
end

--[[
Gets the value of a setting, starting from the outer-most scope.
--]]
function ScopedSettings:Get(Key: string, ...: any): any?
    --Throw an error if there is no scope.
    if not self.OuterScope then
        error("There are no scopes. Use AddScope before calling Get.")
    end

    --Return the result from the outer scope.
    return self.OuterScope:Get(Key, ...)
end

--[[
Sets the value of a setting for the given scope.
--]]
function ScopedSettings:Set(Scope: string, Key: string, Value: any?, ...: any): ()
    --Throw an error if the scope is not found.
    if not self.Scopes[Scope] then
        error(`Scope "{Scope}" does not exist. Use AddScope before calling Set.`)
    end

    --Set the value.
    self.Scopes[Scope]:Set(Key, Value, ...)
end

--[[
Adds a scope to the settinbgs.
--]]
function ScopedSettings:AddScope(ScopeName: string, Scope: Types.SettingsScope): ()
    if self.Scopes[ScopeName] then
        error(`Scope "{ScopeName}" already exists. Scope names must be unique.`)
    end
    self.Scopes[ScopeName] = Scope
    self.OuterScope = Scope
end

--[[
Serializes all of the scopes to a table.
--]]
function ScopedSettings:Serialize(): {[string]: any}
    local SerializedScopes = {}
    for ScopeName, Scope in self.Scopes do
        SerializedScopes[ScopeName] = Scope:Serialize()
    end
    return SerializedScopes
end



return (ScopedSettings :: any) :: ScopedSettings