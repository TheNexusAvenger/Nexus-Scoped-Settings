--[[
TheNexusAvenger

Generic scope for storing values.
--]]
--!strict

local Types = require(script.Parent:WaitForChild("Types"))

local GenericScope = {}
GenericScope.__index = GenericScope

export type GenericScope = {
    Settings: {[string]: any},
    Parent: Types.SettingsScope?,
} & Types.SettingsScope



--[[
Creates a generic scope.
--]]
function GenericScope.new(SerializationData: any?, ParentScope: Types.SettingsScope?): GenericScope
    return (setmetatable({
        Settings = SerializationData or {},
        Parent = ParentScope,
    }, GenericScope) :: any) :: GenericScope
end

--[[
Returns the value for a setting.
The returned value may be the parent scope instead of the current one.
--]]
function GenericScope:Get(Key: string, ...: any?): any?
    local Value = self.Settings[Key]
    if Value ~= nil then
        return Value
    end
    if self.Parent then
        return self.Parent:Get(Key, ...)
    end
    return nil
end

--[[
Sets the setting for the current scope.
--]]
function GenericScope:Set(Key: string, Value: any?, ...: any?): ()
    self.Settings[Key] = Value
end

--[[
Serializes the settings to be saved for later.
--]]
function GenericScope:Serialize(): any?
    return self.Settings
end



return (GenericScope :: any) :: GenericScope