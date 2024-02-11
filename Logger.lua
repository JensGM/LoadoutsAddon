Loadouts.colorScheme = {
    white = "FFFFFF",
    cyan = "00E7F0",
    blue = "0050F0",
    lightBlue = "009DF0",
    teal = "00F0A7",
    darkBlue = "0004F0",
    skyBlue = "56BAF0",
}

for color, hex in pairs(Loadouts.colorScheme) do
    Loadouts[color] = hex
end

Loadouts.LogLevel = Loadouts.LogLevel or {}
Loadouts.LogLevel.__index = Loadouts.LogLevel
Loadouts.LogLevel.__eq = function(a, b)
    return a.value == b.value
end
Loadouts.LogLevel.__lt = function(a, b)
    return a.value < b.value
end
Loadouts.LogLevel.__eq = function(a, b)
    return a.value == b.value
end

function Loadouts.LogLevel:new(name, value, color)
    local self = setmetatable({}, Loadouts.LogLevel)
    self.name = name
    self.value = value
    self.color = color
    return self
end

Loadouts.logLevels = {
    error = Loadouts.LogLevel:new("error", 0, Loadouts.colorScheme.red),
    always = Loadouts.LogLevel:new("always", 1, Loadouts.colorScheme.white),
    info = Loadouts.LogLevel:new("info", 2, Loadouts.colorScheme.white),
    debug = Loadouts.LogLevel:new("debug", 3, Loadouts.colorScheme.skyBlue),
}

function Loadouts.toWowColor(hex)
    return "|cff" .. hex
end

function Loadouts.printToChat(msg, color)
    local colorCode = Loadouts.toWowColor(color or "ffffff")
    DEFAULT_CHAT_FRAME:AddMessage(colorCode .. msg .. "|r")
end

Loadouts.Logger = {}
Loadouts.Logger.__index = Loadouts.Logger

function Loadouts.Logger:new(logLevelName)
    local self = setmetatable({}, Loadouts.Logger)
    self.logLevel
        = Loadouts.logLevels[logLevelName]
        or Loadouts.logLevels.info
    self.tokenColors = {}
    return self
end

function Loadouts.Logger:token(token, color)
    self.tokenColors[token] = color
    return token
end

Loadouts.Log = {}
Loadouts.Log.__index = Loadouts.Log

function Loadouts.Log:new(logger, logLevel)
    local self = setmetatable({}, Loadouts.Log)
    self.logger = logger
    self.logLevel = logLevel
    self.buffer = {}
    self.lastLine = nil
    self.lastPart = nil
    self.indentString = "    "
    return self
end


function Loadouts.Logger:log(logLevelName)
    local logLevel = Loadouts.logLevels[logLevelName]
    if not logLevel then
        error("Invalid log level: " .. logLevelName)
    end
    return Loadouts.Log:new(self, logLevel)
end

function Loadouts.Log:newline()
    local indentLevel = 0
    if self.lastLine then
        indentLevel = self.lastLine.indentLevel
    end

    self.lastLine = {
        line = {},
        indentLevel = indentLevel,
    }
    table.insert(self.buffer, self.lastLine)
    return self
end

function Loadouts.Log:println(...)
    self:print(...)
    self:newline()
    return self
end

function Loadouts.Log:print(...)
    if not self.lastLine then
        self:newline()
    end

    local lastLine = self.buffer[#self.buffer]
    self.lastPart = {
        part = {...},
        color = self.logger.logLevel.color,
    }
    table.insert(lastLine.line, self.lastPart)

    return self
end

function Loadouts.Log:indent(levels)
    if not self.lastLine then
        self:newline()
    end

    local levels = levels or 1
    self.lastLine.indentLevel = math.max(0, self.lastLine.indentLevel + levels)
    return self
end

function Loadouts.Log:popIndent(levels)
    local levels = levels or 1
    self:indent(-levels)
    return self
end

function Loadouts.Log:as(token)
    local color = self.logger.tokenColors[token]
    return self:rgb(color)
end

function Loadouts.Log:rgb(color)
    if not color or not self.lastPart then
        return self
    end
    self.lastPart.color = color
    return self
end

function Loadouts.Log:flush()
    if self.logLevel > self.logger.logLevel then
        return self
    end

    local is_first = true
    local string = ""
    for _, line in ipairs(self.buffer) do
        if is_first then
            is_first = false
        else
            string = string .. "\n"
        end
        local indent = string.rep(self.indentString, line.indentLevel)
        string = string .. indent
        for _, part in ipairs(line.line) do
            local color = part.color or self.logger.logLevel.color
            string = string .. Loadouts.toWowColor(color)
            for _, part in ipairs(part.part) do
                string = string .. part
            end
            string = string .. "|r"
        end
    end

    -- strip trailing whitespace
    string = string:gsub("%s+$", "")

    Loadouts.printToChat(string)

    self.buffer = {}
    self.indentLevel = 0
    return self
end
