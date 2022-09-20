local MESSAGE_PREFIX = "FORGE"
local playerName = UnitName("player")
local listeners = {}
local listenerIndex = {}
local awaitingMessage = {}
FORGE = {}

FieldType = {
    NUMBER = "NUM",
    BOOL = "BOOL"
}

PereqReqirementType =
{
    ALL = 0,
    ONE = 1
};

SpecVisibility =
{
    PRIVATE = "0",
    FRIENDS = "1",
    GUILD = "2",
    PUBLIC = "3"
}

GameModeRewardType = {
    Mount = "0",
    Title = "1",
    Item = "2"
}

CharacterPointType = {
    TALENT_SKILL_TREE = "0",
    FORGE_SKILL_TREE = "1",
    SPEC_COUNT = 2,
    PRESTIGE_TREE = "3",
    RACIAL_TREE = "4",
    SKILL_PAGE = "5",
    PRESTIGE_COUNT = "6",
    LEVEL_10_TAB = "7"
}

ForgeTopic = {
    -- Message Content: tabid
    GET_TALENTS = 0,
    -- Message Content: tabid;talentId
    LEARN_TALENT = 1,
    -- Message Content: tabid;talentId
    -- a single talent.
    UNLEARN_TALENT = 2,
    -- Message Content: CharacterPointType
    -- will re-send all talents with GET_TALENTS topic if sucsessful
    RESPEC_TALENTSS = 3,
    RESPEC_TALENT_ERROR = 4,
    UPDATE_SPEC = 5,
    -- Message Content: specId
    ACTIVATE_SPEC = 6,
    PRESTIGE = 7,
    TalentTree_LAYOUT = 8,
    GET_SHOP_ITEMS = 9,
    UPDATE_SPEC_ERROR = 10,
    ACTIVATE_SPEC_ERROR = 11,
    LEARN_TALENT_ERROR = 12,
    BUY_ITEM_ERROR = 13,
    UNLEARN_TALENT_ERROR = 14,
    GET_TALENT_ERROR = 15,
    BUY_ITEMS = 16,
    GET_ITEM_FROM_COLLECTION = 17,
    GET_PLAYER_COLLECTION = 18,
    GET_SHOP_LAYOUT = 19,
    HOLIDAYS = 20,
    GET_CHARACTER_SPECS = 21,
    PRESTIGE_ERROR = 22,
    ACTIVATE_CLASS_SPEC = 23,
    ACTIVATE_CLASS_SPEC_ERROR = 24,
    GET_TOOLTIPS = 25,
    FORGET_TOOLTIP = 26,
    GET_GAME_MODES = 27,
    SET_GAME_MODES = 28,
    SET_GAME_MODES_ERROR = 29,
    END_GAME_MODES = 30,
    COLLECTION_INIT = 31,
    OUTFIT_COST = 32,
    LOAD_XMOG_SET = 33,
    LOAD_XMOG_SET_ERROR = 34,
    SEARCH_XMOG = 35,
    LOAD_XMOG = 36,
    LOAD_MOUNTS = 37,
    LOAD_PETS = 38,
    LOAD_TOYS = 39,
    LOAD_HEIRLOOM = 40,
    MISSING_XMOG = 41,
    PREVIEW_XMOG = 42,
    PLAYER_XMOG = 43,
    LEARN_MOUNT = 44,
    USE_TOY = 45,
    GET_XMOG_COST = 46,
    APPLY_XMOG = 47,
    REMOVE_XMOG_SET = 48,
    SAVE_XMOG_SET = 49,
    RENAME_XMOG_SET = 50,
    MAX_OUTFITS = 51,
    COLLECTION_SETUP_STARTED = 52,
    COLLECTION_SETUP_FINISHED = 53,
    ADD_XMOG = 54,
    APPLY_XMOG_ERROR = 55,
}

-- These are the object definitions. Keyed by the same forge topic key.
SerializerDefinitions =
{
    BUY_ITEMS = {
        OBJECT = ";",
        FIELDS = {
            DELIMITER = "^",
            FIELDS = {
                {
                    NAME = "ShopItemId",
                },
                {
                    NAME = "Amount",
                }
            }
        }
    },
    UPDATE_SPEC = {
        DELIMITER = ";",
        FIELDS = {
            {
                NAME = "Id",
            },
            {
                NAME = "Name",
            },
            {
                NAME = "Description",
            },
            {
                NAME = "Active",
            },
            {
                NAME = "SpellIconId",
            },
            {
                NAME = "Visability",
            },
        }
    }
}

-- These are the object definitions. Keyed by the same forge topic key.
DeserializerDefinitions =
{
    LOAD_TOYS ={
        NAME = "Toys",
        OBJECT = ";",
        FIELDS = {
            DELIMITER = "^",
            FIELDS = {
                {
                    NAME = "ID",
                    TYPE = FieldType.NUMBER
                },
                {
                    NAME = "itemID",
                    TYPE = FieldType.NUMBER
                },
                {
                    NAME = "flags",
                    TYPE = FieldType.NUMBER
                },
                {
                    NAME = "expansion",
                    TYPE = FieldType.NUMBER
                },
                {
                    NAME = "sourceType",
                    TYPE = FieldType.NUMBER
                },
                {
                    NAME = "sourceText",
                },
                {
                    NAME = "holiday",
                    TYPE = FieldType.NUMBER
                }
            }
        }
    },
    LOAD_XMOG ={
        OBJECT = ";", -- ItemId
        DICT = "~",
        TYPE = FieldType.NUMBER,
        FIELDS = {
            DELIMITER = "^",
            FIELDS = {
                {
                    NAME = "InventoryType",
                    TYPE = FieldType.NUMBER
                },
                {
                    NAME = "SourceQuests",
                    OBJECT = ",",
                    TYPE = FieldType.NUMBER
                },
                {
                    NAME = "SourceBosses",
                    OBJECT = "$",
                    TYPE = FieldType.NUMBER
                },
                {
                    NAME = "Holiday",
                    TYPE = FieldType.NUMBER
                },
                {
                    NAME = "Camera",
                    TYPE = FieldType.NUMBER
                },
                {
                    NAME = "Unusable",
                    TYPE = FieldType.BOOL
                },
                {
                    NAME = "Unobtainable",
                    TYPE = FieldType.BOOL
                },
                {
                    NAME = "Weapon",
                    TYPE = FieldType.BOOL
                },
                {
                    NAME = "Enchantable",
                    TYPE = FieldType.BOOL
                },
                {
                    NAME = "Armor",
                    TYPE = FieldType.NUMBER
                },
                {
                    NAME = "SourceMask",
                    TYPE = FieldType.NUMBER
                },
                {
                    NAME = "ClassMask",
                    TYPE = FieldType.NUMBER
                },
                {
                    NAME = "RaceMask",
                    TYPE = FieldType.NUMBER
                },
                {
                    NAME = "Icon",
                    TYPE = FieldType.NUMBER
                }
            }
        }
    },
    HOLIDAYS = {
        NAME = "HOLIDAYS",
        OBJECT = ";",
        DICT = "~"
    },
    PLAYER_XMOG = {
        NAME = "Xmog",
        OBJECT = ";",
        DICT = "~"
    },
    GET_TOOLTIPS = {
        OBJECT = ";",
        FIELDS = {
            DELIMITER = "#",
            FIELDS = {
                {
                    NAME = "Id",
                },
                {
                    NAME = "AddedTooltipEffects",
                    OBJECT = "%",
                },
                {
                    NAME = "Tokens",
                    OBJECT = "*",
                    DICT = "~" -- will build dict of basic KVP without fields defined.
                }
            }
        }
    },
    GET_GAME_MODES = {
        OBJECT = ";",
        FIELDS = {
            DELIMITER = "^",
            FIELDS = {
                {
                    NAME = "GameMode",
                },
                {
                    NAME = "Rewards",
                    OBJECT = "*",
                    FIELDS = {
                        DELIMITER = "&",
                        FIELDS = {
                            {
                                NAME = "RewardType",
                            },
                            {
                                NAME = "Entry",
                            }
                        }
                    }
                }
            }
        }
    },
    GET_PLAYER_COLLECTION_LAYOUT = {
        OBJECT = ";",
        FIELDS = {
            DELIMITER = "^",
            FIELDS = {
                {
                    NAME = "Id",
                },
                {
                    NAME = "Name",
                },
                {
                    NAME = "Description",
                },
                {
                    NAME = "SpellIcon",
                },
                {
                    NAME = "Subcategories",
                    OBJECT = "*",
                    FIELDS = {
                        DELIMITER = "&",
                        FIELDS = {
                            {
                                NAME = "Id",
                            },
                            {
                                NAME = "Category",
                            },
                            {
                                NAME = "Name",
                            },
                            {
                                NAME = "Description",
                            },
                            {
                                NAME = "SpellIcon",
                            }
                        }
                    }
                }
            }
        }
    },
    GET_SHOP_LAYOUT = {
        OBJECT = ";",
        FIELDS = {
            DELIMITER = "^",
            FIELDS = {
                {
                    NAME = "Id",
                },
                {
                    NAME = "Name",
                },
                {
                    NAME = "Description",
                },
                {
                    NAME = "SpellIcon",
                },
                {
                    NAME = "Subcategories",
                    OBJECT = "*",
                    FIELDS = {
                        DELIMITER = "&",
                        FIELDS = {
                            {
                                NAME = "Id",
                            },
                            {
                                NAME = "Category",
                            },
                            {
                                NAME = "Name",
                            },
                            {
                                NAME = "Description",
                            },
                            {
                                NAME = "SpellIcon",
                            },
                            {
                                NAME = "Items",
                                OBJECT = "@",
                                FIELDS = {
                                    DELIMITER = "$",
                                    FIELDS = {
                                        {
                                            NAME = "Id",
                                        },
                                        {
                                            NAME = "Category",
                                        },
                                        {
                                            NAME = "Subcategory",
                                        },
                                        {
                                            NAME = "Name",
                                        },
                                        {
                                            NAME = "Description",
                                        },
                                        {
                                            NAME = "SpellIcon",
                                        },
                                        {
                                            NAME = "Image",
                                        },
                                        {
                                            NAME = "Cost",
                                        },
                                        {
                                            NAME = "SaleCost",
                                        },
                                        {
                                            NAME = "OnSale",
                                        },
                                        {
                                            NAME = "Listed",
                                        },
                                        {
                                            NAME = "ItemContents",
                                            OBJECT = "<",
                                            FIELDS = {
                                                DELIMITER = ">",
                                                FIELDS = {
                                                    {
                                                        NAME = "ForgeShopItemId",
                                                    },
                                                    {
                                                        NAME = "ItemId",
                                                    },
                                                    {
                                                        NAME = "Amount",
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    },
    GET_PLAYER_COLLECTION = {
        NAME = "Collection",
        OBJECT = "%",
        DICT = "~" -- will build dict of basic KVP without fields defined.
    },
    GET_TALENTS = {
        OBJECT = ";",
        FIELDS = {
            DELIMITER = "^",
            FIELDS = {
                {
                    NAME = "TabId",
                },
                {
                    NAME = "PointType",
                },
                {
                    NAME = "Talents",
                    OBJECT = "*",
                    DICT = "~" -- will build dict of basic KVP without fields defined.
                }
            }
        }
    },
    LEARN_TALENT = {
        OBJECT = ";",
        FIELDS = {
            DELIMITER = "K",
            FIELDS = {
                {
                    NAME = "TabId",
                },
                {
                    NAME = "SpellId",
                },
                {
                    NAME = "CurrentRank",
                }
            }
        }
    },
    LEARN_SPELL_TALENT = {
        OBJECT = ";",
        FIELDS = {
            DELIMITER = "K",
            FIELDS = {
                {
                    NAME = "TabId",
                },
                {
                    NAME = "SpellId",
                },
                {
                    NAME = "CurrentRank",
                }
            }
        }
    },
    TalentTree_LAYOUT = {
        OBJECT = ";",
        FIELDS = {
            DELIMITER = "^",
            FIELDS = {
                {
                    NAME = "Id",
                },
                {
                    NAME = "Name",
                },
                {
                    NAME = "SpellIconId",
                },
                {
                    NAME = "Background",
                },
                {
                    NAME = "TalentType",
                },
                {
                    NAME = "TabIndex",
                },
                {
                    NAME = "Talents",
                    OBJECT = "*",
                    FIELDS = {
                        DELIMITER = "&",
                        FIELDS = {
                            {
                                NAME = "SpellId",
                            },
                            {
                                NAME = "ColumnIndex",
                            },
                            {
                                NAME = "RowIndex",
                            },
                            {
                                NAME = "RankCost",
                            },
                            {
                                NAME = "RequiredLevel",
                            },
                            {
                                NAME = "NumberOfRanks",
                            },
                            {
                                NAME = "PreReqType",
                            },
                            {
                                NAME = "Prereqs",
                                OBJECT = "@",
                                FIELDS = {
                                    DELIMITER = "$",
                                    FIELDS = {
                                        {
                                            NAME = "Talent",
                                        },
                                        {
                                            NAME = "TalentTabId",
                                        },
                                        {
                                            NAME = "RequiredRank",
                                        }
                                    }
                                }
                            },
                            {
                                NAME = "ExclusiveWith",
                                OBJECT = "!" -- with just object delimiter this will be treated as a list to the deserializer
                            },
                            {
                                NAME = "Ranks",
                                OBJECT = "%",
                                DICT = "~" -- will build dict of basic KVP without fields defined.
                            },
                            {
                                NAME = "UnleanSpellIds",
                                OBJECT = "`" -- with just object delimiter this will be treated as a list to the deserializer
                            }
                        }
                    }
                }
            }
        }

    },
    GET_CHARACTER_SPECS = {
        OBJECT = ";",
        FIELDS = {
            DELIMITER = "^",
            FIELDS = {
                {
                    NAME = "Id",
                },
                {
                    NAME = "Name",
                },
                {
                    NAME = "Description",
                },
                {
                    NAME = "Active",
                },
                {
                    NAME = "SpellIconId",
                },
                {
                    NAME = "Visability",
                },
                {
                    NAME = "CharacterSpecTabId",
                },
                {
                    NAME = "PointsSpent",
                    OBJECT = "%",
                    DICT = "~" -- will build dict of basic KVP without fields defined.
                },
                {
                    NAME = "TalentPoints",
                    OBJECT = "@",
                    FIELDS = {
                        DELIMITER = "$",
                        FIELDS = {
                            {
                                NAME = "CharacterPointType",
                            },
                            {
                                NAME = "AvailablePoints",
                            },
                            {
                                NAME = "Earned",
                            },
                            {
                                NAME = "MaxPointsForTree",
                            },
                            {
                                NAME = "MaxPoints",
                            }
                        }
                    }
                }
            }
        }
    },
}

--- Serializes a message
--- @param serializerDefinition table
--- @param obj table
--- @return string string The serialized string
--- @useage SerializeMessageerializeMessage(SerializerDefinitions.UPDATE_SPEC, obj)
function SerializeMessage(serializerDefinition, obj)
    local msg = ""

    msg = ResursiveSerilize(serializerDefinition, obj, msg)

    return msg;
end

--- @return string string The serialized string
function ResursiveSerilize(serializerDefinition, obj, msg)
    if serializerDefinition.OBJECT ~= nil then
        for i, f in ipairs(serializerDefinition.FIELDS) do
            if f.OBJECT ~= nil then
                msg = ResursiveSerilize(serializerDefinition, obj, msg)
            else
                for i, field in ipairs(serializerDefinition.FIELDS) do
                    if msg == "" then
                        msg = msg .. obj[field.NAME]
                    else
                        msg = msg .. f.DELIMITER .. obj[field.NAME]
                    end
                end
            end
        end
    elseif serializerDefinition.DELIMITER ~= nil and serializerDefinition.FIELDS ~= nil then
        for i, field in ipairs(serializerDefinition.FIELDS) do

            if msg == "" then
                msg = msg .. obj[field.NAME]
            else
                msg = msg .. serializerDefinition.DELIMITER .. obj[field.NAME]
            end

        end
    end

    return msg;
end

--- Deserializes a message
--- @param deserializerDefinition table
--- @param msg string
--- @return table Object deserialized message
--- @useage local listOfObjects = DeserializeMessage(DeserializerDefinitions.GET_SPELL_TALENTS, message)
function DeserializeMessage(deserializerDefinition, msg)
    if deserializerDefinition == nil or deserializerDefinition.OBJECT == nil then
        return {}
    end
    local objects = {}

    if (deserializerDefinition.DICT ~= nil) then
        objects = ParseObjectPart(objects, msg, deserializerDefinition)
    else
        local serializedObjs = ForgeSplit(deserializerDefinition.OBJECT, msg)

        if deserializerDefinition.FIELDS ~= nil then
            for i, objStr in ipairs(serializedObjs) do
                local obj = {}
                obj = ParseObjectPart(obj, objStr, deserializerDefinition.FIELDS)
                objects[i] = obj
            end
        else
            if deserializerDefinition.TYPE ~= nil then
                for i, objStr in ipairs(serializedObjs) do
                    objects[i] = ParseType(deserializerDefinition, objStr)
                end
            else
                objects = serializedObjs;
            end
        end
    end

    return objects

end

--- internal for deserializer.
function ParseObjectPart(obj, objStr, fields)
    if fields == nil then
        return obj;
    end

    if fields.DICT ~= nil then
        local dict = {}
        local kvps = ForgeSplit(fields.OBJECT, objStr)

        for i, str in ipairs(kvps) do
            local kvp = ForgeSplit(fields.DICT, str)
            if kvp[1] then
                local key = kvp[1];
                local val = kvp[2];

                if fields.TYPE ~= nil then
                    key = ParseType(fields, kvp[1]);
                end
                
                if fields.FIELDS ~= nil then
                    val = {}
                    val = ParseObjectPart(val, fields.FIELDS, kvp[2])
                end

                dict[key] = val;  -- regular kvp of dict
            end
        end

        if fields.NAME ~= nil then
            obj[fields.NAME] = dict
        else
            obj = dict
        end

    elseif fields.OBJECT ~= nil then
        obj[fields.NAME] = DeserializeMessage(fields, objStr);  -- list of objects
    elseif fields.NAME ~= nil then
        if fields.TYPE ~= nil then
            obj[fields.NAME] = ParseType(fields, objStr)
        else
            obj[fields.NAME] = objStr;  -- field
        end
    else
        local splitFields = ForgeSplit(fields.DELIMITER, objStr);
        for j, fldStr in ipairs(splitFields) do
            obj = ParseObjectPart(obj, fldStr, fields.FIELDS[j])
        end
    end

    return obj;
end

function ParseType(fields, objStr)
    if fields.TYPE then
        if fields.TYPE == FieldType.NUMBER then
            if objStr then
                return tonumber(objStr) or 0;
            else
                return 0;
            end
        elseif fields.TYPE == FieldType.BOOL then
            if objStr and objStr == "1" then
                return true;
            else
                return false;
            end
        end
    end
    
end

--- Subscribes to a topic
--- @param topic integer
--- @param listener function
--- @return nil nil Void return
function SubscribeToForgeTopic(topic, listener)
    if listeners[topic] == nil then
        listeners[topic] = {}
    end

    if listenerIndex[topic] == nil then
        listenerIndex[topic] = 0
    end

    local currentIndex = listenerIndex[topic]
    listeners[topic][currentIndex] = listener
    listenerIndex[topic] = currentIndex + 1
end

--- Sends a message to the server, ForgeTopic has descriptors on each enum value for what the message contents should be
--- @param topic integer
--- @param msg string
--- @return nil nil Void return
function PushForgeMessage(topic, msg)
    if not msg then return end
    msg = tostring(msg)
    SendAddonMessage(MESSAGE_PREFIX, topic .. ":" .. msg, "WHISPER", playerName)
end

local fs = CreateFrame("Frame")
fs:RegisterEvent("CHAT_MSG_ADDON")
fs:SetScript("OnEvent",
    function(self, event, ...)
        local prefix, msg, msgType, sender = ...
        if event == "CHAT_MSG_ADDON" then
            if prefix ~= MESSAGE_PREFIX or msgType ~= "WHISPER" then
                return
            end
            local split = ForgeSplit(":", msg)
            local numberStartIndex = string.find(split[1], "}")
            local messageContent = split[2]
            if numberStartIndex then
                local headerSplit = ForgeSplit("}", split[1]) -- we got a big message, its coming in parts.
                local topic = tonumber(headerSplit[1])
                local messageNuber = tonumber(headerSplit[2])
                local numberOfMessages = tonumber(headerSplit[3])
                
                if awaitingMessage[topic] == nil then
                    awaitingMessage[topic] = {}
                end

                if awaitingMessage[topic][messageNuber] == nil then
                    awaitingMessage[topic][messageNuber] = {}
                end

                awaitingMessage[topic][messageNuber]["messageNuber"] = messageNuber
                awaitingMessage[topic][messageNuber]["numberOfMessages"] = numberOfMessages
                awaitingMessage[topic][messageNuber]["messageContent"] = messageContent

                local numMsg = table.getn(awaitingMessage[topic])

                if numMsg == numberOfMessages then

                    local entireMessage = "";

                    for i = 1, numberOfMessages, 1 do
                        entireMessage = entireMessage .. awaitingMessage[topic][i]["messageContent"];
                    end

                    table.remove(awaitingMessage, topic); --remove messages from queue
                    if listeners[topic] ~= nil then
                        for k, topicListener in pairs(listeners[topic]) do
                            topicListener(entireMessage)
                        end
                    end
                end

            else
                local topic = tonumber(split[1]);
                if listeners[topic] ~= nil then
                    for k, topicListener in pairs(listeners[topic]) do
                        topicListener(messageContent)
                    end
                end
            end
        end
    end
)


function SplitByChunk(text, chunkSize)
    local s = {}
    for i = 1, #text, chunkSize do
        s[#s + 1] = strsub(text, i, i + chunkSize - 1)
    end

    return s
end

-- This will sort by key and itterate over the key
function PairsByKeys(t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0 -- iterator variable
    local iter = function() -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
    end
    return iter
end

function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

function ForgeSplit(delim, str)
    local t = {};
    local part = "";

    for i = 1, #str do
        local c = str:sub(i, i)

        if c == delim then
            table.insert(t, part);
            part = "";
        else
            part = part .. c;
        end
    end

    if part ~= "" then
        table.insert(t, part);
    end

    return t;
end