local _0x0A3B = require('ffi')
local _0xA1BA = require('encoding')
_0xA1BA.default ='CP1251'local _0x1329 = _0xA1BA.UTF8local _0xA407, _0xEFB3 = pcall(require,'mimgui')
local _0x8AD0, _0x8553 = pcall(require,'fAwesome6')
if not _0xA407 or not _0x8AD0 then
local _0xF479 = {}
if not _0xA407 then _0xF479[#_0xF479 + 1] ="mimgui"end
if not _0x8AD0 then _0xF479[#_0xF479 + 1] ="fAwesome6"end
function main()
while not isSampAvailable() do wait(100) end
sampAddChatMessage(_0x1329:decode("{FF5555}[Arizona Prices] {FFFFFF}Не найдены библиотеки: {FFCC33}".. table.concat(_0xF479,", ") .."{FFFFFF}. Положите их в папку {FFCC33}moonloader\\lib{FFFFFF} и перезапустите игру."), -1)
sampAddChatMessage(_0x1329:decode("{FF5555}[Arizona Prices] {FFFFFF}Где скачать, смотрите в нашем ТГК: {33AAFF}@arizona_prices"), -1)
thisScript():unload()
end
return
endlocal _0xB914 = setmetatable({}, { __index = function(_0xEDD8, _0x22D5) return _0x8553[_0x22D5] or""end })
_0x0A3B.cdef[[
    int ShellExecuteA(void* hwnd, const char* op, const char* file, const char* params, const char* dir, int show);
]]local _0x9909 = _0x0A3B.load('shell32')
local _0xC2BA = nillocal function _0x091E(_0x4BB2)
_0xC2BA = _0x4BB2
end
local _0x950A = _0xEFB3.new.bool(false)
local _0xEEF6 = _0xEFB3.new.bool(false)
local _0xEB19 = _0xB914.CIRCLE_PLUS .." Добавить предмет###item_modal"local _0x91ED = _0xB914.PEN_LINE .." Редактировать предмет###item_modal"local _0x6ADB = _0xEFB3.new.char[256]()
local _0x30A6 = _0xEFB3.new.char[256]()
local _0xE69C = _0xEFB3.new.char[64]()
local _0x931A = _0xEFB3.new.char[64]()
local _0x0CCE = _0xEFB3.new.int(0)
local _0x0078 = false
local _0x0109 = nil
local _0x6B64 = false
local _0xF2E8 = false
local _0x9D23 = nil
local _0x3CD2 = nillocal _0xCCA7 = false
local _0x8BA4 = 0
local _0xFD3A = false
local _0x1AD5 = false
local _0xAE54 = false
local _0xE004 = {}
local _0x65A4 = getWorkingDirectory() .."\\config\\item_prices.json"local _0x6826 = {}
local function _0xBBE7(_0xF692, _0x53EC)
_0x6826[#_0x6826 + 1] = { _0xF692 = _0xF692, _0x53EC = _0x53EC }
end
local _0xE2F4 = {}
local function _0xFB09(_0xA49F)
return debug.traceback(tostring(_0xA49F), 2)
end
local function _0xC746(where, _0x7139)
local _0xF692 = tostring(_0x7139)
_0xE2F4[#_0xE2F4 + 1] = os.date("%H:%M:%S") .." [".. tostring(where) .."] ".. (_0xF692:sub(1, 300):gsub("%s+"," "))
if #_0xE2F4 > 8 then table.remove(_0xE2F4, 1) end
pcall(function()
print("[Arizona Prices] ".. tostring(where) ..": ".. _0xF692)
local _0xEEB2 = getWorkingDirectory() .."\\config"if not doesDirectoryExist(_0xEEB2) then createDirectory(_0xEEB2) end
local _0x374D = _0xEEB2 .."\\arizona_prices_errors.log"local _0xE8B2 = io.open(_0x374D,"ab")
if _0xE8B2 then
if (_0xE8B2:seek("end") or 0) > 200000 then
_0xE8B2:close()
_0xE8B2 = io.open(_0x374D,"wb")
end
if _0xE8B2 then
_0xE8B2:write(os.date("%Y-%m-%d %H:%M:%S") .." [".. tostring(where) .."] ".. _0xF692 .."\n\n")
_0xE8B2:close()
end
end
end)
endlocal function _0x2C6A(where, fn, ...)
local _0xECF9 = { ... }
local _0x054C, _0x7139 = xpcall(function() return fn(unpack(_0xECF9)) end, _0xFB09)
if not _0x054C then _0xC746(where, _0x7139) end
return _0x054C
endlocal _0x509E = {}
local function _0x5104(fn)
_0x509E[#_0x509E + 1] = fn
endlocal function _0xD9E5(_0x4D0B, fn, on_fail)
return function(...)
local _0xECF9 = { ... }
local _0x3CF1 = select("#", ...)
local _0x054C, _0x7139 = xpcall(function() return fn(unpack(_0xECF9, 1, _0x3CF1)) end, _0xFB09)
if not _0x054C then
_0xC746("frame:".. _0x4D0B, _0x7139)
_0xBBE7("Ошибка в окне (".. _0x4D0B .."). Откройте Настройки и нажмите «Сообщить об ошибке»","err")
if on_fail then pcall(on_fail) end
end
end
end
local function _0x7546(_0x374D)
local _0xE8B2 = io.open(_0x374D,"rb")
if not _0xE8B2 then return nil end
local _0x65BB = _0xE8B2:read("*a")
_0xE8B2:close()
return _0x65BB
end
local function _0x64B2(_0x374D, content)
local _0xE8B2 = io.open(_0x374D,"wb")
if not _0xE8B2 then return false end
local _0x054C = _0xE8B2:write(content)
_0xE8B2:close()
return _0x054C ~= nil and _0x054C ~= false
end
local function _0x90BB(str)
if type(str) ~="string"or str ==""then return false end
local _0x054C, _0xF60E = pcall(decodeJson, str)
return _0x054C and type(_0xF60E) =="table"endlocal function _0x35AE(_0x374D, content)
if type(content) ~="string"or content ==""then return false end
local _0x8CF1 = _0x374D ..".tmp"if not _0x64B2(_0x8CF1, content) then os.remove(_0x8CF1); return false end
if _0x7546(_0x8CF1) ~= content then os.remove(_0x8CF1); return false end
local _0x6792 = _0x7546(_0x374D)
if _0x6792 and _0x90BB(_0x6792) then _0x64B2(_0x374D ..".bak", _0x6792) end
os.remove(_0x374D)
if not os.rename(_0x8CF1, _0x374D) then
local _0x054C = _0x64B2(_0x374D, content)
os.remove(_0x8CF1)
return _0x054C
end
return true
endlocal function _0x5729(_0x374D)
local _0x65BB = _0x7546(_0x374D)
if _0x90BB(_0x65BB) then return decodeJson(_0x65BB) end
local _0x8AAA = _0x7546(_0x374D ..".bak")
if _0x90BB(_0x8AAA) then
if _0x65BB and _0x65BB ~=""then
_0xBBE7("Файл данных был повреждён - восстановили из резервной копии","warn")
_0x64B2(_0x374D ..".broken", _0x65BB)
end
_0x64B2(_0x374D, _0x8AAA)
return decodeJson(_0x8AAA)
end
if _0x65BB and _0x65BB ~=""then
_0x64B2(_0x374D ..".broken", _0x65BB)
_0xBBE7("Файл данных повреждён и копии нет - начинаем с чистого листа","err")
end
return nil
endlocal _0x9100 = {
on = false,
HASH = 888940931,
LIQ = { ["Ликвид"] = true, ["Средне"] = true, ["Неликвид"] = true },
_0x374D = getWorkingDirectory() .."\\config\\arizona_prices_admin.json",
}
function _0x9100.hash(_0x4390)
local _0xB814 ="arzp|".. tostring(_0x4390):lower()
local _0xCC7A = 5381
for _0x43EB = 1, #_0xB814 do _0xCC7A = (_0xCC7A * 33 + _0xB814:byte(_0x43EB)) % 4294967296 end
return _0xCC7A
end
function _0x9100.valid_liq(_0x0448)
if type(_0x0448) =="string"and _0x9100.LIQ[_0x0448] then return _0x0448 end
return nil
end
function _0x9100.enable(_0x4390)
if _0x9100.hash(_0x4390) ~= _0x9100.HASH then return false end
_0x9100.on = true
local _0xEEB2 = getWorkingDirectory() .."\\config"if not doesDirectoryExist(_0xEEB2) then createDirectory(_0xEEB2) end
_0x64B2(_0x9100.path, encodeJson({ hash = _0x9100.HASH }))
return true
end
function _0x9100.disable()
_0x9100.on = false
os.remove(_0x9100.path)
end
do
local _0xF60E = _0x5729(_0x9100.path)
if type(_0xF60E) =="table"and tonumber(_0xF60E.hash) == _0x9100.HASH then _0x9100.on = true end
end
local function _0x78D9()
local _0x9779 = _0x5729(_0x65A4)
if _0x9779 then
local _0xBF73 = {}
for _0xEDD8, _0x0448 in ipairs(_0x9779) do
if type(_0x0448) =="table"then
_0xBF73[#_0xBF73 + 1] = { _0xB96F = tostring(_0x0448.item or""), _0xA09E = tonumber(_0x0448.buy) or 0, _0x6932 = tonumber(_0x0448.sell) or 0, _0x5535 = _0x9100.valid_liq(_0x0448.liq) }
end
end
_0xE004 = _0xBF73
elseif not doesFileExist(_0x65A4) then
_0xE004 = {}
end
end
local function _0xA936()
local _0xEEB2 = getWorkingDirectory() .."\\config"if not doesDirectoryExist(_0xEEB2) then
createDirectory(_0xEEB2)
end
local _0x054C, _0xE79B = pcall(encodeJson, _0xE004)
if _0x054C and type(_0xE79B) =="string"and _0xE79B ~=""then
if not _0x35AE(_0x65A4, _0xE79B) then
_0xBBE7("Не удалось сохранить список предметов","err")
end
end
end
local function _0x3823(amount)
local _0x6ECC = tonumber(amount)
if not _0x6ECC then return tostring(amount) end
local _0xADD4 = _0x6ECC < 0 and"-"or""_0x6ECC = math.abs(_0x6ECC)
local _0xB814 = (_0x6ECC == math.floor(_0x6ECC)) and string.format("%.0f", _0x6ECC) or tostring(_0x6ECC)
local _0x3D93, _0x02BC = _0xB814:match("^(%d+)(.*)$")
if not _0x3D93 then return _0xADD4 .. _0xB814 end
_0x3D93 = _0x3D93:reverse():gsub("(%d%d%d)","%1."):reverse()
if _0x3D93:sub(1, 1) =="."then _0x3D93 = _0x3D93:sub(2) end
return _0xADD4 .. _0x3D93 .. _0x02BC
end
local function _0xE8BA(str)
local _0xC383, _0xEA9A = pcall(function() return _0x1329:decode(tostring(str or"")) end)
str = _0xC383 and _0xEA9A or tostring(str or"")
return (str:gsub(".", function(char)
local _0x11F9 = char:byte()
if _0x11F9 >= 192 and _0x11F9 <= 223 then
return string.char(_0x11F9 + 32)
elseif _0x11F9 == 168 then
return string.char(184)
end
return char:lower()
end))
end
local function _0x1DF1()
_0xEEF6[0] = false
_0xEFB3.CloseCurrentPopup()
end
local function _0x7044()
_0x0078 = false
_0x0109 = nil
_0xEFB3.StrCopy(_0x30A6,"")
_0xEFB3.StrCopy(_0xE69C,"")
_0xEFB3.StrCopy(_0x931A,"")
_0xEEF6[0] = true
_0x6B64 = true
end
local function _0x56AE(_0x9913)
local _0xB96F = _0xE004[_0x9913]
if not _0xB96F then return end
_0x0078 = true
_0x0109 = _0x9913
_0xEFB3.StrCopy(_0x30A6, _0xB96F.item or"")
_0xEFB3.StrCopy(_0xE69C, tostring(_0xB96F.buy or 0))
_0xEFB3.StrCopy(_0x931A, tostring(_0xB96F.sell or 0))
_0xEEF6[0] = true
_0x6B64 = true
endlocal _0xF228 = {
accent = {0.98, 0.55, 0.12}, opacity = 1.0, overlay_scale = 1.0, open_key = 0, _0x34EA = true, toast_corner = 3,
halloween = true,border_mode = 1, border_speed = 1.0, shadow = true, _0xC2B8 ="seguisb",
win_w = 835, win_h = 500, bg_fx = true, splash = true,
}local _0xDFF1 = {
_0x45CA = 0,_0x7173 = 1,base = 1,tab_t = -10,table_t = -10,was_open = false,
splashed = false,TAB_ORDER = { 1, 2, 3, 4, 8, 6, 5, 7 },}local _0x2132 = {
{ _0x15EA ="seguisb", _0x4D0B ="Segoe UI Semibold", file ="seguisb.ttf"},
{ _0x15EA ="segoeui", _0x4D0B ="Segoe UI", file ="segoeui.ttf"},
{ _0x15EA ="bahnschrift", _0x4D0B ="Bahnschrift", file ="bahnschrift.ttf"},
{ _0x15EA ="corbel", _0x4D0B ="Corbel", file ="corbel.ttf"},
{ _0x15EA ="candara", _0x4D0B ="Candara", file ="candara.ttf"},
{ _0x15EA ="calibri", _0x4D0B ="Calibri", file ="calibri.ttf"},
{ _0x15EA ="verdana", _0x4D0B ="Verdana", file ="verdana.ttf"},
{ _0x15EA ="tahoma", _0x4D0B ="Tahoma", file ="tahoma.ttf"},
}
local _0x36D7 = { { _0x15EA ="default", _0x4D0B ="Системный (Trebuchet)"} }
pcall(function()
local _0xEEB2 = getFolderPath(0x14)
for _0xEDD8, _0xE8B2 in ipairs(_0x2132) do
local _0x374D = _0xEEB2 .."\\".. _0xE8B2.file
if doesFileExist(_0x374D) then
_0x36D7[#_0x36D7 + 1] = { _0x15EA = _0xE8B2.key, _0x4D0B = _0xE8B2.name, _0x374D = _0x374D }
end
end
end)
local function _0xCD0C(_0xD40E, lo, hi)
return math.max(lo, math.min(hi, _0xD40E))
end
local function _0xBD61(mult, _0x45CA)
local _0xC5C6 = _0xF228.accent
local _0x7173 = mult or 1.0
return _0xEFB3.ImVec4(math.min(1, _0xC5C6[1] * _0x7173), math.min(1, _0xC5C6[2] * _0x7173), math.min(1, _0xC5C6[3] * _0x7173), _0x45CA or 1.0)
endlocal function _0xE27E(_0x2CC1, _0xCAFA, _0x8AAA, _0xC5C6)
return _0xEFB3.ColorConvertFloat4ToU32(_0xEFB3.ImVec4(_0x2CC1, _0xCAFA, _0x8AAA, _0xC5C6 * _0xDFF1.m))
end
local function _0xD2F6(_0xCC7A, _0xB814, _0x0448)
_0xCC7A = _0xCC7A % 1
local _0x43EB = math.floor(_0xCC7A * 6)
local _0xE8B2 = _0xCC7A * 6 - _0x43EB
local _0xBAC3, _0xC36F, _0xF27D = _0x0448 * (1 - _0xB814), _0x0448 * (1 - _0xE8B2 * _0xB814), _0x0448 * (1 - (1 - _0xE8B2) * _0xB814)
_0x43EB = _0x43EB % 6
if _0x43EB == 0 then return _0x0448, _0xF27D, _0xBAC3
elseif _0x43EB == 1 then return _0xC36F, _0x0448, _0xBAC3
elseif _0x43EB == 2 then return _0xBAC3, _0x0448, _0xF27D
elseif _0x43EB == 3 then return _0xBAC3, _0xC36F, _0x0448
elseif _0x43EB == 4 then return _0xF27D, _0xBAC3, _0x0448
end
return _0x0448, _0xBAC3, _0xC36F
end
local function _0x877D(_0x2CC1, _0xCAFA, _0x8AAA)
local _0x2A12, _0x8A00 = math.max(_0x2CC1, _0xCAFA, _0x8AAA), math.min(_0x2CC1, _0xCAFA, _0x8AAA)
local _0xF60E = _0x2A12 - _0x8A00
local _0xCC7A = 0
if _0xF60E > 0 then
if _0x2A12 == _0x2CC1 then _0xCC7A = ((_0xCAFA - _0x8AAA) / _0xF60E) % 6
elseif _0x2A12 == _0xCAFA then _0xCC7A = (_0x8AAA - _0x2CC1) / _0xF60E + 2
else _0xCC7A = (_0x2CC1 - _0xCAFA) / _0xF60E + 4 end
_0xCC7A = _0xCC7A / 6
end
return _0xCC7A, (_0x2A12 == 0) and 0 or _0xF60E / _0x2A12, _0x2A12
endlocal function _0x5822(_0xCAD9, _0xC5C6)
local _0x4CF0 = _0xF228.accent
if _0xF228.halloween then
return _0xEFB3.ImVec4(math.min(1, _0xCAD9 + 0.022), math.min(1, _0xCAD9 + 0.002), math.min(1, _0xCAD9 + 0.058), _0xC5C6 or 1.0)
end
return _0xEFB3.ImVec4(math.min(1, _0xCAD9 + _0x4CF0[1] * 0.04), math.min(1, _0xCAD9 + _0x4CF0[2] * 0.04), math.min(1, _0xCAD9 + _0x4CF0[3] * 0.06), _0xC5C6 or 1.0)
endlocal function _0x2F6E(_0xCAD9, _0x22D5, _0xC5C6)
local _0x4CF0 = _0xF228.accent
local _0xF60E = _0x5822(_0xCAD9)
return _0xEFB3.ImVec4(_0xF60E.x + (_0x4CF0[1] - _0xF60E.x) * _0x22D5, _0xF60E.y + (_0x4CF0[2] - _0xF60E.y) * _0x22D5, _0xF60E.z + (_0x4CF0[3] - _0xF60E.z) * _0x22D5, _0xC5C6 or 1.0)
endlocal function _0x9C75(fallback)
if _0xEFB3.GetForegroundDrawList then
local _0x054C, _0x6A4A = pcall(_0xEFB3.GetForegroundDrawList)
if _0x054C and _0x6A4A ~= nil then return _0x6A4A end
end
return fallback()
end
local function _0xDC06(_0x0C0A, _0xA731, _0x91E7, _0xD740, _0x2CC1)
local _0x7940, _0xAA2C = {}, {}
local function _0x2C04(_0xD40E, _0xC60C) _0x7940[#_0x7940 + 1] = _0xD40E; _0xAA2C[#_0xAA2C + 1] = _0xC60C end
local function _0x7B13(ax, ay, _0x8578, _0x5C38)
local _0x0186 = math.sqrt((_0x8578 - ax) ^ 2 + (_0x5C38 - ay) ^ 2)
local _0x3CF1 = math.max(1, math.floor(_0x0186 / 14))
for _0x43EB = 0, _0x3CF1 - 1 do
local _0xF27D = _0x43EB / _0x3CF1
_0x2C04(ax + (_0x8578 - ax) * _0xF27D, ay + (_0x5C38 - ay) * _0xF27D)
end
end
local function _0xB56F(_0x6551, _0xE58A, a0)
for _0x43EB = 0, 5 do
local _0xC5C6 = a0 + (math.pi / 2) * (_0x43EB / 5)
_0x2C04(_0x6551 + math.cos(_0xC5C6) * _0x2CC1, _0xE58A + math.sin(_0xC5C6) * _0x2CC1)
end
end
_0x7B13(_0x0C0A + _0x2CC1, _0xA731, _0x91E7 - _0x2CC1, _0xA731)
_0xB56F(_0x91E7 - _0x2CC1, _0xA731 + _0x2CC1, -math.pi / 2)
_0x7B13(_0x91E7, _0xA731 + _0x2CC1, _0x91E7, _0xD740 - _0x2CC1)
_0xB56F(_0x91E7 - _0x2CC1, _0xD740 - _0x2CC1, 0)
_0x7B13(_0x91E7 - _0x2CC1, _0xD740, _0x0C0A + _0x2CC1, _0xD740)
_0xB56F(_0x0C0A + _0x2CC1, _0xD740 - _0x2CC1, math.pi / 2)
_0x7B13(_0x0C0A, _0xD740 - _0x2CC1, _0x0C0A, _0xA731 + _0x2CC1)
_0xB56F(_0x0C0A + _0x2CC1, _0xA731 + _0x2CC1, math.pi)
return _0x7940, _0xAA2C
endlocal function _0xAEAE(_0x0C0A, _0xA731, _0x91E7, _0xD740)
local _0x7940, _0xAA2C = _0xDC06(_0x0C0A + 1, _0xA731 + 1, _0x91E7 - 1, _0xD740 - 1, 12)
local _0x3CF1 = #_0x7940
local _0x5421 = {}
for _0x43EB = 1, _0x3CF1 do _0x5421[_0x43EB] = _0xEFB3.ImVec2(_0x7940[_0x43EB], _0xAA2C[_0x43EB]) end
local _0x6A4A = _0x9C75(_0xEFB3.GetWindowDrawList)
local _0x4CF0 = _0xF228.accent
local _0xCEEE = _0xF228.border_mode
local _0xF27D = os.clock() * _0xF228.border_speed
local _0x8D4B, _0xF81F, _0x5EAD = 1, 1, 1
if _0xCEEE == 1 then
local _0xCC7A, _0x7087 = _0x877D(_0x4CF0[1], _0x4CF0[2], _0x4CF0[3])
_0x8D4B, _0xF81F, _0x5EAD = _0xD2F6(_0xCC7A + 0.08, math.max(0.35, _0x7087 * 0.75), 1.0)
end
for _0x43EB = 1, _0x3CF1 do
local _0xAEF5 = _0x43EB % _0x3CF1 + 1
local _0xE8B2 = (_0x43EB - 1) / _0x3CF1
local _0x2CC1, _0xCAFA, _0x8AAA
if _0xCEEE == 1 then
local _0x81C3 = 0.5 + 0.5 * math.sin((_0xE8B2 * 2 - _0xF27D * 0.6) * math.pi * 2)
local _0x8522, _0xCE73, _0x4AB4 = _0x4CF0[1] * 0.55, _0x4CF0[2] * 0.55, _0x4CF0[3] * 0.55
_0x2CC1, _0xCAFA, _0x8AAA = _0x8522 + (_0x8D4B - _0x8522) * _0x81C3, _0xCE73 + (_0xF81F - _0xCE73) * _0x81C3, _0x4AB4 + (_0x5EAD - _0x4AB4) * _0x81C3
elseif _0xCEEE == 2 then
_0x2CC1, _0xCAFA, _0x8AAA = _0xD2F6(_0xE8B2 - _0xF27D * 0.3, 0.75, 1.0)
else
_0x2CC1, _0xCAFA, _0x8AAA = _0x4CF0[1], _0x4CF0[2], _0x4CF0[3]
end
_0x6A4A:AddLine(_0x5421[_0x43EB], _0x5421[_0xAEF5], _0xE27E(_0x2CC1, _0xCAFA, _0x8AAA, 0.16), 5.0)
_0x6A4A:AddLine(_0x5421[_0x43EB], _0x5421[_0xAEF5], _0xE27E(_0x2CC1, _0xCAFA, _0x8AAA, 0.95), 2.0)
end
endlocal _0xD552 = false
local function _0x7340(_0x0C0A, _0xA731, _0x91E7, _0xD740)
if _0xD552 then return end
local _0x054C, _0x7139 = pcall(function()
if _0xF228.shadow then
local _0x100A = _0xEFB3.GetBackgroundDrawList()
for _0x43EB = 1, 6 do
local _0xA49F = _0x43EB * 3
_0x100A:AddRectFilled(_0xEFB3.ImVec2(_0x0C0A - _0xA49F, _0xA731 - _0xA49F + 5), _0xEFB3.ImVec2(_0x91E7 + _0xA49F, _0xD740 + _0xA49F + 5), _0xE27E(0, 0, 0, 0.045), 12 + _0xA49F)
end
end
if _0xF228.border_mode ~= 0 then _0xAEAE(_0x0C0A, _0xA731, _0x91E7, _0xD740) end
end)
if not _0x054C then
_0xD552 = true
_0xC746("window_fx", _0x7139)
end
if _0xF228.halloween then _0xDFF1.hw_safe(_0xDFF1.hw_front, _0x0C0A, _0xA731, _0x91E7, _0xD740) end
end
function apply_theme()
local _0x061A = _0xEFB3.GetStyle()
local _0xCBC8 = _0x061A.Colors
local _0x4CF0 = _0xF228.accent
local function _0x563C(_0x4D0B, _0x0448) pcall(function() _0x061A[_0x4D0B] = _0x0448 end) end
local function _0xD599(_0x4D0B, _0x0448)
local _0x49D8 = _0xEFB3.Col[_0x4D0B]
if _0x49D8 ~= nil then _0xCBC8[_0x49D8] = _0x0448 end
end_0x563C("WindowPadding", _0xEFB3.ImVec2(5, 5))
_0x563C("FramePadding", _0xEFB3.ImVec2(5, 5))
_0x563C("ItemSpacing", _0xEFB3.ImVec2(5, 5))
_0x563C("ItemInnerSpacing", _0xEFB3.ImVec2(2, 2))
_0x563C("WindowTitleAlign", _0xEFB3.ImVec2(0.5, 0.5))
_0x563C("ScrollbarSize", 10)
_0x563C("WindowBorderSize", 0)
_0x563C("PopupBorderSize", 0)
_0x563C("ChildBorderSize", 1)
_0x563C("FrameBorderSize", 0)_0x563C("WindowRounding", 12)
_0x563C("ChildRounding", 8)
_0x563C("FrameRounding", 6)
_0x563C("PopupRounding", 10)
_0x563C("ScrollbarRounding", 8)
_0x563C("GrabRounding", 6)
_0x563C("TabRounding", 6)_0xD599("Text", _0xEFB3.ImVec4(0.93, 0.94, 0.97, 1.00))
_0xD599("TextDisabled", _0xEFB3.ImVec4(0.52, 0.55, 0.62, 1.00))
_0xD599("WindowBg", _0x5822(0.058, _0xF228.opacity))
_0xD599("ChildBg", _0x5822(0.080, 0.50))
_0xD599("PopupBg", _0x5822(0.085, 0.98))
_0xD599("Border", _0xEFB3.ImVec4(_0x4CF0[1], _0x4CF0[2], _0x4CF0[3], 0.20))
_0xD599("TitleBg", _0x5822(0.058))
_0xD599("TitleBgActive", _0x5822(0.058))
_0xD599("TitleBgCollapsed", _0x5822(0.058))
_0xD599("FrameBg", _0x5822(0.105))
_0xD599("FrameBgHovered", _0x2F6E(0.105, 0.14))
_0xD599("FrameBgActive", _0x2F6E(0.105, 0.22))
_0xD599("Button", _0x5822(0.115))
_0xD599("ButtonHovered", _0x2F6E(0.115, 0.30))
_0xD599("ButtonActive", _0x2F6E(0.115, 0.50))
_0xD599("Header", _0x2F6E(0.115, 0.22))
_0xD599("HeaderHovered", _0x2F6E(0.115, 0.34))
_0xD599("HeaderActive", _0x2F6E(0.115, 0.48))
_0xD599("ScrollbarBg", _0xEFB3.ImVec4(0, 0, 0, 0))
_0xD599("ScrollbarGrab", _0x2F6E(0.12, 0.30))
_0xD599("ScrollbarGrabHovered", _0x2F6E(0.12, 0.50))
_0xD599("ScrollbarGrabActive", _0x2F6E(0.12, 0.75))
_0xD599("Separator", _0xEFB3.ImVec4(1, 1, 1, 0.07))
_0xD599("ModalWindowDimBg", _0xEFB3.ImVec4(0, 0, 0, 0.65))
_0xD599("CheckMark", _0xBD61(1.15))
_0xD599("SliderGrab", _0xBD61(1.0))
_0xD599("SliderGrabActive", _0xBD61(1.25))
_0xD599("PlotHistogram", _0xBD61(1.0))
_0xD599("TextSelectedBg", _0xEFB3.ImVec4(_0x4CF0[1], _0x4CF0[2], _0x4CF0[3], 0.35))
_0xD599("ResizeGrip", _0xEFB3.ImVec4(_0x4CF0[1], _0x4CF0[2], _0x4CF0[3], 0.45))
_0xD599("ResizeGripHovered", _0xEFB3.ImVec4(_0x4CF0[1], _0x4CF0[2], _0x4CF0[3], 0.75))
_0xD599("ResizeGripActive", _0xEFB3.ImVec4(_0x4CF0[1], _0x4CF0[2], _0x4CF0[3], 1.00))
endlocal _0x9E4F = 200
local _0xE16E = { _0x81C3 = 835, _0xCC7A = 500, tab_h = 42, block_y = 340, force = false }local _0x69CC = 1local _0xCF33 =""local _0x323C =""local _0x023B = nil
local _0x53E6 = false
local _0xED0C = { hover = {}, press = {}, ripple = {}, hist = {}, hist_open = false, pop_t = -10, grown = false }
local function _0x2075(_0x4D0B, fallback)
return _0x8553[_0x4D0B] or fallback
endlocal _0x34EA = {}
local _0x8E8A = {
info = { _0xD5FA ="CIRCLE_INFO", _0xA6B2 = nil },
_0x054C = { _0xD5FA ="CIRCLE_CHECK", _0xA6B2 = {0.30, 0.78, 0.45} },
warn = { _0xD5FA ="TRIANGLE_EXCLAMATION", _0xA6B2 = {1.00, 0.75, 0.20} },
_0x7139 = { _0xD5FA ="CIRCLE_XMARK", _0xA6B2 = {0.92, 0.32, 0.32} },
}
local _0x0B2B = false
local function _0xE3A1(_0xF692, _0x53EC, _0xFEBE)
if _0xF228.toasts == false or _0x0B2B then return false end
_0x34EA[#_0x34EA + 1] = { _0xF692 = tostring(_0xF692), _0x53EC = _0x8E8A[_0x53EC] and _0x53EC or"info", t0 = os.clock(), _0xFEBE = _0xFEBE or 3.5 }
if #_0x34EA > 5 then table.remove(_0x34EA, 1) end
return true
endlocal function _0x3D10(_0xF692, _0x53EC, _0xFEBE)
if not _0xE3A1(_0xF692, _0x53EC, _0xFEBE) then
if sampAddChatMessage then
pcall(sampAddChatMessage, _0x1329:decode("{33AAFF}[Arizona Prices] {FFFFFF}".. tostring(_0xF692)), -1)
end
end
endlocal function _0xB66E()
local _0x27A0 = os.clock()
for _0x43EB = #_0x34EA, 1, -1 do
if _0x27A0 - _0x34EA[_0x43EB].t0 > _0x34EA[_0x43EB].dur then table.remove(_0x34EA, _0x43EB) end
end
if #_0x34EA == 0 then return end
local _0x6A4A = _0x9C75(_0xEFB3.GetBackgroundDrawList)
local _0x72C1, _0x5CFA = getScreenResolution()
local _0xCD61 = _0xF228.toast_corner or 3local _0x7D4F = (_0xCD61 == 1 or _0xCD61 == 3)
local _0x3685 = (_0xCD61 == 2 or _0xCD61 == 3)
local _0xB67C, _0x689B, _0xD8B8 = 46, 8, 20
for _0x43EB, _0xF27D in ipairs(_0x34EA) do
local _0x53EC = _0x8E8A[_0xF27D.kind] or _0x8E8A.info
local _0xA46C = _0xEFB3.CalcTextSize(_0xF27D.text)
local _0x81C3 = math.min(760, _0xA46C.x + 84)
local _0xDBFD = _0x27A0 - _0xF27D.t0
local _0xC153 = math.min(1, _0xDBFD / 0.25)
local _0x16FB = 1 - (1 - _0xC153) ^ 3
local _0x45CA = math.max(0, math.min(1, (_0xF27D.dur - _0xDBFD) / 0.4))
local _0x77AD = (1 - _0x16FB) * (_0x81C3 + _0xD8B8 + 10)
local _0x083B = #_0x34EA - _0x43EB
local _0xD40E = _0x7D4F and (_0x72C1 - _0xD8B8 - _0x81C3 + _0x77AD) or (_0xD8B8 - _0x77AD)
local _0xC60C = _0x3685 and (_0x5CFA - _0xD8B8 - 80 - _0xB67C - _0x083B * (_0xB67C + _0x689B)) or (_0xD8B8 + _0x083B * (_0xB67C + _0x689B))
local _0x65BB = _0x53EC.color or _0xF228.accent
local _0x4957 = _0xC60C + (_0xB67C - _0xA46C.y) / 2
local _0xED65, _0x6549 = _0xEFB3.ImVec2(_0xD40E, _0xC60C), _0xEFB3.ImVec2(_0xD40E + _0x81C3, _0xC60C + _0xB67C)
local _0x6551, _0xE58A = _0xD40E + 28, _0xC60C + _0xB67C / 2
_0x6A4A:AddRectFilled(_0xED65, _0x6549, _0xE27E(0.07, 0.075, 0.09, 0.96 * _0x45CA), 10)
pcall(function()
_0x6A4A:AddRect(_0xED65, _0x6549, _0xE27E(_0x65BB[1], _0x65BB[2], _0x65BB[3], 0.60 * _0x45CA), 10, 0, 1.5)
_0x6A4A:AddCircleFilled(_0xEFB3.ImVec2(_0x6551, _0xE58A), 17, _0xE27E(_0x65BB[1], _0x65BB[2], _0x65BB[3], 0.20 * _0x45CA), 28)
end)local _0x8DD5 = _0xE27E(_0x65BB[1], _0x65BB[2], _0x65BB[3], _0x45CA)
local function _0x9A42(ax, ay, _0x8578, _0x5C38)
_0x6A4A:AddLine(_0xEFB3.ImVec2(_0x6551 + ax, _0xE58A + ay), _0xEFB3.ImVec2(_0x6551 + _0x8578, _0xE58A + _0x5C38), _0x8DD5, 3.0)
end
if _0xF27D.kind =="ok"then
_0x9A42(-7, 0.5, -2.5, 5.5)
_0x9A42(-2.5, 5.5, 7.5, -5.5)
_0x6A4A:AddCircleFilled(_0xEFB3.ImVec2(_0x6551 - 2.5, _0xE58A + 5.5), 1.5, _0x8DD5, 12)
elseif _0xF27D.kind =="err"then
_0x9A42(-6, -6, 6, 6)
_0x9A42(-6, 6, 6, -6)
elseif _0xF27D.kind =="warn"then
_0x9A42(0, -8, 0, 2)
_0x6A4A:AddCircleFilled(_0xEFB3.ImVec2(_0x6551, _0xE58A + 7), 2.0, _0x8DD5, 12)
else
_0x6A4A:AddCircleFilled(_0xEFB3.ImVec2(_0x6551, _0xE58A - 7), 2.0, _0x8DD5, 12)
_0x9A42(0, -2.5, 0, 8)
end
_0x6A4A:AddText(_0xEFB3.ImVec2(_0xD40E + 56, _0x4957), _0xE27E(1, 1, 1, _0x45CA), _0xF27D.text)
end
end
local _0xF703
_0xF703 = _0xEFB3.OnFrame(
function()
_0xF703.HideCursor = true
return #_0x34EA > 0
end,
function()
local _0x054C, _0x7139 = xpcall(_0xB66E, _0xFB09)
if not _0x054C then
_0x0B2B = true
_0x34EA = {}
_0xC746("toast", _0x7139)
_0xBBE7("Карточки уведомлений отключены из-за ошибки, сообщения будут в чате","warn")
end
end
)local function _0x0758(_0xB814)
if _0xB814 ==""then return"0"end
local _0x2CC1 = _0xB814:reverse():gsub("(%d%d%d)","%1."):reverse()
if _0x2CC1:sub(1, 1) =="."then _0x2CC1 = _0x2CC1:sub(2) end
return _0x2CC1
end
local function _0x6F87(expr)
local _0xB43C = expr:gsub("[%d%.]+", function(_0x6ECC)
local _0xA290, _0xE281 = _0x6ECC:match("^(%d*)%.(%d*)$")
if _0xA290 then
return _0x0758(_0xA290) ..",".. _0xE281
end
return _0x0758(_0x6ECC)
end)
_0xB43C = _0xB43C:gsub("%*"," x "):gsub("/"," / "):gsub("%+"," + "):gsub("%-"," - ")
_0xB43C = _0xB43C:gsub("^%s+",""):gsub("%s+$","")
_0xB43C = _0xB43C:gsub("^%- ","-")
return _0xB43C
end
local function _0x8971(_0xD40E)
if _0xD40E >= 0 then
_0xD40E = math.floor(_0xD40E * 100 + 0.5) / 100
else
_0xD40E = -math.floor(-_0xD40E * 100 + 0.5) / 100
end
local _0xB814 = string.format("%.2f", _0xD40E)
_0xB814 = _0xB814:gsub("0+$",""):gsub("%.$","")
if _0xB814 =="-0"or _0xB814 ==""then _0xB814 ="0"end
return _0xB814
end
local function _0x460A(expr)
local _0xF408 = {}
local _0x43EB, _0x3CF1 = 1, #expr
while _0x43EB <= _0x3CF1 do
local _0x65BB = expr:sub(_0x43EB, _0x43EB)
if _0x65BB:match("[%d%.]") then
local _0x6ECC = expr:match("^[%d%.]+", _0x43EB)
_0x43EB = _0x43EB + #_0x6ECC
local _0x0448 = tonumber(_0x6ECC)
if not _0x0448 then return nil,"Ошибка"end
local _0x4B80 = false
if expr:sub(_0x43EB, _0x43EB) =="%"then
_0x4B80 = true
_0x43EB = _0x43EB + 1
end
_0xF408[#_0xF408 + 1] = {_0x6ECC = _0x0448, _0x4B80 = _0x4B80}
elseif _0x65BB:match("[%+%-%*/]") then
_0xF408[#_0xF408 + 1] = {op = _0x65BB}
_0x43EB = _0x43EB + 1
else
return nil,"Ошибка"end
end
if _0xF408[#_0xF408] and _0xF408[#_0xF408].op then _0xF408[#_0xF408] = nil end
local _0x49D8, _0xADD4 = 1, 1
if _0xF408[1] and _0xF408[1].op =="-"then
_0xADD4 = -1
_0x49D8 = 2
end
if _0x49D8 > #_0xF408 then return nil,"Ошибка"end
local _0xCD06, _0xA655, _0xB554 = 0,"+", true
while _0x49D8 <= #_0xF408 do
local _0xA3E1 = _0xF408[_0x49D8]
if not _0xA3E1.num then return nil,"Ошибка"end
local _0xFDCF = _0xA3E1.pct and (_0xA3E1.num / 100) or _0xA3E1.num
local _0x6C15 = true
_0x49D8 = _0x49D8 + 1
while _0xF408[_0x49D8] and (_0xF408[_0x49D8].op =="*"or _0xF408[_0x49D8].op =="/") do
local _0x13AA = _0xF408[_0x49D8 + 1]
if not _0x13AA or not _0x13AA.num then return nil,"Ошибка"end
local _0x5E6A = _0x13AA.pct and (_0x13AA.num / 100) or _0x13AA.num
if _0xF408[_0x49D8].op =="*"then
_0xFDCF = _0xFDCF * _0x5E6A
else
if _0x5E6A == 0 then return nil,"Деление на ноль"end
_0xFDCF = _0xFDCF / _0x5E6A
end
_0x6C15 = false
_0x49D8 = _0x49D8 + 2
end
if _0xB554 then
_0xFDCF = _0xFDCF * _0xADD4
_0xCD06 = _0xFDCF
_0xB554 = false
else
if _0x6C15 and _0xA3E1.pct then _0xFDCF = _0xCD06 * _0xA3E1.num / 100 end
if _0xA655 =="+"then _0xCD06 = _0xCD06 + _0xFDCF else _0xCD06 = _0xCD06 - _0xFDCF end
end
local _0x9789 = _0xF408[_0x49D8]
if _0x9789 then
if _0x9789.op ~="+"and _0x9789.op ~="-"then return nil,"Ошибка"end
_0xA655 = _0x9789.op
_0x49D8 = _0x49D8 + 1
end
end
return _0xCD06
end
local function _0x1654()
if _0x53E6 then
_0xCF33 =""_0x323C =""_0x53E6 = false
end
end
local function _0x3076(_0xF60E)
_0x023B = nil
_0x1654()
if #_0xCF33 > 45 then return end
if _0xCF33:sub(-1) =="%"then return end
local _0x2E37 = _0xCF33:match("[%d%.]*$")
if _0xF60E =="000"then
if _0x2E37 ==""or _0x2E37 =="0"then return end
_0xCF33 = _0xCF33 .."000"return
end
if _0x2E37 =="0"then
if _0xF60E =="0"then return end
_0xCF33 = _0xCF33:sub(1, -2) .. _0xF60E
else
_0xCF33 = _0xCF33 .. _0xF60E
end
end
local function _0x7B91()
_0x023B = nil
_0x1654()
if #_0xCF33 > 45 then return end
if _0xCF33:sub(-1) =="%"then return end
local _0x2E37 = _0xCF33:match("[%d%.]*$")
if _0x2E37:find(".", 1, true) then return end
if _0x2E37 ==""then
_0xCF33 = _0xCF33 .."0."else
_0xCF33 = _0xCF33 .."."end
end
local function _0xDB92(op)
_0x023B = nil
if _0x53E6 then
_0x53E6 = false
_0x323C =""end
if _0xCF33 ==""then
if op =="-"then _0xCF33 ="-"end
return
end
local _0x8F25 = _0xCF33:sub(-1)
if _0x8F25:match("[%+%-%*/]") then
if #_0xCF33 == 1 then return end
_0xCF33 = _0xCF33:sub(1, -2) .. op
else
if _0x8F25 =="."then _0xCF33 = _0xCF33:sub(1, -2) end
_0xCF33 = _0xCF33 .. op
end
end
local function _0x4631()
_0x023B = nil
if _0x53E6 then
_0x53E6 = false
_0x323C =""end
if _0xCF33:sub(-1):match("%d") then
_0xCF33 = _0xCF33 .."%"end
end
local function _0xD31E()
_0x023B = nil
if _0x53E6 then
_0x53E6 = false
_0x323C =""end
_0xCF33 = _0xCF33:sub(1, -2)
end
local function _0x5E2F()
_0xCF33 =""_0x323C =""_0x023B = nil
_0x53E6 = false
end
local function _0x681D()
if _0xCF33 ==""or _0x53E6 then return end
local _0x7FC3, _0x7139 = _0x460A(_0xCF33)
if not _0x7FC3 then
_0x023B = _0x7139 or"Ошибка"return
end
local _0x4B25 = _0x6F87(_0xCF33)
_0x323C = _0x4B25 .." ="_0xCF33 = _0x8971(_0x7FC3)
_0x53E6 = true
_0xED0C.pop_t = _0xEFB3.GetTime()
_0xED0C.hist[#_0xED0C.hist + 1] = { expr = _0x4B25, _0x7FC3 = _0x6F87(_0xCF33), raw = _0xCF33 }
if #_0xED0C.hist > 15 then table.remove(_0xED0C.hist, 1) end
endlocal function _0x081D(_0xBC3A)
local _0x6A4A = _0xEFB3.GetWindowDrawList()
local _0x6907 = _0xEFB3.ColorConvertFloat4ToU32(_0x5822(0.088, _0xDFF1.m))
_0x6A4A:AddRectFilled(_0xBC3A, _0xEFB3.ImVec2(_0xBC3A.x + _0x9E4F - 1, _0xBC3A.y + _0xE16E.h), _0x6907, 12)
_0x6A4A:AddRectFilled(_0xEFB3.ImVec2(_0xBC3A.x + 14, _0xBC3A.y), _0xEFB3.ImVec2(_0xBC3A.x + _0x9E4F - 1, _0xBC3A.y + _0xE16E.h), _0x6907)
_0x6A4A:AddLine(_0xEFB3.ImVec2(_0xBC3A.x + _0x9E4F - 1, _0xBC3A.y + 8), _0xEFB3.ImVec2(_0xBC3A.x + _0x9E4F - 1, _0xBC3A.y + _0xE16E.h - 8), _0xEFB3.GetColorU32(_0xEFB3.Col.Separator), 1.0)
if _0xF228.halloween then _0xDFF1.hw_safe(_0xDFF1.hw_web, _0x6A4A, _0xBC3A.x + 7, _0xBC3A.y + _0xE16E.h - 7, 84, 1, -1, 0.18) end
endfunction _0xDFF1.liq_color(_0xCAD9)
if _0xCAD9 =="Ликвид"then return _0xEFB3.ImVec4(0.45, 0.95, 0.55, 1) end
if _0xCAD9 =="Средне"then return _0xEFB3.ImVec4(1.00, 0.85, 0.40, 1) end
if _0xCAD9 =="Неликвид"then return _0xEFB3.ImVec4(1.00, 0.45, 0.45, 1) end
return _0xEFB3.ImVec4(0.50, 0.52, 0.58, 1)
end
function _0xDFF1.liq_next(_0xCAD9)
if _0xCAD9 == nil then return"Ликвид"end
if _0xCAD9 =="Ликвид"then return"Средне"end
if _0xCAD9 =="Средне"then return"Неликвид"end
return nil
end
function _0xDFF1.set_alpha(_0xC5C6)
_0xC5C6 = _0xCD0C(_0xC5C6, 0, 1)
_0xDFF1.m = _0xC5C6
pcall(function() _0xEFB3.GetStyle().Alpha = _0xC5C6 end)
endfunction _0xDFF1.go_tab(_0x6319)
if _0x6319 ~= _0x69CC then
_0x69CC = _0x6319
local _0x27A0 = _0xEFB3.GetTime()
_0xDFF1.tab_t, _0xDFF1.table_t = _0x27A0, _0x27A0
end
endfunction _0xDFF1.tick()
local _0x9BBB = _0xEFB3.GetIO().DeltaTime
local _0x0434 = _0x950A[0]
local _0xF157 = _0x0434 and 1 or 0
_0xDFF1.alpha = _0xDFF1.alpha + (_0xF157 - _0xDFF1.alpha) * math.min(1, _0x9BBB * (_0x0434 and 11 or 15))
if not _0x0434 and _0xDFF1.alpha < 0.03 then _0xDFF1.alpha = 0 end
if _0x0434 and _0xDFF1.alpha > 0.99 then _0xDFF1.alpha = 1 end
if _0x0434 and not _0xDFF1.was_open then
local _0x27A0 = _0xEFB3.GetTime()
_0xDFF1.table_t, _0xDFF1.tab_t = _0x27A0, _0x27A0
if _0xF228.splash and not _0xDFF1.splashed then
_0xDFF1.splash_t = _0x27A0
_0xDFF1.splashed = true
end
end
_0xDFF1.was_open = _0x0434
if _0xDFF1.pending_tab then
_0xDFF1.go_tab(_0xDFF1.pending_tab)
_0xDFF1.pending_tab = nil
end
endfunction _0xDFF1.draw_bar(_0xBC3A)
if not _0xDFF1.bar_ty then return end
local _0x9BBB = _0xEFB3.GetIO().DeltaTime
if not _0xDFF1.bar_cur then _0xDFF1.bar_cur = _0xDFF1.bar_ty end
_0xDFF1.bar_cur = _0xDFF1.bar_cur + (_0xDFF1.bar_ty - _0xDFF1.bar_cur) * math.min(1, _0x9BBB * 16)
local _0x4CF0 = _0xF228.accent
local _0xD40E, _0xC60C = _0xBC3A.x + _0xDFF1.bar_x, _0xBC3A.y + _0xDFF1.bar_cur
_0xEFB3.GetWindowDrawList():AddRectFilled(_0xEFB3.ImVec2(_0xD40E, _0xC60C - 13), _0xEFB3.ImVec2(_0xD40E + 3, _0xC60C + 13),
_0xE27E(math.min(1, _0x4CF0[1] * 1.15), math.min(1, _0x4CF0[2] * 1.15), math.min(1, _0x4CF0[3] * 1.15), 1), 2)
endfunction _0xDFF1.draw_bg()
local _0xBAC3, _0xB814 = _0xEFB3.GetWindowPos(), _0xEFB3.GetWindowSize()
local _0x6A4A = _0xEFB3.GetWindowDrawList()
local _0xF27D, _0x4CF0 = _0xEFB3.GetTime(), _0xF228.accent
for _0x43EB = 1, 3 do
local _0x6551 = _0xBAC3.x + _0xB814.x * (0.5 + 0.38 * math.sin(_0xF27D * 0.11 * _0x43EB + _0x43EB * 2.1))
local _0xE58A = _0xBAC3.y + _0xB814.y * (0.5 + 0.38 * math.cos(_0xF27D * 0.09 * _0x43EB + _0x43EB * 1.3))
for _0x2CC1 = 4, 1, -1 do
_0x6A4A:AddCircleFilled(_0xEFB3.ImVec2(_0x6551, _0xE58A), _0x2CC1 * 55, _0xE27E(_0x4CF0[1], _0x4CF0[2], _0x4CF0[3], 0.014), 32)
end
end
for _0x43EB = 1, 26 do
local _0x4287 = 10 + (_0x43EB * 7) % 17
local _0xD40E = _0xBAC3.x + ((_0x43EB * 137) % 100) / 100 * _0xB814.x + math.sin(_0xF27D * 0.5 + _0x43EB) * 12
local _0xC60C = _0xBAC3.y + _0xB814.y - ((_0xF27D * _0x4287 + _0x43EB * 61) % (_0xB814.y + 20)) + 10
local _0x86F4 = 0.5 + 0.5 * math.sin(_0xF27D * 1.5 + _0x43EB * 1.7)
_0x6A4A:AddCircleFilled(_0xEFB3.ImVec2(_0xD40E, _0xC60C), 1.2 + (_0x43EB % 3) * 0.7,
_0xE27E(_0x4CF0[1] * 0.5 + 0.5, _0x4CF0[2] * 0.5 + 0.5, _0x4CF0[3] * 0.5 + 0.5, 0.05 + 0.14 * _0x86F4), 8)
end
endfunction _0xDFF1.hw_safe(fn, ...)
if _0xDFF1.hw_broken then return end
local _0x054C, _0x7139 = pcall(fn, ...)
if not _0x054C then
_0xDFF1.hw_broken = true
pcall(_0xC746,"halloween", _0x7139)
end
endfunction _0xDFF1.hw_tri(_0x6A4A, _0x6907, ax, ay, _0x8578, _0x5C38, _0x6551, _0xE58A)
local _0x2818 = _0xEFB3.ImVec2
if (_0x8578 - ax) * (_0xE58A - ay) - (_0x5C38 - ay) * (_0x6551 - ax) < 0 then
_0x8578, _0x5C38, _0x6551, _0xE58A = _0x6551, _0xE58A, _0x8578, _0x5C38
end
_0x6A4A:AddTriangleFilled(_0x2818(ax, ay), _0x2818(_0x8578, _0x5C38), _0x2818(_0x6551, _0xE58A), _0x6907)
endfunction _0xDFF1.hw_pumpkin(_0x6A4A, _0x6551, _0xE58A, _0x2CC1, _0x22D5, hat)
local _0x2818 = _0xEFB3.ImVec2
local _0xF27D = _0xEFB3.GetTime()
local _0x5D7B = 0.85 + 0.15 * math.sin(_0xF27D * 7 + _0x6551 * 0.05) * math.sin(_0xF27D * 3.1 + _0xE58A * 0.1)for _0x43EB = 3, 1, -1 do
_0x6A4A:AddCircleFilled(_0x2818(_0x6551, _0xE58A), _0x2CC1 * (1.0 + _0x43EB * 0.45), _0xE27E(1.0, 0.45, 0.05, 0.04 * _0x22D5 * _0x5D7B), 28)
end
local _0x0390 = _0xE58A - _0x2CC1 * 0.78
local _0x9CA4 = _0xE27E(0.80, 0.33, 0.03, _0x22D5)
local _0x5A11 = _0xE27E(1.00, 0.52, 0.08, _0x22D5)
_0x6A4A:AddCircleFilled(_0x2818(_0x6551 - _0x2CC1 * 0.45, _0xE58A + _0x2CC1 * 0.03), _0x2CC1 * 0.62, _0x9CA4, 22)
_0x6A4A:AddCircleFilled(_0x2818(_0x6551 + _0x2CC1 * 0.45, _0xE58A + _0x2CC1 * 0.03), _0x2CC1 * 0.62, _0x9CA4, 22)
_0x6A4A:AddCircleFilled(_0x2818(_0x6551, _0xE58A), _0x2CC1 * 0.78, _0x5A11, 28)
_0x6A4A:AddCircleFilled(_0x2818(_0x6551 - _0x2CC1 * 0.38, _0xE58A - _0x2CC1 * 0.38), _0x2CC1 * 0.13, _0xE27E(1.0, 0.82, 0.55, 0.35 * _0x22D5), 12)local _0x05D4 = _0xE27E(1.0, 0.88, 0.30, _0x22D5 * _0x5D7B)
_0xDFF1.hw_tri(_0x6A4A, _0x05D4, _0x6551 - _0x2CC1 * 0.55, _0xE58A - _0x2CC1 * 0.02, _0x6551 - _0x2CC1 * 0.18, _0xE58A - _0x2CC1 * 0.02, _0x6551 - _0x2CC1 * 0.36, _0xE58A - _0x2CC1 * 0.34)
_0xDFF1.hw_tri(_0x6A4A, _0x05D4, _0x6551 + _0x2CC1 * 0.18, _0xE58A - _0x2CC1 * 0.02, _0x6551 + _0x2CC1 * 0.55, _0xE58A - _0x2CC1 * 0.02, _0x6551 + _0x2CC1 * 0.36, _0xE58A - _0x2CC1 * 0.34)
_0xDFF1.hw_tri(_0x6A4A, _0x05D4, _0x6551 - _0x2CC1 * 0.08, _0xE58A + _0x2CC1 * 0.14, _0x6551 + _0x2CC1 * 0.08, _0xE58A + _0x2CC1 * 0.14, _0x6551, _0xE58A + _0x2CC1 * 0.03)
_0x6A4A:AddRectFilled(_0x2818(_0x6551 - _0x2CC1 * 0.58, _0xE58A + _0x2CC1 * 0.26), _0x2818(_0x6551 + _0x2CC1 * 0.58, _0xE58A + _0x2CC1 * 0.48), _0x05D4, _0x2CC1 * 0.06)
for _0xAEF5 = -2, 2, 2 do
local _0xD40E = _0x6551 + _0xAEF5 * _0x2CC1 * 0.22
_0xDFF1.hw_tri(_0x6A4A, _0x5A11, _0xD40E - _0x2CC1 * 0.09, _0xE58A + _0x2CC1 * 0.26, _0xD40E + _0x2CC1 * 0.09, _0xE58A + _0x2CC1 * 0.26, _0xD40E, _0xE58A + _0x2CC1 * 0.37)
end
for _0xAEF5 = -1, 1, 2 do
local _0xD40E = _0x6551 + _0xAEF5 * _0x2CC1 * 0.22
_0xDFF1.hw_tri(_0x6A4A, _0x5A11, _0xD40E - _0x2CC1 * 0.09, _0xE58A + _0x2CC1 * 0.48, _0xD40E + _0x2CC1 * 0.09, _0xE58A + _0x2CC1 * 0.48, _0xD40E, _0xE58A + _0x2CC1 * 0.37)
end
if hat then
local _0x9BAC = _0xE27E(0.22, 0.10, 0.38, _0x22D5)
local _0x4095 = _0x0390 + _0x2CC1 * 0.12
_0xDFF1.hw_tri(_0x6A4A, _0x9BAC, _0x6551 - _0x2CC1 * 0.55, _0x4095 - _0x2CC1 * 0.05, _0x6551 + _0x2CC1 * 0.55, _0x4095 - _0x2CC1 * 0.05, _0x6551 + _0x2CC1 * 0.22, _0x4095 - _0x2CC1 * 1.35)
_0x6A4A:AddRectFilled(_0x2818(_0x6551 - _0x2CC1 * 0.44, _0x4095 - _0x2CC1 * 0.30), _0x2818(_0x6551 + _0x2CC1 * 0.44, _0x4095 - _0x2CC1 * 0.10), _0x5A11, 2)
_0x6A4A:AddRectFilled(_0x2818(_0x6551 - _0x2CC1 * 0.95, _0x4095 - _0x2CC1 * 0.10), _0x2818(_0x6551 + _0x2CC1 * 0.95, _0x4095 + _0x2CC1 * 0.08), _0x9BAC, _0x2CC1 * 0.08)
else
local _0x6469 = _0xE27E(0.30, 0.45, 0.10, _0x22D5)
_0xDFF1.hw_tri(_0x6A4A, _0x6469, _0x6551 - _0x2CC1 * 0.10, _0x0390 + _0x2CC1 * 0.08, _0x6551 + _0x2CC1 * 0.14, _0x0390 + _0x2CC1 * 0.08, _0x6551 + _0x2CC1 * 0.20, _0x0390 - _0x2CC1 * 0.28)
_0xDFF1.hw_tri(_0x6A4A, _0x6469, _0x6551 - _0x2CC1 * 0.10, _0x0390 + _0x2CC1 * 0.08, _0x6551 + _0x2CC1 * 0.20, _0x0390 - _0x2CC1 * 0.28, _0x6551 - _0x2CC1 * 0.02, _0x0390 - _0x2CC1 * 0.30)
end
endfunction _0xDFF1.hw_bat(_0x6A4A, _0xD40E, _0xC60C, _0xB814, _0x5D7B, _0x22D5)
local _0x2818 = _0xEFB3.ImVec2
local _0x65BB = _0xE27E(0.36, 0.23, 0.52, 0.90 * _0x22D5)
local _0xE8B2 = _0x5D7B * _0xB814 * 0.55
for _0xF60E = -1, 1, 2 do
_0xDFF1.hw_tri(_0x6A4A, _0x65BB, _0xD40E, _0xC60C - _0xB814 * 0.15, _0xD40E + _0xF60E * _0xB814 * 1.35, _0xC60C - _0xB814 * 0.45 + _0xE8B2, _0xD40E + _0xF60E * _0xB814 * 0.85, _0xC60C + _0xB814 * 0.05)
_0xDFF1.hw_tri(_0x6A4A, _0x65BB, _0xD40E, _0xC60C - _0xB814 * 0.15, _0xD40E + _0xF60E * _0xB814 * 0.85, _0xC60C + _0xB814 * 0.05, _0xD40E + _0xF60E * _0xB814 * 0.45, _0xC60C + _0xB814 * 0.32)
_0xDFF1.hw_tri(_0x6A4A, _0x65BB, _0xD40E, _0xC60C - _0xB814 * 0.05, _0xD40E + _0xF60E * _0xB814 * 0.45, _0xC60C + _0xB814 * 0.32, _0xD40E, _0xC60C + _0xB814 * 0.22)
end
_0x6A4A:AddCircleFilled(_0x2818(_0xD40E, _0xC60C + _0xB814 * 0.02), _0xB814 * 0.30, _0x65BB, 12)
_0xDFF1.hw_tri(_0x6A4A, _0x65BB, _0xD40E - _0xB814 * 0.26, _0xC60C - _0xB814 * 0.12, _0xD40E - _0xB814 * 0.06, _0xC60C - _0xB814 * 0.22, _0xD40E - _0xB814 * 0.24, _0xC60C - _0xB814 * 0.52)
_0xDFF1.hw_tri(_0x6A4A, _0x65BB, _0xD40E + _0xB814 * 0.06, _0xC60C - _0xB814 * 0.22, _0xD40E + _0xB814 * 0.26, _0xC60C - _0xB814 * 0.12, _0xD40E + _0xB814 * 0.24, _0xC60C - _0xB814 * 0.52)
local _0xBA74 = _0xE27E(1.0, 0.40, 0.10, _0x22D5)
_0x6A4A:AddCircleFilled(_0x2818(_0xD40E - _0xB814 * 0.11, _0xC60C), _0xB814 * 0.05, _0xBA74, 6)
_0x6A4A:AddCircleFilled(_0x2818(_0xD40E + _0xB814 * 0.11, _0xC60C), _0xB814 * 0.05, _0xBA74, 6)
endfunction _0xDFF1.hw_web(_0x6A4A, _0x6551, _0xE58A, size, dx, dy, _0xC5C6)
local _0x2818 = _0xEFB3.ImVec2
local _0x6907 = _0xE27E(0.85, 0.85, 1.0, _0xC5C6)
local _0x3CF1 = 5
for _0x22D5 = 0, _0x3CF1 do
local _0xDD65 = (_0x22D5 / _0x3CF1) * (math.pi / 2)
_0x6A4A:AddLine(_0x2818(_0x6551, _0xE58A), _0x2818(_0x6551 + dx * math.cos(_0xDD65) * size, _0xE58A + dy * math.sin(_0xDD65) * size), _0x6907, 1.0)
end
for _0xAEF5 = 1, 4 do
local _0xE978 = size * _0xAEF5 / 4
for _0x22D5 = 0, _0x3CF1 - 1 do
local _0xE3C1, _0x3253, _0x98D7 = (_0x22D5 / _0x3CF1) * (math.pi / 2), ((_0x22D5 + 1) / _0x3CF1) * (math.pi / 2), ((_0x22D5 + 0.5) / _0x3CF1) * (math.pi / 2)
local _0x91E7, _0xD740 = _0x6551 + dx * math.cos(_0xE3C1) * _0xE978, _0xE58A + dy * math.sin(_0xE3C1) * _0xE978
local _0xBCCB, _0x570E = _0x6551 + dx * math.cos(_0x3253) * _0xE978, _0xE58A + dy * math.sin(_0x3253) * _0xE978
local _0x1717, _0x09A2 = _0x6551 + dx * math.cos(_0x98D7) * _0xE978 * 0.86, _0xE58A + dy * math.sin(_0x98D7) * _0xE978 * 0.86
_0x6A4A:AddLine(_0x2818(_0x91E7, _0xD740), _0x2818(_0x1717, _0x09A2), _0x6907, 1.0)
_0x6A4A:AddLine(_0x2818(_0x1717, _0x09A2), _0x2818(_0xBCCB, _0x570E), _0x6907, 1.0)
end
end
endfunction _0xDFF1.hw_bg()
local _0xBAC3, _0xB814 = _0xEFB3.GetWindowPos(), _0xEFB3.GetWindowSize()
local _0x6A4A = _0xEFB3.GetWindowDrawList()
local _0x2818 = _0xEFB3.ImVec2
local _0xF27D = _0xEFB3.GetTime()
local _0x2A12, _0x4BBC = _0xBAC3.x + _0xB814.x - 78, _0xBAC3.y + 70
for _0x43EB = 5, 1, -1 do
_0x6A4A:AddCircleFilled(_0x2818(_0x2A12, _0x4BBC), 40 + _0x43EB * 14, _0xE27E(1.0, 0.82, 0.45, 0.012), 40)
end
_0x6A4A:AddCircleFilled(_0x2818(_0x2A12, _0x4BBC), 40, _0xE27E(1.0, 0.90, 0.62, 0.15), 40)
_0x6A4A:AddCircleFilled(_0x2818(_0x2A12 - 12, _0x4BBC - 8), 9, _0xE27E(0.9, 0.7, 0.4, 0.08), 16)
_0x6A4A:AddCircleFilled(_0x2818(_0x2A12 + 14, _0x4BBC + 10), 6, _0xE27E(0.9, 0.7, 0.4, 0.08), 16)
_0x6A4A:AddCircleFilled(_0x2818(_0x2A12 + 6, _0x4BBC - 20), 5, _0xE27E(0.9, 0.7, 0.4, 0.08), 16)
local _0x47B1, _0x3C4D = _0xBAC3.x + _0xB814.x * (0.30 + 0.20 * math.sin(_0xF27D * 0.13)), _0xBAC3.y + _0xB814.y * (0.65 + 0.15 * math.cos(_0xF27D * 0.10))
for _0x2CC1 = 4, 1, -1 do
_0x6A4A:AddCircleFilled(_0x2818(_0x47B1, _0x3C4D), _0x2CC1 * 60, _0xE27E(0.55, 0.20, 0.85, 0.016), 36)
end
for _0x43EB = 1, 4 do
local _0xF253 = _0xB814.x + 140
local _0x8578 = _0xBAC3.x - 70 + ((_0xF27D * (22 + _0x43EB * 6) + _0x43EB * 173) % _0xF253)
local _0x5C38 = _0xBAC3.y + _0xB814.y * (0.12 + 0.17 * _0x43EB) + math.sin(_0xF27D * 0.8 + _0x43EB * 2.0) * 16
_0xDFF1.hw_bat(_0x6A4A, _0x8578, _0x5C38, 10 + (_0x43EB % 3) * 4, math.sin(_0xF27D * 9 + _0x43EB * 1.7), 0.85)
end
_0xDFF1.hw_web(_0x6A4A, _0xBAC3.x + _0xB814.x - 6, _0xBAC3.y + 6, 80, -1, 1, 0.20)
_0xDFF1.hw_web(_0x6A4A, _0xBAC3.x + _0xB814.x - 6, _0xBAC3.y + _0xB814.y - 6, 100, -1, -1, 0.17)
endfunction _0xDFF1.hw_front(_0x0C0A, _0xA731, _0x91E7, _0xD740)
local _0x6A4A = _0x9C75(_0xEFB3.GetWindowDrawList)
_0xDFF1.hw_pumpkin(_0x6A4A, _0x91E7 - 135, _0xA731 + 3 - 22 * 0.78, 22, 1, true)
_0xDFF1.hw_pumpkin(_0x6A4A, _0x91E7 - 66, _0xA731 + 3 - 16 * 0.78, 16, 1, false)
_0xDFF1.hw_pumpkin(_0x6A4A, _0x0C0A + 80, _0xA731 + 3 - 19 * 0.78, 19, 1, false)
end
local function _0x77C1(_0x6130, _0x6319, tip)
local _0x28D2 = (_0x69CC == _0x6319)
local _0x4CF0 = _0xF228.accent
if _0x28D2 then
_0xEFB3.PushStyleColor(_0xEFB3.Col.Button, _0x2F6E(0.115, 0.28))
end
_0xEFB3.SetWindowFontScale(1.15)
local _0x14D3 = _0xEFB3.Button(_0x6130 .."##tab".. _0x6319, _0xEFB3.ImVec2(_0x9E4F - 10, _0xE16E.tab_h))
local _0xDF97 = _0xEFB3.IsItemHovered()
_0xEFB3.SetWindowFontScale(1.0)
if _0x14D3 then _0xDFF1.go_tab(_0x6319) end
if _0xDF97 and tip then _0xEFB3.SetTooltip(tip) end
if _0x28D2 then
_0xEFB3.PopStyleColor(1)
local _0xD3EB, _0xABFA = _0xEFB3.GetItemRectMin(), _0xEFB3.GetItemRectMax()
local _0x65AE = _0xEFB3.GetWindowPos()
_0xDFF1.bar_ty = (_0xD3EB.y + _0xABFA.y) / 2 - _0x65AE.y
_0xDFF1.bar_x = _0xD3EB.x + 2 - _0x65AE.xlocal _0x6A4A = _0xEFB3.GetWindowDrawList()
for _0x43EB = 3, 1, -1 do
_0x6A4A:AddRect(_0xEFB3.ImVec2(_0xD3EB.x - _0x43EB * 1.5, _0xD3EB.y - _0x43EB * 1.5), _0xEFB3.ImVec2(_0xABFA.x + _0x43EB * 1.5, _0xABFA.y + _0x43EB * 1.5),
_0xE27E(_0x4CF0[1], _0x4CF0[2], _0x4CF0[3], 0.07 * (4 - _0x43EB)), 8 + _0x43EB, 15, 1.2)
end
end
endfunction _0xED0C.step(tbl, _0x15EA, _0xF157, speed, _0x9BBB)
local _0x0448 = tbl[_0x15EA] or 0
_0x0448 = _0x0448 + (_0xF157 - _0x0448) * math.min(1, _0x9BBB * speed)
tbl[_0x15EA] = _0x0448
return _0x0448
endfunction _0xED0C.button(_0x6319, _0x6130, _0x53EC, _0x81C3, _0xCC7A, action)
local _0x6A4A = _0xEFB3.GetWindowDrawList()
local _0xBAC3 = _0xEFB3.GetCursorScreenPos()
local _0x27A0 = _0xEFB3.GetTime()
local _0x9BBB = _0xEFB3.GetIO().DeltaTime
local _0x14D3 = _0xEFB3.InvisibleButton("##cb".. _0x6319, _0xEFB3.ImVec2(_0x81C3, _0xCC7A))
local _0xDF97, _0x5BD6 = _0xEFB3.IsItemHovered(), _0xEFB3.IsItemActive()
if _0x14D3 then
local _0x7173 = _0xEFB3.GetMousePos()
_0xED0C.ripple[_0x6319] = { _0xF27D = _0x27A0, _0xD40E = _0x7173.x, _0xC60C = _0x7173.y }
action()
end
local _0x0D4F = _0xED0C.step(_0xED0C.hover, _0x6319, _0xDF97 and 1 or 0, 14, _0x9BBB)
local _0xC153 = _0xED0C.step(_0xED0C.press, _0x6319, _0x5BD6 and 1 or 0, 24, _0x9BBB)local _0xC3AF, _0x3A08, _0x5247
if _0x53EC == 2 then
local _0xC5C6 = _0xF228.accent
_0xC3AF, _0x3A08, _0x5247 = _0xC5C6[1], _0xC5C6[2], _0xC5C6[3]
elseif _0x53EC == 3 then
_0xC3AF, _0x3A08, _0x5247 = 0.55, 0.18, 0.20
elseif _0x53EC == 1 then
_0xC3AF, _0x3A08, _0x5247 = 0.20, 0.20, 0.23
else
_0xC3AF, _0x3A08, _0x5247 = 0.145, 0.145, 0.165
end
local _0xDDB1 = 0.07 * _0x0D4F - 0.05 * _0xC153
local _0x2CC1, _0xCAFA, _0x8AAA = _0xCD0C(_0xC3AF + _0xDDB1, 0, 1), _0xCD0C(_0x3A08 + _0xDDB1, 0, 1), _0xCD0C(_0x5247 + _0xDDB1, 0, 1)
local _0xAE2F = 2.5 * _0xC153local _0x91E7, _0xD740 = _0xBAC3.x + _0xAE2F, _0xBAC3.y + _0xAE2F
local _0xBCCB, _0x570E = _0xBAC3.x + _0x81C3 - _0xAE2F, _0xBAC3.y + _0xCC7A - _0xAE2F
local _0xACD7 = 11local _0x4CF0 = _0xF228.accent
local _0xF7FD = _0x0D4F
if _0x53EC == 2 then _0xF7FD = math.max(_0x0D4F, 0.35 + 0.25 * math.sin(_0x27A0 * 3.0)) end
if _0xF7FD > 0.02 then
for _0x43EB = 3, 1, -1 do
_0x6A4A:AddRect(_0xEFB3.ImVec2(_0x91E7 - _0x43EB * 1.6, _0xD740 - _0x43EB * 1.6), _0xEFB3.ImVec2(_0xBCCB + _0x43EB * 1.6, _0x570E + _0x43EB * 1.6),
_0xE27E(_0x4CF0[1], _0x4CF0[2], _0x4CF0[3], 0.10 * _0xF7FD * (4 - _0x43EB) / 3), _0xACD7 + _0x43EB, 15, 1.4)
end
end
_0x6A4A:AddRectFilled(_0xEFB3.ImVec2(_0x91E7, _0xD740), _0xEFB3.ImVec2(_0xBCCB, _0x570E), _0xE27E(_0x2CC1, _0xCAFA, _0x8AAA, 1), _0xACD7)_0x6A4A:AddRectFilled(_0xEFB3.ImVec2(_0x91E7 + 2, _0xD740 + 2), _0xEFB3.ImVec2(_0xBCCB - 2, _0xD740 + (_0x570E - _0xD740) * 0.45), _0xE27E(1, 1, 1, 0.045 + 0.03 * _0x0D4F), _0xACD7 - 2)local _0x7566 = 0.10 + 0.75 * _0x0D4F
_0x6A4A:AddRect(_0xEFB3.ImVec2(_0x91E7, _0xD740), _0xEFB3.ImVec2(_0xBCCB, _0x570E), _0xE27E(_0x4CF0[1], _0x4CF0[2], _0x4CF0[3], _0x7566), _0xACD7, 15, 1.2)local _0xCEC7 = _0xED0C.ripple[_0x6319]
if _0xCEC7 then
local _0x22D5 = (_0x27A0 - _0xCEC7.t) / 0.5
if _0x22D5 >= 1 then
_0xED0C.ripple[_0x6319] = nil
else
_0x6A4A:PushClipRect(_0xEFB3.ImVec2(_0x91E7, _0xD740), _0xEFB3.ImVec2(_0xBCCB, _0x570E), true)
_0x6A4A:AddCircleFilled(_0xEFB3.ImVec2(_0xCEC7.x, _0xCEC7.y), _0x22D5 * math.max(_0x81C3, _0xCC7A) * 1.1, _0xE27E(1, 1, 1, 0.30 * (1 - _0x22D5)), 32)
_0x6A4A:PopClipRect()
end
endlocal _0xA46C = _0xEFB3.CalcTextSize(_0x6130)
_0x6A4A:AddText(_0xEFB3.ImVec2(_0xBAC3.x + (_0x81C3 - _0xA46C.x) / 2, _0xBAC3.y + (_0xCC7A - _0xA46C.y) / 2 + _0xC153), _0xE27E(1, 1, 1, 0.95), _0x6130)
endfunction _0xED0C.display(_0x81C3, _0xCC7A)
local _0x27A0 = _0xEFB3.GetTime()
local _0x4CF0 = _0xF228.accent
local _0xBAC3 = _0xEFB3.GetCursorScreenPos()
local _0x6A4A = _0xEFB3.GetWindowDrawList()
local _0xD3B7 = _0xCD0C(1 - (_0x27A0 - _0xED0C.pop_t) / 0.6, 0, 1)
_0x6A4A:AddRectFilled(_0xBAC3, _0xEFB3.ImVec2(_0xBAC3.x + _0x81C3, _0xBAC3.y + _0xCC7A), _0xE27E(0.075, 0.075, 0.09, 1), 14)
_0x6A4A:AddRectFilled(_0xBAC3, _0xEFB3.ImVec2(_0xBAC3.x + _0x81C3, _0xBAC3.y + _0xCC7A), _0xE27E(_0x4CF0[1], _0x4CF0[2], _0x4CF0[3], 0.05 + 0.10 * _0xD3B7), 14)
_0x6A4A:AddRect(_0xBAC3, _0xEFB3.ImVec2(_0xBAC3.x + _0x81C3, _0xBAC3.y + _0xCC7A), _0xE27E(_0x4CF0[1], _0x4CF0[2], _0x4CF0[3], 0.35 + 0.55 * _0xD3B7), 14, 15, 1.5)
local _0xBF55 = _0xCD0C(_0xCC7A / 100 * 1.9, 1.7, 3.2)
local _0x95F5, _0xA6B2
if _0x023B then
_0x95F5, _0xA6B2 = _0x023B, { 1.0, 0.38, 0.38 }
else
_0x95F5, _0xA6B2 = (_0xCF33 =="") and"0"or _0x6F87(_0xCF33), { 1, 1, 1 }
end_0xEFB3.SetWindowFontScale(1.1)
local _0x2858 = _0x323C ~=""and _0x323C or""local _0x2607 = _0xEFB3.CalcTextSize(_0x2858)
_0x6A4A:AddText(_0xEFB3.ImVec2(_0xBAC3.x + _0x81C3 - 16 - _0x2607.x, _0xBAC3.y + 10), _0xE27E(0.62, 0.62, 0.68, 1), _0x2858)local _0x9D9C = 1 + 0.16 * _0xD3B7 * _0xD3B7
local _0x32AA = _0xBF55
_0xEFB3.SetWindowFontScale(_0x32AA)
while _0x32AA > 0.9 and _0xEFB3.CalcTextSize(_0x95F5).x > (_0x81C3 - 36) / _0x9D9C do
_0x32AA = _0x32AA - 0.1
_0xEFB3.SetWindowFontScale(_0x32AA)
end
local _0xA46C = _0xEFB3.CalcTextSize(_0x95F5)
local _0x4142 = _0x32AA * _0x9D9C
_0xEFB3.SetWindowFontScale(_0x4142)
_0xA46C = _0xEFB3.CalcTextSize(_0x95F5)
local _0xB349 = _0xBAC3.x + _0x81C3 - 18 - _0xA46C.x
local _0x4957 = _0xBAC3.y + _0xCC7A - 12 - _0xA46C.y + 4 * (1 - _0xD3B7)
_0x6A4A:AddText(_0xEFB3.ImVec2(_0xB349 + 1.5, _0x4957 + 1.5), _0xE27E(0, 0, 0, 0.5), _0x95F5)
_0x6A4A:AddText(_0xEFB3.ImVec2(_0xB349, _0x4957), _0xE27E(_0xA6B2[1], _0xA6B2[2], _0xA6B2[3], 1), _0x95F5)
_0xEFB3.SetWindowFontScale(1.0)
_0xEFB3.Dummy(_0xEFB3.ImVec2(_0x81C3, _0xCC7A))
endfunction _0xED0C.history(_0x81C3, _0xCC7A)
local _0x4CF0 = _0xF228.accent
if _0xEFB3.BeginChild("##calc_hist", _0xEFB3.ImVec2(_0x81C3, _0xCC7A), true) then
_0xEFB3.TextColored(_0xBD61(1.2), _0x2075("CLOCK_ROTATE_LEFT","") .." История")
_0xEFB3.Separator()
if #_0xED0C.hist == 0 then
_0xEFB3.TextColored(_0xEFB3.ImVec4(0.55, 0.55, 0.6, 1),"Пока пусто")
else
for _0x43EB = #_0xED0C.hist, 1, -1 do
local _0xA49F = _0xED0C.hist[_0x43EB]
_0xEFB3.PushStyleColor(_0xEFB3.Col.Button, _0xEFB3.ImVec4(0, 0, 0, 0))
_0xEFB3.PushStyleColor(_0xEFB3.Col.ButtonHovered, _0xBD61(1.0, 0.25))
_0xEFB3.PushStyleColor(_0xEFB3.Col.ButtonActive, _0xBD61(1.0, 0.4))
if _0xEFB3.Button(_0xA49F.res .."##h".. _0x43EB, _0xEFB3.ImVec2(-1, 34)) then
_0xCF33, _0x323C, _0x023B, _0x53E6 = _0xA49F.raw,"", nil, false
end
_0xEFB3.PopStyleColor(3)
_0xEFB3.TextColored(_0xEFB3.ImVec4(0.55, 0.55, 0.6, 1), _0xA49F.expr)
_0xEFB3.Spacing()
end
end
if #_0xED0C.hist > 0 then
if _0xEFB3.Button("Очистить##hclr", _0xEFB3.ImVec2(-1, 28)) then _0xED0C.hist = {} end
end
end
_0xEFB3.EndChild()
end
local function _0x17DF()
local _0x72C1, _0x5CFA = getScreenResolution()if not _0xED0C.grown then
_0xED0C.grown = true
if _0xE16E.w < 960 or _0xE16E.h < 640 then
_0xE16E.req = { _0x81C3 = math.min(math.max(_0xE16E.w, 980), _0x72C1 - 40), _0xCC7A = math.min(math.max(_0xE16E.h, 660), _0x5CFA - 40) }
end
end_0xEFB3.AlignTextToFramePadding()
_0xEFB3.SetCursorPosX(9)
_0xEFB3.Text(_0x2075("CALCULATOR","") .." Калькулятор")
_0xEFB3.SameLine(_0xE16E.w - _0x9E4F - 76)
_0xEFB3.PushStyleColor(_0xEFB3.Col.Button, _0xEFB3.ImVec4(0, 0, 0, 0))
if _0xEFB3.Button(_0x2075("CLOCK_ROTATE_LEFT","H") .."##calc_hist_btn", _0xEFB3.ImVec2(30, 24)) then
_0xED0C.hist_open = not _0xED0C.hist_open
end
_0xEFB3.SameLine(_0xE16E.w - _0x9E4F - 29)
if _0xEFB3.Button(_0xB914.CIRCLE_XMARK .."##close_calc", _0xEFB3.ImVec2(24, 24)) then
_0x950A[0] = false
end
if _0xEFB3.IsItemHovered() then _0xEFB3.SetTooltip("Закрыть") end
_0xEFB3.PopStyleColor(1)
_0xEFB3.Spacing()
local _0xD5D6 = _0xEFB3.GetContentRegionAvail()
local _0xDA49 = 9
local _0x4DD7 = _0xED0C.hist_open and 200 or 0
local _0x1F9D = _0xD5D6.x - _0x4DD7 - (_0x4DD7 > 0 and 12 or 0) - 16
local _0x27B6 = _0xCD0C(_0x1F9D, 300, 720)
local _0x152E = _0xCD0C(_0xD5D6.y * 0.25, 92, 160)
local _0x3931 = _0xCD0C((_0xD5D6.y - _0x152E - 6 * _0xDA49 - 6) / 5, 40, 110)
local _0x502E = (_0x27B6 - 3 * _0xDA49) / 4
local _0x0C0A = 8 + math.max(0, (_0x1F9D - _0x27B6) / 2)
local _0xA731 = _0xEFB3.GetCursorPosY()
_0xEFB3.SetCursorPos(_0xEFB3.ImVec2(_0x0C0A, _0xA731))
_0xED0C.display(_0x27B6, _0x152E)
local function _0xF60E(_0x3CF1) return function() _0x3076(_0x3CF1) end end
local function _0x9EC4(_0x3CF1) return function() _0xDB92(_0x3CF1) end end
local _0x848A = {
{ {"C", _0x5E2F, 3}, {_0x2075("DELETE_LEFT","<"), _0xD31E, 1}, {_0x2075("PERCENT","%"), _0x4631, 1}, {_0x2075("DIVIDE","/"), _0x9EC4("/"), 1} },
{ {"7", _0xF60E("7"), 0}, {"8", _0xF60E("8"), 0}, {"9", _0xF60E("9"), 0}, {_0x2075("XMARK","x"), _0x9EC4("*"), 1} },
{ {"4", _0xF60E("4"), 0}, {"5", _0xF60E("5"), 0}, {"6", _0xF60E("6"), 0}, {_0x2075("MINUS","-"), _0x9EC4("-"), 1} },
{ {"1", _0xF60E("1"), 0}, {"2", _0xF60E("2"), 0}, {"3", _0xF60E("3"), 0}, {_0x2075("PLUS","+"), _0x9EC4("+"), 1} },
{ {"0", _0xF60E("0"), 0}, {"000", _0xF60E("000"), 0}, {",", _0x7B91, 0}, {_0x2075("EQUALS","="), _0x681D, 2} },
}
_0xEFB3.SetWindowFontScale(_0xCD0C(_0x3931 / 54 * 1.25, 1.2, 2.0))
for _0x2CC1, row in ipairs(_0x848A) do
_0xEFB3.SetCursorPos(_0xEFB3.ImVec2(_0x0C0A, _0xA731 + _0x152E + _0xDA49 + (_0x2CC1 - 1) * (_0x3931 + _0xDA49)))
for _0x65BB, _0x8AAA in ipairs(row) do
if _0x65BB > 1 then _0xEFB3.SameLine(0, _0xDA49) end
_0xED0C.button(_0x2CC1 .."_".. _0x65BB, _0x8AAA[1], _0x8AAA[3], _0x502E, _0x3931, _0x8AAA[2])
end
end
_0xEFB3.SetWindowFontScale(1.0)
if _0x4DD7 > 0 then
_0xEFB3.SetCursorPos(_0xEFB3.ImVec2(_0x0C0A + _0x27B6 + 12 + math.max(0, (_0x1F9D - _0x27B6) / 2) * 0, _0xA731))
_0xED0C.history(_0x4DD7, _0x152E + 5 * (_0x3931 + _0xDA49))
end
endlocal _0xFF94 = getWorkingDirectory() .."\\config\\arizona_prices_settings.json"local _0x3049 = { ui = _0xF228, favs = {}, notes ="", payday = { enabled = false, _0xD40E = 20, _0xC60C = 300 }, phrases = {}, clock = { enabled = false, country ="Узбекистан", _0xD40E = 20, _0xC60C = 340 } }
local function _0xC3A6()
local _0x9779 = _0x5729(_0xFF94)
if not _0x9779 then return end
if type(_0x9779.payday) =="table"then
_0x3049.payday.enabled = (_0x9779.payday.enabled == true)
_0x3049.payday.x = tonumber(_0x9779.payday.x) or 20
_0x3049.payday.y = tonumber(_0x9779.payday.y) or 300
end
if type(_0x9779.phrases) =="table"then
local _0x3205 = {}
for _0xEDD8, _0x0448 in ipairs(_0x9779.phrases) do
if type(_0x0448) =="string"and _0x0448 ~=""then _0x3205[#_0x3205 + 1] = _0x0448 end
end
_0x3049.phrases = _0x3205
end
if type(_0x9779.clock) =="table"then
_0x3049.clock.enabled = (_0x9779.clock.enabled == true)
if type(_0x9779.clock.country) =="string"then _0x3049.clock.country = _0x9779.clock.country end
_0x3049.clock.x = tonumber(_0x9779.clock.x) or 20
_0x3049.clock.y = tonumber(_0x9779.clock.y) or 340
end
if type(_0x9779.favs) =="table"then
local _0xE8B2 = {}
for _0x22D5, _0x0448 in pairs(_0x9779.favs) do
if type(_0x22D5) =="string"and _0x0448 == true then _0xE8B2[_0x22D5] = true end
end
_0x3049.favs = _0xE8B2
end
if type(_0x9779.notes) =="string"then _0x3049.notes = _0x9779.notes:sub(1, 8000) end
if type(_0x9779.ui) =="table"then
local _0x91AC = _0x9779.ui
if type(_0x91AC.accent) =="table"and tonumber(_0x91AC.accent[1]) and tonumber(_0x91AC.accent[2]) and tonumber(_0x91AC.accent[3]) then
_0xF228.accent = { _0xCD0C(tonumber(_0x91AC.accent[1]), 0, 1), _0xCD0C(tonumber(_0x91AC.accent[2]), 0, 1), _0xCD0C(tonumber(_0x91AC.accent[3]), 0, 1) }
end
_0xF228.opacity = _0xCD0C(tonumber(_0x91AC.opacity) or 1.0, 0.3, 1.0)
_0xF228.overlay_scale = _0xCD0C(tonumber(_0x91AC.overlay_scale) or 1.0, 0.7, 2.0)
_0xF228.open_key = math.max(0, math.floor(tonumber(_0x91AC.open_key) or 0))
_0xF228.toasts = (_0x91AC.toasts ~= false)
_0xF228.toast_corner = _0xCD0C(math.floor(tonumber(_0x91AC.toast_corner) or 3), 0, 3)
_0xF228.border_mode = _0xCD0C(math.floor(tonumber(_0x91AC.border_mode) or 1), 0, 3)
_0xF228.border_speed = _0xCD0C(tonumber(_0x91AC.border_speed) or 1.0, 0.2, 3.0)
_0xF228.shadow = (_0x91AC.shadow ~= false)
_0xF228.bg_fx = (_0x91AC.bg_fx ~= false)
_0xF228.splash = (_0x91AC.splash ~= false)
if _0x91AC.halloween == nil then
_0xF228.halloween = true
_0xF228.accent = { 0.98, 0.55, 0.12 }
else
_0xF228.halloween = (_0x91AC.halloween == true)
end
if type(_0x91AC.font) =="string"then _0xF228.font = _0x91AC.font end
_0xF228.win_w = _0xCD0C(math.floor(tonumber(_0x91AC.win_w) or 835), 700, 2400)
_0xF228.win_h = _0xCD0C(math.floor(tonumber(_0x91AC.win_h) or 500), 400, 1400)
end
end
local function _0xF5E0()
local _0xEEB2 = getWorkingDirectory() .."\\config"if not doesDirectoryExist(_0xEEB2) then
createDirectory(_0xEEB2)
end
local _0x054C, _0xE79B = pcall(encodeJson, _0x3049)
if _0x054C and type(_0xE79B) =="string"and _0xE79B ~=""then
_0x35AE(_0xFF94, _0xE79B)
end
end
_0x2C6A("load_settings", _0xC3A6)_0xDFF1.notes = _0xEFB3.new.char[8192]()
_0xEFB3.StrCopy(_0xDFF1.notes, _0x3049.notes or"")
function _0xDFF1.toggle_fav(_0x4D0B)
if _0x3049.favs[_0x4D0B] then _0x3049.favs[_0x4D0B] = nil else _0x3049.favs[_0x4D0B] = true end
_0xF5E0()
end
local _0xE043 = _0xEFB3.new.bool(_0x3049.payday.enabled)
local _0xF152 = false
local _0x4FC4 = { _0xD40E = _0x3049.payday.x, _0xC60C = _0x3049.payday.y }
local _0x83C4 = _0xEFB3.new.char[256]()
local function _0x094F()
local _0x7173 = tonumber(os.date("%M")) or 0
if _0x7173 < 30 then return 30 - _0x7173 end
return 60 - _0x7173
end
local function _0x2618()
local _0xF60E = os.date("*t")
local _0x6883 = 1800 - ((_0xF60E.min % 30) * 60 + _0xF60E.sec)
return"До PayDay: ".. math.floor(_0x6883 / 60) .." мин ".. string.format("%02d", _0x6883 % 60) .." сек"end
local function _0xDE9A(_0x3CF1)
local _0x7093, _0x14C5 = _0x3CF1 % 10, _0x3CF1 % 100
if _0x14C5 >= 11 and _0x14C5 <= 14 then return"минут"end
if _0x7093 == 1 then return"минута"end
if _0x7093 >= 2 and _0x7093 <= 4 then return"минуты"end
return"минут"end
local function _0x2C44(_0xD5FA, _0xFC74)
_0xEFB3.AlignTextToFramePadding()
_0xEFB3.SetCursorPosX(9)
_0xEFB3.Text(_0xD5FA .." ".. _0xFC74)
_0xEFB3.SameLine(_0xE16E.w - _0x9E4F - 29)
_0xEFB3.PushStyleColor(_0xEFB3.Col.Button, _0xEFB3.ImVec4(0, 0, 0, 0))
if _0xEFB3.Button(_0xB914.CIRCLE_XMARK .."##close_section", _0xEFB3.ImVec2(24, 24)) then
_0x950A[0] = false
end
if _0xEFB3.IsItemHovered() then _0xEFB3.SetTooltip("Закрыть") end
_0xEFB3.PopStyleColor(1)
_0xEFB3.Spacing()
end
local function _0xF910()
_0x2C44(_0x2075("CLOCK",""),"Отчет до PayDay")
if _0xEFB3.BeginChild("##payday_child", _0xEFB3.ImVec2(-1, _0xE16E.h - 79), true) then
_0xEFB3.SetWindowFontScale(1.35)
_0xEFB3.TextWrapped("На экране появится надпись «До PayDay: N мин N сек». PayDay выплачивается каждые 30 минут: в :00 и :30.")
_0xEFB3.Spacing()
if _0xEFB3.Checkbox(" Включить", _0xE043) then
_0x3049.payday.enabled = _0xE043[0]
_0xF5E0()
end
_0xEFB3.Spacing()
_0xEFB3.Separator()
_0xEFB3.Spacing()
_0xEFB3.Text("Положение надписи на экране:")
_0xEFB3.Spacing()
if not _0xF152 then
if _0xEFB3.Button(_0x2075("UP_DOWN_LEFT_RIGHT","") .." Передвинуть надпись", _0xEFB3.ImVec2(360, 56)) then
_0xF152 = true
_0xE043[0] = true
end
else
_0xEFB3.TextColored(_0xEFB3.ImVec4(0.45, 1.00, 0.55, 1.00),"Перетащи надпись мышкой, затем нажми «Сохранить».")
if _0xEFB3.Button(_0xB914.FLOPPY_DISK .." Сохранить положение", _0xEFB3.ImVec2(360, 56)) then
_0x3049.payday.x = _0x4FC4.x
_0x3049.payday.y = _0x4FC4.y
_0x3049.payday.enabled = _0xE043[0]
_0xF5E0()
_0xF152 = false
_0x3D10("Положение надписи сохранено","ok")
end
end
_0xEFB3.Spacing()
_0xEFB3.TextDisabled("Сейчас: ".. _0x2618())
_0xEFB3.SetWindowFontScale(1.0)
end
_0xEFB3.EndChild()
end
local function _0x337B()
_0x2C44(_0x2075("COMMENT_DOTS",""),"Фразы для автоотправки")
_0xEFB3.SetWindowFontScale(1.3)
_0xEFB3.SetNextItemWidth(_0xEFB3.GetContentRegionAvail().x - 190)
local _0x1C35 = _0xEFB3.InputTextWithHint("##phrase_input","Введи фразу или команду (например /time)", _0x83C4, _0x0A3B.sizeof(_0x83C4), _0xEFB3.InputTextFlags.EnterReturnsTrue)
_0xEFB3.SameLine()
local _0x8104 = _0xEFB3.Button(_0xB914.CIRCLE_PLUS .." Добавить##add_phrase", _0xEFB3.ImVec2(180, 0))
if _0x1C35 or _0x8104 then
local _0xF692 = _0x0A3B.string(_0x83C4)
if _0xF692:gsub("%s","") ~=""then
table.insert(_0x3049.phrases, _0xF692)
_0xF5E0()
_0xEFB3.StrCopy(_0x83C4,"")
end
end
_0xEFB3.Spacing()
if _0xEFB3.BeginChild("##phrases_list", _0xEFB3.ImVec2(-1, -36), true) then
if #_0x3049.phrases == 0 then
_0xEFB3.TextDisabled("Пока нет фраз. Добавь первую выше.")
end
local _0xA6B0 = nil
for _0x43EB, phrase in ipairs(_0x3049.phrases) do
if _0xEFB3.Button(_0xB914.PAPER_PLANE .."##send_phrase_".. _0x43EB, _0xEFB3.ImVec2(52, 40)) then
local _0x1F47 = phrase
_0x5104(function() sampSendChat(_0x1329:decode(_0x1F47)) end)
end
if _0xEFB3.IsItemHovered() then _0xEFB3.SetTooltip("Отправить в чат") end
_0xEFB3.SameLine()
if _0xEFB3.Button(_0xB914.TRASH_CAN .."##del_phrase_".. _0x43EB, _0xEFB3.ImVec2(52, 40)) then
_0xA6B0 = _0x43EB
end
if _0xEFB3.IsItemHovered() then _0xEFB3.SetTooltip("Удалить фразу") end
_0xEFB3.SameLine()
_0xEFB3.AlignTextToFramePadding()
_0xEFB3.TextUnformatted(phrase)
end
if _0xA6B0 then
table.remove(_0x3049.phrases, _0xA6B0)
_0xF5E0()
end
end
_0xEFB3.EndChild()
_0xEFB3.SetWindowFontScale(1.0)
end
local _0xDAA6 = {
{ _0xD5FA ="PAPER_PLANE", _0xFC74 ="Telegram-канал", _0x4BB2 ="https://t.me/arizona_prices", _0xA6B2 = {0.16, 0.62, 0.86} },
{ _0xD5FA ="COMMENTS", _0xFC74 ="Discord-канал", _0x4BB2 ="https://discord.gg/z4UmCnRwd", _0xA6B2 = {0.35, 0.40, 0.95} },
{ _0xD5FA ="MUSIC", _0xFC74 ="TikTok-канал", _0x4BB2 ="https://www.tiktok.com/@cosmychesky_jetpack", _0xA6B2 = {0.86, 0.15, 0.40} },
{ _0xD5FA ="USER", _0xFC74 ="Discord разработчика", copy ="sawnoff_karabin07", _0xA6B2 = {0.35, 0.40, 0.95} },
{ _0xD5FA ="PAPER_PLANE", _0xFC74 ="ЛС разработчика в Telegram", _0x4BB2 ="https://t.me/xi_vivide", _0xA6B2 = {0.16, 0.62, 0.86} },
{ _0xD5FA ="PAPER_PLANE", _0xFC74 ="ЛС разработчика в Telegram 2", _0x4BB2 ="https://t.me/obrezik", _0xA6B2 = {0.16, 0.62, 0.86} },
}
local function _0x00ED()
_0x2C44(_0x2075("CIRCLE_INFO",""),"О скрипте")
if _0xEFB3.BeginChild("##about_child", _0xEFB3.ImVec2(-1, _0xE16E.h - 79), true) then
_0xEFB3.SetWindowFontScale(1.25)
_0xEFB3.TextColored(_0xEFB3.ImVec4(0.30, 0.65, 1.00, 1.00),"Arizona Prices V2.0")
_0xEFB3.TextWrapped("Спасибо, что пользуешься скриптом! Заходи в наши соцсети: там актуальные цены, новости и обновления. Нашёл ошибку или есть идея - пиши разработчику в личные сообщения.")
_0xEFB3.Spacing()
_0xEFB3.Separator()
_0xEFB3.Spacing()
for _0x43EB, _0xCAD9 in ipairs(_0xDAA6) do
local _0x65BB = _0xCAD9.color
_0xEFB3.PushStyleColor(_0xEFB3.Col.Button, _0xEFB3.ImVec4(_0x65BB[1] * 0.55, _0x65BB[2] * 0.55, _0x65BB[3] * 0.55, 1.00))
_0xEFB3.PushStyleColor(_0xEFB3.Col.ButtonHovered, _0xEFB3.ImVec4(_0x65BB[1] * 0.80, _0x65BB[2] * 0.80, _0x65BB[3] * 0.80, 1.00))
_0xEFB3.PushStyleColor(_0xEFB3.Col.ButtonActive, _0xEFB3.ImVec4(_0x65BB[1], _0x65BB[2], _0x65BB[3], 1.00))
if _0xEFB3.Button("##about_".. _0x43EB, _0xEFB3.ImVec2(-1, 56)) then
if _0xCAD9.url then
_0x091E(_0xCAD9.url)
elseif _0xCAD9.copy then
_0xEFB3.SetClipboardText(_0xCAD9.copy)
_0x3D10("Ник скопирован: ".. _0xCAD9.copy,"ok")
end
end
local _0xD3EB, _0xABFA = _0xEFB3.GetItemRectMin(), _0xEFB3.GetItemRectMax()
local _0x6A4A = _0xEFB3.GetWindowDrawList()
local _0xE58A = (_0xD3EB.y + _0xABFA.y) / 2
local _0xA46C = _0xEFB3.CalcTextSize(_0xCAD9.title)
_0x6A4A:AddText(_0xEFB3.ImVec2((_0xD3EB.x + _0xABFA.x) / 2 - _0xA46C.x / 2, _0xE58A - _0xA46C.y / 2), 0xFFFFFFFF, _0xCAD9.title)
local _0xD5FA = _0x2075(_0xCAD9.icon,"")
local _0x2410 = _0xEFB3.CalcTextSize(_0xD5FA)
_0x6A4A:AddText(_0xEFB3.ImVec2(_0xD3EB.x + 18, _0xE58A - _0x2410.y / 2), 0xFFFFFFFF, _0xD5FA)
_0xEFB3.PopStyleColor(3)
end
_0xEFB3.SetWindowFontScale(1.0)
end
_0xEFB3.EndChild()
endlocal function _0xCE99(_0xC60C, _0x7173, _0xF60E)
if _0x7173 <= 2 then _0xC60C = _0xC60C - 1 end
local _0xE372 = math.floor(_0xC60C / 400)
local _0x10ED = _0xC60C - _0xE372 * 400
local _0xB442 = (_0x7173 + 9) % 12
local _0x923A = math.floor((153 * _0xB442 + 2) / 5) + _0xF60E - 1
local _0x2CFF = _0x10ED * 365 + math.floor(_0x10ED / 4) - math.floor(_0x10ED / 100) + _0x923A
return _0xE372 * 146097 + _0x2CFF - 719468
end
local function _0x68A4(_0xC60C, _0x7173, _0xF60E, _0xCC7A)
return _0xCE99(_0xC60C, _0x7173, _0xF60E) * 86400 + _0xCC7A * 3600
end
local function _0x9569(_0xC60C, _0x7173, _0xF60E)return (_0xCE99(_0xC60C, _0x7173, _0xF60E) + 4) % 7
end
local function _0xA83C(_0xC60C, _0x7173, _0x3CF1)
local _0xB554 = 1 + (7 - _0x9569(_0xC60C, _0x7173, 1)) % 7
return _0xB554 + (_0x3CF1 - 1) * 7
end
local function _0x254D(_0xC60C, _0x7173)
local _0x3174 = ({31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31})[_0x7173]
return _0x3174 - _0x9569(_0xC60C, _0x7173, _0x3174)
end
local function _0x48AF(rule, std_offset, _0x27A0)
local _0xC60C = tonumber(os.date("!%Y", _0x27A0))
if rule =="eu"then
local _0xB814 = _0x68A4(_0xC60C, 3, _0x254D(_0xC60C, 3), 1)
local _0xA49F = _0x68A4(_0xC60C, 10, _0x254D(_0xC60C, 10), 1)
return _0x27A0 >= _0xB814 and _0x27A0 < _0xA49F
elseif rule =="us"then
local _0xB814 = _0x68A4(_0xC60C, 3, _0xA83C(_0xC60C, 3, 2), 2) - std_offset * 3600
local _0xA49F = _0x68A4(_0xC60C, 11, _0xA83C(_0xC60C, 11, 1), 2) - (std_offset + 1) * 3600
return _0x27A0 >= _0xB814 and _0x27A0 < _0xA49F
end
return false
end
local function _0x80AE()
local _0x27A0 = os.time()
local _0xCAD9 = os.date("*t", _0x27A0)
local _0x91AC = os.date("!*t", _0x27A0)
_0x91AC.isdst = _0xCAD9.isdst
return os.difftime(os.time(_0xCAD9), os.time(_0x91AC)) / 3600
end
local _0x8568 = {
{ _0x4D0B ="Азербайджан", _0x77AD = 4 },
{ _0x4D0B ="Армения", _0x77AD = 4 },
{ _0x4D0B ="Беларусь", _0x77AD = 3 },
{ _0x4D0B ="Великобритания", _0x77AD = 0, dst ="eu"},
{ _0x4D0B ="Германия", _0x77AD = 1, dst ="eu"},
{ _0x4D0B ="Грузия", _0x77AD = 4 },
{ _0x4D0B ="Индия", _0x77AD = 5.5 },
{ _0x4D0B ="Казахстан", _0x77AD = 5 },
{ _0x4D0B ="Китай", _0x77AD = 8 },
{ _0x4D0B ="Кыргызстан", _0x77AD = 6 },
{ _0x4D0B ="Москва (время Аризоны)", _0x77AD = 3 },
{ _0x4D0B ="ОАЭ", _0x77AD = 4 },
{ _0x4D0B ="Польша", _0x77AD = 1, dst ="eu"},
{ _0x4D0B ="Россия, Владивосток", _0x77AD = 10 },
{ _0x4D0B ="Россия, Екатеринбург", _0x77AD = 5 },
{ _0x4D0B ="Россия, Новосибирск", _0x77AD = 7 },
{ _0x4D0B ="США, Лос-Анджелес", _0x77AD = -8, dst ="us"},
{ _0x4D0B ="США, Нью-Йорк", _0x77AD = -5, dst ="us"},
{ _0x4D0B ="Таджикистан", _0x77AD = 5 },
{ _0x4D0B ="Таиланд", _0x77AD = 7 },
{ _0x4D0B ="Турция", _0x77AD = 3 },
{ _0x4D0B ="Узбекистан", _0x77AD = 5 },
{ _0x4D0B ="Украина", _0x77AD = 2, dst ="eu"},
{ _0x4D0B ="Япония", _0x77AD = 9 },
}
local _0xFF8E = 1
for _0x43EB, _0x65BB in ipairs(_0x8568) do
if _0x65BB.name =="Узбекистан"then _0xFF8E = _0x43EB end
end
local function _0x6C06(_0x65BB)
local _0x27A0 = os.time()
local _0x77AD
if _0x65BB.pc then
_0x77AD = _0x80AE()
else
_0x77AD = _0x65BB.off
if _0x65BB.dst and _0x48AF(_0x65BB.dst, _0x65BB.off, _0x27A0) then _0x77AD = _0x77AD + 1 end
end
local _0xF5C2 = _0x27A0 + _0x77AD * 3600
return os.date("!%H:%M:%S", _0xF5C2), os.date("!%d.%m.%Y", _0xF5C2)
end
local function _0x89E0(_0xA6B2, _0xF692)
local _0xBAC3 = _0xEFB3.GetCursorScreenPos()
_0xEFB3.GetWindowDrawList():AddText(_0xEFB3.ImVec2(_0xBAC3.x + 1, _0xBAC3.y + 1), 0xFF000000, _0xF692)
_0xEFB3.TextColored(_0xA6B2, _0xF692)
end
local _0xACE4 = false
local _0x8C26 = { _0xD40E = _0x3049.clock.x, _0xC60C = _0x3049.clock.y }
local _0x1D73 = false
local _0x0573 = nil
local _0x4EB8 ="Время на экране###clock_modal"local function _0x758B(_0x4D0B)
for _0xEDD8, _0x65BB in ipairs(_0x8568) do
if _0x65BB.name == _0x4D0B then return _0x65BB end
end
return _0x8568[1]
end
local function _0xC0C5()
_0x2C44(_0x2075("GLOBE",""),"Время стран")
if _0xEFB3.BeginChild("##time_child", _0xEFB3.ImVec2(-1, _0xE16E.h - 79), true) then
local _0xD436 = _0x8568[_0xFF8E]
local _0x564F, _0x9BBB = _0x6C06(_0xD436)
local _0xB6D3 = _0xEFB3.GetWindowWidth()
_0xEFB3.SetWindowFontScale(2.4)
local _0xA46C = _0xEFB3.CalcTextSize(_0x564F)
_0xEFB3.SetCursorPosX(math.max(5, (_0xB6D3 - _0xA46C.x) / 2))
_0xEFB3.TextColored(_0xEFB3.ImVec4(1.00, 0.85, 0.30, 1.00), _0x564F)
_0xEFB3.SetWindowFontScale(1.0)
local _0x6130 = _0xD436.name .."  |  ".. _0x9BBB
local _0x7316 = _0xEFB3.CalcTextSize(_0x6130)
_0xEFB3.SetCursorPosX(math.max(5, (_0xB6D3 - _0x7316.x) / 2))
_0xEFB3.Text(_0x6130)
_0xEFB3.Spacing()
_0xEFB3.Separator()
_0xEFB3.Spacing()
if _0x3049.clock.enabled then
_0xEFB3.AlignTextToFramePadding()
_0xEFB3.Text("На экране: ".. _0x3049.clock.country)
_0xEFB3.SameLine()
if not _0xACE4 then
if _0xEFB3.Button("Передвинуть##clock_move") then _0xACE4 = true end
else
if _0xEFB3.Button(_0xB914.FLOPPY_DISK .." Сохранить положение##clock_save") then
_0x3049.clock.x = _0x8C26.x
_0x3049.clock.y = _0x8C26.y
_0xF5E0()
_0xACE4 = false
end
end
_0xEFB3.SameLine()
if _0xEFB3.Button("Убрать с экрана##clock_hide") then
_0x3049.clock.enabled = false
_0xACE4 = false
_0xF5E0()
end
if _0xACE4 then
_0xEFB3.TextColored(_0xEFB3.ImVec4(0.45, 1.00, 0.55, 1.00),"Перетащи надпись мышкой, затем нажми «Сохранить положение».")
end
_0xEFB3.Spacing()
_0xEFB3.Separator()
_0xEFB3.Spacing()
end
if _0xEFB3.BeginChild("##time_list", _0xEFB3.ImVec2(-1, -1), false) then
local _0x44C0 = math.floor((_0xEFB3.GetContentRegionAvail().x - 10 - 16) / 3)
for _0x43EB, _0x65BB in ipairs(_0x8568) do
if (_0x43EB - 1) % 3 ~= 0 then _0xEFB3.SameLine() end
local _0xCF31 = _0x6C06(_0x65BB)
local _0x28D2 = (_0x43EB == _0xFF8E)
if _0x28D2 then
_0xEFB3.PushStyleColor(_0xEFB3.Col.Button, _0xBD61(1.0))
end
if _0xEFB3.Button(_0x65BB.name .."\n".. _0xCF31 .."###country_".. _0x43EB, _0xEFB3.ImVec2(_0x44C0, 44)) then
_0xFF8E = _0x43EB
_0x0573 = _0x43EB
_0x1D73 = true
local _0x5EC7, _0xB719 = _0x6C06(_0x65BB)
local _0x96F0 = _0x1329:decode("{33AAFF}[Arizona Prices] {FFFFFF}Время (".. _0x65BB.name .."): {33AAFF}".. _0x5EC7 .." {FFFFFF}(".. _0xB719 ..")")
_0x5104(function() sampAddChatMessage(_0x96F0, -1) end)
end
if _0x28D2 then _0xEFB3.PopStyleColor(1) end
end
end
_0xEFB3.EndChild()
if _0x1D73 then
_0xEFB3.OpenPopup(_0x4EB8)
_0x1D73 = false
end
local _0x72C1, _0x5CFA = getScreenResolution()
_0xEFB3.SetNextWindowPos(_0xEFB3.ImVec2(_0x72C1 / 2, _0x5CFA / 2), _0xEFB3.Cond.Always, _0xEFB3.ImVec2(0.5, 0.5))
_0xEFB3.SetNextWindowSize(_0xEFB3.ImVec2(400, 135), _0xEFB3.Cond.Always)
if _0xEFB3.BeginPopupModal(_0x4EB8, nil, bit.bor(_0xEFB3.WindowFlags.NoCollapse, _0xEFB3.WindowFlags.NoResize)) then
local _0x387D = _0x8568[_0x0573 or _0xFF8E]
_0xEFB3.TextColored(_0xEFB3.ImVec4(1.00, 0.85, 0.30, 1.00), _0x387D.name)
_0xEFB3.TextWrapped("Показывать время этой страны на экране?")
_0xEFB3.Spacing()
local _0xC835 = (_0xEFB3.GetContentRegionAvail().x - 5) / 2
if _0xEFB3.Button(_0x2075("CIRCLE_CHECK","") .." Да##clock_yes", _0xEFB3.ImVec2(_0xC835, 34)) then
_0x3049.clock.enabled = true
_0x3049.clock.country = _0x387D.name
_0xF5E0()
_0xEFB3.CloseCurrentPopup()
end
_0xEFB3.SameLine()
if _0xEFB3.Button(_0xB914.CIRCLE_XMARK .." Нет##clock_no", _0xEFB3.ImVec2(_0xC835, 34)) then
_0xEFB3.CloseCurrentPopup()
end
_0xEFB3.EndPopup()
end
end
_0xEFB3.EndChild()
end
local _0xE3BD
_0xE3BD = _0xEFB3.OnFrame(
function()
_0xE3BD.HideCursor = not _0xACE4
return _0x3049.clock.enabled
end,
_0xD9E5("clock", function()
if _0xACE4 and not _0x950A[0] then _0xACE4 = false end
local _0x6F06 = bit.bor(_0xEFB3.WindowFlags.NoTitleBar, _0xEFB3.WindowFlags.AlwaysAutoResize, _0xEFB3.WindowFlags.NoScrollbar, _0xEFB3.WindowFlags.NoSavedSettings)
if not _0xACE4 then
_0x6F06 = bit.bor(_0x6F06, _0xEFB3.WindowFlags.NoMove, _0xEFB3.WindowFlags.NoInputs, _0xEFB3.WindowFlags.NoBackground)
_0xEFB3.SetNextWindowPos(_0xEFB3.ImVec2(_0x8C26.x, _0x8C26.y), _0xEFB3.Cond.Always)
end
_0xEFB3.SetNextWindowBgAlpha(0.45)
_0xEFB3.Begin("##clock_overlay", nil, _0x6F06)
_0xEFB3.SetWindowFontScale(_0xF228.overlay_scale)
local _0x65BB = _0x758B(_0x3049.clock.country)
_0x89E0(_0xEFB3.ImVec4(0.55, 0.85, 1.00, 1.00), _0x65BB.name ..": ".. _0x6C06(_0x65BB))
if _0xACE4 then
local _0x8CE5 = _0xEFB3.GetWindowPos()
_0x8C26.x, _0x8C26.y = _0x8CE5.x, _0x8CE5.y
end
_0xEFB3.End()
end, function() _0x3049.clock.enabled = false end)
)local _0x2CC5 ="3.2"local _0xF2A2 ="https://raw.githubusercontent.com/hydracrmpdesign-commits/arizona-prices/main/"local _0xEBE6 = 1800local _0x544B = getWorkingDirectory() .."\\config\\"local _0x5410 = _0x544B .."arizona_prices_state.json"local _0xD85E = { prices_sig ="", auto_prices = true }
local _0x911D = { available = false, version ="", _0x41CB = false, status =""}
local _0x26F5 = {}
local _0xE914 = false
local _0x7D83 = false
local _0x4A62 = 0
local _0x73AC, _0x1287 = pcall(require,'moonloader')
local _0x3C5C = _0x73AC and _0x1287.download_status or nil
local function _0x3B0C(_0x374D)
local _0xE8B2 = io.open(_0x374D,"rb")
if not _0xE8B2 then return nil end
local _0x65BB = _0xE8B2:read("*a")
_0xE8B2:close()
return _0x65BB
end
local function _0x49AE(_0x374D, content)
local _0xE8B2 = io.open(_0x374D,"wb")
if not _0xE8B2 then return false end
_0xE8B2:write(content)
_0xE8B2:close()
return true
end
local function _0xD5A6()
local _0x65BB = _0x3B0C(_0x5410)
if _0x65BB then
local _0x054C, _0xF60E = pcall(decodeJson, _0x65BB)
if _0x054C and type(_0xF60E) =="table"then
if type(_0xF60E.prices_sig) =="string"then _0xD85E.prices_sig = _0xF60E.prices_sig end
if _0xF60E.auto_prices == false then _0xD85E.auto_prices = false end
end
end
end
local function _0xC16C()
if not doesDirectoryExist(_0x544B) then createDirectory(_0x544B) end
_0x35AE(_0x5410, encodeJson(_0xD85E))
end
_0x2C6A("load_state", _0xD5A6)
local _0x1C58 = _0xEFB3.new.bool(_0xD85E.auto_prices)
local function _0x82CF(_0x5886, current)
local _0xC5C6, _0x8AAA = {}, {}
for _0x3CF1 in tostring(_0x5886):gmatch("%d+") do _0xC5C6[#_0xC5C6 + 1] = tonumber(_0x3CF1) end
for _0x3CF1 in tostring(current):gmatch("%d+") do _0x8AAA[#_0x8AAA + 1] = tonumber(_0x3CF1) end
for _0x43EB = 1, math.max(#_0xC5C6, #_0x8AAA) do
local _0xD40E, _0xC60C = _0xC5C6[_0x43EB] or 0, _0x8AAA[_0x43EB] or 0
if _0xD40E ~= _0xC60C then return _0xD40E > _0xC60C end
end
return false
end
local function _0xA5DE(_0xB814)
local _0xB8AC = 0
for _0x43EB = 1, #_0xB814 do _0xB8AC = (_0xB8AC * 31 + _0xB814:byte(_0x43EB)) % 4294967291 end
return #_0xB814 ..":".. _0xB8AC
endlocal function _0xA0FC(_0x4D0B, _0x0EC1, flag)
os.remove(_0x0EC1)
if not _0x3C5C or not downloadUrlToFile then
_0x911D.status ="Загрузка недоступна"return false
end
local _0x4BB2 = _0xF2A2 .. _0x4D0B .."?t=".. os.time()
local _0x054C = pcall(downloadUrlToFile, _0x4BB2, _0x0EC1, function(_0x6319, status, _0x6549, p2)
if status == _0x3C5C.STATUSEX_ENDDOWNLOAD then
_0x26F5[flag] = true
end
end)
return _0x054C
end
local function _0x76E0()
if not doesDirectoryExist(_0x544B) then createDirectory(_0x544B) end
_0xA0FC("version.txt", _0x544B .."arizona_prices_remote_version.txt","version")
if _0xD85E.auto_prices then
_0xA0FC("item_prices.json", _0x544B .."arizona_prices_remote.json","prices")
end
end
local function _0xD0F3()
local _0x374D = _0x544B .."arizona_prices_remote_version.txt"local _0x65BB = _0x3B0C(_0x374D)
os.remove(_0x374D)
local _0x0448 = _0x65BB and _0x65BB:match("%d[%d%.]*")
if _0x0448 and _0x82CF(_0x0448, _0x2CC5) then
if not _0x911D.available then
_0x3D10("Вышла новая версия ".. _0x0448 .."! Откройте /prices и нажмите «Обновить»","info", 8)
end
_0x911D.available = true
_0x911D.version = _0x0448
_0x911D.status =""elseif _0x7D83 then
_0x911D.status = _0x0448 and"У вас последняя версия"or"Не удалось проверить"end
_0x7D83 = false
end
local function _0x944F()
local _0x0EC1 = _0x544B .."arizona_prices_update.lua"local _0x65BB = _0x3B0C(_0x0EC1)
_0x911D.busy = false
if not _0x65BB or #_0x65BB < 2000 then
_0x911D.status ="Ошибка загрузки"return
end
if not loadstring(_0x65BB) then
_0x911D.status ="Файл повреждён"return
end
local _0xA8AA = thisScript().path
local _0x6792 = _0x3B0C(_0xA8AA)
if _0x6792 then _0x49AE(_0x544B .."Table_Prices.lua.bak", _0x6792) end
if _0x49AE(_0xA8AA, _0x65BB) then
os.remove(_0x0EC1)
_0x911D.status ="Готово, перезапуск..."_0xE914 = true
else
_0x911D.status ="Не удалось записать файл"end
end
local function _0x1D4D()
local _0x374D = _0x544B .."arizona_prices_remote.json"local _0x65BB = _0x3B0C(_0x374D)
os.remove(_0x374D)
if not _0x65BB or #_0x65BB < 2 then return end
local _0x16DA = _0xA5DE(_0x65BB)
local _0x054C, _0x5886 = pcall(decodeJson, _0x65BB)
if not _0x054C or type(_0x5886) ~="table"then return endif not _0x9100.on then
local _0xDDCB = {}
for _0xEDD8, _0x2CC1 in ipairs(_0x5886) do
local _0xA09E = type(_0x2CC1) =="table"and tonumber(_0x2CC1.buy) or nil
local _0x6932 = type(_0x2CC1) =="table"and tonumber(_0x2CC1.sell) or nil
if _0xA09E and _0x6932 and type(_0x2CC1.item) =="string"then
_0xDDCB[#_0xDDCB + 1] = { _0xB96F = _0x2CC1.item, _0xA09E = _0xA09E, _0x6932 = _0x6932, _0x5535 = _0x9100.valid_liq(_0x2CC1.liq) }
end
end
if #_0xDDCB == 0 then return end
local _0x7101 = false
local _0x4EB5, _0xE3C1, _0x3253 = pcall(function() return encodeJson(_0xDDCB), encodeJson(_0xE004) end)
if _0x4EB5 and _0xE3C1 == _0x3253 then _0x7101 = true end
if not _0x7101 then
_0xE004 = _0xDDCB
_0xA936()
if _0x16DA ~= _0xD85E.prices_sig then _0x3D10("Цены обновлены из канала","ok", 5) end
end
_0xD85E.prices_sig = _0x16DA
_0xC16C()
return
endif _0x16DA == _0xD85E.prices_sig then return end
local _0x9913 = {}
for _0x43EB, it in ipairs(_0xE004) do
if it.item then _0x9913[it.item] = _0x43EB end
end
local _0xEF57, _0x4EED = 0, 0
for _0xEDD8, _0x2CC1 in ipairs(_0x5886) do
local _0xA09E = type(_0x2CC1) =="table"and tonumber(_0x2CC1.buy) or nil
local _0x6932 = type(_0x2CC1) =="table"and tonumber(_0x2CC1.sell) or nil
if _0xA09E and _0x6932 and type(_0x2CC1.item) =="string"then
local _0x43EB = _0x9913[_0x2CC1.item]
if _0x43EB then
local _0xCAD9 = _0xE004[_0x43EB]
if tonumber(_0xCAD9.buy) ~= _0xA09E or tonumber(_0xCAD9.sell) ~= _0x6932 then
_0xCAD9.buy, _0xCAD9.sell = _0xA09E, _0x6932
_0x4EED = _0x4EED + 1
end
else
_0xE004[#_0xE004 + 1] = { _0xB96F = _0x2CC1.item, _0xA09E = _0xA09E, _0x6932 = _0x6932, _0x5535 = _0x9100.valid_liq(_0x2CC1.liq) }
_0x9913[_0x2CC1.item] = #_0xE004
_0xEF57 = _0xEF57 + 1
end
end
end
_0xD85E.prices_sig = _0x16DA
_0xC16C()
if _0xEF57 + _0x4EED > 0 then
_0xA936()
_0x3D10("Цены обновлены: новых ".. _0xEF57 ..", изменено ".. _0x4EED,"ok", 5)
end
end
local function _0x302D()
if _0x26F5.version then _0x26F5.version = nil; pcall(_0xD0F3) end
if _0x26F5.script then _0x26F5.script = nil; pcall(_0x944F) end
if _0x26F5.prices then _0x26F5.prices = nil; pcall(_0x1D4D) end
if _0x911D.busy and os.time() - _0x4A62 > 40 then
_0x911D.busy = false
_0x911D.status ="Не удалось скачать"end
end
local _0x2D19 = _0xEFB3.new.bool(false)
local function _0x5E50()
_0x911D.busy = true
_0x911D.status =""_0x4A62 = os.time()
if not _0xA0FC("Table_Prices.lua", _0x544B .."arizona_prices_update.lua","script") then
_0x911D.busy = false
if _0x911D.status ==""then _0x911D.status ="Ошибка загрузки"end
end
end
local function _0x7F67()
_0x911D.busy = true
_0x911D.status =""_0x4A62 = os.time()
_0x5104(_0x5E50)
end
local function _0x5546()
_0xEFB3.SetCursorPos(_0xEFB3.ImVec2(5, _0xE16E.block_y))
_0xEFB3.TextDisabled("Версия ".. _0x2CC5)
_0xEFB3.SetCursorPosX(5)
if _0x911D.available then
_0xEFB3.TextColored(_0xEFB3.ImVec4(0.45, 1.00, 0.55, 1.00),"Вышла версия ".. _0x911D.version)
_0xEFB3.SetCursorPosX(5)
if _0x911D.busy then
_0xEFB3.TextDisabled("Скачивание...")
elseif _0xEFB3.Button(_0x2075("DOWNLOAD","") .." Обновить##do_update", _0xEFB3.ImVec2(_0x9E4F - 10, 32)) then
_0x7F67()
end
else
if _0xEFB3.Button(_0x2075("ARROWS_ROTATE","") .." Проверить##check_update", _0xEFB3.ImVec2(_0x9E4F - 10, 28)) then
_0x7D83 = true
_0x911D.status ="Проверка..."_0x5104(_0x76E0)
end
end
if _0x911D.status ~=""then
_0xEFB3.SetCursorPosX(5)
_0xEFB3.TextDisabled(_0x911D.status)
end
_0xEFB3.SetCursorPosX(5)
if _0xEFB3.Checkbox(" Автообновление цен##auto_prices", _0x1C58) then
_0xD85E.auto_prices = _0x1C58[0]
_0xC16C()
if _0xD85E.auto_prices then _0x5104(_0x76E0) end
end
endlocal _0xDA0E = { binding = false, typing = false }
local _0x367B, _0x8E9E = pcall(require,'vkeys')
local function _0xD5EC(_0x4390)
if not _0x4390 or _0x4390 == 0 then return"Не задана"end
if _0x367B and _0x8E9E.id_to_name then
local _0x3CF1 = _0x8E9E.id_to_name(_0x4390)
if _0x3CF1 then return _0x3CF1 end
end
return"VK ".. tostring(_0x4390)
end
local _0xEF43 = {
accent = _0xEFB3.new.float[3](_0xF228.accent[1], _0xF228.accent[2], _0xF228.accent[3]),
opacity = _0xEFB3.new.float(_0xF228.opacity),
_0x32AA = _0xEFB3.new.float(_0xF228.overlay_scale),
_0x34EA = _0xEFB3.new.bool(_0xF228.toasts),
border_speed = _0xEFB3.new.float(_0xF228.border_speed),
shadow = _0xEFB3.new.bool(_0xF228.shadow),
bg_fx = _0xEFB3.new.bool(_0xF228.bg_fx),
splash = _0xEFB3.new.bool(_0xF228.splash),
halloween = _0xEFB3.new.bool(_0xF228.halloween),
font_pending = false,
}
local _0xF25E = nil
local function _0x32DC()
_0xF25E = os.clock()
end
local function _0x225E(force)
if _0xF25E and (force or os.clock() - _0xF25E > 0.8) then
_0xF25E = nil
_0xF5E0()
end
endlocal _0xA69E = {
ACCESS_CODE ="PRICES2026",
_0x374D = getWorkingDirectory() .."\\config\\arizona_prices_auth.json",
_0x0434 = _0xEFB3.new.bool(false),
_0x6777 = _0xEFB3.new.char[48](),
_0x4390 = _0xEFB3.new.char[48](),
error ="",
_0x054C = false,
}do
local _0xF60E = _0x5729(_0xA69E.path)
if type(_0xF60E) =="table"and tostring(_0xF60E.code or""):lower() == _0xA69E.ACCESS_CODE:lower() then
_0xA69E.ok = true
end
end
function _0xA69E.try_login()
local _0x6777 = _0x0A3B.string(_0xA69E.nick):gsub("^%s+",""):gsub("%s+$","")
local _0x4390 = _0x0A3B.string(_0xA69E.code):gsub("%s","")
if _0x6777 ==""then _0xA69E.error ="Введите ваш никнейм"; return end
if _0x4390 ==""then _0xA69E.error ="Введите код из телеграм-канала"; return end
if _0xA69E.loading then return end
_0xA69E.error =""_0xA69E.loading = { _0xF27D = _0xEFB3.GetTime(), _0x6777 = _0x6777, _0x4390 = _0x4390 }
endfunction _0xA69E.finish()
local _0x6777, _0x4390 = _0xA69E.loading.nick, _0xA69E.loading.code
_0xA69E.loading = nil
if _0x4390:lower() ~= _0xA69E.ACCESS_CODE:lower() then
_0xA69E.error ="Неверный код. Получите актуальный код в телеграм-канале"return
end
_0xA69E.ok = true
_0xA69E.error =""_0xA69E.open[0] = false
local _0xEEB2 = getWorkingDirectory() .."\\config"if not doesDirectoryExist(_0xEEB2) then createDirectory(_0xEEB2) end
_0x64B2(_0xA69E.path, encodeJson({ _0x6777 = _0x6777, _0x4390 = _0x4390 }))
_0x3D10("Доступ открыт. Добро пожаловать, ".. _0x6777 .."!","ok", 5)
_0x950A[0] = true
end
_0xEFB3.OnFrame(function() return _0xA69E.open[0] end, _0xD9E5("auth", function()
local _0x72C1, _0x5CFA = getScreenResolution()
local _0x2ABC, _0xB67C = 560, 380
_0xEFB3.SetNextWindowPos(_0xEFB3.ImVec2(_0x72C1 / 2, _0x5CFA / 2), _0xEFB3.Cond.Always, _0xEFB3.ImVec2(0.5, 0.5))
_0xEFB3.SetNextWindowSize(_0xEFB3.ImVec2(_0x2ABC, _0xB67C), _0xEFB3.Cond.Always)
_0xEFB3.PushStyleColor(_0xEFB3.Col.WindowBg, _0xEFB3.ImVec4(0.075, 0.07, 0.095, 1.0))
_0xEFB3.Begin("##auth_window", nil, bit.bor(_0xEFB3.WindowFlags.NoTitleBar, _0xEFB3.WindowFlags.NoResize,
_0xEFB3.WindowFlags.NoCollapse, _0xEFB3.WindowFlags.NoScrollbar, _0xEFB3.WindowFlags.NoSavedSettings))
local _0xBAC3 = _0xEFB3.GetWindowPos()
local _0x4CF0 = _0xF228.accent
_0xEFB3.GetWindowDrawList():AddRectFilled(_0xBAC3, _0xEFB3.ImVec2(_0xBAC3.x + _0x2ABC, _0xBAC3.y + 5), _0xE27E(_0x4CF0[1], _0x4CF0[2], _0x4CF0[3], 1))
_0xEFB3.SetCursorPos(_0xEFB3.ImVec2(26, 24))
_0xEFB3.SetWindowFontScale(1.7)
_0xEFB3.TextColored(_0xBD61(1.2), _0x2075("LOCK","") .." Авторизация")
_0xEFB3.SetWindowFontScale(1.15)
_0xEFB3.SetCursorPos(_0xEFB3.ImVec2(26, 76))
_0xEFB3.PushTextWrapPos(_0x2ABC - 26)
_0xEFB3.TextWrapped("Вы попали в окно авторизации. Введите свой никнейм и код. Код можно получить в телеграм-канале.")
_0xEFB3.PopTextWrapPos()
if _0xA69E.loading thenlocal _0x27A0 = _0xEFB3.GetTime()
local _0x22D5 = _0xCD0C((_0x27A0 - _0xA69E.loading.t) / 3.0, 0, 1)
local _0x6A4A = _0xEFB3.GetWindowDrawList()
local _0x6551, _0xE58A = _0xBAC3.x + _0x2ABC / 2, _0xBAC3.y + 165
for _0x43EB = 0, 11 do
local _0xDD65 = _0x43EB / 12 * math.pi * 2 - _0x27A0 * 6
local _0x83F5 = ((_0x43EB / 12) - (_0x27A0 * 1.5) % 1) % 1
_0x6A4A:AddCircleFilled(_0xEFB3.ImVec2(_0x6551 + math.cos(_0xDD65) * 34, _0xE58A + math.sin(_0xDD65) * 34), 5.5,
_0xE27E(_0x4CF0[1], _0x4CF0[2], _0x4CF0[3], 0.15 + 0.85 * (1 - _0x83F5)), 12)
end
local _0x7689 = {"Подключение к серверу...","Проверка кода...","Верификация никнейма...","Доступ разрешён"}
local _0x3CFB = _0x7689[math.min(#_0x7689, 1 + math.floor(_0x22D5 * #_0x7689))]
_0xEFB3.SetCursorPos(_0xEFB3.ImVec2(0, 232))
_0xEFB3.SetWindowFontScale(1.6)
local _0x7E28 = string.rep(".", math.floor(_0x27A0 * 3) % 4)
local _0xFC74 ="Загрузка".. _0x7E28
_0xEFB3.SetCursorPosX((_0x2ABC - _0xEFB3.CalcTextSize("Загрузка...").x) / 2)
_0xEFB3.Text(_0xFC74)
_0xEFB3.SetWindowFontScale(1.1)
_0xEFB3.SetCursorPosX((_0x2ABC - _0xEFB3.CalcTextSize(_0x3CFB).x) / 2)
_0xEFB3.TextColored(_0xEFB3.ImVec4(0.65, 0.65, 0.72, 1), _0x3CFB)
_0xEFB3.SetCursorPos(_0xEFB3.ImVec2(60, _0xB67C - 46))
_0xEFB3.PushStyleColor(_0xEFB3.Col.PlotHistogram, _0xBD61(1.1))
_0xEFB3.ProgressBar(_0x22D5, _0xEFB3.ImVec2(_0x2ABC - 120, 10),"")
_0xEFB3.PopStyleColor(1)
_0xEFB3.SetWindowFontScale(1.0)
_0xEFB3.End()
_0xEFB3.PopStyleColor(1)
if _0x22D5 >= 1 then _0xA69E.finish() end
return
end
_0xEFB3.SetCursorPos(_0xEFB3.ImVec2(26, 150))
_0xEFB3.SetNextItemWidth(_0x2ABC - 52)
_0xEFB3.InputTextWithHint("##auth_nick","Ваш никнейм", _0xA69E.nick, _0x0A3B.sizeof(_0xA69E.nick))
_0xEFB3.SetCursorPosX(26)
_0xEFB3.SetNextItemWidth(_0x2ABC - 52)
local _0x1C35 = _0xEFB3.InputTextWithHint("##auth_code","Код из телеграм-канала", _0xA69E.code, _0x0A3B.sizeof(_0xA69E.code), _0xEFB3.InputTextFlags.EnterReturnsTrue)
if _0x1C35 then _0xA69E.try_login() end
_0xEFB3.SetCursorPosX(26)
if _0xA69E.error ~=""then
_0xEFB3.TextColored(_0xEFB3.ImVec4(1.0, 0.4, 0.4, 1.0), _0xA69E.error)
else
_0xEFB3.Text(" ")
end
_0xEFB3.SetCursorPos(_0xEFB3.ImVec2(26, _0xB67C - 26 - 46))
local _0x44C0 = (_0x2ABC - 52 - 20) / 3
_0xEFB3.PushStyleColor(_0xEFB3.Col.Button, _0xBD61(1.0))
_0xEFB3.PushStyleColor(_0xEFB3.Col.ButtonHovered, _0xBD61(1.15))
_0xEFB3.PushStyleColor(_0xEFB3.Col.ButtonActive, _0xBD61(0.85))
if _0xEFB3.Button(_0x2075("RIGHT_TO_BRACKET","") .." Войти##auth_go", _0xEFB3.ImVec2(_0x44C0, 46)) then _0xA69E.try_login() end
_0xEFB3.PopStyleColor(3)
_0xEFB3.SameLine()
if _0xEFB3.Button(_0x2075("PAPER_PLANE","") .." Получить код##auth_tg", _0xEFB3.ImVec2(_0x44C0 + 40, 46)) then
_0x091E("https://t.me/arizona_prices")
end
_0xEFB3.SameLine()
if _0xEFB3.Button(_0xB914.CIRCLE_XMARK .." Закрыть##auth_close", _0xEFB3.ImVec2(_0x44C0 - 40, 46)) then _0xA69E.open[0] = false end
_0xEFB3.SetWindowFontScale(1.0)
_0xEFB3.End()
_0xEFB3.PopStyleColor(1)
end, function() _0xA69E.open[0] = false; _0xA69E.loading = nil end))
local function _0x565A()
if not _0xA69E.ok then_0x950A[0] = false
_0xA69E.loading = nil
_0xA69E.open[0] = not _0xA69E.open[0]
if _0xA69E.open[0] and _0x0A3B.string(_0xA69E.nick) ==""then
local _0x2FEA, _0x6319 = pcall(function() local _0xEDD8, _0x43EB = sampGetPlayerIdByCharHandle(PLAYER_PED); return sampGetPlayerNickname(_0x43EB) end)
if _0x2FEA and _0x6319 then _0xEFB3.StrCopy(_0xA69E.nick, _0x6319) end
end
return
end
_0x950A[0] = not _0x950A[0]
if _0x950A[0] and _0x911D.available then
_0x2D19[0] = true
end
end
local function _0x9B0F(msg, wparam, lparam)
if msg ~= 0x100 and msg ~= 0x104 then return end
local _0x9368 = bit.band(lparam, 0x40000000) ~= 0
if _0xDA0E.binding then
consumeWindowMessage(true, true)
if _0x9368 then return end
_0xDA0E.binding = false
if wparam == 0x08 then
_0xF228.open_key = 0
_0x32DC()
_0x3D10("Горячая клавиша убрана","info")
elseif wparam ~= 0x1B then
_0xF228.open_key = wparam
_0x32DC()
_0x3D10("Клавиша открытия меню: ".. _0xD5EC(wparam),"ok")
end
return
end
if _0x9368 then return endif _0x950A[0] and _0xDFF1.alpha > 0.5 and not _0xDA0E.typing then
local _0x4EB5, _0x41CB = pcall(function() return sampIsChatInputActive() or sampIsDialogActive() end)
if not (_0x4EB5 and _0x41CB) then
if wparam >= 0x31 and wparam <= 0x38 then
_0xDFF1.pending_tab = _0xDFF1.TAB_ORDER[wparam - 0x30]
consumeWindowMessage(true, true)
return
elseif wparam == 0x46 then
local _0x08A2, _0xB22C = pcall(isKeyDown, 0x11)
if _0x08A2 and _0xB22C then
_0xDFF1.pending_tab = 1
_0xDFF1.focus_search = true
consumeWindowMessage(true, true)
return
end
end
end
end
local _0x15EA = _0xF228.open_key
if _0x15EA and _0x15EA ~= 0 and wparam == _0x15EA then
local _0x4EB5, _0x41CB = pcall(function() return sampIsChatInputActive() or sampIsDialogActive() end)
if _0x4EB5 and _0x41CB then return end
if _0x950A[0] and _0xDA0E.typing then return end
_0x565A()
end
end
local function _0xF098()
local _0x150B = {}
local function _0x2C04(_0xF27D) _0x150B[#_0x150B + 1] = _0xF27D end
_0x2C04("Arizona Prices - отчёт об ошибке")
_0x2C04("Версия скрипта: ".. _0x2CC5)
_0x2C04("Журнал ошибок: moonloader\\config\\arizona_prices_errors.log")
_0x2C04("Дата: ".. os.date("%Y-%m-%d %H:%M:%S"))
local _0xAC69, _0x8F7D = pcall(function() return getMoonloaderVersion() end)
_0x2C04("MoonLoader: ".. (_0xAC69 and tostring(_0x8F7D) or"?"))
_0x2C04("Lua: ".. tostring(_VERSION) .. (jit and (" / ".. tostring(jit.version)) or""))
local _0x2B93, _0x3858, _0x6AAB = pcall(getScreenResolution)
_0x2C04("Экран: ".. (_0x2B93 and (tostring(_0x3858) .."x".. tostring(_0x6AAB)) or"?"))
_0x2C04("Предметов в списке: ".. #_0xE004)
_0x2C04("Автообновление цен: ".. tostring(_0xD85E.auto_prices))
_0x2C04("Загрузка файлов: ".. ((downloadUrlToFile and _0x3C5C) and"доступна"or"недоступна"))
_0x2C04("Уведомления: ".. tostring(_0xF228.toasts) ..", горячая клавиша: ".. _0xD5EC(_0xF228.open_key))
if #_0xE2F4 > 0 then
_0x2C04("Последние ошибки:")
for _0xEDD8, _0xA49F in ipairs(_0xE2F4) do _0x2C04("  ".. _0xA49F) end
else
_0x2C04("Ошибок в журнале нет")
end
_0x2C04("")
_0x2C04("Что вы делали перед ошибкой:")
return table.concat(_0x150B,"\n")
end
local function _0x1C07()
local _0x054C, _0xF692 = pcall(_0xF098)
local _0x5A11 = _0x054C and _0xF692 or ("Arizona Prices ".. _0x2CC5)
_0xEFB3.SetClipboardText("Привет. Заметил о баге:\n\n\n".. _0x5A11)
_0x091E("https://t.me/xi_vivide")
_0x3D10("Сообщение скопировано - допишите, что случилось, и отправьте (Ctrl+V)","ok", 6)
end
local _0xE74F = {
{ _0x4D0B ="Океан", _0x65BB = {0.18, 0.45, 0.85} }, { _0x4D0B ="Изумруд", _0x65BB = {0.20, 0.70, 0.45} },
{ _0x4D0B ="Аметист", _0x65BB = {0.60, 0.35, 0.90} }, { _0x4D0B ="Рубин", _0x65BB = {0.90, 0.30, 0.35} },
{ _0x4D0B ="Янтарь", _0x65BB = {0.95, 0.60, 0.15} }, { _0x4D0B ="Бирюза", _0x65BB = {0.15, 0.72, 0.78} },
{ _0x4D0B ="Сакура", _0x65BB = {0.90, 0.40, 0.70} }, { _0x4D0B ="Неон", _0x65BB = {0.55, 1.00, 0.20} },
}
local _0xFDA7 = {"Выключена","Переливы цвета","Радуга","Статичная"}
local _0x0AA7 = {
{ _0x4D0B ="Справа снизу", _0x0448 = 3 }, { _0x4D0B ="Справа сверху", _0x0448 = 1 },
{ _0x4D0B ="Слева снизу", _0x0448 = 2 }, { _0x4D0B ="Слева сверху", _0x0448 = 0 },
}
local function _0x8CB1(icon_name, _0xF692)
_0xEFB3.Spacing()
_0xEFB3.TextColored(_0xBD61(1.2), _0x2075(icon_name,"") .." ".. _0xF692)
_0xEFB3.Separator()
_0xEFB3.Spacing()
end
local function _0xF44D()
_0x2C44(_0x2075("GEAR",""),"Настройки")
if _0xEFB3.BeginChild("##settings_child", _0xEFB3.ImVec2(-1, _0xE16E.h - 79), true) then
_0x8CB1("PALETTE","Темы оформления")
for _0x43EB, th in ipairs(_0xE74F) do
local _0x65BB = th.c
_0xEFB3.PushStyleColor(_0xEFB3.Col.Button, _0xEFB3.ImVec4(_0x65BB[1] * 0.55, _0x65BB[2] * 0.55, _0x65BB[3] * 0.55, 1.0))
_0xEFB3.PushStyleColor(_0xEFB3.Col.ButtonHovered, _0xEFB3.ImVec4(_0x65BB[1] * 0.80, _0x65BB[2] * 0.80, _0x65BB[3] * 0.80, 1.0))
_0xEFB3.PushStyleColor(_0xEFB3.Col.ButtonActive, _0xEFB3.ImVec4(_0x65BB[1], _0x65BB[2], _0x65BB[3], 1.0))
if _0xEFB3.Button(th.name .."##theme".. _0x43EB, _0xEFB3.ImVec2(110, 30)) then
_0xF228.accent = { _0x65BB[1], _0x65BB[2], _0x65BB[3] }
_0xEF43.accent[0], _0xEF43.accent[1], _0xEF43.accent[2] = _0x65BB[1], _0x65BB[2], _0x65BB[3]
apply_theme()
_0x32DC()
end
_0xEFB3.PopStyleColor(3)
if _0x43EB % 4 ~= 0 and _0x43EB < #_0xE74F then _0xEFB3.SameLine() end
end
_0xEFB3.Spacing()
if _0xEFB3.ColorEdit3("Свой цвет##accent_custom", _0xEF43.accent, _0xEFB3.ColorEditFlags.NoInputs) then
_0xF228.accent = { _0xEF43.accent[0], _0xEF43.accent[1], _0xEF43.accent[2] }
apply_theme()
_0x32DC()
end
_0xEFB3.SetNextItemWidth(260)
if _0xEFB3.SliderFloat("Прозрачность окна##opacity", _0xEF43.opacity, 0.3, 1.0,"%.2f") then
_0xF228.opacity = _0xEF43.opacity[0]
apply_theme()
_0x32DC()
end
_0x8CB1("WAND_MAGIC_SPARKLES","Рамка и эффекты")
_0xEFB3.SetNextItemWidth(220)
if _0xEFB3.BeginCombo("Рамка окна##border_mode", _0xFDA7[_0xF228.border_mode + 1] or _0xFDA7[2]) then
for _0x43EB, _0x4D0B in ipairs(_0xFDA7) do
if _0xEFB3.Selectable(_0x4D0B .."##bm".. _0x43EB, _0xF228.border_mode == _0x43EB - 1) then
_0xF228.border_mode = _0x43EB - 1
_0x32DC()
end
end
_0xEFB3.EndCombo()
end
if _0xF228.border_mode == 1 or _0xF228.border_mode == 2 then
_0xEFB3.SetNextItemWidth(260)
if _0xEFB3.SliderFloat("Скорость переливов##border_speed", _0xEF43.border_speed, 0.2, 3.0,"%.1f") then
_0xF228.border_speed = _0xEF43.border_speed[0]
_0x32DC()
end
end
if _0xEFB3.Checkbox("Тень под окном##shadow", _0xEF43.shadow) then
_0xF228.shadow = _0xEF43.shadow[0]
_0x32DC()
end
if _0xEFB3.Checkbox("Анимированный фон##bgfx", _0xEF43.bg_fx) then
_0xF228.bg_fx = _0xEF43.bg_fx[0]
_0x32DC()
end
if _0xEFB3.Checkbox("Заставка при первом открытии меню##splash", _0xEF43.splash) then
_0xF228.splash = _0xEF43.splash[0]
_0x32DC()
end
if _0xEFB3.Checkbox("Хэллоуин: тыквы, летучие мыши, паутина##halloween", _0xEF43.halloween) then
_0xF228.halloween = _0xEF43.halloween[0]
local _0x65BB = _0xF228.halloween and { 0.98, 0.55, 0.12 } or { 0.18, 0.45, 0.85 }
_0xF228.accent = _0x65BB
_0xEF43.accent[0], _0xEF43.accent[1], _0xEF43.accent[2] = _0x65BB[1], _0x65BB[2], _0x65BB[3]
apply_theme()
_0x32DC()
end
_0x8CB1("FONT","Шрифт")
local _0xBBA1 = _0x36D7[1].name
for _0xEDD8, _0xE8B2 in ipairs(_0x36D7) do
if _0xE8B2.key == _0xF228.font then _0xBBA1 = _0xE8B2.name end
end
_0xEFB3.SetNextItemWidth(260)
if _0xEFB3.BeginCombo("Шрифт интерфейса##font", _0xBBA1) then
for _0xEDD8, _0xE8B2 in ipairs(_0x36D7) do
if _0xEFB3.Selectable(_0xE8B2.name .."##font_".. _0xE8B2.key, _0xF228.font == _0xE8B2.key) then
_0xF228.font = _0xE8B2.key
_0xEF43.font_pending = true
_0x32DC()
end
end
_0xEFB3.EndCombo()
end
if _0xEF43.font_pending then
if _0xEFB3.Button(_0x2075("ARROWS_ROTATE","") .." Применить шрифт (перезапуск скрипта)##apply_font", _0xEFB3.ImVec2(360, 28)) then
_0x5104(function()
_0x225E(true)
thisScript():reload()
end)
end
else
_0xEFB3.TextDisabled("Шрифт меняется после перезапуска скрипта. Берётся из папки Fonts в Windows.")
end
_0x8CB1("EXPAND","Надписи на экране")
_0xEFB3.SetNextItemWidth(260)
if _0xEFB3.SliderFloat("Размер надписей на экране##overlay_scale", _0xEF43.scale, 0.7, 2.0,"%.1f") then
_0xF228.overlay_scale = _0xEF43.scale[0]
_0x32DC()
end
_0xEFB3.TextDisabled("Касается надписей PayDay и часов, которые показываются поверх игры.")
_0xEFB3.Spacing()
if _0xEFB3.Button(_0x2075("ROTATE_LEFT","") .." Сбросить внешний вид##reset_look", _0xEFB3.ImVec2(230, 28)) then
_0xF228.accent = _0xF228.halloween and { 0.98, 0.55, 0.12 } or { 0.18, 0.45, 0.85 }
_0xF228.opacity = 1.0
_0xF228.overlay_scale = 1.0
_0xF228.border_mode = 1
_0xF228.border_speed = 1.0
_0xF228.shadow = true
if _0xF228.font ~="seguisb"then
_0xF228.font ="seguisb"_0xEF43.font_pending = true
end
_0xEF43.accent[0], _0xEF43.accent[1], _0xEF43.accent[2] = _0xF228.accent[1], _0xF228.accent[2], _0xF228.accent[3]
_0xEF43.opacity[0] = 1.0
_0xEF43.scale[0] = 1.0
_0xEF43.border_speed[0] = 1.0
_0xEF43.shadow[0] = true
apply_theme()
_0x32DC()
end
_0xEFB3.SameLine()
if _0xEFB3.Button(_0x2075("EXPAND","") .." Сбросить размер окна##reset_size", _0xEFB3.ImVec2(230, 28)) then
_0xE16E.force = true
end
_0x8CB1("KEYBOARD","Управление")
_0xEFB3.AlignTextToFramePadding()
_0xEFB3.Text("Клавиша открытия меню:")
_0xEFB3.SameLine()
local _0x5F57 = _0xDA0E.binding and"Нажмите клавишу..."or _0xD5EC(_0xF228.open_key)
if _0xEFB3.Button(_0x5F57 .."##bind_open_key", _0xEFB3.ImVec2(190, 26)) then
_0xDA0E.binding = not _0xDA0E.binding
end
_0xEFB3.TextDisabled("Esc - отмена, Backspace - убрать клавишу. Команда /prices работает всегда.")
_0x8CB1("BELL","Уведомления")
if _0xEFB3.Checkbox("Всплывающие карточки вместо сообщений в чате", _0xEF43.toasts) then
_0xF228.toasts = _0xEF43.toasts[0]
_0x32DC()
end
local _0x07EA = _0x0AA7[1].name
for _0xEDD8, _0x65BB in ipairs(_0x0AA7) do
if _0x65BB.v == _0xF228.toast_corner then _0x07EA = _0x65BB.name end
end
_0xEFB3.SetNextItemWidth(220)
if _0xEFB3.BeginCombo("Угол экрана##toast_corner", _0x07EA) then
for _0xEDD8, _0x65BB in ipairs(_0x0AA7) do
if _0xEFB3.Selectable(_0x65BB.name, _0x65BB.v == _0xF228.toast_corner) then
_0xF228.toast_corner = _0x65BB.v
_0x32DC()
end
end
_0xEFB3.EndCombo()
end
if _0xEFB3.Button(_0x2075("BELL","") .." Показать пример##toast_test", _0xEFB3.ImVec2(230, 28)) then
_0x3D10("Так выглядят уведомления","ok")
end
_0x8CB1("BUG","Поддержка")
if _0xEFB3.Button(_0x2075("BUG","") .." Сообщить об ошибке##report_error", _0xEFB3.ImVec2(230, 30)) then
_0x1C07()
end
_0xEFB3.TextDisabled("Скопирует версию скрипта и данные для диагностики и откроет Telegram разработчика.")
if #_0xE2F4 > 0 then
_0xEFB3.TextColored(_0xEFB3.ImVec4(1.0, 0.55, 0.40, 1.0),"Записей в журнале ошибок: ".. #_0xE2F4)
end
end
_0xEFB3.EndChild()
end
local function _0x73EC()
_0x2C44(_0x2075("NOTE_STICKY",""),"Заметки")
if _0xEFB3.BeginChild("##notes_child", _0xEFB3.ImVec2(-1, _0xE16E.h - 79), true) then
_0xEFB3.TextDisabled("Записывай сюда всё важное: цены, договорённости, ники. Сохраняется само.")
_0xEFB3.Spacing()
_0xEFB3.SetWindowFontScale(1.15)
local _0xCC7A = _0xEFB3.GetContentRegionAvail().y - 48
if _0xEFB3.InputTextMultiline("##notes_text", _0xDFF1.notes, _0x0A3B.sizeof(_0xDFF1.notes), _0xEFB3.ImVec2(-1, math.max(80, _0xCC7A))) then
_0x3049.notes = _0x0A3B.string(_0xDFF1.notes)
_0x32DC()
end
_0xEFB3.SetWindowFontScale(1.0)
local _0x8A46 = math.floor(#_0x3049.notes / 81.91)
_0xEFB3.AlignTextToFramePadding()
_0xEFB3.TextDisabled("Заполнено: ".. _0x8A46 .."%")
_0xEFB3.SameLine()
if _0xEFB3.Button(_0x2075("TRASH_CAN","") .." Очистить##notes_clear", _0xEFB3.ImVec2(130, 28)) then
_0xEFB3.StrCopy(_0xDFF1.notes,"")
_0x3049.notes =""_0x32DC()
end
end
_0xEFB3.EndChild()
end
local function _0xF9A5(_0x6319)
if _0x6319 == 3 then
_0xF910()
elseif _0x6319 == 4 then
_0x337B()
elseif _0x6319 == 5 then
_0x00ED()
elseif _0x6319 == 6 then
_0xC0C5()
elseif _0x6319 == 7 then
_0xF44D()
elseif _0x6319 == 8 then
_0x73EC()
end
end
local _0x0ED2
_0x0ED2 = _0xEFB3.OnFrame(
function()
_0x0ED2.HideCursor = not _0xF152
return _0xE043[0]
end,
_0xD9E5("payday", function()
if _0xF152 and not _0x950A[0] then _0xF152 = false end
local _0x6F06 = bit.bor(_0xEFB3.WindowFlags.NoTitleBar, _0xEFB3.WindowFlags.AlwaysAutoResize, _0xEFB3.WindowFlags.NoScrollbar, _0xEFB3.WindowFlags.NoSavedSettings)
if not _0xF152 then
_0x6F06 = bit.bor(_0x6F06, _0xEFB3.WindowFlags.NoMove, _0xEFB3.WindowFlags.NoInputs, _0xEFB3.WindowFlags.NoBackground)
_0xEFB3.SetNextWindowPos(_0xEFB3.ImVec2(_0x4FC4.x, _0x4FC4.y), _0xEFB3.Cond.Always)
end
_0xEFB3.SetNextWindowBgAlpha(0.45)
_0xEFB3.Begin("##payday_overlay", nil, _0x6F06)
_0xEFB3.SetWindowFontScale(_0xF228.overlay_scale)
_0x89E0(_0xEFB3.ImVec4(1.00, 0.85, 0.30, 1.00), _0x2618())
if _0xF152 then
local _0x8CE5 = _0xEFB3.GetWindowPos()
_0x4FC4.x, _0x4FC4.y = _0x8CE5.x, _0x8CE5.y
end
_0xEFB3.End()
end, function() _0xE043[0] = false end)
)
_0xEFB3.OnInitialize(function()_0x2C6A("fa_init", function() _0x8553.Init() end)_0x2C6A("custom_font", function()
local _0x374D
for _0xEDD8, _0xE8B2 in ipairs(_0x36D7) do
if _0xE8B2.key == _0xF228.font and _0xE8B2.path then _0x374D = _0xE8B2.path end
end
if not _0x374D thenlocal _0x054C, _0xEEB2 = pcall(getFolderPath, 0x14)
if _0x054C and _0xEEB2 then
for _0xEDD8, _0x4D0B in ipairs({"trebucbd.ttf","trebuc.ttf","arial.ttf"}) do
if doesFileExist(_0xEEB2 .."\\".. _0x4D0B) then _0x374D = _0xEEB2 .."\\".. _0x4D0B break end
end
end
end
if not _0x374D then return end
local _0xF20D = _0xEFB3.GetIO()
local _0xC2B8 = _0xF20D.Fonts:AddFontFromFileTTF(_0x374D, 28, nil, _0xF20D.Fonts:GetGlyphRangesCyrillic())
if _0xC2B8 ~= nil thenif not pcall(_0x8553.Init, 28) then pcall(_0x8553.Init) end
_0xF20D.FontDefault = _0xC2B8
_0xF20D.FontGlobalScale = 0.5
end
end)
_0x2C6A("apply_theme", apply_theme)
_0x2C6A("load_data", _0x78D9)
end)local _0x3CCA = { on = false, _0x2A12 = 0, _0x4BBC = 0, _0x81C3 = 0, _0xCC7A = 0 }
local function _0xF5BE()local _0x65AE, _0x892F = _0xEFB3.GetWindowPos(), _0xEFB3.GetWindowSize()
local _0x6551, _0xE58A = _0x65AE.x + _0x892F.x, _0x65AE.y + _0x892F.y_0xEFB3.SetCursorPos(_0xEFB3.ImVec2(_0x892F.x - 28, _0x892F.y - 28 + _0xEFB3.GetScrollY()))
_0xEFB3.InvisibleButton("##resize_grip", _0xEFB3.ImVec2(20, 20))
local _0xB442 = _0xEFB3.GetMousePos()
local _0x0E44 = _0xB442.x >= _0x6551 - 34 and _0xB442.x <= _0x6551 + 4 and _0xB442.y >= _0xE58A - 34 and _0xB442.y <= _0xE58A + 4
if not _0x3CCA.on and _0x0E44 and _0xEFB3.IsMouseClicked(0) then
_0x3CCA.on = true
_0x3CCA.mx, _0x3CCA.my, _0x3CCA.w, _0x3CCA.h = _0xB442.x, _0xB442.y, _0xE16E.w, _0xE16E.h
end
if _0x3CCA.on then
if _0xEFB3.IsMouseDown(0) then
local _0x72C1, _0x5CFA = getScreenResolution()
_0xE16E.req = {
_0x81C3 = _0xCD0C(_0x3CCA.w + _0xB442.x - _0x3CCA.mx, 700, math.max(700, _0x72C1 - 20)),
_0xCC7A = _0xCD0C(_0x3CCA.h + _0xB442.y - _0x3CCA.my, 400, math.max(400, _0x5CFA - 20)),
}
else
_0x3CCA.on = false
end
end
local _0x4CF0 = _0xF228.accent
local _0xC5C6 = (_0x0E44 or _0x3CCA.on) and 0.95 or 0.55
_0xEFB3.GetWindowDrawList():AddTriangleFilled(
_0xEFB3.ImVec2(_0x6551 - 6, _0xE58A - 6), _0xEFB3.ImVec2(_0x6551 - 6, _0xE58A - 22), _0xEFB3.ImVec2(_0x6551 - 22, _0xE58A - 6),
_0xE27E(_0x4CF0[1], _0x4CF0[2], _0x4CF0[3], _0xC5C6))
endlocal function _0x24B8(wsz)
if wsz.x < 700 or wsz.y < 400 then
wsz = _0xEFB3.ImVec2(math.max(700, wsz.x), math.max(400, wsz.y))
_0xEFB3.SetWindowSize(wsz, _0xEFB3.Cond.Always)
end
_0xE16E.w, _0xE16E.h = wsz.x, wsz.y
_0xE16E.tab_h = _0xCD0C(math.floor((_0xE16E.h - 161) / 8) - 5, 26, 42)
_0xE16E.block_y = 5 + 8 * (_0xE16E.tab_h + 5) + 6
local _0x81C3, _0xCC7A = math.floor(wsz.x + 0.5), math.floor(wsz.y + 0.5)
if _0x81C3 ~= _0xF228.win_w or _0xCC7A ~= _0xF228.win_h then
_0xF228.win_w, _0xF228.win_h = _0x81C3, _0xCC7A
_0x32DC()
end
endfunction _0xDFF1.draw_splash(_0xBC3A)
if not _0xDFF1.splash_t then return end
local _0x2818 = _0xEFB3.ImVec2
local _0x1244 = _0xEFB3.GetTime() - _0xDFF1.splash_t
local _0xFEBE = 2.0
if _0x1244 >= _0xFEBE then
_0xDFF1.splash_t = nil
return
end
_0xEFB3.SetCursorPos(_0x2818(0, 0))
if _0xEFB3.InvisibleButton("##splash_block", _0x2818(_0xE16E.w, _0xE16E.h)) then
_0xDFF1.splash_t = nil
return
end
local _0xC5C6 = (_0x1244 < 1.35) and 1 or _0xCD0C(1 - (_0x1244 - 1.35) / (_0xFEBE - 1.35), 0, 1)
local _0x4CF0 = _0xF228.accent
local _0x6A4A = _0xEFB3.GetWindowDrawList()
local _0x91E7, _0xD740 = _0xBC3A.x + _0xE16E.w, _0xBC3A.y + _0xE16E.h
_0x6A4A:AddRectFilled(_0xBC3A, _0x2818(_0x91E7, _0xD740), _0xE27E(0.04, 0.035, 0.06, 0.98 * _0xC5C6), 12)
local _0x6551, _0xE58A = (_0xBC3A.x + _0x91E7) / 2, (_0xBC3A.y + _0xD740) / 2 - 24
for _0x43EB = 5, 1, -1 do
_0x6A4A:AddCircleFilled(_0x2818(_0x6551, _0xE58A), 40 + _0x43EB * 26, _0xE27E(_0x4CF0[1], _0x4CF0[2], _0x4CF0[3], 0.035 * _0xC5C6), 40)
end
if _0xF228.halloween then _0xDFF1.hw_safe(_0xDFF1.hw_pumpkin, _0x6A4A, _0x6551, _0xE58A - 92, 30, _0xC5C6, true) end
local _0x5432 = 1 + 0.12 * (1 - _0xCD0C(_0x1244 / 0.7, 0, 1)) ^ 2
local _0xFC74 ="Arizona Prices"_0xEFB3.SetWindowFontScale(2.6 * _0x5432)
local _0xA46C = _0xEFB3.CalcTextSize(_0xFC74)
_0x6A4A:AddText(_0x2818(_0x6551 - _0xA46C.x / 2 + 2, _0xE58A - _0xA46C.y / 2 + 2), _0xE27E(0, 0, 0, 0.6 * _0xC5C6), _0xFC74)
_0x6A4A:AddText(_0x2818(_0x6551 - _0xA46C.x / 2, _0xE58A - _0xA46C.y / 2), _0xE27E(1, 1, 1, _0xC5C6), _0xFC74)
_0xEFB3.SetWindowFontScale(1.2)
local _0x3A00 ="Версия ".. _0x2CC5 .."  |  t.me/arizona_prices"local _0x8629 = _0xEFB3.CalcTextSize(_0x3A00)
_0x6A4A:AddText(_0x2818(_0x6551 - _0x8629.x / 2, _0xE58A + _0xA46C.y / 2 + 12), _0xE27E(0.75, 0.78, 0.9, _0xC5C6), _0x3A00)
_0xEFB3.SetWindowFontScale(1.0)
local _0x44C0 = 240
local _0x8578, _0x5C38 = _0x6551 - _0x44C0 / 2, _0xE58A + _0xA46C.y / 2 + 62
_0x6A4A:AddRectFilled(_0x2818(_0x8578, _0x5C38), _0x2818(_0x8578 + _0x44C0, _0x5C38 + 6), _0xE27E(1, 1, 1, 0.10 * _0xC5C6), 3)
_0x6A4A:AddRectFilled(_0x2818(_0x8578, _0x5C38), _0x2818(_0x8578 + _0x44C0 * _0xCD0C(_0x1244 / (_0xFEBE - 0.3), 0, 1), _0x5C38 + 6), _0xE27E(_0x4CF0[1], _0x4CF0[2], _0x4CF0[3], _0xC5C6), 3)
if _0xF228.halloween then
_0xEFB3.SetWindowFontScale(1.1)
local _0xB1AC = _0xEFB3.CalcTextSize("Happy Halloween")
_0x6A4A:AddText(_0x2818(_0x6551 - _0xB1AC.x / 2, _0x5C38 + 20), _0xE27E(1.0, 0.60, 0.15, _0xC5C6),"Happy Halloween")
_0xEFB3.SetWindowFontScale(1.0)
end
end
_0xEFB3.OnFrame(function() return _0x950A[0] or _0xEEF6[0] or _0xDFF1.alpha > 0 end,
_0xD9E5("menu", function(player)
_0xDFF1.tick()
if _0x950A[0] or _0xDFF1.alpha > 0 then
_0xDFF1.set_alpha(_0xDFF1.alpha)
local _0x72C1, _0x5CFA = getScreenResolution()
_0xEFB3.SetNextWindowPos(_0xEFB3.ImVec2(_0x72C1 / 2, _0x5CFA / 2), _0xEFB3.Cond.FirstUseEver, _0xEFB3.ImVec2(0.5, 0.5))
if _0xE16E.force then
_0xE16E.force = false
_0xEFB3.SetNextWindowSize(_0xEFB3.ImVec2(835, 500), _0xEFB3.Cond.Always)
elseif _0xE16E.req then
_0xEFB3.SetNextWindowSize(_0xEFB3.ImVec2(_0xE16E.req.w, _0xE16E.req.h), _0xEFB3.Cond.Always)
_0xE16E.req = nil
else
_0xEFB3.SetNextWindowSize(_0xEFB3.ImVec2(_0xF228.win_w, _0xF228.win_h), _0xEFB3.Cond.FirstUseEver)
end
pcall(_0xEFB3.SetNextWindowSizeConstraints, _0xEFB3.ImVec2(700, 400), _0xEFB3.ImVec2(math.max(700, _0x72C1 - 20), math.max(400, _0x5CFA - 20)))
if _0xEFB3.Begin(_0x1329("Arizona Prices##main_window"), _0x950A[0] and _0x950A or nil, bit.bor(_0xEFB3.WindowFlags.NoCollapse, _0xEFB3.WindowFlags.NoResize, _0xEFB3.WindowFlags.NoTitleBar, _0xEFB3.WindowFlags.NoScrollbar, _0xEFB3.WindowFlags.NoScrollWithMouse)) then
_0x24B8(_0xEFB3.GetWindowSize())
local _0xBC3A = _0xEFB3.GetWindowPos()
local _0xE7E2, _0x69F8 = _0xBC3A.x + _0xE16E.w / 2, _0xBC3A.y + _0xE16E.h / 2
_0xDA0E.typing = _0xEFB3.GetIO().WantTextInput_0x081D(_0xBC3A)
_0xEFB3.SetCursorPos(_0xEFB3.ImVec2(5, 5))
_0x77C1(_0xB914.CIRCLE_DOLLAR .. _0x1329(" Arizona Prices"), 1,"Таблица цен предметов (клавиша 1)\nCtrl+F - быстрый поиск")
_0x77C1(_0x2075("CALCULATOR","") .." Калькулятор", 2,"Калькулятор с историей (клавиша 2)")
_0x77C1(_0x2075("CLOCK","") .." Отчет до PayDay", 3,"Таймер до PayDay на экране (клавиша 3)")
_0x77C1(_0x2075("COMMENT_DOTS","") .." Фразы", 4,"Быстрые фразы в чат (клавиша 4)")
_0x77C1(_0x2075("NOTE_STICKY","") .." Заметки", 8,"Ваши заметки (клавиша 5)")
_0x77C1(_0x2075("GLOBE","") .." Время стран", 6,"Время в других странах (клавиша 6)")
_0x77C1(_0x2075("CIRCLE_INFO","") .." О скрипте", 5,"Соцсети и разработчик (клавиша 7)")
_0x77C1(_0x2075("GEAR","") .." Настройки", 7,"Тема, шрифт, прозрачность (клавиша 8)")
_0xDFF1.draw_bar(_0xBC3A)
_0x5546()local _0xA3E1 = _0xCD0C((_0xEFB3.GetTime() - _0xDFF1.tab_t) / 0.30, 0, 1)
local _0x75A1 = 1 - (1 - _0xA3E1) ^ 3
local _0xC633 = (1 - _0x75A1) * 30
_0xDFF1.base = _0xDFF1.alpha * _0x75A1
_0xDFF1.set_alpha(_0xDFF1.base)
_0xEFB3.SetCursorPos(_0xEFB3.ImVec2(_0x9E4F + _0xC633, 0))
local _0xA9C7 = _0xEFB3.WindowFlags.AlwaysUseWindowPadding or 0
if not (_0x69CC == 2 and (_0xE16E.h < 495 or _0xE16E.w < 830)) then
_0xA9C7 = bit.bor(_0xA9C7, _0xEFB3.WindowFlags.NoScrollbar, _0xEFB3.WindowFlags.NoScrollWithMouse)
end
local _0xF469 = _0xEFB3.BeginChild("##content", _0xEFB3.ImVec2(_0xE16E.w - _0x9E4F - _0xC633, _0xE16E.h), false, _0xA9C7)
if _0xF469 then
if _0xF228.bg_fx then pcall(_0xDFF1.draw_bg) end
if _0xF228.halloween then _0xDFF1.hw_safe(_0xDFF1.hw_bg) end
if _0x69CC == 1 then
_0xEFB3.AlignTextToFramePadding()
_0xEFB3.SetCursorPosX(9)
local _0xC8EA = _0xEFB3.GetCursorScreenPos()
_0xEFB3.Text(_0xB914.CIRCLE_DOLLAR .. _0x1329(' Arizona Prices'))
if _0xEFB3.IsItemHovered() then
local _0x8B0F, _0x3B10 = _0xEFB3.GetItemRectMin(), _0xEFB3.GetItemRectMax()
_0xEFB3.GetWindowDrawList():AddLine(_0xEFB3.ImVec2(_0x8B0F.x, _0x3B10.y), _0xEFB3.ImVec2(_0x3B10.x, _0x3B10.y), _0xE27E(_0xF228.accent[1], _0xF228.accent[2], _0xF228.accent[3], 1), 1.5)
_0xEFB3.SetTooltip("Открыть наш Telegram-канал @arizona_prices")
if _0xEFB3.IsMouseClicked(0) then _0x091E("https://t.me/arizona_prices") end
end
_0xEFB3.SameLine(140)
_0xEFB3.SetNextItemWidth(math.max(90, _0xE16E.w - _0x9E4F - 329))
if _0xDFF1.focus_search then
_0xEFB3.SetKeyboardFocusHere()
_0xDFF1.focus_search = false
end
_0xEFB3.InputTextWithHint("##search", _0xB914.MAGNIFYING_GLASS .." Поиск", _0x6ADB, _0x0A3B.sizeof(_0x6ADB))
_0xEFB3.SameLine()
_0xEFB3.SetNextItemWidth(150)
local _0x9623 = {"По умолчанию","Сначала дорогие","Сначала дешёвые","По алфавиту"}
local _0x4DF3 = _0x9623[_0x0CCE[0] + 1] or"Сортировка"if _0xEFB3.BeginCombo("##sort_combo", _0x4DF3) then
for _0x43EB, _0x4D0B in ipairs(_0x9623) do
local _0xC966 = _0x0CCE[0] == (_0x43EB - 1)
if _0xEFB3.Selectable(_0x4D0B, _0xC966) then
_0x0CCE[0] = _0x43EB - 1
end
if _0xC966 then
_0xEFB3.SetItemDefaultFocus()
end
end
_0xEFB3.EndCombo()
end
_0xEFB3.SameLine(_0xE16E.w - _0x9E4F - 29)
_0xEFB3.PushStyleColor(_0xEFB3.Col.Button, _0xEFB3.ImVec4(0, 0, 0, 0))
if _0xEFB3.Button(_0xB914.CIRCLE_XMARK .."##close", _0xEFB3.ImVec2(24, 24)) then
_0x950A[0] = false
end
if _0xEFB3.IsItemHovered() then _0xEFB3.SetTooltip("Закрыть") end
_0xEFB3.PopStyleColor(1)
_0xEFB3.Spacing()
local _0x252A = _0x0A3B.string(_0x6ADB)
if _0x252A ~= _0xDFF1.last_q or _0x0CCE[0] ~= _0xDFF1.last_sort then
_0xDFF1.last_q, _0xDFF1.last_sort = _0x252A, _0x0CCE[0]
_0xDFF1.table_t = _0xEFB3.GetTime()
end
if not _0xDFF1.hint_shown then
_0xDFF1.hint_shown = true
_0x3D10("Подсказка: правая кнопка мыши по предмету - быстрые действия, звёздочка - избранное","info", 7)
end
if _0xEFB3.BeginChild("##table_child", _0xEFB3.ImVec2(-1, _0xE16E.h - 79), true) then
local _0xA36C = _0xEFB3.GetStyle()
local _0x23C4 = _0xEFB3.GetCursorScreenPos().x
local _0x3DE0 = _0xEFB3.GetCursorScreenPos().y - _0xA36C.WindowPadding.y
local _0xA71A = _0xA36C.ItemSpacing.y
local _0x8435 = 110
local _0xE768, _0xD3F4, _0x588F = 140, 120, _0x9100.on and 108 or 44
local _0x836E = math.max(110, math.floor(_0xEFB3.GetContentRegionAvail().x) - (_0x8435 + _0xE768 + _0xD3F4 + _0x588F))
_0xEFB3.Columns(5,"item_table", false)
_0xEFB3.SetColumnWidth(0, _0x836E)
_0xEFB3.SetColumnWidth(1, _0x8435)
_0xEFB3.SetColumnWidth(2, _0xE768)
_0xEFB3.SetColumnWidth(3, _0xD3F4)
_0xEFB3.SetColumnWidth(4, _0x588F)
do
local _0x9AF4 = _0xEFB3.CalcTextSize("Предмет")
_0xEFB3.SetCursorPosX(_0xEFB3.GetCursorPosX() + math.max(0, (_0x836E - _0x9AF4.x) * 0.5))
_0xEFB3.TextColored(_0xBD61(1.3),"Предмет")
end
_0xEFB3.NextColumn()
do
local _0x9AF4 = _0xEFB3.CalcTextSize("Ликвидность")
_0xEFB3.SetCursorPosX(_0xEFB3.GetCursorPosX() + math.max(0, (_0x8435 - _0x9AF4.x) * 0.5))
_0xEFB3.TextColored(_0xBD61(1.3),"Ликвидность")
end
_0xEFB3.NextColumn()
do
local _0x9AF4 = _0xEFB3.CalcTextSize("Скупочная цена")
_0xEFB3.SetCursorPosX(_0xEFB3.GetCursorPosX() + math.max(0, (_0xE768 - _0x9AF4.x) * 0.5))
_0xEFB3.TextColored(_0xBD61(1.3),"Скупочная цена")
end
_0xEFB3.NextColumn()
do
local _0x9AF4 = _0xEFB3.CalcTextSize("Продажа")
_0xEFB3.SetCursorPosX(_0xEFB3.GetCursorPosX() + math.max(0, (_0xD3F4 - _0x9AF4.x) * 0.5))
_0xEFB3.TextColored(_0xBD61(1.3),"Продажа")
end
_0xEFB3.NextColumn()
do
local _0x9AF4 = _0xEFB3.CalcTextSize("Действия")
_0xEFB3.SetCursorPosX(_0xEFB3.GetCursorPosX() + math.max(0, (_0x588F - _0x9AF4.x) * 0.5))
_0xEFB3.TextColored(_0xBD61(1.3),"Действия")
end
_0xEFB3.NextColumn()
_0xEFB3.Separator()
local _0x7655 = _0xEFB3.GetCursorScreenPos().y - _0xA71A - 1.0
local _0x3F58 = {}
local _0x744D = _0xE8BA(_0x0A3B.string(_0x6ADB))
for _0x43EB, _0x0448 in ipairs(_0xE004) do
local _0xBCCE = _0xE8BA(_0x0448.item or"")
if _0x744D ==""or _0xBCCE:find(_0x744D, 1, true) then
table.insert(_0x3F58, _0x43EB)
end
end
if _0x0CCE[0] == 1 then
table.sort(_0x3F58, function(_0xC5C6, _0x8AAA) return tonumber(_0xE004[_0xC5C6].sell or 0) > tonumber(_0xE004[_0x8AAA].sell or 0) end)
elseif _0x0CCE[0] == 2 then
table.sort(_0x3F58, function(_0xC5C6, _0x8AAA) return tonumber(_0xE004[_0xC5C6].sell or 0) < tonumber(_0xE004[_0x8AAA].sell or 0) end)
elseif _0x0CCE[0] == 3 then
table.sort(_0x3F58, function(_0xC5C6, _0x8AAA) local _0x23D6 = (_0xE004[_0xC5C6].item or""):lower() local _0x8D76 = (_0xE004[_0x8AAA].item or""):lower() return _0x23D6 < _0x8D76 end)
end
if next(_0x3049.favs) thenlocal _0xFBF7, _0xC9FD = {}, {}
for _0xEDD8, ix in ipairs(_0x3F58) do
if _0xE004[ix] and _0x3049.favs[_0xE004[ix].item] then
_0xFBF7[#_0xFBF7 + 1] = ix
else
_0xC9FD[#_0xC9FD + 1] = ix
end
end
for _0xEDD8, ix in ipairs(_0xC9FD) do _0xFBF7[#_0xFBF7 + 1] = ix end
_0x3F58 = _0xFBF7
end
local _0x2AA6 = _0xEFB3.GetTime()
for ri, _0x49D8 in ipairs(_0x3F58) do
local _0xB96F = _0xE004[_0x49D8]
if _0xB96F then
local _0x8DB4 = _0xEFB3.GetCursorPosY()
local _0x83F3 = _0xCD0C((_0x2AA6 - _0xDFF1.table_t - math.min(ri, 14) * 0.03) / 0.22, 0, 1)
_0xDFF1.set_alpha(_0xDFF1.base * _0x83F3)
do
local _0xCEC7 = _0xEFB3.GetCursorScreenPos()
local _0x5B3A = _0x23C4 + _0x836E + _0x8435 + _0xE768 + _0xD3F4 + _0x588F
local _0x8B0F, _0x3B10 = _0xEFB3.ImVec2(_0x23C4, _0xCEC7.y - 2), _0xEFB3.ImVec2(_0x5B3A, _0xCEC7.y + 27)
local _0x158E = _0xEFB3.IsMouseHoveringRect(_0x8B0F, _0x3B10)
if _0x158E and _0xEFB3.IsWindowHovered() and _0xEFB3.IsMouseClicked(1) then
_0x3CD2 = _0xB96F.item
_0xDFF1.ctx_open = true
end
if _0x158E and _0xEFB3.IsWindowHovered() and _0xEFB3.IsMouseClicked(0) then
_0x3CD2 = _0xB96F.item
end
if _0x3CD2 ~= nil and _0xB96F.item == _0x3CD2 then
_0xEFB3.GetWindowDrawList():AddRectFilled(_0x8B0F, _0x3B10, _0xE27E(_0xF228.accent[1], _0xF228.accent[2], _0xF228.accent[3], 0.30), 6)
elseif _0x158E then
_0xEFB3.GetWindowDrawList():AddRectFilled(_0x8B0F, _0x3B10, _0xE27E(_0xF228.accent[1], _0xF228.accent[2], _0xF228.accent[3], 0.14), 6)
elseif ri % 2 == 0 then
_0xEFB3.GetWindowDrawList():AddRectFilled(_0x8B0F, _0x3B10, _0xE27E(1, 1, 1, 0.025), 6)
end
end
local _0xBAE6 = _0xB96F.item or""local _0x9AF4 = _0xEFB3.CalcTextSize(_0xBAE6)
_0xEFB3.SetCursorPosY(_0x8DB4 + math.max(0, (24 - _0x9AF4.y) * 0.5))
local _0x68C8 = _0xEFB3.CalcTextSize(_0xB914.CIRCLE_QUESTION).x
local _0x1E48 = _0x836E - _0x68C8 - 12
if _0x9AF4.x > _0x1E48 then
local _0xA144 = _0xBAE6
while #_0xA144 > 3 and _0xEFB3.CalcTextSize(_0xA144 .."...").x > _0x1E48 do
local _0x0186 = #_0xA144
local _0x8CE5 = _0x0186
while _0x8CE5 > 0 and _0xA144:byte(_0x8CE5) >= 128 and _0xA144:byte(_0x8CE5) < 192 do
_0x8CE5 = _0x8CE5 - 1
end
_0xA144 = _0xA144:sub(1, _0x8CE5 - 1)
end
_0xA144 = _0xA144 .."..."_0xEFB3.Text(_0xA144)
if _0xEFB3.IsItemHovered() then _0xEFB3.SetTooltip((_0xBAE6:gsub("%%","%%%%"))) end
_0xEFB3.SameLine(_0x836E - _0x68C8 - 6)
_0xEFB3.Text(_0xB914.CIRCLE_QUESTION)
if _0xEFB3.IsItemHovered() then _0xEFB3.SetTooltip((_0xBAE6:gsub("%%","%%%%"))) end
else
_0xEFB3.SetCursorPosX(_0xEFB3.GetCursorPosX() + math.max(0, (_0x836E - _0x9AF4.x) * 0.5))
_0xEFB3.TextUnformatted(_0xBAE6)
end
_0xEFB3.NextColumn()
do
local _0x5535 = _0xB96F.liq
local _0x1F47 = _0x5535 or"-"local _0x90CF = _0xDFF1.liq_color(_0x5535)
if _0x9100.on then_0xEFB3.SetCursorPosY(_0x8DB4)
_0xEFB3.PushStyleColor(_0xEFB3.Col.Text, _0x90CF)
if _0xEFB3.Button(_0x1F47 .."##liq_".. _0x49D8, _0xEFB3.ImVec2(_0x8435 - 14, 24)) then
_0xB96F.liq = _0xDFF1.liq_next(_0x5535)
_0xA936()
end
_0xEFB3.PopStyleColor(1)
else
local _0x9AF4 = _0xEFB3.CalcTextSize(_0x1F47)
_0xEFB3.SetCursorPosY(_0x8DB4 + math.max(0, (24 - _0x9AF4.y) * 0.5))
_0xEFB3.SetCursorPosX(_0xEFB3.GetCursorPosX() + math.max(0, (_0x8435 - _0x9AF4.x) * 0.5))
_0xEFB3.TextColored(_0x90CF, _0x1F47)
end
end
_0xEFB3.NextColumn()
do
local _0x9AF4 = _0xEFB3.CalcTextSize(_0x3823(_0xB96F.buy))
_0xEFB3.SetCursorPosY(_0x8DB4 + math.max(0, (24 - _0x9AF4.y) * 0.5))
_0xEFB3.SetCursorPosX(_0xEFB3.GetCursorPosX() + math.max(0, (_0xE768 - _0x9AF4.x) * 0.5))
_0xEFB3.TextColored(_0xEFB3.ImVec4(0.55, 0.92, 0.65, 1.0), _0x3823(_0xB96F.buy))
end
_0xEFB3.NextColumn()
do
local _0x769D = tonumber(_0xB96F.sell) or 0
local _0xD3B1 = _0x3823(_0xB96F.sell)
local _0x9AF4 = _0xEFB3.CalcTextSize(_0xD3B1)
_0xEFB3.SetCursorPosY(_0x8DB4 + math.max(0, (24 - _0x9AF4.y) * 0.5))
_0xEFB3.SetCursorPosX(_0xEFB3.GetCursorPosX() + math.max(0, (_0xD3F4 - _0x9AF4.x - 20) * 0.5))
_0xEFB3.TextColored(_0xEFB3.ImVec4(1.0, 0.85, 0.45, 1.0), _0xD3B1)
local _0x68C8 = _0xEFB3.CalcTextSize(_0xB914.BADGE_PERCENT).x
_0xEFB3.SameLine(_0xD3F4 - _0x68C8 - 6)
_0xEFB3.Text(_0xB914.BADGE_PERCENT)
if _0xEFB3.IsItemHovered() then
_0xEFB3.SetTooltip("1%% - ".. _0x3823(math.floor(_0x769D * 0.99 + 0.5)) .."\n".."3%% - ".. _0x3823(math.floor(_0x769D * 0.97 + 0.5)) .."\n".."4%% - ".. _0x3823(math.floor(_0x769D * 0.96 + 0.5)) .."\n".."5%% - ".. _0x3823(math.floor(_0x769D * 0.95 + 0.5)))
end
end
_0xEFB3.NextColumn()
local _0xDD20 = _0x9100.on and (28 * 3 + 10) or 28
_0xEFB3.SetCursorPosY(_0x8DB4)
_0xEFB3.SetCursorPosX(_0xEFB3.GetCursorPosX() + math.max(0, (_0x588F - _0xDD20) * 0.5))
local _0x9C12 = _0x3049.favs[_0xB96F.item] == true
_0xEFB3.PushStyleColor(_0xEFB3.Col.Text, _0x9C12 and _0xEFB3.ImVec4(1.0, 0.82, 0.25, 1.0) or _0xEFB3.ImVec4(0.50, 0.52, 0.58, 1.0))
if _0xEFB3.Button(_0x2075("STAR","*") .."##fav_".. _0x49D8, _0xEFB3.ImVec2(28, 24)) then
_0xDFF1.toggle_fav(_0xB96F.item)
end
_0xEFB3.PopStyleColor(1)
if _0xEFB3.IsItemHovered() then _0xEFB3.SetTooltip(_0x9C12 and"Убрать из избранного"or"В избранное") end
if _0x9100.on then
_0xEFB3.SameLine()
if _0xEFB3.Button(_0xB914.PEN_LINE .."##edit_".. _0x49D8, _0xEFB3.ImVec2(28, 24)) then
_0x56AE(_0x49D8)
end
_0xEFB3.SameLine()
if _0xEFB3.Button(_0xB914.TRASH_CAN .."##del_".. _0x49D8, _0xEFB3.ImVec2(28, 24)) then
_0x9D23 = _0x49D8
_0xF2E8 = true
end
end
_0xEFB3.NextColumn()
_0xEFB3.Separator()
_0x7655 = _0xEFB3.GetCursorScreenPos().y - _0xA71A - 1.0
end
end
_0xEFB3.Columns(1)
_0xDFF1.set_alpha(_0xDFF1.base)
if _0xDFF1.ctx_open then
_0xEFB3.OpenPopup("##row_ctx")
_0xDFF1.ctx_open = false
end
if _0xEFB3.BeginPopup("##row_ctx") then
local _0xA8AA
for _0xEDD8, _0x0448 in ipairs(_0xE004) do
if _0x0448.item == _0x3CD2 then _0xA8AA = _0x0448; break end
end
if _0xA8AA then
local _0x7B13 = _0xA8AA.item ..": скупка ".. _0x3823(_0xA8AA.buy) .." / продажа ".. _0x3823(_0xA8AA.sell)
_0xEFB3.TextColored(_0xBD61(1.3), _0xA8AA.item)
_0xEFB3.Separator()
if _0xEFB3.Selectable(_0x2075("COMMENT_DOTS","") .."  Вставить в строку чата##ctx_chat") then
_0x5104(function()
sampSetChatInputEnabled(true)
sampSetChatInputText(_0x1329:decode(_0x7B13))
end)
end
if _0xEFB3.Selectable(_0x2075("COPY","") .."  Скопировать в буфер##ctx_copy") then
_0xEFB3.SetClipboardText(_0x7B13)
_0x3D10("Скопировано: ".. _0x7B13,"ok", 4)
end
local _0x6062 = _0x3049.favs[_0xA8AA.item] == true
if _0xEFB3.Selectable(_0x2075("STAR","*") .. (_0x6062 and"  Убрать из избранного"or"  В избранное") .."##ctx_fav") then
_0xDFF1.toggle_fav(_0xA8AA.item)
end
else
_0xEFB3.Text("Предмет не найден")
end
_0xEFB3.EndPopup()
end
if _0x7655 > _0x3DE0 then
local _0xB12F = _0xEFB3.GetWindowDrawList()
local _0x1DE6 = _0xEFB3.GetColorU32(_0xEFB3.Col.Separator)
local _0xD40E = _0x23C4
local _0x97DF = {_0x836E, _0x8435, _0xE768, _0xD3F4}
for _0x43EB = 1, 4 do
_0xD40E = _0xD40E + _0x97DF[_0x43EB]
_0xB12F:AddLine(_0xEFB3.ImVec2(_0xD40E, _0x3DE0), _0xEFB3.ImVec2(_0xD40E, _0x7655), _0x1DE6, 1.0)
end
end
_0xEFB3.EndChild()
end
local _0x61E8 = _0xEFB3.GetContentRegionAvail().x - 95
if _0x9100.on then
if _0xEFB3.Button(_0xB914.CIRCLE_PLUS .." Добавить предмет", _0xEFB3.ImVec2(_0x61E8, 30)) then
_0x7044()
end
else
if _0xEFB3.Button(_0x2075("PAPER_PLANE","") .." Актуальные цены - в нашем ТГК @arizona_prices##open_tg", _0xEFB3.ImVec2(_0x61E8, 30)) then
_0x091E("https://t.me/arizona_prices")
end
end
_0xEFB3.SameLine()
if _0xEFB3.Button(_0xB914.TRIANGLE_EXCLAMATION .."##report_prices", _0xEFB3.ImVec2(30, 30)) then
if _0x3CD2 and _0x3CD2 ~=""then
_0xEFB3.SetClipboardText("Привет. Заметил что цена предмета \"".. _0x3CD2 .."\" изменилась, прошу обновить")
_0x091E("https://t.me/xi_vivide")
_0x3D10("Сообщение скопировано - вставьте его в чат (Ctrl+V)","ok", 6)
else
_0x3D10("Сначала нажмите на предмет в таблице, цена которого устарела","warn", 5)
end
end
if _0xEFB3.IsItemHovered() then _0xEFB3.SetTooltip("Сообщить об устаревших ценах\n(сначала нажмите на предмет в таблице)") end
_0xEFB3.SameLine()
if _0xEFB3.Button(_0xB914.BUG .."##report_bug", _0xEFB3.ImVec2(30, 30)) then
_0x1C07()
end
if _0xEFB3.IsItemHovered() then _0xEFB3.SetTooltip("Сообщить о баге (скопирует данные для разработчика)") end
if _0x6B64 then
_0xEFB3.OpenPopup(_0x0078 and _0x91ED or _0xEB19)
_0x6B64 = false
end
if _0xEEF6[0] then
local _0xCC37 = _0x0078 and _0x91ED or _0xEB19
_0xEFB3.SetNextWindowPos(_0xEFB3.ImVec2(_0xE7E2, _0x69F8), _0xEFB3.Cond.Always, _0xEFB3.ImVec2(0.5, 0.5))
_0xEFB3.SetNextWindowSize(_0xEFB3.ImVec2(300, 171), _0xEFB3.Cond.Always)
if _0xEFB3.BeginPopupModal(_0xCC37, _0xEEF6, bit.bor(_0xEFB3.WindowFlags.NoCollapse, _0xEFB3.WindowFlags.NoResize)) then
local _0x9FD6 = _0xB914.LAYER_GROUP .." Предмет"local _0x789B = _0xB914.HANDS_HOLDING_DOLLAR .." Скупочная цена"local _0xD7B5 = _0xB914.HAND_HOLDING_DOLLAR .." Продажа"if _0xCCA7 then
local _0x73AE = os.clock() - _0x8BA4
if _0x73AE >= 1.2 then
_0xCCA7 = false
else
local _0xE72A = (_0x73AE % 0.4) < 0.2
if _0xFD3A and _0xE72A then _0x9FD6 =""end
if _0x1AD5 and _0xE72A then _0x789B =""end
if _0xAE54 and _0xE72A then _0xD7B5 =""end
end
end
if _0xEFB3.BeginChild("##modal", _0xEFB3.ImVec2(-1, 102), true) then
_0xEFB3.SetNextItemWidth(-1)
_0xEFB3.InputTextWithHint("##modal_item", _0x9FD6, _0x30A6, _0x0A3B.sizeof(_0x30A6))
_0xEFB3.Separator()
_0xEFB3.SetNextItemWidth(-1)
_0xEFB3.InputTextWithHint("##modal_buy", _0x789B, _0xE69C, _0x0A3B.sizeof(_0xE69C), _0xEFB3.InputTextFlags.CharsDecimal)
_0xEFB3.Separator()
_0xEFB3.SetNextItemWidth(-1)
_0xEFB3.InputTextWithHint("##modal_sell", _0xD7B5, _0x931A, _0x0A3B.sizeof(_0x931A), _0xEFB3.InputTextFlags.CharsDecimal)
_0xEFB3.EndChild()
end
if _0x0078 then
if _0xEFB3.Button(_0xB914.FLOPPY_DISK .." Сохранить", _0xEFB3.ImVec2(142, 30)) then
local _0xA91E = _0x0A3B.string(_0x30A6)
local _0x3FAB = _0x0A3B.string(_0xE69C)
local _0x93B7 = _0x0A3B.string(_0x931A)
_0xFD3A = (_0xA91E =="")
_0x1AD5 = (_0x3FAB =="")
_0xAE54 = (_0x93B7 =="")
if _0xFD3A or _0x1AD5 or _0xAE54 then
_0xCCA7 = true
_0x8BA4 = os.clock()
else
local _0x4D0B = _0xA91E
local _0xA09E = tonumber(_0x3FAB)
local _0x6932 = tonumber(_0x93B7)
if _0xA09E and _0x6932 and _0x0109 and _0xE004[_0x0109] then
_0xE004[_0x0109] = {_0xB96F = _0x4D0B, _0xA09E = _0xA09E, _0x6932 = _0x6932, _0x5535 = _0xE004[_0x0109].liq}
_0xA936()
_0x1DF1()
end
end
end
_0xEFB3.SameLine()
if _0xEFB3.Button(_0xB914.CIRCLE_XMARK .." Отменить", _0xEFB3.ImVec2(142, 30)) then
_0x1DF1()
end
else
if _0xEFB3.Button(_0xB914.CIRCLE_PLUS .." Добавить", _0xEFB3.ImVec2(-1, 30)) then
local _0xA91E = _0x0A3B.string(_0x30A6)
local _0x3FAB = _0x0A3B.string(_0xE69C)
local _0x93B7 = _0x0A3B.string(_0x931A)
_0xFD3A = (_0xA91E =="")
_0x1AD5 = (_0x3FAB =="")
_0xAE54 = (_0x93B7 =="")
if _0xFD3A or _0x1AD5 or _0xAE54 then
_0xCCA7 = true
_0x8BA4 = os.clock()
else
local _0x4D0B = _0xA91E
local _0xA09E = tonumber(_0x3FAB)
local _0x6932 = tonumber(_0x93B7)
if _0xA09E and _0x6932 then
table.insert(_0xE004, {_0xB96F = _0x4D0B, _0xA09E = _0xA09E, _0x6932 = _0x6932})
_0xA936()
_0x1DF1()
end
end
end
end
_0xEFB3.EndPopup()
end
end
if _0xF2E8 then
_0xEFB3.OpenPopup(_0xB914.TRASH_CAN ..' Подтверждение удаления##delete_modal')
_0xF2E8 = false
end
_0xEFB3.SetNextWindowPos(_0xEFB3.ImVec2(_0xE7E2, _0x69F8), _0xEFB3.Cond.Always, _0xEFB3.ImVec2(0.5, 0.5))
_0xEFB3.SetNextWindowSize(_0xEFB3.ImVec2(415, 88), _0xEFB3.Cond.Always)
if _0xEFB3.BeginPopupModal(_0xB914.TRASH_CAN ..' Подтверждение удаления##delete_modal', nil, bit.bor(_0xEFB3.WindowFlags.NoCollapse, _0xEFB3.WindowFlags.NoResize)) then
_0xEFB3.TextWrapped(_0xB914.CIRCLE_QUESTION ..' Вы действительно хотите удалить этот предмет из справочника?')
_0xEFB3.Spacing()
if _0xEFB3.Button(_0xB914.TRASH_CAN ..' Да, удалить', _0xEFB3.ImVec2(200, 30)) then
if _0x9D23 and _0xE004[_0x9D23] then
table.remove(_0xE004, _0x9D23)
_0xA936()
end
_0x9D23 = nil
_0xEFB3.CloseCurrentPopup()
end
_0xEFB3.SameLine()
if _0xEFB3.Button(_0xB914.CIRCLE_XMARK ..' Отменить', _0xEFB3.ImVec2(200, 30)) then
_0x9D23 = nil
_0xEFB3.CloseCurrentPopup()
end
_0xEFB3.EndPopup()
end
elseif _0x69CC == 2 then
_0x17DF()
else
_0xF9A5(_0x69CC)
end
end
if _0xF469 then pcall(_0xF5BE) end
_0xEFB3.EndChild()
_0xDFF1.set_alpha(_0xDFF1.alpha)
_0xDFF1.draw_splash(_0xBC3A)
_0x7340(_0xBC3A.x, _0xBC3A.y, _0xBC3A.x + _0xE16E.w, _0xBC3A.y + _0xE16E.h)
_0xEFB3.End()
else
_0xEFB3.End()
end
_0xDFF1.set_alpha(1)
end
end, function() _0x950A[0] = false; _0xEEF6[0] = false; _0xDA0E.binding = false; _0xDFF1.alpha = 0; _0xDFF1.set_alpha(1) end)
)_0xEFB3.OnFrame(function() return _0x2D19[0] end, _0xD9E5("outdated", function()
local _0x72C1, _0x5CFA = getScreenResolution()
_0xEFB3.SetNextWindowPos(_0xEFB3.ImVec2(_0x72C1 / 2, _0x5CFA / 2), _0xEFB3.Cond.Always, _0xEFB3.ImVec2(0.5, 0.5))
_0xEFB3.SetNextWindowSize(_0xEFB3.ImVec2(580, 290), _0xEFB3.Cond.Always)
_0xEFB3.SetNextWindowFocus()
local _0x6F06 = bit.bor(_0xEFB3.WindowFlags.NoTitleBar, _0xEFB3.WindowFlags.NoResize, _0xEFB3.WindowFlags.NoMove,
_0xEFB3.WindowFlags.NoCollapse, _0xEFB3.WindowFlags.NoScrollbar, _0xEFB3.WindowFlags.NoSavedSettings)_0xEFB3.PushStyleColor(_0xEFB3.Col.WindowBg, _0xEFB3.ImVec4(0.075, 0.07, 0.095, 1.0))
_0xEFB3.Begin("##outdated_window", nil, _0x6F06)
local _0xBAC3 = _0xEFB3.GetWindowPos()
_0xEFB3.GetWindowDrawList():AddRectFilled(_0xBAC3, _0xEFB3.ImVec2(_0xBAC3.x + 580, _0xBAC3.y + 5), _0xEFB3.ColorConvertFloat4ToU32(_0xEFB3.ImVec4(1.00, 0.75, 0.15, 1.00)))
_0xEFB3.SetCursorPos(_0xEFB3.ImVec2(24, 28))
_0xEFB3.SetWindowFontScale(1.9)
_0xEFB3.TextColored(_0xEFB3.ImVec4(1.00, 0.80, 0.20, 1.00), _0x2075("TRIANGLE_EXCLAMATION","") .." Внимание!")
_0xEFB3.SetWindowFontScale(1.0)
_0xEFB3.SetCursorPos(_0xEFB3.ImVec2(24, 90))
_0xEFB3.SetWindowFontScale(1.3)
_0xEFB3.PushTextWrapPos(556)
_0xEFB3.TextWrapped("У вас старая версия скрипта. Обновите для комфортного использования.")
_0xEFB3.PopTextWrapPos()
_0xEFB3.SetWindowFontScale(1.0)
_0xEFB3.SetCursorPos(_0xEFB3.ImVec2(24, 160))
_0xEFB3.TextDisabled("Ваша версия: ".. _0x2CC5 .."    Новая версия: ".. _0x911D.version)
if _0x911D.status ~=""then
_0xEFB3.SetCursorPosX(24)
_0xEFB3.TextDisabled(_0x911D.status)
end
_0xEFB3.SetCursorPos(_0xEFB3.ImVec2(24, 290 - 24 - 44))
local _0xC835 = (580 - 48 - 10) / 2
_0xEFB3.PushStyleColor(_0xEFB3.Col.Button, _0xBD61(1.0))
_0xEFB3.PushStyleColor(_0xEFB3.Col.ButtonHovered, _0xBD61(1.15))
_0xEFB3.PushStyleColor(_0xEFB3.Col.ButtonActive, _0xBD61(0.85))
if _0x911D.busy then
_0xEFB3.Button("Скачивание...##outdated_busy", _0xEFB3.ImVec2(_0xC835, 44))
elseif _0xEFB3.Button(_0x2075("DOWNLOAD","") .." Обновить##outdated_update", _0xEFB3.ImVec2(_0xC835, 44)) then
_0x7F67()
end
_0xEFB3.PopStyleColor(3)
_0xEFB3.SameLine()
if _0xEFB3.Button(_0xB914.CIRCLE_XMARK .." Закрыть##outdated_close", _0xEFB3.ImVec2(_0xC835, 44)) then
_0x2D19[0] = false
end
_0xEFB3.End()
_0xEFB3.PopStyleColor(1)
end, function() _0x2D19[0] = false end))
function main()
while not isSampAvailable() do wait(0) end
_0x2C6A("load_data", _0x78D9)
sampAddChatMessage(_0x1329:decode("{33AAFF}[Arizona Prices V2.0] {FFFFFF}Скрипт успешно загружен! Для активации - {33AAFF}/prices{FFFFFF}. ТГК - {33AAFF}@arizona_prices"), -1)
sampRegisterChatCommand('prices', _0x565A)
sampRegisterChatCommand('pradmin', function(arg)
arg = tostring(arg or""):gsub("%s","")
if arg =="off"then
_0x9100.disable()
sampAddChatMessage(_0x1329:decode("{33AAFF}[Arizona Prices] {FFFFFF}Режим разработчика выключен"), -1)
elseif arg ~=""and _0x9100.enable(arg) then
sampAddChatMessage(_0x1329:decode("{33AAFF}[Arizona Prices] {55FF55}Режим разработчика включён{FFFFFF}. Правка цен и ликвидности открыта"), -1)
else
sampAddChatMessage(_0x1329:decode("{33AAFF}[Arizona Prices] {FF5555}Неверный код"), -1)
end
end)
addEventHandler('onWindowMessage', function(msg, wparam, lparam)
_0x2C6A("hotkey", _0x9B0F, msg, wparam, lparam)
end)
local _0x230B = os.time() + 5
while true do
wait(100)
if _0xC2BA then
local _0x4BB2 = _0xC2BA
_0xC2BA = nil
pcall(function() _0x9909.ShellExecuteA(nil,"open", _0x4BB2, nil, nil, 1) end)
end
while #_0x509E > 0 do
_0x2C6A("action", table.remove(_0x509E, 1))
end
if not _0x950A[0] and _0xDA0E.binding then _0xDA0E.binding = false end
_0x2C6A("updates", _0x302D)
if #_0x6826 > 0 then
local _0x3CF1 = table.remove(_0x6826, 1)
_0x2C6A("notice", _0x3D10, _0x3CF1.text, _0x3CF1.kind)
end
_0x2C6A("save_ui", _0x225E)
if os.time() >= _0x230B then
_0x230B = os.time() + _0xEBE6
_0x2C6A("start_checks", _0x76E0)
end
if _0xE914 then
_0xE914 = false
wait(700)
thisScript():reload()
end
end
end
function onScriptTerminate(scr, quit)
if scr == thisScript() then
pcall(_0x225E, true)
end
end