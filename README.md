# Tom's i18n library
This library's purpose is to make multi-language support for your addons easier.

# How to implement
- Put the `sh_tom_i18n.lua` file in your addon somewhere (feel free to rename this), making sure your loader loads it before any language files you add.
- Define your addon by calling [`gmodI18n.registerAddon`](https://github.com/TomDotBat/gmod-i18n/tree/master#gmodi18nregisteraddon).
- In your language files use a similar structure to this:
```lua
local lang = gmodI18n.registerLanguage("myTestAddon", "en", "Tom.bat", 1)
lang:addPhrase("helloWorld", "Hello world, my name is #name!", {name = "N/A"})
lang:addPhrase("helloWorldNoName", "Hello world!")
```
- When you need to use a translated string in your addon, you can do it like so:
```lua
local lang = gmodI18n.getAddon("myTestAddon") --Cache the translations at the start of the file

--Somewhere later in the file...
print(lang:getString("helloWorld", {name = "Tom.bat"}))
print(lang:getString("helloWorld")) --Fallback data will be shown
print(lang:getString("helloWorldNoName"))
```

# FAQ
- **Q: All of my text says `ERROR CODE: {NO}`, what's causing this?**
  - A: Reference the [error codes section](https://github.com/TomDotBat/gmod-i18n/tree/master#error-codes).
- **Q: My game is using the wrong language, how do I fix this?**
  - A: In your console, enter `i18n_override_language {your preferred language code}`, if this doesn't work, the addon your using might not have a translation available for your desired language.
- **Q: I'm having problems with the libary, where can I get help?**
  - A: Make an issue on this repository, clearly describing the issue you are having. Remember, this library is free for you to modify and use to your liking, so don't complain if it takes a long time to fix your problem.
- **Q: I have a feature I'd have implemented, where should I post my idea?**
  - A: If you know how to implement it yourself, feel free to make a pull request with the changes your feature idea requires. Otherwise, make an issue on this repository and your ideawill be considered.
- **Q: Are pull requests welcomed?**
  - A: Yes! Feel free to improve on the code, add features to the library or fix any bugs I may not have found.

# Global functions
## gmodI18n.registerAddon
```lua
gmodI18n.registerAddon(identifier :: any, fallbackLang :: string, name :: string, author :: string, version :: number) :: addon
```
This registers an addon for usage with gmod-i18n. While calling this function isn't actually required, it is recommended so the correct information is shown on the loading message.
- The identifier of the addon you are registering must be unique. You can identify it using any type of variable, but it is best to use a string.
- The fallback language is optional but recommeneded, this should be the language code of the language you want your addon to fall back to.
- The name should be the nice looking name of your addon, this will appear in the loading message of the libary. This is an optional argument.
- The author should be the name of the author, development team of your addon. This is an optional argument.
- The version should be a number that represents the current version of your addon. This is an optional argument.

## gmodI18n.registerLanguage
```lua
gmodI18n.registerLanguage(addonId :: any, languageCode :: string, author :: string, version :: number) :: language
```
This registers and returns a language for a specified addon and stores additional information about the translation.
- The addon ID should be the identifier of the addon you're registering a language for.
- The language code should be the code the `gmod_language` convar uses for the language you are trying to register.
- The author should be the name of the person/people who translated the addon to the specified language. This appears in the loading message. This is an optional argument.
- The version should be a number that represents the current version of the addon translation. This appears in the loading message. This is an optional argument.

## gmodI18n.getAddon
```lua
gmodI18n.getAddon(addonId :: any) :: addon
```
This function is used for getting an addon object from a certain identifier.
- The addon ID should be the identifier of the addon you're trying to get.

## gmodI18n.getLanguageCode
```lua
gmodI18n.getLanguageCode() :: string
```
This function returns the language code that gmod-i18n is using to get language strings with. This is also affected by the `i18n_override_language` convar.

# Language metamethods
## language:addPhrase
```lua
language:addPhrase(identifier :: string, phrase :: string, fallbackData :: table) :: phrase
```
This creates and returns a phrase object and attaches it to the language object
- The identifier should be a unique to the phrase.
- The phrase should contain your translated sentence with placeholders. Placeholders start with a '#' and should be unique.
- The fallback data should be an associative table with the placeholder being the key and the value being the fallback string. This is an optional argument.

## language:getString
```lua
language:getString(identifier :: string, data :: table) :: string
```
This returns a formed language string using the phrase specified.
- The identifier is the identification string that was used to define the phrase you're trying to get.
- The data should be an associative table with the placeholder being the key and the value being the fallback string. This is an optional argument.

# Addon metamethods
## addon:getString
```lua
addon:getString(identifier :: string, data :: table) :: string
```
This will return a formed language string from an addon. This function should always return a string. The language is automatically determined by calling `gmodI18n.getLanguageCode()`.
- The identifier is the identification string that was used to define the phrase you're trying to get.
- The data should be an associative table with the placeholder being the key and the value being the fallback string. This is an optional argument.

# Error codes
### 1 - Language not found, no fallback language set for this addon.
  This error will happen if the language you are using isn't available for the addon you're using.
  You should recommend to the author that they set a fallback language for their addon in this instance.
### 2 - Language not found, fallback language not found.
  This error will occur if the language your client uses doesn't exist for the addon and its fallback language couldn't be found.
  If this happens you should report this to the author of the addon.
### 3 - Phrase not found in both specified langauge and fallback language.
  This means the phrase the library is looking for hasn't been set.
  It is recommended that you tell the author about the missing string in this situation.
### 4 - Phrase not found in specified langauge, fallback language not found.
  This means the phrase the library is trying to look for isn't available in your language and a fallback language isn't set.
  In this case, it is recommened that you tell the author of the addon that a phrase is missing and that they should set up a fallback language.
