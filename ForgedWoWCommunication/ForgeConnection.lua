local playerName = UnitName("player")
local listeners = {}
local listenerIndex = {}
local awaitingMessage = {}

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

                dict[key] = val; -- regular kvp of dict
            end
        end

        if fields.NAME ~= nil then
            obj[fields.NAME] = dict
        else
            obj = dict
        end

    elseif fields.OBJECT ~= nil then
        obj[fields.NAME] = DeserializeMessage(fields, objStr); -- list of objects
    elseif fields.NAME ~= nil then
        if fields.TYPE ~= nil then
            obj[fields.NAME] = ParseType(fields, objStr)
        else
            obj[fields.NAME] = objStr; -- field
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
    if not msg then
        return
    end
    SendAddonMessage(MESSAGE_PREFIX, topic .. ":" .. tostring(msg), "WHISPER", playerName)
end

local fs = CreateFrame("Frame")
fs:RegisterEvent("CHAT_MSG_ADDON")
fs:SetScript("OnEvent", function(self, event, ...)
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

                table.remove(awaitingMessage, topic); -- remove messages from queue
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
end)

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
    for n in pairs(t) do
        table.insert(a, n)
    end
    table.sort(a, f)
    local i = 0 -- iterator variable
    local iter = function() -- iterator function
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
    return iter
end

function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
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
