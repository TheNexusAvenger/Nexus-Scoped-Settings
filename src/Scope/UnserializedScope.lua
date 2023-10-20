--[[
TheNexusAvenger

Extension of the GenericScope that disables serialization.
This is only intended for storing default setting.
--]]
--!strict

local GenericScope = require(script.Parent:WaitForChild("GenericScope"))
local Types = require(script.Parent.Parent:WaitForChild("Types"))

local UnserializedScope = {}
UnserializedScope.__index = UnserializedScope
setmetatable(UnserializedScope, GenericScope)



--[[
Creates a generic scope.
--]]
function UnserializedScope.new(SerializationData: any?, ParentScope: Types.SettingsScope?): GenericScope.GenericScope
    return (setmetatable(GenericScope.new(SerializationData, ParentScope), UnserializedScope) :: any) :: GenericScope.GenericScope
end

--[[
Serializes the settings to be saved for later.
--]]
function UnserializedScope:Serialize(): any?
    return nil
end



return (UnserializedScope :: any) :: GenericScope.GenericScope