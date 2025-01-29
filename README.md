# Renewed Sirensync

Originally this resource was PMA sirensync but I have made some improvements like, swapping over to lua completely will make it easier to drag and drop, utilizing Ox_Lib to handle a lot of the heavy lifting.

The resource works closer to LVC than Pma Sirensync did, here's a quick rundown of how the keybinds work.

`Q` - Toggles the emergency lights on and off

`E` - Uses the vehicles emergency horn

`R` - Hold to use the vehicles sirens, if the siren is toggled by `ALT` then this will toggle between the vehicles different emergency siren sounds

`ALT` - (Left ALT) is used to toggle the vehicle sirens can only be used if the lights are toggled on.

**NOTE**: If another resource fails to use `ReleaseSoundId(soundId)` after using `GetSoundId()`, it may break the sounds in this resource as the sound limit gets reached

If you wish to change any keybinds you can do so in the client.lua

## Installation

- Download the latest release of [ox_lib](https://github.com/overextended/ox_lib/tags)
- Download renewed sirensync
- Place both resources into your server (make sure ox_lib is started before renewed sirensync)
- and enjoy :)

## Addon Sirens
If you have a server sided siren pack you can replace the sirens used in the `config.lua`. You can create "groups" of models that use the same siren sounds.
You can refer to the type annotations, but here is an example:

```lua
sirens = {
    -- make sure to keep the base sirens ABOVE the addon sirens
    --base
    { ... },

    --Addon Group 1 (just a name for your reference)
    {
        sirenModes = {
            --[[
            This table has to be in the correct order, only 3 sirenModes (or steps (when pressing R) if you prefer) are supported
            (You can specify the index of the sirenMode, but it's not necessary)
            (that's what i mean:)
                [1] = { ... }
            ]]
            { audioName = 'VEHAUD_LSPD_NEW_SIREN_ADAM',   audioRef = "VEHAUD_LSPD_NEW_SOUNDSET" }, -- First sirenMode
            { audioName = 'VEHAUD_LSPD_NEW_SIREN_BOY',   audioRef = "VEHAUD_LSPD_NEW_SOUNDSET" }, -- Second sirenMode
            { audioName = 'VEHAUD_LSPD_NEW_SIREN_CHARLES', audioRef = "VEHAUD_LSPD_NEW_SOUNDSET" }, -- Third sirenMode
        },

        horn = {
            audioName = 'VEHAUD_LSPD_NEW_HORN'
            audioRef = "VEHAUD_LSPD_NEW_SOUNDSET"
        },

        models = {
            [`police5`] = true,
            [`polgauntlet`] = true,
        }
    },
}
```

## Credits

* [AvarianKnight](https://github.com/AvarianKnight) Original creator of PMA Sirensync.
* [BerkieBb](https://github.com/BerkieBb) Maintained PMA Sirensync.
