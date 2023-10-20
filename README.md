# Nexus-Scoped-Settings
Nexus Scoped Settings provides state management and replication
of settings with multiple scopes/layers.

## Why?
In other applications, you may notice settings are stored in
layers with one overriding the previous. There are multiple
reasons why, but there are two for this project:
1. To be able to override and then clear settings while still
   having lower layers for default/previous values.
2. To be able to have different implementations for layers,
   such as the `PlatformScope` that stores settings for certain
   inputs. For example, in On Tap, there is a popup to enable
   the lower graphics mode for certain devices. This allows
   it to be remembered for certain groups of platforms, like
   low on VR but high on PC.

## Creating Settings
The main settings class that external code will interact with is
the `NexusScopedSettings` module.

### Manual Way
`NexusScopedSettings` can be created using `NexusScopedSettings.new()`,
but it creates no scopes by default. In order to use it, `AddScope`
*must* be called with at least one scope. By default, there are
3 provided scope implementations:
- `GenericScope`: Simple key-value pairing.
- `UnserializedScope`: Extension of `GenericScope` that will never
  return any data when serializing. It is recommended to be used
  for session-specific settings or default values.
- `PlatformScope`: Key-value pairing tied to the input methods of
  the player. This is meant to be used with settings that may depend
  on the capability of the system (especially standalone VR).
  - Internally, the settings are stored based on a hardware identifier
    based on if the player has a touch input, VR, and if they are using
    a "ten foot interface" (console). It does not distinguish between
    specific hardware, such as a phone vs tablet.

Scopes are treated like a linked list. Each scope is aware of the
next one. When `Get` is called for a given scope and no value is
stored, it is expected to call the `Get` of the next one. After
being created, `AddScope(ScopeName: string, Scope: SettingsScope)`
is used to store the scope with the name to use with `Set`.

```lua
local NexusScopedSettingsModule = ...
local NexusScopedSettings = require(NexusScopedSettings)
local GenericScope = require(NexusScopedSettings:WaitForChild("Scope"):WaitForChild("GenericScope"))
local PlatformScope = require(NexusScopedSettings:WaitForChild("Scope"):WaitForChild("PlatformScope"))
local UnserializedScope = require(NexusScopedSettings:WaitForChild("Scope"):WaitForChild("UnserializedScope"))

--Create the scopes.
local SerializationData = ... --Fetch stored settings from previous server.
local DefaultScope = UnserializedScope.new()
local UserScope = GenericScope.new(SerializationData.User, DefaultScope) --First argument is the previous settings to use. Second argument is the next scope to reference.
local SystemScope = PlatformScope.new(SerializationData.System, UserScope) --First argument is the previous settings to use. Second argument is the next scope to reference.
local SessionScope = UnserializedScope.new(nil, SystemScope) --First argument is the previous settings to use. Second argument is the next scope to reference.

--Create settings.
--Order matters! The first scope to reference must be added last.
local Settings = NexusScopedSettings.new()
Settings:AddScope("Default", DefaultScope)
Settings:AddScope("User", UserScope)
Settings:AddScope("System", SystemScope)
Settings:AddScope("Session", SessionScope)

--To save settings, use Serialize.
MyDataStorage:SavePlayerSettings(Settings:Serialize())
```

### Default Way
For most cases, `NexusScopedSettings.CreatePlayerDefault(SerializationData: {[string]: any}?)`
will be suitable. It creates a settings instance with 4 scopes:
- `Default` (`UnserializedScope`) - Default settings. It is strongly
  recommended to put all default values here.
- `User` (`GenericScope`) - Overriden values for the user accross
  all input types.
- `System` (`PlatformScope`) - Overriden values for the user's current
  input methods.
- `Session` (`UnserializedScope`) - Overriden values for only the curren
  session. They are never saved between servers.

The only parameter for `CreatePlayerDefault` is an optional `SerializationData`.
It is meant to be the return value of `NexusScopedSettings:Serialize()`
that was stored by a previous server.

## Using Settings
### Reading/Writing Settings
`Get` and `Set` are used to read and write settings respectively.
However, they operate a bit differently.
- `Get(Key: string): any?` will start at the lasted added scope and try
  to return the first value from any scope.
- `Set(Scope: string, Key: string, Value: any?): ()` will
  set the value for a specific scope.

Because of the requirement to have a scope for setting, it is
possible to write a setting and then get a different value when
reading because a higher scope overrides it.

In addition, **avoid writing to `PlatformScope`s on the server**.
The hardware key is required, and the server does not automatically
have it.

### Listening To Changes
Settings can change at any time. Events are the recommended way
to handle changes. `SettingChanged: Event<string, any?>` exists
in the settings that will be fired with the changed setting name
and new value when any setting changes. To listen to a specific
setting, `GetSettingChangedEvent(Key: string): Event<any?>`
can be used, which returns an event that only returns the new
value of the changed setting.

In order to disconnect all events, use `Destroy(): ()`.

### Saving
When saving settings, `Serialize(): {[string]: any}` returns
a table of each scope by name to their serialization data.

## Repositories
Settings instances are not singleton and aren't safe to be recreated.
Repositories are provided to store settings instances.

### BasicSettingsRepository
`BasicSettingsRepository` is a very simple key-value storage
method for settings without replication. The key for a settings
can be any type.

The constructor takes in a `CreateSettingsFunction: (Key: T) -> (ScopedSettings)`
function. The key is the value passed into `Get` and a settings
instance must be returned. **The function is allowed to yield**,
but `Get` *will* yield when settings are being created. Once it
is cached, there is no delay getting.

```lua
local Repository = BasicSettingsRepository.new(function(Key: Player)
    local Settings = NexusScopedSettings.CreatePlayerDefault(GetPreviousData(Player))
    for DefaultName, DefaultValue in MyDefaultSettings do --*Strongly* recommended to set any defaults.
        Settings:Set("Default", DefaultName, DefaultValue)
    end
    return Settings
end)

local Settings = Repository:Get("MySettings") --Gets settings.
Repository:Clear("MySettings") --Clears settings, allowing them to be garbage collected.
```

### ReplicatedPlayerSettingsRepository
`ReplicatedPlayerSettingsRepository` is a more complex repository
that provides client to server replication and server to client
initialization.

The constructor takes in a `Name: string` that is used for creating
the events. It *must* be the same on the client and server. After
the name is a different version of `CreateSettingsFunction: (Key: Player, ServerData: {[string]: any}?) -> (ScopedSettings)`
from above. The key will always be a `Player`, while `ServerData`
is never provided on the server and always provided from `Serialize`
on the client. Because of this, fetching settings on the client
will yield until the server settings initialize.

A couple additional methods are added as well *for the server*.
- `SetValidator(Key: string, Validator: (any?) -> () | {any?}): ()`: 
  In order to accept changes from the client, a validator must
  be set to prevent the client filling the settings with garbage
  data (or worse, unfiltered text). It can be either a function that throws an error when
  an incorrect value is passed, or a list of valid values.
- `LoadOnPlayerJoin(): ReplicatedPlayerSettingsRepository`:
  When a player joins, settings will automatically be initialized.
- `ClearOnPlayerLeaving(): ReplicatedPlayerSettingsRepository`:
  When a player leaves, settings will automatically be cleared.

```lua
--Server
local Repository = ReplicatedPlayerSettingsRepository.new(function(Key: Player)
    local Settings = NexusScopedSettings.CreatePlayerDefault(GetPreviousData(Player))

    --Set the defaults.
    Settings:Set("Default", "Key1", false)
    Settings:Set("Default", "Key2", "MyValue1")
    Settings:Set("Default", "Key3", 0.5)

    --Connect saving.
    --This may be called a lot. Make sure requests are properly buffered.
    Settings.SettingChanged:Connect(function()
        SaveSettings(Player, Settings:Serialize())
    end)
    
    return Settings
end)

Repository:SetValidator("Key1", {true, false, nil}) --Key1 can be true, false, or nil
Repository:SetValidator("Key2", {"MyValue1", "MyValue2", "MyValue3"}) --Key2 can be "MyValue1", "MyValue2", or "MyValue3"
Repository:SetValidator("Key3", function(Value: number)
    if Value >= 0 and Value <= 1 then return end
    error(`Key3 must be between 0 and 1 (not {Value})`)
end) --Key3 can be a number between 0 and 1.
Repository:LoadOnPlayerJoin():ClearOnPlayerLeaving()



--Client
local Repository = ReplicatedPlayerSettingsRepository.new(function(Key: Player)
    local Settings = NexusScopedSettings.CreatePlayerDefault(GetPreviousData(Player))
    Settings:Set("Default", "Key1", false)
    Settings:Set("Default", "Key2", "MyValue1")
    Settings:Set("Default", "Key3", 0.5)
    return Settings
end)
```

## License
Nexus Scoped Settings is available under the terms of the MIT 
License. See [LICENSE](LICENSE) for details.