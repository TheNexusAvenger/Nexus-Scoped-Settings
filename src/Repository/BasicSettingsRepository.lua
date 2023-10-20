--[[
TheNexusAvenger

Simple repository for storing instances of settings.
--]]
--!strict

local Event = require(script.Parent.Parent:WaitForChild("Event"))
local Types = require(script.Parent.Parent:WaitForChild("Types"))

local BasicSettingsRepository = {}
BasicSettingsRepository.__index = BasicSettingsRepository

export type BasicSettingsRepository<T> = {
    new: (CreateSettingsFunction: (Key: T) -> (Types.ScopedSettings)) -> (BasicSettingsRepository<T>),
} & Types.SettingsRepository<T>



--[[
Creates a basic settings repository.
The CreateSettingsFunction function is meant to return the settings for the key. It can yield.
--]]
function BasicSettingsRepository.new<T>(CreateSettingsFunction: (Key: T) -> (Types.ScopedSettings)): BasicSettingsRepository<T>
    return (setmetatable({
        SettingsInstances = {},
        CreatingSettings = {},
        SettingsCreatedEvent = Event.new(),
        CreateSettingsFunction = CreateSettingsFunction,
    }, BasicSettingsRepository) :: any) :: BasicSettingsRepository<T>
end

--[[
Returns an instance of settings for the given key.
Depending on CreateSettingsFunction, this may yield.
--]]
function BasicSettingsRepository:Get<T>(Key: T): Types.ScopedSettings
    if not self.SettingsInstances[Key] then
        if not self.CreatingSettings[Key] then
            self.CreatingSettings[Key] = true
            self.SettingsInstances[Key] = self.CreateSettingsFunction(Key)
            self.SettingsCreatedEvent:Fire(Key)
            self.CreatingSettings[Key] = nil
        else
            while not self.SettingsInstances[Key] do
                self.SettingsCreatedEvent:Wait()
            end
        end
    end
    return self.SettingsInstances[Key]
end

--[[
Clears an instance of settings if it exists.
--]]
function BasicSettingsRepository:Clear<T>(Key: T): ()
    self.SettingsInstances[Key] = nil
    self.CreatingSettings[Key] = nil
end



return (BasicSettingsRepository :: any) :: BasicSettingsRepository<any>