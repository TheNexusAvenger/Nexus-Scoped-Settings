--[[
TheNexusAvenger

Main class for Scroped Settings.
--]]
--!strict

local Event = require(script:WaitForChild("Event"))
local GenericScope = require(script:WaitForChild("Scope"):WaitForChild("GenericScope"))
local PlatformScope = require(script:WaitForChild("Scope"):WaitForChild("PlatformScope"))
local UnserializedScope = require(script:WaitForChild("Scope"):WaitForChild("UnserializedScope"))
local Types = require(script:WaitForChild("Types"))

local ScopedSettings = {}
ScopedSettings.__index = ScopedSettings



--[[
Creates a settings instance with the default scopes for a player.
--]]
function ScopedSettings.CreatePlayerDefault(SerializationData: {[string]: any}?): Types.ScopedSettings
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
function ScopedSettings.new(): Types.ScopedSettings
    return (setmetatable({
        SettingChanged = Event.new(),
        Scopes = {},
        SettingChangedEvents = {},
    }, ScopedSettings) :: any) :: Types.ScopedSettings
end

--[[
Returns a changed event for a setting.
--]]
function ScopedSettings:GetSettingChangedEvent(Key: string): Event.Event<any?>
    if not self.SettingChangedEvents[Key] then
        self.SettingChangedEvents[Key] = Event.new()
    end
    return self.SettingChangedEvents[Key]
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
    local OriginalValue = self:Get(Key, ...)
    self.Scopes[Scope]:Set(Key, Value, ...)

    --Fire changed events.
    if Value == OriginalValue then return end
    self.SettingChanged:Fire(Key, Value)
    if self.SettingChangedEvents[Key] then
        self.SettingChangedEvents[Key]:Fire(Value)
    end
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

--[[
Disconnects the changed events.
--]]
function ScopedSettings:Destroy(): ()
    self.SettingChanged:Destroy()
    for _, Event in self.SettingChangedEvents do
        Event:Destroy()
    end
    self.SettingChangedEvents = {}
end



return (ScopedSettings :: any) :: Types.ScopedSettings