--[[
	GMod i18n - Copyright Notice
	© 2023 Thomas O'Sullivan - All rights reserved

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <https://www.gnu.org/licenses/>.
--]]

local VERSION = 200000 --LuaJIT style
if i18n and i18n.Version >= VERSION then
    return
end

i18n = {
    Version = VERSION,
    _addons = i18n and i18n._addons or {}
}

local overrideLanguage, gmodLanguage
do
    overrideLanguage = CreateConVar("i18n_language", "", FCVAR_ARCHIVE,
            "The language to use for i18n translations."):GetString()
    gmodLanguage = GetConVar("gmod_language"):GetString()

    cvars.AddChangeCallback("i18n_language", function(_, _, newValue)
        overrideLanguage = newValue
    end, "i18n.OverrideLanguage")

    cvars.AddChangeCallback("gmod_language", function(_, _, newValue)
        gmodLanguage = newValue
    end, "i18n.GModLanguage")

    --- Gets the override language configured for translations.
    --- @treturn string language The override language (empty string when unset).
    function i18n.GetLanguage()
        return overrideLanguage
    end
end

--- @class Phrase
local Phrase = {}
Phrase.__index = Phrase
Phrase._isPhrase = true
do
    --- Creates a new phrase.
    --- @tparam string id The phrase identifier.
    --- @tparam string template The phrase template.
    --- @tparam[opt] table fallbacks Fallback replacements for template keys.
    --- @treturn Phrase phrase The created phrase.
    function Phrase.New(id, template, fallbacks)
        assert(isstring(id), "The phrase identifier must be a string.")
        assert(isstring(template), "The phrase template must be a string.")
        assert(istable(fallbacks) or fallbacks == nil, "The phrase fallback replacements must be a table or nil.")

        local phrase = setmetatable({}, Phrase)
        phrase._identifier = id
        phrase._template = template
        phrase._fallbacks = fallbacks or {}
        return phrase
    end

    --- Gets the phrase identifier.
    --- @treturn string id The phrase identifier.
    function Phrase:GetIdentifier()
        return self._identifier
    end

    --- Gets the phrase template.
    --- @treturn string template The phrase template.
    function Phrase:GetTemplate()
        return self._template
    end

    --- Gets the fallback replacements for template keys.
    --- @treturn table fallbacks The fallback replacements.
    function Phrase:GetFallbacks()
        return self._fallbacks
    end

    local REPLACEMENT_PATTERN = "#(%w+)"
    --- Builds the phrase string with replacements.
    --- @tparam[opt] table replacements Replacement values keyed by token.
    --- @treturn string value The rendered phrase.
    function Phrase:GetString(replacements)
        if replacements then
            return self._template:gsub(REPLACEMENT_PATTERN, function(key)
                return replacements[key] or self._fallbacks[key] or key
            end)
        else
            return self._template:gsub(REPLACEMENT_PATTERN, self._fallbacks)
        end
    end
end

--- @class Translation
local Translation = {}
Translation.__index = Translation
Translation._isTranslation = true
do
    --- Creates a new translation.
    --- @tparam string language The language code.
    --- @tparam[opt] string author The translation author.
    --- @treturn Translation translation The created translation.
    function Translation.New(language, author)
        assert(isstring(language), "The translation language must be a string.")
        assert(isstring(author) or author == nil, "The translation author must be a string or nil.")

        local translation = setmetatable({}, Translation)
        translation._language = language
        translation._author = author
        translation._phrases = {}
        return translation
    end

    --- Gets the translation language.
    --- @treturn string language The language code.
    function Translation:GetLanguage()
        return self._language
    end

    --- Gets the translation author.
    --- @treturn string|nil author The translation author.
    function Translation:GetAuthor()
        return self._author
    end

    --- Gets the phrases for this translation.
    --- @treturn table phrases The phrase map keyed by identifier.
    function Translation:GetPhrases()
        return self._phrases
    end

    --- Gets a translated string by phrase identifier.
    --- @tparam string id The phrase identifier.
    --- @tparam[opt] table replacements Replacement values keyed by token.
    --- @treturn[opt] string value The translated string if found.
    function Translation:GetString(id, replacements)
        local phrase = self._phrases[id]
        if phrase then
            return phrase:GetString(replacements)
        end
    end

    --- Adds a phrase to the translation.
    --- @tparam Phrase|string phraseOrId Phrase instance or phrase identifier.
    --- @tparam[opt] string template The phrase template when providing an identifier.
    --- @tparam[opt] table fallbacks Fallback replacements when providing an identifier.
    --- @treturn Phrase phrase The added phrase.
    function Translation:AddPhrase(phraseOrId, template, fallbacks)
        local phrase
        if isstring(phraseOrId) then
            phrase = Phrase.New(phraseOrId, template, fallbacks)
        else
            assert(istable(phrase) and phrase._isPhrase, "The phrase must be a table of the Phrase type.")
            phrase = phraseOrId
        end

        self._phrases[phrase:GetIdentifier()] = phrase
        return phrase
    end
end

--- @class Addon
local Addon = {}
Addon.__index = Addon
Addon._isAddon = true
do
    --- Creates a new addon container.
    --- @tparam string name The addon name.
    --- @tparam[opt] string author The addon author.
    --- @tparam[opt] string fallbackLanguage The fallback language code.
    --- @treturn Addon addon The created addon.
    function Addon.New(name, author, fallbackLanguage)
        assert(isstring(name), "The addon name must be a string.")
        assert(isstring(author) or author == nil, "The addon author must be a string or nil.")
        assert(isstring(fallbackLanguage) or fallbackLanguage == nil, "The addon fallback language must be a string or nil.")

        local addon = setmetatable({}, Addon)
        addon._name = name
        addon._author = author
        addon._fallbackLanguage = fallbackLanguage or "en"
        addon._translations = {}
        return addon
    end

    --- Gets the addon name.
    --- @treturn string name The addon name.
    function Addon:GetName()
        return self._name
    end

    --- Gets the addon author.
    --- @treturn string|nil author The addon author.
    function Addon:GetAuthor()
        return self._author
    end

    --- Sets the addon author.
    --- @tparam[opt] string author The addon author.
    function Addon:SetAuthor(author)
        assert(isstring(author) or author == nil, "The addon author must be a string or nil.")
        self._author = author
    end

    --- Gets the fallback language code.
    --- @treturn string language The fallback language code.
    function Addon:GetFallbackLanguage()
        return self._fallbackLanguage
    end

    --- Sets the fallback language code.
    --- @tparam string fallbackLanguage The fallback language code.
    function Addon:SetFallbackLanguage(fallbackLanguage)
        assert(isstring(fallbackLanguage), "The addon fallback language must be a string.")
        self._fallbackLanguage = fallbackLanguage
    end

    --- Gets the translations for this addon.
    --- @treturn table translations The translation map keyed by language.
    function Addon:GetTranslations()
        return self._translations
    end

    --- Gets a translated string by phrase identifier.
    --- @tparam string id The phrase identifier.
    --- @tparam[opt] table replacements Replacement values keyed by token.
    --- @treturn string value The resolved string.
    function Addon:GetString(id, replacements)
        for i = overrideLanguage == "" and 2 or 1, 3 do
            local translation
            if i == 1 then
                translation = self._translations[overrideLanguage]
            elseif i == 2 then
                translation = self._translations[gmodLanguage]
            else
                translation = self._translations[self._fallbackLanguage]
            end

            if translation then
                local result = translation:GetString(id, replacements)
                if result then
                    return result
                end
            end
        end

        for _, translation in pairs(self._translations) do
            local result = translation:GetString(id, replacements)
            if result then
                return result
            end
        end

        return "#" .. id
    end
    --- Allows addon instances to be called to resolve strings.
    --- @tparam string id The phrase identifier.
    --- @tparam[opt] table replacements Replacement values keyed by token.
    --- @treturn string value The resolved string.
    Addon.__call = Addon.GetString

    --- Adds a translation to the addon.
    --- @tparam string language The language code.
    --- @tparam[opt] string author The translation author.
    --- @treturn Translation translation The created translation.
    function Addon:AddTranslation(language, author)
        local translation = Translation.New(language, author)
        self._translations[language] = translation
        return translation
    end
end

--- Gets a registered addon by name.
--- @tparam string name The addon name.
--- @treturn[opt] Addon addon The addon if registered.
function i18n.GetAddon(name)
    assert(isstring(name), "The addon name must be a string.")
    return i18n._addons[name]
end

--- Registers or updates an addon.
--- @tparam string name The addon name.
--- @tparam[opt] string author The addon author.
--- @tparam[opt] string fallbackLanguage The fallback language code.
--- @treturn Addon addon The registered addon.
function i18n.RegisterAddon(name, author, fallbackLanguage)
    assert(isstring(name), "The addon name must be a string.")

    local addon = i18n._addons[name]
    if addon then
        addon:SetAuthor(author)
        addon:SetFallbackLanguage(fallbackLanguage)
    else
        addon = Addon.New(name, author, fallbackLanguage)
        i18n._addons[name] = addon
    end

    return addon
end

--- Registers a translation for an addon.
--- @tparam string addonName The addon name.
--- @tparam string language The language code.
--- @tparam[opt] string author The translation author.
--- @treturn Translation translation The registered translation.
function i18n.RegisterTranslation(addonName, language, author)
    local addon = i18n.GetAddon(addonName)
    if not addon then
        addon = i18n.RegisterAddon(addonName)
    end

    return addon:AddTranslation(language, author)
end

hook.Run("i18n.FullyLoaded", VERSION)
