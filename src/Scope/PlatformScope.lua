--[[
TheNexusAvenger

Scope that is tied to the type of hardware of a user.
--]]
--!strict

local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local FLAG_YES = "Y"
local FLAG_NO = "N"
local HARDWARE_INDICATORS = {
    {
        Name = "Touch",
        Indicator = "T",
        IsTrue = function() return UserInputService.TouchEnabled end,
    },
    {
        Name = "VR",
        Indicator = "V",
        IsTrue = function() return UserInputService.VREnabled end,
    },
    {
        Name = "Console",
        Indicator = "C",
        IsTrue = function() return GuiService:IsTenFootInterface() end,
    },
}

local Types = require(script.Parent.Parent:WaitForChild("Types"))

local PlatformScope = {}
PlatformScope.__index = PlatformScope

export type PlatformScope = {
    ParseHardwareKey: (Key: string) -> ({[string]: boolean}),
    CreateHardwareKey: (HardwareData: {[string]: boolean}?) -> (string),

    Settings: {[string]: {[string]: any}},
    Parent: Types.SettingsScope?,
    new: (SerializationData: any?, ParentScope: Types.SettingsScope?) -> (PlatformScope),
    GetClosestHardwareKey: (self: PlatformScope, Key: string) -> (string?),
} & Types.SettingsScope



--[[
Parses a hardware key.
--]]
function PlatformScope.ParseHardwareKey(Key: string): {[string]: boolean}
    --Throw an error if the length is invalid.
    if not Key or string.len(Key) == 0 then
        error("Hardware key is empty.")
    end
    if string.len(Key) % 2 ~= 0 then
        error(`Hardware key is not an even length: {Key}`)
    end

    --Parse the properties.
    local KeyProperties = {}
    for i = 1, string.len(Key) - 1, 2 do
        local Indicator = string.sub(Key, i, i)
        local Flag = string.sub(Key, i + 1, i + 1)
        local HardwareIndicator = nil
        for _, CurrentHardwareIndicator in HARDWARE_INDICATORS do
            if CurrentHardwareIndicator.Indicator ~= Indicator then continue end
            HardwareIndicator = CurrentHardwareIndicator
            break
        end

        if HardwareIndicator then
            if Flag ~= FLAG_YES and Flag ~= FLAG_NO then
                error(`Unknown flag: {Flag} for {Indicator} in {Key}`)
            end
            KeyProperties[HardwareIndicator.Name] = (Flag == FLAG_YES)
        else
            error(`Unknown indicator: {Indicator} in {Key}`)
        end
    end

    --Return the properties.
    return KeyProperties
end

--[[
Creates a hardware key.
--]]
function PlatformScope.CreateHardwareKey(HardwareData: {[string]: boolean}?): string
    --Create the hardware data.
    if not HardwareData then
        local NewHardwareData = {}
        for _, HardwareIndicator in HARDWARE_INDICATORS do
            NewHardwareData[HardwareIndicator.Name] = HardwareIndicator.IsTrue()
        end
        HardwareData = NewHardwareData
    end

    --Build and return the key.
    local Key = ""
    for _, HardwareIndicator in HARDWARE_INDICATORS do
        local Value = (HardwareData :: {[string]: boolean})[HardwareIndicator.Name]
        if Value == nil then continue end
        Key = Key..HardwareIndicator.Indicator..(Value and FLAG_YES or FLAG_NO)
    end
    return Key
end

--[[
Creates a parent scope.
--]]
function PlatformScope.new(SerializationData: any?, ParentScope: Types.SettingsScope?): PlatformScope
    return (setmetatable({
        Settings = SerializationData or {},
        Parent = ParentScope,
    }, PlatformScope) :: any) :: PlatformScope
end

--[[
Returns the key of the closest platform for the hardware key.
--]]
function PlatformScope:GetClosestHardwareKey(Key: string): string?
    --Return the key if it exists directly.
    if self.Settings[Key] then return Key end

    --Return the first key that matches, if any.
    local ParsedKey = self.ParseHardwareKey(Key)
    for HardwareKey, _ in self.Settings do
        local ParsedHardwareKey = self.ParseHardwareKey(HardwareKey)
        local Matches = true
        for Name, Value in ParsedKey do
            if ParsedHardwareKey[Name] == nil or ParsedHardwareKey[Name] == Value then continue end
            Matches = false
            break
        end
        if not Matches then continue end
        return HardwareKey
    end
    return nil
end

--[[
Returns the value for a setting.
The returned value may be the parent scope instead of the current one.
--]]
function PlatformScope:Get(Key: string, HardwareKey: string?, ...: any?): any?
    if RunService:IsServer() and not HardwareKey then
        if self.Parent then
            return self.Parent:Get(Key, HardwareKey, ...)
        end
        return nil
    end

    local MatchedHardwareKey = self:GetClosestHardwareKey(HardwareKey or self.CreateHardwareKey())
    if MatchedHardwareKey then
        local Value = self.Settings[MatchedHardwareKey][Key]
        if Value ~= nil then
            return Value
        end
    end
    if self.Parent then
        return self.Parent:Get(Key, HardwareKey :: any, ...)
    end
    return nil
end

--[[
Sets the setting for the current scope.
--]]
function PlatformScope:Set(Key: string, Value: any?, HardwareKey: string?, ...: any?): ()
    if RunService:IsServer() and not HardwareKey then
        error("Setting value in platform scope requires a hardware key when on the server.")
    end

    --Reprocess the key to ensure it isn't corrupted by the client.
    if HardwareKey then
        HardwareKey = self.CreateHardwareKey(self.ParseHardwareKey(HardwareKey))
    end
    HardwareKey = HardwareKey or self.CreateHardwareKey()

    --Migrate the key if the existing key is different.
    local ExistingKey = self:GetClosestHardwareKey(HardwareKey)
    if ExistingKey and ExistingKey ~= HardwareKey then
        self.Settings[HardwareKey] = self.Settings[ExistingKey]
        self.Settings[ExistingKey] = nil
    end

    --Store the setting.
    if not self.Settings[HardwareKey] then
        self.Settings[HardwareKey] = {}
    end
    self.Settings[HardwareKey][Key] = Value
end

--[[
Serializes the settings to be saved for later.
--]]
function PlatformScope:Serialize(): any?
    return self.Settings
end



return (PlatformScope :: any) :: PlatformScope