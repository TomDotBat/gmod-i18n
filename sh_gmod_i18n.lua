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

    function i18n.GetLanguage()
        return overrideLanguage
    end
end

local Phrase = {}
Phrase.__index = Phrase
Phrase._isPhrase = true
do
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

    function Phrase:GetIdentifier()
        return self._identifier
    end

    function Phrase:GetTemplate()
        return self._template
    end

    function Phrase:GetFallbacks()
        return self._fallbacks
    end

    local REPLACEMENT_PATTERN = "#(%w+)"
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

local Translation = {}
Translation.__index = Translation
Translation._isTranslation = true
do
    function Translation.New(language, author)
        assert(isstring(language), "The translation language must be a string.")
        assert(isstring(author) or author == nil, "The translation author must be a string or nil.")

        local translation = setmetatable({}, Translation)
        translation._language = language
        translation._author = author
        translation._phrases = {}
        return translation
    end

    function Translation:GetLanguage()
        return self._language
    end

    function Translation:GetAuthor()
        return self._author
    end

    function Translation:GetPhrases()
        return self._phrases
    end

    function Translation:GetString(id, replacements)
        local phrase = self._phrases[id]
        if phrase then
            return phrase:GetString(replacements)
        end
    end

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

local Addon = {}
Addon.__index = Addon
Addon._isAddon = true
do
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

    function Addon:GetName()
        return self._name
    end

    function Addon:GetAuthor()
        return self._author
    end

    function Addon:SetAuthor(author)
        assert(isstring(author) or author == nil, "The addon author must be a string or nil.")
        self._author = author
    end

    function Addon:GetFallbackLanguage()
        return self._fallbackLanguage
    end

    function Addon:SetFallbackLanguage(fallbackLanguage)
        assert(isstring(fallbackLanguage), "The addon fallback language must be a string.")
        self._fallbackLanguage = fallbackLanguage
    end

    function Addon:GetTranslations()
        return self._translations
    end

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
    Addon.__call = Addon.GetString

    function Addon:AddTranslation(language, author)
        local translation = Translation.New(language, author)
        self._translations[language] = translation
        return translation
    end
end

function i18n.GetAddon(name)
    assert(isstring(name), "The addon name must be a string.")
    return i18n._addons[name]
end

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

function i18n.RegisterTranslation(addonName, language, author)
    local addon = i18n.GetAddon(addonName)
    if not addon then
        addon = i18n.RegisterAddon(addonName)
    end

    return addon:AddTranslation(language, author)
end

hook.Run("i18n.FullyLoaded", VERSION)