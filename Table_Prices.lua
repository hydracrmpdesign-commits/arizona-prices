local _0x2A38 = require('ffi')
local _0x8ED7 = require('encoding')
_0x8ED7.default ='CP1251'local _0x8A46 = _0x8ED7.UTF8
local _0xBC05 ="3.3"local _0x78C7, _0xD452 = pcall(require,'mimgui')
local _0x33D9, _0x7FE0 = pcall(require,'fAwesome6')
if not _0x78C7 or not _0x33D9 then
local _0xEA39 = {}
if not _0x78C7 then _0xEA39[#_0xEA39 + 1] ="mimgui"end
if not _0x33D9 then _0xEA39[#_0xEA39 + 1] ="fAwesome6"end
function main()
while not isSampAvailable() do wait(100) end
sampAddChatMessage(_0x8A46:decode("{FF5555}[Arizona Prices] {FFFFFF}Не найдены библиотеки: {FFCC33}".. table.concat(_0xEA39,", ") .."{FFFFFF}. Положите их в папку {FFCC33}moonloader\\lib{FFFFFF} и перезапустите игру."), -1)
sampAddChatMessage(_0x8A46:decode("{FF5555}[Arizona Prices] {FFFFFF}Где скачать, смотрите в нашем ТГК: {33AAFF}@arizona_prices"), -1)
thisScript():unload()
end
return
endlocal _0x0833 = setmetatable({}, { __index = function(_0x11D3, _0x562D) return _0x7FE0[_0x562D] or""end })
_0x2A38.cdef[[
    int ShellExecuteA(void* hwnd, const char* op, const char* file, const char* params, const char* dir, int show);
]]local _0x4D27 = _0x2A38.load('shell32')
local _0x7C6A = nillocal function _0x2A70(_0xC781)
_0x7C6A = _0xC781
end
local _0xC2A7 = _0xD452.new.bool(false)
local _0x2D04 = _0xD452.new.bool(false)
local _0x7FD1 = _0x0833.CIRCLE_PLUS .." Добавить предмет###item_modal"local _0x6895 = _0x0833.PEN_LINE .." Редактировать предмет###item_modal"local _0xAF5C = _0xD452.new.char[256]()
local _0x0AD7 = _0xD452.new.char[256]()
local _0x227D = _0xD452.new.char[64]()
local _0x86B7 = _0xD452.new.char[64]()
local _0xCBFB = _0xD452.new.int(0)
local _0xD7A8 = false
local _0x0BED = nil
local _0x9AF0 = false
local _0xA336 = false
local _0xE5A5 = nil
local _0x5B27 = nillocal _0x2CB1 = false
local _0x460F = 0
local _0x08EC = false
local _0x2A09 = false
local _0x553F = false
local _0xC12B = {}
local _0x328B = getWorkingDirectory() .."\\config\\item_prices.json"local _0x84CA = {}
local function _0x8F59(_0x4AD0, _0x2849)
_0x84CA[#_0x84CA + 1] = { _0x4AD0 = _0x4AD0, _0x2849 = _0x2849 }
end
local _0x6EE0 = {}
local function _0xF904(_0x93C7)
return debug.traceback(tostring(_0x93C7), 2)
end
local function _0x9FEB(where, _0xAB96)
local _0x4AD0 = tostring(_0xAB96)
_0x6EE0[#_0x6EE0 + 1] = os.date("%H:%M:%S") .." [".. tostring(where) .."] ".. (_0x4AD0:sub(1, 300):gsub("%s+"," "))
if #_0x6EE0 > 8 then table.remove(_0x6EE0, 1) end
pcall(function()
print("[Arizona Prices] ".. tostring(where) ..": ".. _0x4AD0)
local _0x24EF = getWorkingDirectory() .."\\config"if not doesDirectoryExist(_0x24EF) then createDirectory(_0x24EF) end
local _0xCE87 = _0x24EF .."\\arizona_prices_errors.log"local _0xA75A = io.open(_0xCE87,"ab")
if _0xA75A then
if (_0xA75A:seek("end") or 0) > 200000 then
_0xA75A:close()
_0xA75A = io.open(_0xCE87,"wb")
end
if _0xA75A then
_0xA75A:write(os.date("%Y-%m-%d %H:%M:%S") .." [".. tostring(where) .."] ".. _0x4AD0 .."\n\n")
_0xA75A:close()
end
end
end)
endlocal function _0x3271(where, fn, ...)
local _0xB96B = { ... }
local _0x48FB, _0xAB96 = xpcall(function() return fn(unpack(_0xB96B)) end, _0xF904)
if not _0x48FB then _0x9FEB(where, _0xAB96) end
return _0x48FB
endlocal _0x35B6 = {}
local function _0xEECB(fn)
_0x35B6[#_0x35B6 + 1] = fn
endlocal function _0xFBE9(_0x9851, fn, on_fail)
return function(...)
local _0xB96B = { ... }
local _0x72E2 = select("#", ...)
local _0x48FB, _0xAB96 = xpcall(function() return fn(unpack(_0xB96B, 1, _0x72E2)) end, _0xF904)
if not _0x48FB then
_0x9FEB("frame:".. _0x9851, _0xAB96)
_0x8F59("Ошибка в окне (".. _0x9851 .."). Откройте Настройки и нажмите «Сообщить об ошибке»","err")
if on_fail then pcall(on_fail) end
end
end
end
local function _0x939D(_0xCE87)
local _0xA75A = io.open(_0xCE87,"rb")
if not _0xA75A then return nil end
local _0xCD49 = _0xA75A:read("*a")
_0xA75A:close()
return _0xCD49
end
local function _0x081E(_0xCE87, content)
local _0xA75A = io.open(_0xCE87,"wb")
if not _0xA75A then return false end
local _0x48FB = _0xA75A:write(content)
_0xA75A:close()
return _0x48FB ~= nil and _0x48FB ~= false
end
local function _0xBC9B(str)
if type(str) ~="string"or str ==""then return false end
local _0x48FB, _0xD02A = pcall(decodeJson, str)
return _0x48FB and type(_0xD02A) =="table"endlocal function _0x5BFC(_0xCE87, content)
if type(content) ~="string"or content ==""then return false end
local _0x3CD9 = _0xCE87 ..".tmp"if not _0x081E(_0x3CD9, content) then os.remove(_0x3CD9); return false end
if _0x939D(_0x3CD9) ~= content then os.remove(_0x3CD9); return false end
local _0xB3DE = _0x939D(_0xCE87)
if _0xB3DE and _0xBC9B(_0xB3DE) then _0x081E(_0xCE87 ..".bak", _0xB3DE) end
os.remove(_0xCE87)
if not os.rename(_0x3CD9, _0xCE87) then
local _0x48FB = _0x081E(_0xCE87, content)
os.remove(_0x3CD9)
return _0x48FB
end
return true
endlocal function _0x73C3(_0xCE87)
local _0xCD49 = _0x939D(_0xCE87)
if _0xBC9B(_0xCD49) then return decodeJson(_0xCD49) end
local _0x385E = _0x939D(_0xCE87 ..".bak")
if _0xBC9B(_0x385E) then
if _0xCD49 and _0xCD49 ~=""then
_0x8F59("Файл данных был повреждён - восстановили из резервной копии","warn")
_0x081E(_0xCE87 ..".broken", _0xCD49)
end
_0x081E(_0xCE87, _0x385E)
return decodeJson(_0x385E)
end
if _0xCD49 and _0xCD49 ~=""then
_0x081E(_0xCE87 ..".broken", _0xCD49)
_0x8F59("Файл данных повреждён и копии нет - начинаем с чистого листа","err")
end
return nil
endlocal _0x5E6F = {
on = false,
HASH = 888940931,
LIQ = { ["Ликвид"] = true, ["Средне"] = true, ["Неликвид"] = true },
_0xCE87 = getWorkingDirectory() .."\\config\\arizona_prices_admin.json",
}
function _0x5E6F.hash(_0xBE59)
local _0x6984 ="arzp|".. tostring(_0xBE59):lower()
local _0x097D = 5381
for _0x7AB2 = 1, #_0x6984 do _0x097D = (_0x097D * 33 + _0x6984:byte(_0x7AB2)) % 4294967296 end
return _0x097D
end
function _0x5E6F.valid_liq(_0x3C2B)
if type(_0x3C2B) =="string"and _0x5E6F.LIQ[_0x3C2B] then return _0x3C2B end
return nil
end
function _0x5E6F.enable(_0xBE59)
if _0x5E6F.hash(_0xBE59) ~= _0x5E6F.HASH then return false end
_0x5E6F.on = true
local _0x24EF = getWorkingDirectory() .."\\config"if not doesDirectoryExist(_0x24EF) then createDirectory(_0x24EF) end
_0x081E(_0x5E6F.path, encodeJson({ hash = _0x5E6F.HASH }))
return true
end
function _0x5E6F.disable()
_0x5E6F.on = false
os.remove(_0x5E6F.path)
end
do
local _0xD02A = _0x73C3(_0x5E6F.path)
if type(_0xD02A) =="table"and tonumber(_0xD02A.hash) == _0x5E6F.HASH then _0x5E6F.on = true end
end
local function _0xF4C6()
local _0x4135 = _0x73C3(_0x328B)
if _0x4135 then
local _0x8AC6 = {}
for _0x11D3, _0x3C2B in ipairs(_0x4135) do
if type(_0x3C2B) =="table"then
_0x8AC6[#_0x8AC6 + 1] = { _0x2A2B = tostring(_0x3C2B.item or""), _0x49E1 = tonumber(_0x3C2B.buy) or 0, _0x8AAB = tonumber(_0x3C2B.sell) or 0, _0xF92D = _0x5E6F.valid_liq(_0x3C2B.liq) }
end
end
_0xC12B = _0x8AC6
elseif not doesFileExist(_0x328B) then
_0xC12B = {}
end
end
local function _0x4A95()
local _0x24EF = getWorkingDirectory() .."\\config"if not doesDirectoryExist(_0x24EF) then
createDirectory(_0x24EF)
end
local _0x48FB, _0x1775 = pcall(encodeJson, _0xC12B)
if _0x48FB and type(_0x1775) =="string"and _0x1775 ~=""then
if not _0x5BFC(_0x328B, _0x1775) then
_0x8F59("Не удалось сохранить список предметов","err")
end
end
end
local function _0x7B79(amount)
local _0x408D = tonumber(amount)
if not _0x408D then return tostring(amount) end
local _0x91A7 = _0x408D < 0 and"-"or""_0x408D = math.abs(_0x408D)
local _0x6984 = (_0x408D == math.floor(_0x408D)) and string.format("%.0f", _0x408D) or tostring(_0x408D)
local _0x943B, _0x0050 = _0x6984:match("^(%d+)(.*)$")
if not _0x943B then return _0x91A7 .. _0x6984 end
_0x943B = _0x943B:reverse():gsub("(%d%d%d)","%1."):reverse()
if _0x943B:sub(1, 1) =="."then _0x943B = _0x943B:sub(2) end
return _0x91A7 .. _0x943B .. _0x0050
end
local function _0x4D89(str)
local _0x5F34, _0x1769 = pcall(function() return _0x8A46:decode(tostring(str or"")) end)
str = _0x5F34 and _0x1769 or tostring(str or"")
return (str:gsub(".", function(char)
local _0x9B9E = char:byte()
if _0x9B9E >= 192 and _0x9B9E <= 223 then
return string.char(_0x9B9E + 32)
elseif _0x9B9E == 168 then
return string.char(184)
end
return char:lower()
end))
end
local function _0xAE5A()
_0x2D04[0] = false
_0xD452.CloseCurrentPopup()
end
local function _0x4DC9()
_0xD7A8 = false
_0x0BED = nil
_0xD452.StrCopy(_0x0AD7,"")
_0xD452.StrCopy(_0x227D,"")
_0xD452.StrCopy(_0x86B7,"")
_0x2D04[0] = true
_0x9AF0 = true
end
local function _0xB174(_0xB14C)
local _0x2A2B = _0xC12B[_0xB14C]
if not _0x2A2B then return end
_0xD7A8 = true
_0x0BED = _0xB14C
_0xD452.StrCopy(_0x0AD7, _0x2A2B.item or"")
_0xD452.StrCopy(_0x227D, tostring(_0x2A2B.buy or 0))
_0xD452.StrCopy(_0x86B7, tostring(_0x2A2B.sell or 0))
_0x2D04[0] = true
_0x9AF0 = true
endlocal _0x8800 = {
accent = {0.98, 0.55, 0.12}, opacity = 1.0, overlay_scale = 1.0, open_key = 0, _0x37FA = true, toast_corner = 3,
halloween = true,border_mode = 1, border_speed = 1.0, shadow = true, _0x4A5B ="seguisb",
win_w = 835, win_h = 500, bg_fx = true, splash = true,
}local _0xB6FD = {
_0x85AF = 0,_0x6E23 = 1,base = 1,tab_t = -10,table_t = -10,was_open = false,
splashed = false,TAB_ORDER = { 1, 2, 3, 4, 8, 6, 5, 7 },}local _0x2763 = {
{ _0x2890 ="seguisb", _0x9851 ="Segoe UI Semibold", file ="seguisb.ttf"},
{ _0x2890 ="segoeui", _0x9851 ="Segoe UI", file ="segoeui.ttf"},
{ _0x2890 ="bahnschrift", _0x9851 ="Bahnschrift", file ="bahnschrift.ttf"},
{ _0x2890 ="corbel", _0x9851 ="Corbel", file ="corbel.ttf"},
{ _0x2890 ="candara", _0x9851 ="Candara", file ="candara.ttf"},
{ _0x2890 ="calibri", _0x9851 ="Calibri", file ="calibri.ttf"},
{ _0x2890 ="verdana", _0x9851 ="Verdana", file ="verdana.ttf"},
{ _0x2890 ="tahoma", _0x9851 ="Tahoma", file ="tahoma.ttf"},
}
local _0x776F = { { _0x2890 ="default", _0x9851 ="Системный (Trebuchet)"} }
pcall(function()
local _0x24EF = getFolderPath(0x14)
for _0x11D3, _0xA75A in ipairs(_0x2763) do
local _0xCE87 = _0x24EF .."\\".. _0xA75A.file
if doesFileExist(_0xCE87) then
_0x776F[#_0x776F + 1] = { _0x2890 = _0xA75A.key, _0x9851 = _0xA75A.name, _0xCE87 = _0xCE87 }
end
end
end)
local function _0x997A(_0xB7FE, lo, hi)
return math.max(lo, math.min(hi, _0xB7FE))
end
local function _0x6FB3(mult, _0x85AF)
local _0xF1FB = _0x8800.accent
local _0x6E23 = mult or 1.0
return _0xD452.ImVec4(math.min(1, _0xF1FB[1] * _0x6E23), math.min(1, _0xF1FB[2] * _0x6E23), math.min(1, _0xF1FB[3] * _0x6E23), _0x85AF or 1.0)
endlocal function _0xEB5D(_0x0458, _0xCE3A, _0x385E, _0xF1FB)
return _0xD452.ColorConvertFloat4ToU32(_0xD452.ImVec4(_0x0458, _0xCE3A, _0x385E, _0xF1FB * _0xB6FD.m))
end
local function _0x5502(_0x097D, _0x6984, _0x3C2B)
_0x097D = _0x097D % 1
local _0x7AB2 = math.floor(_0x097D * 6)
local _0xA75A = _0x097D * 6 - _0x7AB2
local _0x0A19, _0x70B0, _0xDDCC = _0x3C2B * (1 - _0x6984), _0x3C2B * (1 - _0xA75A * _0x6984), _0x3C2B * (1 - (1 - _0xA75A) * _0x6984)
_0x7AB2 = _0x7AB2 % 6
if _0x7AB2 == 0 then return _0x3C2B, _0xDDCC, _0x0A19
elseif _0x7AB2 == 1 then return _0x70B0, _0x3C2B, _0x0A19
elseif _0x7AB2 == 2 then return _0x0A19, _0x3C2B, _0xDDCC
elseif _0x7AB2 == 3 then return _0x0A19, _0x70B0, _0x3C2B
elseif _0x7AB2 == 4 then return _0xDDCC, _0x0A19, _0x3C2B
end
return _0x3C2B, _0x0A19, _0x70B0
end
local function _0xDDA1(_0x0458, _0xCE3A, _0x385E)
local _0xC859, _0x6471 = math.max(_0x0458, _0xCE3A, _0x385E), math.min(_0x0458, _0xCE3A, _0x385E)
local _0xD02A = _0xC859 - _0x6471
local _0x097D = 0
if _0xD02A > 0 then
if _0xC859 == _0x0458 then _0x097D = ((_0xCE3A - _0x385E) / _0xD02A) % 6
elseif _0xC859 == _0xCE3A then _0x097D = (_0x385E - _0x0458) / _0xD02A + 2
else _0x097D = (_0x0458 - _0xCE3A) / _0xD02A + 4 end
_0x097D = _0x097D / 6
end
return _0x097D, (_0xC859 == 0) and 0 or _0xD02A / _0xC859, _0xC859
endlocal function _0x935C(_0x433A, _0xF1FB)
local _0x4EDA = _0x8800.accent
if _0x8800.halloween then
return _0xD452.ImVec4(math.min(1, _0x433A + 0.022), math.min(1, _0x433A + 0.002), math.min(1, _0x433A + 0.058), _0xF1FB or 1.0)
end
return _0xD452.ImVec4(math.min(1, _0x433A + _0x4EDA[1] * 0.04), math.min(1, _0x433A + _0x4EDA[2] * 0.04), math.min(1, _0x433A + _0x4EDA[3] * 0.06), _0xF1FB or 1.0)
endlocal function _0x5416(_0x433A, _0x562D, _0xF1FB)
local _0x4EDA = _0x8800.accent
local _0xD02A = _0x935C(_0x433A)
return _0xD452.ImVec4(_0xD02A.x + (_0x4EDA[1] - _0xD02A.x) * _0x562D, _0xD02A.y + (_0x4EDA[2] - _0xD02A.y) * _0x562D, _0xD02A.z + (_0x4EDA[3] - _0xD02A.z) * _0x562D, _0xF1FB or 1.0)
endlocal function _0x3D39(fallback)
if _0xD452.GetForegroundDrawList then
local _0x48FB, _0x613C = pcall(_0xD452.GetForegroundDrawList)
if _0x48FB and _0x613C ~= nil then return _0x613C end
end
return fallback()
end
local function _0x3370(_0xC8C0, _0x632C, _0x111C, _0x7E78, _0x0458)
local _0x7A50, _0x66AC = {}, {}
local function _0x675D(_0xB7FE, _0xE31B) _0x7A50[#_0x7A50 + 1] = _0xB7FE; _0x66AC[#_0x66AC + 1] = _0xE31B end
local function _0x9D1B(ax, ay, _0x376D, _0x8D20)
local _0x5D5E = math.sqrt((_0x376D - ax) ^ 2 + (_0x8D20 - ay) ^ 2)
local _0x72E2 = math.max(1, math.floor(_0x5D5E / 14))
for _0x7AB2 = 0, _0x72E2 - 1 do
local _0xDDCC = _0x7AB2 / _0x72E2
_0x675D(ax + (_0x376D - ax) * _0xDDCC, ay + (_0x8D20 - ay) * _0xDDCC)
end
end
local function _0x24EC(_0xB2EB, _0x2D7B, a0)
for _0x7AB2 = 0, 5 do
local _0xF1FB = a0 + (math.pi / 2) * (_0x7AB2 / 5)
_0x675D(_0xB2EB + math.cos(_0xF1FB) * _0x0458, _0x2D7B + math.sin(_0xF1FB) * _0x0458)
end
end
_0x9D1B(_0xC8C0 + _0x0458, _0x632C, _0x111C - _0x0458, _0x632C)
_0x24EC(_0x111C - _0x0458, _0x632C + _0x0458, -math.pi / 2)
_0x9D1B(_0x111C, _0x632C + _0x0458, _0x111C, _0x7E78 - _0x0458)
_0x24EC(_0x111C - _0x0458, _0x7E78 - _0x0458, 0)
_0x9D1B(_0x111C - _0x0458, _0x7E78, _0xC8C0 + _0x0458, _0x7E78)
_0x24EC(_0xC8C0 + _0x0458, _0x7E78 - _0x0458, math.pi / 2)
_0x9D1B(_0xC8C0, _0x7E78 - _0x0458, _0xC8C0, _0x632C + _0x0458)
_0x24EC(_0xC8C0 + _0x0458, _0x632C + _0x0458, math.pi)
return _0x7A50, _0x66AC
endlocal function _0xA19C(_0xC8C0, _0x632C, _0x111C, _0x7E78)
local _0x7A50, _0x66AC = _0x3370(_0xC8C0 + 1, _0x632C + 1, _0x111C - 1, _0x7E78 - 1, 12)
local _0x72E2 = #_0x7A50
local _0x9B89 = {}
for _0x7AB2 = 1, _0x72E2 do _0x9B89[_0x7AB2] = _0xD452.ImVec2(_0x7A50[_0x7AB2], _0x66AC[_0x7AB2]) end
local _0x613C = _0x3D39(_0xD452.GetWindowDrawList)
local _0x4EDA = _0x8800.accent
local _0x4AC1 = _0x8800.border_mode
local _0xDDCC = os.clock() * _0x8800.border_speed
local _0x489E, _0xF2FA, _0x8E11 = 1, 1, 1
if _0x4AC1 == 1 then
local _0x097D, _0xEA94 = _0xDDA1(_0x4EDA[1], _0x4EDA[2], _0x4EDA[3])
_0x489E, _0xF2FA, _0x8E11 = _0x5502(_0x097D + 0.08, math.max(0.35, _0xEA94 * 0.75), 1.0)
end
for _0x7AB2 = 1, _0x72E2 do
local _0x8FDB = _0x7AB2 % _0x72E2 + 1
local _0xA75A = (_0x7AB2 - 1) / _0x72E2
local _0x0458, _0xCE3A, _0x385E
if _0x4AC1 == 1 then
local _0x11F5 = 0.5 + 0.5 * math.sin((_0xA75A * 2 - _0xDDCC * 0.6) * math.pi * 2)
local _0x496A, _0xD25A, _0x65D0 = _0x4EDA[1] * 0.55, _0x4EDA[2] * 0.55, _0x4EDA[3] * 0.55
_0x0458, _0xCE3A, _0x385E = _0x496A + (_0x489E - _0x496A) * _0x11F5, _0xD25A + (_0xF2FA - _0xD25A) * _0x11F5, _0x65D0 + (_0x8E11 - _0x65D0) * _0x11F5
elseif _0x4AC1 == 2 then
_0x0458, _0xCE3A, _0x385E = _0x5502(_0xA75A - _0xDDCC * 0.3, 0.75, 1.0)
else
_0x0458, _0xCE3A, _0x385E = _0x4EDA[1], _0x4EDA[2], _0x4EDA[3]
end
_0x613C:AddLine(_0x9B89[_0x7AB2], _0x9B89[_0x8FDB], _0xEB5D(_0x0458, _0xCE3A, _0x385E, 0.16), 5.0)
_0x613C:AddLine(_0x9B89[_0x7AB2], _0x9B89[_0x8FDB], _0xEB5D(_0x0458, _0xCE3A, _0x385E, 0.95), 2.0)
end
endlocal _0x1812 = false
local function _0x99D9(_0xC8C0, _0x632C, _0x111C, _0x7E78)
if _0x1812 then return end
local _0x48FB, _0xAB96 = pcall(function()
if _0x8800.shadow then
local _0x0EFE = _0xD452.GetBackgroundDrawList()
for _0x7AB2 = 1, 6 do
local _0x93C7 = _0x7AB2 * 3
_0x0EFE:AddRectFilled(_0xD452.ImVec2(_0xC8C0 - _0x93C7, _0x632C - _0x93C7 + 5), _0xD452.ImVec2(_0x111C + _0x93C7, _0x7E78 + _0x93C7 + 5), _0xEB5D(0, 0, 0, 0.045), 12 + _0x93C7)
end
end
if _0x8800.border_mode ~= 0 then _0xA19C(_0xC8C0, _0x632C, _0x111C, _0x7E78) end
end)
if not _0x48FB then
_0x1812 = true
_0x9FEB("window_fx", _0xAB96)
end
if _0x8800.halloween then _0xB6FD.hw_safe(_0xB6FD.hw_front, _0xC8C0, _0x632C, _0x111C, _0x7E78) end
end
function apply_theme()
local _0x2B67 = _0xD452.GetStyle()
local _0x55A1 = _0x2B67.Colors
local _0x4EDA = _0x8800.accent
local function _0xA0C9(_0x9851, _0x3C2B) pcall(function() _0x2B67[_0x9851] = _0x3C2B end) end
local function _0x3261(_0x9851, _0x3C2B)
local _0x0FEB = _0xD452.Col[_0x9851]
if _0x0FEB ~= nil then _0x55A1[_0x0FEB] = _0x3C2B end
end_0xA0C9("WindowPadding", _0xD452.ImVec2(5, 5))
_0xA0C9("FramePadding", _0xD452.ImVec2(5, 5))
_0xA0C9("ItemSpacing", _0xD452.ImVec2(5, 5))
_0xA0C9("ItemInnerSpacing", _0xD452.ImVec2(2, 2))
_0xA0C9("WindowTitleAlign", _0xD452.ImVec2(0.5, 0.5))
_0xA0C9("ScrollbarSize", 10)
_0xA0C9("WindowBorderSize", 0)
_0xA0C9("PopupBorderSize", 0)
_0xA0C9("ChildBorderSize", 1)
_0xA0C9("FrameBorderSize", 0)_0xA0C9("WindowRounding", 12)
_0xA0C9("ChildRounding", 8)
_0xA0C9("FrameRounding", 6)
_0xA0C9("PopupRounding", 10)
_0xA0C9("ScrollbarRounding", 8)
_0xA0C9("GrabRounding", 6)
_0xA0C9("TabRounding", 6)_0x3261("Text", _0xD452.ImVec4(0.93, 0.94, 0.97, 1.00))
_0x3261("TextDisabled", _0xD452.ImVec4(0.52, 0.55, 0.62, 1.00))
_0x3261("WindowBg", _0x935C(0.058, _0x8800.opacity))
_0x3261("ChildBg", _0x935C(0.080, 0.50))
_0x3261("PopupBg", _0x935C(0.085, 0.98))
_0x3261("Border", _0xD452.ImVec4(_0x4EDA[1], _0x4EDA[2], _0x4EDA[3], 0.20))
_0x3261("TitleBg", _0x935C(0.058))
_0x3261("TitleBgActive", _0x935C(0.058))
_0x3261("TitleBgCollapsed", _0x935C(0.058))
_0x3261("FrameBg", _0x935C(0.105))
_0x3261("FrameBgHovered", _0x5416(0.105, 0.14))
_0x3261("FrameBgActive", _0x5416(0.105, 0.22))
_0x3261("Button", _0x935C(0.115))
_0x3261("ButtonHovered", _0x5416(0.115, 0.30))
_0x3261("ButtonActive", _0x5416(0.115, 0.50))
_0x3261("Header", _0x5416(0.115, 0.22))
_0x3261("HeaderHovered", _0x5416(0.115, 0.34))
_0x3261("HeaderActive", _0x5416(0.115, 0.48))
_0x3261("ScrollbarBg", _0xD452.ImVec4(0, 0, 0, 0))
_0x3261("ScrollbarGrab", _0x5416(0.12, 0.30))
_0x3261("ScrollbarGrabHovered", _0x5416(0.12, 0.50))
_0x3261("ScrollbarGrabActive", _0x5416(0.12, 0.75))
_0x3261("Separator", _0xD452.ImVec4(1, 1, 1, 0.07))
_0x3261("ModalWindowDimBg", _0xD452.ImVec4(0, 0, 0, 0.65))
_0x3261("CheckMark", _0x6FB3(1.15))
_0x3261("SliderGrab", _0x6FB3(1.0))
_0x3261("SliderGrabActive", _0x6FB3(1.25))
_0x3261("PlotHistogram", _0x6FB3(1.0))
_0x3261("TextSelectedBg", _0xD452.ImVec4(_0x4EDA[1], _0x4EDA[2], _0x4EDA[3], 0.35))
_0x3261("ResizeGrip", _0xD452.ImVec4(_0x4EDA[1], _0x4EDA[2], _0x4EDA[3], 0.45))
_0x3261("ResizeGripHovered", _0xD452.ImVec4(_0x4EDA[1], _0x4EDA[2], _0x4EDA[3], 0.75))
_0x3261("ResizeGripActive", _0xD452.ImVec4(_0x4EDA[1], _0x4EDA[2], _0x4EDA[3], 1.00))
endlocal _0x67A4 = 200
local _0x83B4 = { _0x11F5 = 835, _0x097D = 500, tab_h = 42, block_y = 340, force = false }local _0xE6E2 = 1local _0xBE15 =""local _0xF5D8 =""local _0x9124 = nil
local _0xA73F = false
local _0x8D43 = { hover = {}, press = {}, ripple = {}, hist = {}, hist_open = false, pop_t = -10, grown = false }
local function _0xDC1B(_0x9851, fallback)
return _0x7FE0[_0x9851] or fallback
endlocal _0x37FA = {}
local _0x7F0C = {
info = { _0x2197 ="CIRCLE_INFO", _0x9C52 = nil },
_0x48FB = { _0x2197 ="CIRCLE_CHECK", _0x9C52 = {0.30, 0.78, 0.45} },
warn = { _0x2197 ="TRIANGLE_EXCLAMATION", _0x9C52 = {1.00, 0.75, 0.20} },
_0xAB96 = { _0x2197 ="CIRCLE_XMARK", _0x9C52 = {0.92, 0.32, 0.32} },
}
local _0xC05F = false
local function _0xD527(_0x4AD0, _0x2849, _0x6326)
if _0x8800.toasts == false or _0xC05F then return false end
_0x37FA[#_0x37FA + 1] = { _0x4AD0 = tostring(_0x4AD0), _0x2849 = _0x7F0C[_0x2849] and _0x2849 or"info", t0 = os.clock(), _0x6326 = _0x6326 or 3.5 }
if #_0x37FA > 5 then table.remove(_0x37FA, 1) end
return true
endlocal function _0x75BC(_0x4AD0, _0x2849, _0x6326)
if not _0xD527(_0x4AD0, _0x2849, _0x6326) then
if sampAddChatMessage then
pcall(sampAddChatMessage, _0x8A46:decode("{33AAFF}[Arizona Prices] {FFFFFF}".. tostring(_0x4AD0)), -1)
end
end
endlocal function _0x3C0B()
local _0x723A = os.clock()
for _0x7AB2 = #_0x37FA, 1, -1 do
if _0x723A - _0x37FA[_0x7AB2].t0 > _0x37FA[_0x7AB2].dur then table.remove(_0x37FA, _0x7AB2) end
end
if #_0x37FA == 0 then return end
local _0x613C = _0x3D39(_0xD452.GetBackgroundDrawList)
local _0xC51A, _0xB2A7 = getScreenResolution()
local _0xED7C = _0x8800.toast_corner or 3local _0x72C6 = (_0xED7C == 1 or _0xED7C == 3)
local _0xE74D = (_0xED7C == 2 or _0xED7C == 3)
local _0x6AC1, _0x0086, _0xB32C = 46, 8, 20
for _0x7AB2, _0xDDCC in ipairs(_0x37FA) do
local _0x2849 = _0x7F0C[_0xDDCC.kind] or _0x7F0C.info
local _0xBA57 = _0xD452.CalcTextSize(_0xDDCC.text)
local _0x11F5 = math.min(760, _0xBA57.x + 84)
local _0x2E42 = _0x723A - _0xDDCC.t0
local _0x062E = math.min(1, _0x2E42 / 0.25)
local _0xB59A = 1 - (1 - _0x062E) ^ 3
local _0x85AF = math.max(0, math.min(1, (_0xDDCC.dur - _0x2E42) / 0.4))
local _0x44CA = (1 - _0xB59A) * (_0x11F5 + _0xB32C + 10)
local _0x46E0 = #_0x37FA - _0x7AB2
local _0xB7FE = _0x72C6 and (_0xC51A - _0xB32C - _0x11F5 + _0x44CA) or (_0xB32C - _0x44CA)
local _0xE31B = _0xE74D and (_0xB2A7 - _0xB32C - 80 - _0x6AC1 - _0x46E0 * (_0x6AC1 + _0x0086)) or (_0xB32C + _0x46E0 * (_0x6AC1 + _0x0086))
local _0xCD49 = _0x2849.color or _0x8800.accent
local _0xD79A = _0xE31B + (_0x6AC1 - _0xBA57.y) / 2
local _0x9D7D, _0x7B4B = _0xD452.ImVec2(_0xB7FE, _0xE31B), _0xD452.ImVec2(_0xB7FE + _0x11F5, _0xE31B + _0x6AC1)
local _0xB2EB, _0x2D7B = _0xB7FE + 28, _0xE31B + _0x6AC1 / 2
_0x613C:AddRectFilled(_0x9D7D, _0x7B4B, _0xEB5D(0.07, 0.075, 0.09, 0.96 * _0x85AF), 10)
pcall(function()
_0x613C:AddRect(_0x9D7D, _0x7B4B, _0xEB5D(_0xCD49[1], _0xCD49[2], _0xCD49[3], 0.60 * _0x85AF), 10, 0, 1.5)
_0x613C:AddCircleFilled(_0xD452.ImVec2(_0xB2EB, _0x2D7B), 17, _0xEB5D(_0xCD49[1], _0xCD49[2], _0xCD49[3], 0.20 * _0x85AF), 28)
end)local _0x2B30 = _0xEB5D(_0xCD49[1], _0xCD49[2], _0xCD49[3], _0x85AF)
local function _0x0B24(ax, ay, _0x376D, _0x8D20)
_0x613C:AddLine(_0xD452.ImVec2(_0xB2EB + ax, _0x2D7B + ay), _0xD452.ImVec2(_0xB2EB + _0x376D, _0x2D7B + _0x8D20), _0x2B30, 3.0)
end
if _0xDDCC.kind =="ok"then
_0x0B24(-7, 0.5, -2.5, 5.5)
_0x0B24(-2.5, 5.5, 7.5, -5.5)
_0x613C:AddCircleFilled(_0xD452.ImVec2(_0xB2EB - 2.5, _0x2D7B + 5.5), 1.5, _0x2B30, 12)
elseif _0xDDCC.kind =="err"then
_0x0B24(-6, -6, 6, 6)
_0x0B24(-6, 6, 6, -6)
elseif _0xDDCC.kind =="warn"then
_0x0B24(0, -8, 0, 2)
_0x613C:AddCircleFilled(_0xD452.ImVec2(_0xB2EB, _0x2D7B + 7), 2.0, _0x2B30, 12)
else
_0x613C:AddCircleFilled(_0xD452.ImVec2(_0xB2EB, _0x2D7B - 7), 2.0, _0x2B30, 12)
_0x0B24(0, -2.5, 0, 8)
end
_0x613C:AddText(_0xD452.ImVec2(_0xB7FE + 56, _0xD79A), _0xEB5D(1, 1, 1, _0x85AF), _0xDDCC.text)
end
end
local _0x830D
_0x830D = _0xD452.OnFrame(
function()
_0x830D.HideCursor = true
return #_0x37FA > 0
end,
function()
local _0x48FB, _0xAB96 = xpcall(_0x3C0B, _0xF904)
if not _0x48FB then
_0xC05F = true
_0x37FA = {}
_0x9FEB("toast", _0xAB96)
_0x8F59("Карточки уведомлений отключены из-за ошибки, сообщения будут в чате","warn")
end
end
)local function _0x4F90(_0x6984)
if _0x6984 ==""then return"0"end
local _0x0458 = _0x6984:reverse():gsub("(%d%d%d)","%1."):reverse()
if _0x0458:sub(1, 1) =="."then _0x0458 = _0x0458:sub(2) end
return _0x0458
end
local function _0xD7EE(expr)
local _0xE5A1 = expr:gsub("[%d%.]+", function(_0x408D)
local _0x665C, _0xD8D8 = _0x408D:match("^(%d*)%.(%d*)$")
if _0x665C then
return _0x4F90(_0x665C) ..",".. _0xD8D8
end
return _0x4F90(_0x408D)
end)
_0xE5A1 = _0xE5A1:gsub("%*"," x "):gsub("/"," / "):gsub("%+"," + "):gsub("%-"," - ")
_0xE5A1 = _0xE5A1:gsub("^%s+",""):gsub("%s+$","")
_0xE5A1 = _0xE5A1:gsub("^%- ","-")
return _0xE5A1
end
local function _0xB665(_0xB7FE)
if _0xB7FE >= 0 then
_0xB7FE = math.floor(_0xB7FE * 100 + 0.5) / 100
else
_0xB7FE = -math.floor(-_0xB7FE * 100 + 0.5) / 100
end
local _0x6984 = string.format("%.2f", _0xB7FE)
_0x6984 = _0x6984:gsub("0+$",""):gsub("%.$","")
if _0x6984 =="-0"or _0x6984 ==""then _0x6984 ="0"end
return _0x6984
end
local function _0xF2F2(expr)
local _0xD949 = {}
local _0x7AB2, _0x72E2 = 1, #expr
while _0x7AB2 <= _0x72E2 do
local _0xCD49 = expr:sub(_0x7AB2, _0x7AB2)
if _0xCD49:match("[%d%.]") then
local _0x408D = expr:match("^[%d%.]+", _0x7AB2)
_0x7AB2 = _0x7AB2 + #_0x408D
local _0x3C2B = tonumber(_0x408D)
if not _0x3C2B then return nil,"Ошибка"end
local _0x06BE = false
if expr:sub(_0x7AB2, _0x7AB2) =="%"then
_0x06BE = true
_0x7AB2 = _0x7AB2 + 1
end
_0xD949[#_0xD949 + 1] = {_0x408D = _0x3C2B, _0x06BE = _0x06BE}
elseif _0xCD49:match("[%+%-%*/]") then
_0xD949[#_0xD949 + 1] = {op = _0xCD49}
_0x7AB2 = _0x7AB2 + 1
else
return nil,"Ошибка"end
end
if _0xD949[#_0xD949] and _0xD949[#_0xD949].op then _0xD949[#_0xD949] = nil end
local _0x0FEB, _0x91A7 = 1, 1
if _0xD949[1] and _0xD949[1].op =="-"then
_0x91A7 = -1
_0x0FEB = 2
end
if _0x0FEB > #_0xD949 then return nil,"Ошибка"end
local _0x368A, _0xDF12, _0xE608 = 0,"+", true
while _0x0FEB <= #_0xD949 do
local _0x383B = _0xD949[_0x0FEB]
if not _0x383B.num then return nil,"Ошибка"end
local _0x43F7 = _0x383B.pct and (_0x383B.num / 100) or _0x383B.num
local _0x51AA = true
_0x0FEB = _0x0FEB + 1
while _0xD949[_0x0FEB] and (_0xD949[_0x0FEB].op =="*"or _0xD949[_0x0FEB].op =="/") do
local _0x5F7D = _0xD949[_0x0FEB + 1]
if not _0x5F7D or not _0x5F7D.num then return nil,"Ошибка"end
local _0x2A3E = _0x5F7D.pct and (_0x5F7D.num / 100) or _0x5F7D.num
if _0xD949[_0x0FEB].op =="*"then
_0x43F7 = _0x43F7 * _0x2A3E
else
if _0x2A3E == 0 then return nil,"Деление на ноль"end
_0x43F7 = _0x43F7 / _0x2A3E
end
_0x51AA = false
_0x0FEB = _0x0FEB + 2
end
if _0xE608 then
_0x43F7 = _0x43F7 * _0x91A7
_0x368A = _0x43F7
_0xE608 = false
else
if _0x51AA and _0x383B.pct then _0x43F7 = _0x368A * _0x383B.num / 100 end
if _0xDF12 =="+"then _0x368A = _0x368A + _0x43F7 else _0x368A = _0x368A - _0x43F7 end
end
local _0x4B81 = _0xD949[_0x0FEB]
if _0x4B81 then
if _0x4B81.op ~="+"and _0x4B81.op ~="-"then return nil,"Ошибка"end
_0xDF12 = _0x4B81.op
_0x0FEB = _0x0FEB + 1
end
end
return _0x368A
end
local function _0xCCDD()
if _0xA73F then
_0xBE15 =""_0xF5D8 =""_0xA73F = false
end
end
local function _0x5F08(_0xD02A)
_0x9124 = nil
_0xCCDD()
if #_0xBE15 > 45 then return end
if _0xBE15:sub(-1) =="%"then return end
local _0x17D6 = _0xBE15:match("[%d%.]*$")
if _0xD02A =="000"then
if _0x17D6 ==""or _0x17D6 =="0"then return end
_0xBE15 = _0xBE15 .."000"return
end
if _0x17D6 =="0"then
if _0xD02A =="0"then return end
_0xBE15 = _0xBE15:sub(1, -2) .. _0xD02A
else
_0xBE15 = _0xBE15 .. _0xD02A
end
end
local function _0x7A0E()
_0x9124 = nil
_0xCCDD()
if #_0xBE15 > 45 then return end
if _0xBE15:sub(-1) =="%"then return end
local _0x17D6 = _0xBE15:match("[%d%.]*$")
if _0x17D6:find(".", 1, true) then return end
if _0x17D6 ==""then
_0xBE15 = _0xBE15 .."0."else
_0xBE15 = _0xBE15 .."."end
end
local function _0x7B0B(op)
_0x9124 = nil
if _0xA73F then
_0xA73F = false
_0xF5D8 =""end
if _0xBE15 ==""then
if op =="-"then _0xBE15 ="-"end
return
end
local _0xEF12 = _0xBE15:sub(-1)
if _0xEF12:match("[%+%-%*/]") then
if #_0xBE15 == 1 then return end
_0xBE15 = _0xBE15:sub(1, -2) .. op
else
if _0xEF12 =="."then _0xBE15 = _0xBE15:sub(1, -2) end
_0xBE15 = _0xBE15 .. op
end
end
local function _0x0944()
_0x9124 = nil
if _0xA73F then
_0xA73F = false
_0xF5D8 =""end
if _0xBE15:sub(-1):match("%d") then
_0xBE15 = _0xBE15 .."%"end
end
local function _0x3693()
_0x9124 = nil
if _0xA73F then
_0xA73F = false
_0xF5D8 =""end
_0xBE15 = _0xBE15:sub(1, -2)
end
local function _0x2055()
_0xBE15 =""_0xF5D8 =""_0x9124 = nil
_0xA73F = false
end
local function _0x658D()
if _0xBE15 ==""or _0xA73F then return end
local _0x820A, _0xAB96 = _0xF2F2(_0xBE15)
if not _0x820A then
_0x9124 = _0xAB96 or"Ошибка"return
end
local _0x3E7F = _0xD7EE(_0xBE15)
_0xF5D8 = _0x3E7F .." ="_0xBE15 = _0xB665(_0x820A)
_0xA73F = true
_0x8D43.pop_t = _0xD452.GetTime()
_0x8D43.hist[#_0x8D43.hist + 1] = { expr = _0x3E7F, _0x820A = _0xD7EE(_0xBE15), raw = _0xBE15 }
if #_0x8D43.hist > 15 then table.remove(_0x8D43.hist, 1) end
endlocal function _0x2276(_0x5025)
local _0x613C = _0xD452.GetWindowDrawList()
local _0x86DD = _0xD452.ColorConvertFloat4ToU32(_0x935C(0.088, _0xB6FD.m))
_0x613C:AddRectFilled(_0x5025, _0xD452.ImVec2(_0x5025.x + _0x67A4 - 1, _0x5025.y + _0x83B4.h), _0x86DD, 12)
_0x613C:AddRectFilled(_0xD452.ImVec2(_0x5025.x + 14, _0x5025.y), _0xD452.ImVec2(_0x5025.x + _0x67A4 - 1, _0x5025.y + _0x83B4.h), _0x86DD)
_0x613C:AddLine(_0xD452.ImVec2(_0x5025.x + _0x67A4 - 1, _0x5025.y + 8), _0xD452.ImVec2(_0x5025.x + _0x67A4 - 1, _0x5025.y + _0x83B4.h - 8), _0xD452.GetColorU32(_0xD452.Col.Separator), 1.0)
if _0x8800.halloween then _0xB6FD.hw_safe(_0xB6FD.hw_web, _0x613C, _0x5025.x + 7, _0x5025.y + _0x83B4.h - 7, 84, 1, -1, 0.18) end
endfunction _0xB6FD.liq_color(_0x433A)
if _0x433A =="Ликвид"then return _0xD452.ImVec4(0.45, 0.95, 0.55, 1) end
if _0x433A =="Средне"then return _0xD452.ImVec4(1.00, 0.85, 0.40, 1) end
if _0x433A =="Неликвид"then return _0xD452.ImVec4(1.00, 0.45, 0.45, 1) end
return _0xD452.ImVec4(0.50, 0.52, 0.58, 1)
end
function _0xB6FD.liq_next(_0x433A)
if _0x433A == nil then return"Ликвид"end
if _0x433A =="Ликвид"then return"Средне"end
if _0x433A =="Средне"then return"Неликвид"end
return nil
end
function _0xB6FD.set_alpha(_0xF1FB)
_0xF1FB = _0x997A(_0xF1FB, 0, 1)
_0xB6FD.m = _0xF1FB
pcall(function() _0xD452.GetStyle().Alpha = _0xF1FB end)
endfunction _0xB6FD.go_tab(_0xF753)
if _0xF753 ~= _0xE6E2 then
_0xE6E2 = _0xF753
local _0x723A = _0xD452.GetTime()
_0xB6FD.tab_t, _0xB6FD.table_t = _0x723A, _0x723A
end
endfunction _0xB6FD.tick()
local _0xAC20 = _0xD452.GetIO().DeltaTime
local _0x2AAF = _0xC2A7[0]
local _0x4B83 = _0x2AAF and 1 or 0
_0xB6FD.alpha = _0xB6FD.alpha + (_0x4B83 - _0xB6FD.alpha) * math.min(1, _0xAC20 * (_0x2AAF and 11 or 15))
if not _0x2AAF and _0xB6FD.alpha < 0.03 then _0xB6FD.alpha = 0 end
if _0x2AAF and _0xB6FD.alpha > 0.99 then _0xB6FD.alpha = 1 end
if _0x2AAF and not _0xB6FD.was_open then
local _0x723A = _0xD452.GetTime()
_0xB6FD.table_t, _0xB6FD.tab_t = _0x723A, _0x723A
if _0x8800.splash and not _0xB6FD.splashed then
_0xB6FD.splash_t = _0x723A
_0xB6FD.splashed = true
end
end
_0xB6FD.was_open = _0x2AAF
if _0xB6FD.pending_tab then
_0xB6FD.go_tab(_0xB6FD.pending_tab)
_0xB6FD.pending_tab = nil
end
endfunction _0xB6FD.draw_bar(_0x5025)
if not _0xB6FD.bar_ty then return end
local _0xAC20 = _0xD452.GetIO().DeltaTime
if not _0xB6FD.bar_cur then _0xB6FD.bar_cur = _0xB6FD.bar_ty end
_0xB6FD.bar_cur = _0xB6FD.bar_cur + (_0xB6FD.bar_ty - _0xB6FD.bar_cur) * math.min(1, _0xAC20 * 16)
local _0x4EDA = _0x8800.accent
local _0xB7FE, _0xE31B = _0x5025.x + _0xB6FD.bar_x, _0x5025.y + _0xB6FD.bar_cur
_0xD452.GetWindowDrawList():AddRectFilled(_0xD452.ImVec2(_0xB7FE, _0xE31B - 13), _0xD452.ImVec2(_0xB7FE + 3, _0xE31B + 13),
_0xEB5D(math.min(1, _0x4EDA[1] * 1.15), math.min(1, _0x4EDA[2] * 1.15), math.min(1, _0x4EDA[3] * 1.15), 1), 2)
endfunction _0xB6FD.draw_bg()
local _0x0A19, _0x6984 = _0xD452.GetWindowPos(), _0xD452.GetWindowSize()
local _0x613C = _0xD452.GetWindowDrawList()
local _0xDDCC, _0x4EDA = _0xD452.GetTime(), _0x8800.accent
for _0x7AB2 = 1, 3 do
local _0xB2EB = _0x0A19.x + _0x6984.x * (0.5 + 0.38 * math.sin(_0xDDCC * 0.11 * _0x7AB2 + _0x7AB2 * 2.1))
local _0x2D7B = _0x0A19.y + _0x6984.y * (0.5 + 0.38 * math.cos(_0xDDCC * 0.09 * _0x7AB2 + _0x7AB2 * 1.3))
for _0x0458 = 4, 1, -1 do
_0x613C:AddCircleFilled(_0xD452.ImVec2(_0xB2EB, _0x2D7B), _0x0458 * 55, _0xEB5D(_0x4EDA[1], _0x4EDA[2], _0x4EDA[3], 0.014), 32)
end
end
for _0x7AB2 = 1, 26 do
local _0x895A = 10 + (_0x7AB2 * 7) % 17
local _0xB7FE = _0x0A19.x + ((_0x7AB2 * 137) % 100) / 100 * _0x6984.x + math.sin(_0xDDCC * 0.5 + _0x7AB2) * 12
local _0xE31B = _0x0A19.y + _0x6984.y - ((_0xDDCC * _0x895A + _0x7AB2 * 61) % (_0x6984.y + 20)) + 10
local _0xB24B = 0.5 + 0.5 * math.sin(_0xDDCC * 1.5 + _0x7AB2 * 1.7)
_0x613C:AddCircleFilled(_0xD452.ImVec2(_0xB7FE, _0xE31B), 1.2 + (_0x7AB2 % 3) * 0.7,
_0xEB5D(_0x4EDA[1] * 0.5 + 0.5, _0x4EDA[2] * 0.5 + 0.5, _0x4EDA[3] * 0.5 + 0.5, 0.05 + 0.14 * _0xB24B), 8)
end
endfunction _0xB6FD.hw_safe(fn, ...)
if _0xB6FD.hw_broken then return end
local _0x48FB, _0xAB96 = pcall(fn, ...)
if not _0x48FB then
_0xB6FD.hw_broken = true
pcall(_0x9FEB,"halloween", _0xAB96)
end
endfunction _0xB6FD.hw_tri(_0x613C, _0x86DD, ax, ay, _0x376D, _0x8D20, _0xB2EB, _0x2D7B)
local _0x660C = _0xD452.ImVec2
if (_0x376D - ax) * (_0x2D7B - ay) - (_0x8D20 - ay) * (_0xB2EB - ax) < 0 then
_0x376D, _0x8D20, _0xB2EB, _0x2D7B = _0xB2EB, _0x2D7B, _0x376D, _0x8D20
end
_0x613C:AddTriangleFilled(_0x660C(ax, ay), _0x660C(_0x376D, _0x8D20), _0x660C(_0xB2EB, _0x2D7B), _0x86DD)
endfunction _0xB6FD.hw_pumpkin(_0x613C, _0xB2EB, _0x2D7B, _0x0458, _0x562D, hat)
local _0x660C = _0xD452.ImVec2
local _0xDDCC = _0xD452.GetTime()
local _0xECC7 = 0.85 + 0.15 * math.sin(_0xDDCC * 7 + _0xB2EB * 0.05) * math.sin(_0xDDCC * 3.1 + _0x2D7B * 0.1)for _0x7AB2 = 3, 1, -1 do
_0x613C:AddCircleFilled(_0x660C(_0xB2EB, _0x2D7B), _0x0458 * (1.0 + _0x7AB2 * 0.45), _0xEB5D(1.0, 0.45, 0.05, 0.04 * _0x562D * _0xECC7), 28)
end
local _0x126D = _0x2D7B - _0x0458 * 0.78
local _0x18EB = _0xEB5D(0.80, 0.33, 0.03, _0x562D)
local _0xC235 = _0xEB5D(1.00, 0.52, 0.08, _0x562D)
_0x613C:AddCircleFilled(_0x660C(_0xB2EB - _0x0458 * 0.45, _0x2D7B + _0x0458 * 0.03), _0x0458 * 0.62, _0x18EB, 22)
_0x613C:AddCircleFilled(_0x660C(_0xB2EB + _0x0458 * 0.45, _0x2D7B + _0x0458 * 0.03), _0x0458 * 0.62, _0x18EB, 22)
_0x613C:AddCircleFilled(_0x660C(_0xB2EB, _0x2D7B), _0x0458 * 0.78, _0xC235, 28)
_0x613C:AddCircleFilled(_0x660C(_0xB2EB - _0x0458 * 0.38, _0x2D7B - _0x0458 * 0.38), _0x0458 * 0.13, _0xEB5D(1.0, 0.82, 0.55, 0.35 * _0x562D), 12)local _0xB61E = _0xEB5D(1.0, 0.88, 0.30, _0x562D * _0xECC7)
_0xB6FD.hw_tri(_0x613C, _0xB61E, _0xB2EB - _0x0458 * 0.55, _0x2D7B - _0x0458 * 0.02, _0xB2EB - _0x0458 * 0.18, _0x2D7B - _0x0458 * 0.02, _0xB2EB - _0x0458 * 0.36, _0x2D7B - _0x0458 * 0.34)
_0xB6FD.hw_tri(_0x613C, _0xB61E, _0xB2EB + _0x0458 * 0.18, _0x2D7B - _0x0458 * 0.02, _0xB2EB + _0x0458 * 0.55, _0x2D7B - _0x0458 * 0.02, _0xB2EB + _0x0458 * 0.36, _0x2D7B - _0x0458 * 0.34)
_0xB6FD.hw_tri(_0x613C, _0xB61E, _0xB2EB - _0x0458 * 0.08, _0x2D7B + _0x0458 * 0.14, _0xB2EB + _0x0458 * 0.08, _0x2D7B + _0x0458 * 0.14, _0xB2EB, _0x2D7B + _0x0458 * 0.03)
_0x613C:AddRectFilled(_0x660C(_0xB2EB - _0x0458 * 0.58, _0x2D7B + _0x0458 * 0.26), _0x660C(_0xB2EB + _0x0458 * 0.58, _0x2D7B + _0x0458 * 0.48), _0xB61E, _0x0458 * 0.06)
for _0x8FDB = -2, 2, 2 do
local _0xB7FE = _0xB2EB + _0x8FDB * _0x0458 * 0.22
_0xB6FD.hw_tri(_0x613C, _0xC235, _0xB7FE - _0x0458 * 0.09, _0x2D7B + _0x0458 * 0.26, _0xB7FE + _0x0458 * 0.09, _0x2D7B + _0x0458 * 0.26, _0xB7FE, _0x2D7B + _0x0458 * 0.37)
end
for _0x8FDB = -1, 1, 2 do
local _0xB7FE = _0xB2EB + _0x8FDB * _0x0458 * 0.22
_0xB6FD.hw_tri(_0x613C, _0xC235, _0xB7FE - _0x0458 * 0.09, _0x2D7B + _0x0458 * 0.48, _0xB7FE + _0x0458 * 0.09, _0x2D7B + _0x0458 * 0.48, _0xB7FE, _0x2D7B + _0x0458 * 0.37)
end
if hat then
local _0x68E3 = _0xEB5D(0.22, 0.10, 0.38, _0x562D)
local _0x660B = _0x126D + _0x0458 * 0.12
_0xB6FD.hw_tri(_0x613C, _0x68E3, _0xB2EB - _0x0458 * 0.55, _0x660B - _0x0458 * 0.05, _0xB2EB + _0x0458 * 0.55, _0x660B - _0x0458 * 0.05, _0xB2EB + _0x0458 * 0.22, _0x660B - _0x0458 * 1.35)
_0x613C:AddRectFilled(_0x660C(_0xB2EB - _0x0458 * 0.44, _0x660B - _0x0458 * 0.30), _0x660C(_0xB2EB + _0x0458 * 0.44, _0x660B - _0x0458 * 0.10), _0xC235, 2)
_0x613C:AddRectFilled(_0x660C(_0xB2EB - _0x0458 * 0.95, _0x660B - _0x0458 * 0.10), _0x660C(_0xB2EB + _0x0458 * 0.95, _0x660B + _0x0458 * 0.08), _0x68E3, _0x0458 * 0.08)
else
local _0xCE71 = _0xEB5D(0.30, 0.45, 0.10, _0x562D)
_0xB6FD.hw_tri(_0x613C, _0xCE71, _0xB2EB - _0x0458 * 0.10, _0x126D + _0x0458 * 0.08, _0xB2EB + _0x0458 * 0.14, _0x126D + _0x0458 * 0.08, _0xB2EB + _0x0458 * 0.20, _0x126D - _0x0458 * 0.28)
_0xB6FD.hw_tri(_0x613C, _0xCE71, _0xB2EB - _0x0458 * 0.10, _0x126D + _0x0458 * 0.08, _0xB2EB + _0x0458 * 0.20, _0x126D - _0x0458 * 0.28, _0xB2EB - _0x0458 * 0.02, _0x126D - _0x0458 * 0.30)
end
endfunction _0xB6FD.hw_bat(_0x613C, _0xB7FE, _0xE31B, _0x6984, _0xECC7, _0x562D)
local _0x660C = _0xD452.ImVec2
local _0xCD49 = _0xEB5D(0.36, 0.23, 0.52, 0.90 * _0x562D)
local _0xA75A = _0xECC7 * _0x6984 * 0.55
for _0xD02A = -1, 1, 2 do
_0xB6FD.hw_tri(_0x613C, _0xCD49, _0xB7FE, _0xE31B - _0x6984 * 0.15, _0xB7FE + _0xD02A * _0x6984 * 1.35, _0xE31B - _0x6984 * 0.45 + _0xA75A, _0xB7FE + _0xD02A * _0x6984 * 0.85, _0xE31B + _0x6984 * 0.05)
_0xB6FD.hw_tri(_0x613C, _0xCD49, _0xB7FE, _0xE31B - _0x6984 * 0.15, _0xB7FE + _0xD02A * _0x6984 * 0.85, _0xE31B + _0x6984 * 0.05, _0xB7FE + _0xD02A * _0x6984 * 0.45, _0xE31B + _0x6984 * 0.32)
_0xB6FD.hw_tri(_0x613C, _0xCD49, _0xB7FE, _0xE31B - _0x6984 * 0.05, _0xB7FE + _0xD02A * _0x6984 * 0.45, _0xE31B + _0x6984 * 0.32, _0xB7FE, _0xE31B + _0x6984 * 0.22)
end
_0x613C:AddCircleFilled(_0x660C(_0xB7FE, _0xE31B + _0x6984 * 0.02), _0x6984 * 0.30, _0xCD49, 12)
_0xB6FD.hw_tri(_0x613C, _0xCD49, _0xB7FE - _0x6984 * 0.26, _0xE31B - _0x6984 * 0.12, _0xB7FE - _0x6984 * 0.06, _0xE31B - _0x6984 * 0.22, _0xB7FE - _0x6984 * 0.24, _0xE31B - _0x6984 * 0.52)
_0xB6FD.hw_tri(_0x613C, _0xCD49, _0xB7FE + _0x6984 * 0.06, _0xE31B - _0x6984 * 0.22, _0xB7FE + _0x6984 * 0.26, _0xE31B - _0x6984 * 0.12, _0xB7FE + _0x6984 * 0.24, _0xE31B - _0x6984 * 0.52)
local _0x3CA7 = _0xEB5D(1.0, 0.40, 0.10, _0x562D)
_0x613C:AddCircleFilled(_0x660C(_0xB7FE - _0x6984 * 0.11, _0xE31B), _0x6984 * 0.05, _0x3CA7, 6)
_0x613C:AddCircleFilled(_0x660C(_0xB7FE + _0x6984 * 0.11, _0xE31B), _0x6984 * 0.05, _0x3CA7, 6)
endfunction _0xB6FD.hw_web(_0x613C, _0xB2EB, _0x2D7B, size, dx, dy, _0xF1FB)
local _0x660C = _0xD452.ImVec2
local _0x86DD = _0xEB5D(0.85, 0.85, 1.0, _0xF1FB)
local _0x72E2 = 5
for _0x562D = 0, _0x72E2 do
local _0xDFD1 = (_0x562D / _0x72E2) * (math.pi / 2)
_0x613C:AddLine(_0x660C(_0xB2EB, _0x2D7B), _0x660C(_0xB2EB + dx * math.cos(_0xDFD1) * size, _0x2D7B + dy * math.sin(_0xDFD1) * size), _0x86DD, 1.0)
end
for _0x8FDB = 1, 4 do
local _0x11C2 = size * _0x8FDB / 4
for _0x562D = 0, _0x72E2 - 1 do
local _0x31D8, _0x5868, _0x4424 = (_0x562D / _0x72E2) * (math.pi / 2), ((_0x562D + 1) / _0x72E2) * (math.pi / 2), ((_0x562D + 0.5) / _0x72E2) * (math.pi / 2)
local _0x111C, _0x7E78 = _0xB2EB + dx * math.cos(_0x31D8) * _0x11C2, _0x2D7B + dy * math.sin(_0x31D8) * _0x11C2
local _0xBBE1, _0x16EE = _0xB2EB + dx * math.cos(_0x5868) * _0x11C2, _0x2D7B + dy * math.sin(_0x5868) * _0x11C2
local _0x29C2, _0x4A38 = _0xB2EB + dx * math.cos(_0x4424) * _0x11C2 * 0.86, _0x2D7B + dy * math.sin(_0x4424) * _0x11C2 * 0.86
_0x613C:AddLine(_0x660C(_0x111C, _0x7E78), _0x660C(_0x29C2, _0x4A38), _0x86DD, 1.0)
_0x613C:AddLine(_0x660C(_0x29C2, _0x4A38), _0x660C(_0xBBE1, _0x16EE), _0x86DD, 1.0)
end
end
endfunction _0xB6FD.hw_bg()
local _0x0A19, _0x6984 = _0xD452.GetWindowPos(), _0xD452.GetWindowSize()
local _0x613C = _0xD452.GetWindowDrawList()
local _0x660C = _0xD452.ImVec2
local _0xDDCC = _0xD452.GetTime()
local _0xC859, _0xAF45 = _0x0A19.x + _0x6984.x - 78, _0x0A19.y + 70
for _0x7AB2 = 5, 1, -1 do
_0x613C:AddCircleFilled(_0x660C(_0xC859, _0xAF45), 40 + _0x7AB2 * 14, _0xEB5D(1.0, 0.82, 0.45, 0.012), 40)
end
_0x613C:AddCircleFilled(_0x660C(_0xC859, _0xAF45), 40, _0xEB5D(1.0, 0.90, 0.62, 0.15), 40)
_0x613C:AddCircleFilled(_0x660C(_0xC859 - 12, _0xAF45 - 8), 9, _0xEB5D(0.9, 0.7, 0.4, 0.08), 16)
_0x613C:AddCircleFilled(_0x660C(_0xC859 + 14, _0xAF45 + 10), 6, _0xEB5D(0.9, 0.7, 0.4, 0.08), 16)
_0x613C:AddCircleFilled(_0x660C(_0xC859 + 6, _0xAF45 - 20), 5, _0xEB5D(0.9, 0.7, 0.4, 0.08), 16)
local _0x4B8C, _0x74EE = _0x0A19.x + _0x6984.x * (0.30 + 0.20 * math.sin(_0xDDCC * 0.13)), _0x0A19.y + _0x6984.y * (0.65 + 0.15 * math.cos(_0xDDCC * 0.10))
for _0x0458 = 4, 1, -1 do
_0x613C:AddCircleFilled(_0x660C(_0x4B8C, _0x74EE), _0x0458 * 60, _0xEB5D(0.55, 0.20, 0.85, 0.016), 36)
end
for _0x7AB2 = 1, 4 do
local _0xE31E = _0x6984.x + 140
local _0x376D = _0x0A19.x - 70 + ((_0xDDCC * (22 + _0x7AB2 * 6) + _0x7AB2 * 173) % _0xE31E)
local _0x8D20 = _0x0A19.y + _0x6984.y * (0.12 + 0.17 * _0x7AB2) + math.sin(_0xDDCC * 0.8 + _0x7AB2 * 2.0) * 16
_0xB6FD.hw_bat(_0x613C, _0x376D, _0x8D20, 10 + (_0x7AB2 % 3) * 4, math.sin(_0xDDCC * 9 + _0x7AB2 * 1.7), 0.85)
end
_0xB6FD.hw_web(_0x613C, _0x0A19.x + _0x6984.x - 6, _0x0A19.y + 6, 80, -1, 1, 0.20)
_0xB6FD.hw_web(_0x613C, _0x0A19.x + _0x6984.x - 6, _0x0A19.y + _0x6984.y - 6, 100, -1, -1, 0.17)
endfunction _0xB6FD.hw_front(_0xC8C0, _0x632C, _0x111C, _0x7E78)
local _0x613C = _0x3D39(_0xD452.GetWindowDrawList)
_0xB6FD.hw_pumpkin(_0x613C, _0x111C - 135, _0x632C + 3 - 22 * 0.78, 22, 1, true)
_0xB6FD.hw_pumpkin(_0x613C, _0x111C - 66, _0x632C + 3 - 16 * 0.78, 16, 1, false)
_0xB6FD.hw_pumpkin(_0x613C, _0xC8C0 + 80, _0x632C + 3 - 19 * 0.78, 19, 1, false)
end
local function _0x1C05(_0x003F, _0xF753, tip)
local _0xBC52 = (_0xE6E2 == _0xF753)
local _0x4EDA = _0x8800.accent
if _0xBC52 then
_0xD452.PushStyleColor(_0xD452.Col.Button, _0x5416(0.115, 0.28))
end
_0xD452.SetWindowFontScale(1.15)
local _0xF243 = _0xD452.Button(_0x003F .."##tab".. _0xF753, _0xD452.ImVec2(_0x67A4 - 10, _0x83B4.tab_h))
local _0x1452 = _0xD452.IsItemHovered()
_0xD452.SetWindowFontScale(1.0)
if _0xF243 then _0xB6FD.go_tab(_0xF753) end
if _0x1452 and tip then _0xD452.SetTooltip(tip) end
if _0xBC52 then
_0xD452.PopStyleColor(1)
local _0xB223, _0x1A3D = _0xD452.GetItemRectMin(), _0xD452.GetItemRectMax()
local _0x7FF8 = _0xD452.GetWindowPos()
_0xB6FD.bar_ty = (_0xB223.y + _0x1A3D.y) / 2 - _0x7FF8.y
_0xB6FD.bar_x = _0xB223.x + 2 - _0x7FF8.xlocal _0x613C = _0xD452.GetWindowDrawList()
for _0x7AB2 = 3, 1, -1 do
_0x613C:AddRect(_0xD452.ImVec2(_0xB223.x - _0x7AB2 * 1.5, _0xB223.y - _0x7AB2 * 1.5), _0xD452.ImVec2(_0x1A3D.x + _0x7AB2 * 1.5, _0x1A3D.y + _0x7AB2 * 1.5),
_0xEB5D(_0x4EDA[1], _0x4EDA[2], _0x4EDA[3], 0.07 * (4 - _0x7AB2)), 8 + _0x7AB2, 15, 1.2)
end
end
endfunction _0x8D43.step(tbl, _0x2890, _0x4B83, speed, _0xAC20)
local _0x3C2B = tbl[_0x2890] or 0
_0x3C2B = _0x3C2B + (_0x4B83 - _0x3C2B) * math.min(1, _0xAC20 * speed)
tbl[_0x2890] = _0x3C2B
return _0x3C2B
endfunction _0x8D43.button(_0xF753, _0x003F, _0x2849, _0x11F5, _0x097D, action)
local _0x613C = _0xD452.GetWindowDrawList()
local _0x0A19 = _0xD452.GetCursorScreenPos()
local _0x723A = _0xD452.GetTime()
local _0xAC20 = _0xD452.GetIO().DeltaTime
local _0xF243 = _0xD452.InvisibleButton("##cb".. _0xF753, _0xD452.ImVec2(_0x11F5, _0x097D))
local _0x1452, _0x4236 = _0xD452.IsItemHovered(), _0xD452.IsItemActive()
if _0xF243 then
local _0x6E23 = _0xD452.GetMousePos()
_0x8D43.ripple[_0xF753] = { _0xDDCC = _0x723A, _0xB7FE = _0x6E23.x, _0xE31B = _0x6E23.y }
action()
end
local _0x4D01 = _0x8D43.step(_0x8D43.hover, _0xF753, _0x1452 and 1 or 0, 14, _0xAC20)
local _0x062E = _0x8D43.step(_0x8D43.press, _0xF753, _0x4236 and 1 or 0, 24, _0xAC20)local _0x03C8, _0x612A, _0x46B1
if _0x2849 == 2 then
local _0xF1FB = _0x8800.accent
_0x03C8, _0x612A, _0x46B1 = _0xF1FB[1], _0xF1FB[2], _0xF1FB[3]
elseif _0x2849 == 3 then
_0x03C8, _0x612A, _0x46B1 = 0.55, 0.18, 0.20
elseif _0x2849 == 1 then
_0x03C8, _0x612A, _0x46B1 = 0.20, 0.20, 0.23
else
_0x03C8, _0x612A, _0x46B1 = 0.145, 0.145, 0.165
end
local _0x802F = 0.07 * _0x4D01 - 0.05 * _0x062E
local _0x0458, _0xCE3A, _0x385E = _0x997A(_0x03C8 + _0x802F, 0, 1), _0x997A(_0x612A + _0x802F, 0, 1), _0x997A(_0x46B1 + _0x802F, 0, 1)
local _0xC8E8 = 2.5 * _0x062Elocal _0x111C, _0x7E78 = _0x0A19.x + _0xC8E8, _0x0A19.y + _0xC8E8
local _0xBBE1, _0x16EE = _0x0A19.x + _0x11F5 - _0xC8E8, _0x0A19.y + _0x097D - _0xC8E8
local _0xB40F = 11local _0x4EDA = _0x8800.accent
local _0x9E2C = _0x4D01
if _0x2849 == 2 then _0x9E2C = math.max(_0x4D01, 0.35 + 0.25 * math.sin(_0x723A * 3.0)) end
if _0x9E2C > 0.02 then
for _0x7AB2 = 3, 1, -1 do
_0x613C:AddRect(_0xD452.ImVec2(_0x111C - _0x7AB2 * 1.6, _0x7E78 - _0x7AB2 * 1.6), _0xD452.ImVec2(_0xBBE1 + _0x7AB2 * 1.6, _0x16EE + _0x7AB2 * 1.6),
_0xEB5D(_0x4EDA[1], _0x4EDA[2], _0x4EDA[3], 0.10 * _0x9E2C * (4 - _0x7AB2) / 3), _0xB40F + _0x7AB2, 15, 1.4)
end
end
_0x613C:AddRectFilled(_0xD452.ImVec2(_0x111C, _0x7E78), _0xD452.ImVec2(_0xBBE1, _0x16EE), _0xEB5D(_0x0458, _0xCE3A, _0x385E, 1), _0xB40F)_0x613C:AddRectFilled(_0xD452.ImVec2(_0x111C + 2, _0x7E78 + 2), _0xD452.ImVec2(_0xBBE1 - 2, _0x7E78 + (_0x16EE - _0x7E78) * 0.45), _0xEB5D(1, 1, 1, 0.045 + 0.03 * _0x4D01), _0xB40F - 2)local _0x368E = 0.10 + 0.75 * _0x4D01
_0x613C:AddRect(_0xD452.ImVec2(_0x111C, _0x7E78), _0xD452.ImVec2(_0xBBE1, _0x16EE), _0xEB5D(_0x4EDA[1], _0x4EDA[2], _0x4EDA[3], _0x368E), _0xB40F, 15, 1.2)local _0xCD6D = _0x8D43.ripple[_0xF753]
if _0xCD6D then
local _0x562D = (_0x723A - _0xCD6D.t) / 0.5
if _0x562D >= 1 then
_0x8D43.ripple[_0xF753] = nil
else
_0x613C:PushClipRect(_0xD452.ImVec2(_0x111C, _0x7E78), _0xD452.ImVec2(_0xBBE1, _0x16EE), true)
_0x613C:AddCircleFilled(_0xD452.ImVec2(_0xCD6D.x, _0xCD6D.y), _0x562D * math.max(_0x11F5, _0x097D) * 1.1, _0xEB5D(1, 1, 1, 0.30 * (1 - _0x562D)), 32)
_0x613C:PopClipRect()
end
endlocal _0xBA57 = _0xD452.CalcTextSize(_0x003F)
_0x613C:AddText(_0xD452.ImVec2(_0x0A19.x + (_0x11F5 - _0xBA57.x) / 2, _0x0A19.y + (_0x097D - _0xBA57.y) / 2 + _0x062E), _0xEB5D(1, 1, 1, 0.95), _0x003F)
endfunction _0x8D43.display(_0x11F5, _0x097D)
local _0x723A = _0xD452.GetTime()
local _0x4EDA = _0x8800.accent
local _0x0A19 = _0xD452.GetCursorScreenPos()
local _0x613C = _0xD452.GetWindowDrawList()
local _0x2B6F = _0x997A(1 - (_0x723A - _0x8D43.pop_t) / 0.6, 0, 1)
_0x613C:AddRectFilled(_0x0A19, _0xD452.ImVec2(_0x0A19.x + _0x11F5, _0x0A19.y + _0x097D), _0xEB5D(0.075, 0.075, 0.09, 1), 14)
_0x613C:AddRectFilled(_0x0A19, _0xD452.ImVec2(_0x0A19.x + _0x11F5, _0x0A19.y + _0x097D), _0xEB5D(_0x4EDA[1], _0x4EDA[2], _0x4EDA[3], 0.05 + 0.10 * _0x2B6F), 14)
_0x613C:AddRect(_0x0A19, _0xD452.ImVec2(_0x0A19.x + _0x11F5, _0x0A19.y + _0x097D), _0xEB5D(_0x4EDA[1], _0x4EDA[2], _0x4EDA[3], 0.35 + 0.55 * _0x2B6F), 14, 15, 1.5)
local _0xC3FF = _0x997A(_0x097D / 100 * 1.9, 1.7, 3.2)
local _0x3CF5, _0x9C52
if _0x9124 then
_0x3CF5, _0x9C52 = _0x9124, { 1.0, 0.38, 0.38 }
else
_0x3CF5, _0x9C52 = (_0xBE15 =="") and"0"or _0xD7EE(_0xBE15), { 1, 1, 1 }
end_0xD452.SetWindowFontScale(1.1)
local _0x3617 = _0xF5D8 ~=""and _0xF5D8 or""local _0x857C = _0xD452.CalcTextSize(_0x3617)
_0x613C:AddText(_0xD452.ImVec2(_0x0A19.x + _0x11F5 - 16 - _0x857C.x, _0x0A19.y + 10), _0xEB5D(0.62, 0.62, 0.68, 1), _0x3617)local _0x43A4 = 1 + 0.16 * _0x2B6F * _0x2B6F
local _0xFA37 = _0xC3FF
_0xD452.SetWindowFontScale(_0xFA37)
while _0xFA37 > 0.9 and _0xD452.CalcTextSize(_0x3CF5).x > (_0x11F5 - 36) / _0x43A4 do
_0xFA37 = _0xFA37 - 0.1
_0xD452.SetWindowFontScale(_0xFA37)
end
local _0xBA57 = _0xD452.CalcTextSize(_0x3CF5)
local _0x3273 = _0xFA37 * _0x43A4
_0xD452.SetWindowFontScale(_0x3273)
_0xBA57 = _0xD452.CalcTextSize(_0x3CF5)
local _0x2E93 = _0x0A19.x + _0x11F5 - 18 - _0xBA57.x
local _0xD79A = _0x0A19.y + _0x097D - 12 - _0xBA57.y + 4 * (1 - _0x2B6F)
_0x613C:AddText(_0xD452.ImVec2(_0x2E93 + 1.5, _0xD79A + 1.5), _0xEB5D(0, 0, 0, 0.5), _0x3CF5)
_0x613C:AddText(_0xD452.ImVec2(_0x2E93, _0xD79A), _0xEB5D(_0x9C52[1], _0x9C52[2], _0x9C52[3], 1), _0x3CF5)
_0xD452.SetWindowFontScale(1.0)
_0xD452.Dummy(_0xD452.ImVec2(_0x11F5, _0x097D))
endfunction _0x8D43.history(_0x11F5, _0x097D)
local _0x4EDA = _0x8800.accent
if _0xD452.BeginChild("##calc_hist", _0xD452.ImVec2(_0x11F5, _0x097D), true) then
_0xD452.TextColored(_0x6FB3(1.2), _0xDC1B("CLOCK_ROTATE_LEFT","") .." История")
_0xD452.Separator()
if #_0x8D43.hist == 0 then
_0xD452.TextColored(_0xD452.ImVec4(0.55, 0.55, 0.6, 1),"Пока пусто")
else
for _0x7AB2 = #_0x8D43.hist, 1, -1 do
local _0x93C7 = _0x8D43.hist[_0x7AB2]
_0xD452.PushStyleColor(_0xD452.Col.Button, _0xD452.ImVec4(0, 0, 0, 0))
_0xD452.PushStyleColor(_0xD452.Col.ButtonHovered, _0x6FB3(1.0, 0.25))
_0xD452.PushStyleColor(_0xD452.Col.ButtonActive, _0x6FB3(1.0, 0.4))
if _0xD452.Button(_0x93C7.res .."##h".. _0x7AB2, _0xD452.ImVec2(-1, 34)) then
_0xBE15, _0xF5D8, _0x9124, _0xA73F = _0x93C7.raw,"", nil, false
end
_0xD452.PopStyleColor(3)
_0xD452.TextColored(_0xD452.ImVec4(0.55, 0.55, 0.6, 1), _0x93C7.expr)
_0xD452.Spacing()
end
end
if #_0x8D43.hist > 0 then
if _0xD452.Button("Очистить##hclr", _0xD452.ImVec2(-1, 28)) then _0x8D43.hist = {} end
end
end
_0xD452.EndChild()
end
local function _0xCE5F()
local _0xC51A, _0xB2A7 = getScreenResolution()if not _0x8D43.grown then
_0x8D43.grown = true
if _0x83B4.w < 960 or _0x83B4.h < 640 then
_0x83B4.req = { _0x11F5 = math.min(math.max(_0x83B4.w, 980), _0xC51A - 40), _0x097D = math.min(math.max(_0x83B4.h, 660), _0xB2A7 - 40) }
end
end_0xD452.AlignTextToFramePadding()
_0xD452.SetCursorPosX(9)
_0xD452.Text(_0xDC1B("CALCULATOR","") .." Калькулятор")
_0xD452.SameLine(_0x83B4.w - _0x67A4 - 76)
_0xD452.PushStyleColor(_0xD452.Col.Button, _0xD452.ImVec4(0, 0, 0, 0))
if _0xD452.Button(_0xDC1B("CLOCK_ROTATE_LEFT","H") .."##calc_hist_btn", _0xD452.ImVec2(30, 24)) then
_0x8D43.hist_open = not _0x8D43.hist_open
end
_0xD452.SameLine(_0x83B4.w - _0x67A4 - 29)
if _0xD452.Button(_0x0833.CIRCLE_XMARK .."##close_calc", _0xD452.ImVec2(24, 24)) then
_0xC2A7[0] = false
end
if _0xD452.IsItemHovered() then _0xD452.SetTooltip("Закрыть") end
_0xD452.PopStyleColor(1)
_0xD452.Spacing()
local _0x206E = _0xD452.GetContentRegionAvail()
local _0x7C6B = 9
local _0x503A = _0x8D43.hist_open and 200 or 0
local _0x29EC = _0x206E.x - _0x503A - (_0x503A > 0 and 12 or 0) - 16
local _0x952C = _0x997A(_0x29EC, 300, 720)
local _0x38FF = _0x997A(_0x206E.y * 0.25, 92, 160)
local _0x2116 = _0x997A((_0x206E.y - _0x38FF - 6 * _0x7C6B - 6) / 5, 40, 110)
local _0x0664 = (_0x952C - 3 * _0x7C6B) / 4
local _0xC8C0 = 8 + math.max(0, (_0x29EC - _0x952C) / 2)
local _0x632C = _0xD452.GetCursorPosY()
_0xD452.SetCursorPos(_0xD452.ImVec2(_0xC8C0, _0x632C))
_0x8D43.display(_0x952C, _0x38FF)
local function _0xD02A(_0x72E2) return function() _0x5F08(_0x72E2) end end
local function _0x1F56(_0x72E2) return function() _0x7B0B(_0x72E2) end end
local _0x6840 = {
{ {"C", _0x2055, 3}, {_0xDC1B("DELETE_LEFT","<"), _0x3693, 1}, {_0xDC1B("PERCENT","%"), _0x0944, 1}, {_0xDC1B("DIVIDE","/"), _0x1F56("/"), 1} },
{ {"7", _0xD02A("7"), 0}, {"8", _0xD02A("8"), 0}, {"9", _0xD02A("9"), 0}, {_0xDC1B("XMARK","x"), _0x1F56("*"), 1} },
{ {"4", _0xD02A("4"), 0}, {"5", _0xD02A("5"), 0}, {"6", _0xD02A("6"), 0}, {_0xDC1B("MINUS","-"), _0x1F56("-"), 1} },
{ {"1", _0xD02A("1"), 0}, {"2", _0xD02A("2"), 0}, {"3", _0xD02A("3"), 0}, {_0xDC1B("PLUS","+"), _0x1F56("+"), 1} },
{ {"0", _0xD02A("0"), 0}, {"000", _0xD02A("000"), 0}, {",", _0x7A0E, 0}, {_0xDC1B("EQUALS","="), _0x658D, 2} },
}
_0xD452.SetWindowFontScale(_0x997A(_0x2116 / 54 * 1.25, 1.2, 2.0))
for _0x0458, row in ipairs(_0x6840) do
_0xD452.SetCursorPos(_0xD452.ImVec2(_0xC8C0, _0x632C + _0x38FF + _0x7C6B + (_0x0458 - 1) * (_0x2116 + _0x7C6B)))
for _0xCD49, _0x385E in ipairs(row) do
if _0xCD49 > 1 then _0xD452.SameLine(0, _0x7C6B) end
_0x8D43.button(_0x0458 .."_".. _0xCD49, _0x385E[1], _0x385E[3], _0x0664, _0x2116, _0x385E[2])
end
end
_0xD452.SetWindowFontScale(1.0)
if _0x503A > 0 then
_0xD452.SetCursorPos(_0xD452.ImVec2(_0xC8C0 + _0x952C + 12 + math.max(0, (_0x29EC - _0x952C) / 2) * 0, _0x632C))
_0x8D43.history(_0x503A, _0x38FF + 5 * (_0x2116 + _0x7C6B))
end
endlocal _0x8DB5 = getWorkingDirectory() .."\\config\\arizona_prices_settings.json"local _0xD488 = { ui = _0x8800, favs = {}, notes ="", payday = { enabled = false, _0xB7FE = 20, _0xE31B = 300 }, phrases = {}, clock = { enabled = false, country ="Узбекистан", _0xB7FE = 20, _0xE31B = 340 } }
local function _0x1FA8()
local _0x4135 = _0x73C3(_0x8DB5)
if not _0x4135 then return end
if type(_0x4135.payday) =="table"then
_0xD488.payday.enabled = (_0x4135.payday.enabled == true)
_0xD488.payday.x = tonumber(_0x4135.payday.x) or 20
_0xD488.payday.y = tonumber(_0x4135.payday.y) or 300
end
if type(_0x4135.phrases) =="table"then
local _0xD072 = {}
for _0x11D3, _0x3C2B in ipairs(_0x4135.phrases) do
if type(_0x3C2B) =="string"and _0x3C2B ~=""then _0xD072[#_0xD072 + 1] = _0x3C2B end
end
_0xD488.phrases = _0xD072
end
if type(_0x4135.clock) =="table"then
_0xD488.clock.enabled = (_0x4135.clock.enabled == true)
if type(_0x4135.clock.country) =="string"then _0xD488.clock.country = _0x4135.clock.country end
_0xD488.clock.x = tonumber(_0x4135.clock.x) or 20
_0xD488.clock.y = tonumber(_0x4135.clock.y) or 340
end
if type(_0x4135.favs) =="table"then
local _0xA75A = {}
for _0x562D, _0x3C2B in pairs(_0x4135.favs) do
if type(_0x562D) =="string"and _0x3C2B == true then _0xA75A[_0x562D] = true end
end
_0xD488.favs = _0xA75A
end
if type(_0x4135.notes) =="string"then _0xD488.notes = _0x4135.notes:sub(1, 8000) end
if type(_0x4135.ui) =="table"then
local _0x25A4 = _0x4135.ui
if type(_0x25A4.accent) =="table"and tonumber(_0x25A4.accent[1]) and tonumber(_0x25A4.accent[2]) and tonumber(_0x25A4.accent[3]) then
_0x8800.accent = { _0x997A(tonumber(_0x25A4.accent[1]), 0, 1), _0x997A(tonumber(_0x25A4.accent[2]), 0, 1), _0x997A(tonumber(_0x25A4.accent[3]), 0, 1) }
end
_0x8800.opacity = _0x997A(tonumber(_0x25A4.opacity) or 1.0, 0.3, 1.0)
_0x8800.overlay_scale = _0x997A(tonumber(_0x25A4.overlay_scale) or 1.0, 0.7, 2.0)
_0x8800.open_key = math.max(0, math.floor(tonumber(_0x25A4.open_key) or 0))
_0x8800.toasts = (_0x25A4.toasts ~= false)
_0x8800.toast_corner = _0x997A(math.floor(tonumber(_0x25A4.toast_corner) or 3), 0, 3)
_0x8800.border_mode = _0x997A(math.floor(tonumber(_0x25A4.border_mode) or 1), 0, 3)
_0x8800.border_speed = _0x997A(tonumber(_0x25A4.border_speed) or 1.0, 0.2, 3.0)
_0x8800.shadow = (_0x25A4.shadow ~= false)
_0x8800.bg_fx = (_0x25A4.bg_fx ~= false)
_0x8800.splash = (_0x25A4.splash ~= false)
if _0x25A4.halloween == nil then
_0x8800.halloween = true
_0x8800.accent = { 0.98, 0.55, 0.12 }
else
_0x8800.halloween = (_0x25A4.halloween == true)
end
if type(_0x25A4.font) =="string"then _0x8800.font = _0x25A4.font end
_0x8800.win_w = _0x997A(math.floor(tonumber(_0x25A4.win_w) or 835), 700, 2400)
_0x8800.win_h = _0x997A(math.floor(tonumber(_0x25A4.win_h) or 500), 400, 1400)
end
end
local function _0x167A()
local _0x24EF = getWorkingDirectory() .."\\config"if not doesDirectoryExist(_0x24EF) then
createDirectory(_0x24EF)
end
local _0x48FB, _0x1775 = pcall(encodeJson, _0xD488)
if _0x48FB and type(_0x1775) =="string"and _0x1775 ~=""then
_0x5BFC(_0x8DB5, _0x1775)
end
end
_0x3271("load_settings", _0x1FA8)_0xB6FD.notes = _0xD452.new.char[8192]()
_0xD452.StrCopy(_0xB6FD.notes, _0xD488.notes or"")
function _0xB6FD.toggle_fav(_0x9851)
if _0xD488.favs[_0x9851] then _0xD488.favs[_0x9851] = nil else _0xD488.favs[_0x9851] = true end
_0x167A()
end
local _0x54F3 = _0xD452.new.bool(_0xD488.payday.enabled)
local _0x675B = false
local _0xCF55 = { _0xB7FE = _0xD488.payday.x, _0xE31B = _0xD488.payday.y }
local _0x41D1 = _0xD452.new.char[256]()
local function _0xE273()
local _0x6E23 = tonumber(os.date("%M")) or 0
if _0x6E23 < 30 then return 30 - _0x6E23 end
return 60 - _0x6E23
end
local function _0x03EB()
local _0xD02A = os.date("*t")
local _0x9C2A = 1800 - ((_0xD02A.min % 30) * 60 + _0xD02A.sec)
return"До PayDay: ".. math.floor(_0x9C2A / 60) .." мин ".. string.format("%02d", _0x9C2A % 60) .." сек"end
local function _0xED96(_0x72E2)
local _0x4E2B, _0xFB8B = _0x72E2 % 10, _0x72E2 % 100
if _0xFB8B >= 11 and _0xFB8B <= 14 then return"минут"end
if _0x4E2B == 1 then return"минута"end
if _0x4E2B >= 2 and _0x4E2B <= 4 then return"минуты"end
return"минут"end
local function _0xD74D(_0x2197, _0xB775)
_0xD452.AlignTextToFramePadding()
_0xD452.SetCursorPosX(9)
_0xD452.Text(_0x2197 .." ".. _0xB775)
_0xD452.SameLine(_0x83B4.w - _0x67A4 - 29)
_0xD452.PushStyleColor(_0xD452.Col.Button, _0xD452.ImVec4(0, 0, 0, 0))
if _0xD452.Button(_0x0833.CIRCLE_XMARK .."##close_section", _0xD452.ImVec2(24, 24)) then
_0xC2A7[0] = false
end
if _0xD452.IsItemHovered() then _0xD452.SetTooltip("Закрыть") end
_0xD452.PopStyleColor(1)
_0xD452.Spacing()
end
local function _0x61FA()
_0xD74D(_0xDC1B("CLOCK",""),"Отчет до PayDay")
if _0xD452.BeginChild("##payday_child", _0xD452.ImVec2(-1, _0x83B4.h - 79), true) then
_0xD452.SetWindowFontScale(1.35)
_0xD452.TextWrapped("На экране появится надпись «До PayDay: N мин N сек». PayDay выплачивается каждые 30 минут: в :00 и :30.")
_0xD452.Spacing()
if _0xD452.Checkbox(" Включить", _0x54F3) then
_0xD488.payday.enabled = _0x54F3[0]
_0x167A()
end
_0xD452.Spacing()
_0xD452.Separator()
_0xD452.Spacing()
_0xD452.Text("Положение надписи на экране:")
_0xD452.Spacing()
if not _0x675B then
if _0xD452.Button(_0xDC1B("UP_DOWN_LEFT_RIGHT","") .." Передвинуть надпись", _0xD452.ImVec2(360, 56)) then
_0x675B = true
_0x54F3[0] = true
end
else
_0xD452.TextColored(_0xD452.ImVec4(0.45, 1.00, 0.55, 1.00),"Перетащи надпись мышкой, затем нажми «Сохранить».")
if _0xD452.Button(_0x0833.FLOPPY_DISK .." Сохранить положение", _0xD452.ImVec2(360, 56)) then
_0xD488.payday.x = _0xCF55.x
_0xD488.payday.y = _0xCF55.y
_0xD488.payday.enabled = _0x54F3[0]
_0x167A()
_0x675B = false
_0x75BC("Положение надписи сохранено","ok")
end
end
_0xD452.Spacing()
_0xD452.TextDisabled("Сейчас: ".. _0x03EB())
_0xD452.SetWindowFontScale(1.0)
end
_0xD452.EndChild()
end
local function _0x0342()
_0xD74D(_0xDC1B("COMMENT_DOTS",""),"Фразы для автоотправки")
_0xD452.SetWindowFontScale(1.3)
_0xD452.SetNextItemWidth(_0xD452.GetContentRegionAvail().x - 190)
local _0x56D1 = _0xD452.InputTextWithHint("##phrase_input","Введи фразу или команду (например /time)", _0x41D1, _0x2A38.sizeof(_0x41D1), _0xD452.InputTextFlags.EnterReturnsTrue)
_0xD452.SameLine()
local _0x8592 = _0xD452.Button(_0x0833.CIRCLE_PLUS .." Добавить##add_phrase", _0xD452.ImVec2(180, 0))
if _0x56D1 or _0x8592 then
local _0x4AD0 = _0x2A38.string(_0x41D1)
if _0x4AD0:gsub("%s","") ~=""then
table.insert(_0xD488.phrases, _0x4AD0)
_0x167A()
_0xD452.StrCopy(_0x41D1,"")
end
end
_0xD452.Spacing()
if _0xD452.BeginChild("##phrases_list", _0xD452.ImVec2(-1, -36), true) then
if #_0xD488.phrases == 0 then
_0xD452.TextDisabled("Пока нет фраз. Добавь первую выше.")
end
local _0x6BCE = nil
for _0x7AB2, phrase in ipairs(_0xD488.phrases) do
if _0xD452.Button(_0x0833.PAPER_PLANE .."##send_phrase_".. _0x7AB2, _0xD452.ImVec2(52, 40)) then
local _0x2612 = phrase
_0xEECB(function() sampSendChat(_0x8A46:decode(_0x2612)) end)
end
if _0xD452.IsItemHovered() then _0xD452.SetTooltip("Отправить в чат") end
_0xD452.SameLine()
if _0xD452.Button(_0x0833.TRASH_CAN .."##del_phrase_".. _0x7AB2, _0xD452.ImVec2(52, 40)) then
_0x6BCE = _0x7AB2
end
if _0xD452.IsItemHovered() then _0xD452.SetTooltip("Удалить фразу") end
_0xD452.SameLine()
_0xD452.AlignTextToFramePadding()
_0xD452.TextUnformatted(phrase)
end
if _0x6BCE then
table.remove(_0xD488.phrases, _0x6BCE)
_0x167A()
end
end
_0xD452.EndChild()
_0xD452.SetWindowFontScale(1.0)
end
local _0xA3BD = {
{ _0x2197 ="PAPER_PLANE", _0xB775 ="Telegram-канал", _0xC781 ="https://t.me/arizona_prices", _0x9C52 = {0.16, 0.62, 0.86} },
{ _0x2197 ="COMMENTS", _0xB775 ="Discord-канал", _0xC781 ="https://discord.gg/z4UmCnRwd", _0x9C52 = {0.35, 0.40, 0.95} },
{ _0x2197 ="MUSIC", _0xB775 ="TikTok-канал", _0xC781 ="https://www.tiktok.com/@cosmychesky_jetpack", _0x9C52 = {0.86, 0.15, 0.40} },
{ _0x2197 ="USER", _0xB775 ="Discord разработчика", copy ="sawnoff_karabin07", _0x9C52 = {0.35, 0.40, 0.95} },
{ _0x2197 ="PAPER_PLANE", _0xB775 ="ЛС разработчика в Telegram", _0xC781 ="https://t.me/xi_vivide", _0x9C52 = {0.16, 0.62, 0.86} },
{ _0x2197 ="PAPER_PLANE", _0xB775 ="ЛС разработчика в Telegram 2", _0xC781 ="https://t.me/obrezik", _0x9C52 = {0.16, 0.62, 0.86} },
}
local function _0x5602()
_0xD74D(_0xDC1B("CIRCLE_INFO",""),"О скрипте")
if _0xD452.BeginChild("##about_child", _0xD452.ImVec2(-1, _0x83B4.h - 79), true) then
_0xD452.SetWindowFontScale(1.25)
_0xD452.TextColored(_0xD452.ImVec4(0.30, 0.65, 1.00, 1.00),"Arizona Prices V2.0")
_0xD452.TextWrapped("Спасибо, что пользуешься скриптом! Заходи в наши соцсети: там актуальные цены, новости и обновления. Нашёл ошибку или есть идея - пиши разработчику в личные сообщения.")
_0xD452.Spacing()
_0xD452.Separator()
_0xD452.Spacing()
for _0x7AB2, _0x433A in ipairs(_0xA3BD) do
local _0xCD49 = _0x433A.color
_0xD452.PushStyleColor(_0xD452.Col.Button, _0xD452.ImVec4(_0xCD49[1] * 0.55, _0xCD49[2] * 0.55, _0xCD49[3] * 0.55, 1.00))
_0xD452.PushStyleColor(_0xD452.Col.ButtonHovered, _0xD452.ImVec4(_0xCD49[1] * 0.80, _0xCD49[2] * 0.80, _0xCD49[3] * 0.80, 1.00))
_0xD452.PushStyleColor(_0xD452.Col.ButtonActive, _0xD452.ImVec4(_0xCD49[1], _0xCD49[2], _0xCD49[3], 1.00))
if _0xD452.Button("##about_".. _0x7AB2, _0xD452.ImVec2(-1, 56)) then
if _0x433A.url then
_0x2A70(_0x433A.url)
elseif _0x433A.copy then
_0xD452.SetClipboardText(_0x433A.copy)
_0x75BC("Ник скопирован: ".. _0x433A.copy,"ok")
end
end
local _0xB223, _0x1A3D = _0xD452.GetItemRectMin(), _0xD452.GetItemRectMax()
local _0x613C = _0xD452.GetWindowDrawList()
local _0x2D7B = (_0xB223.y + _0x1A3D.y) / 2
local _0xBA57 = _0xD452.CalcTextSize(_0x433A.title)
_0x613C:AddText(_0xD452.ImVec2((_0xB223.x + _0x1A3D.x) / 2 - _0xBA57.x / 2, _0x2D7B - _0xBA57.y / 2), 0xFFFFFFFF, _0x433A.title)
local _0x2197 = _0xDC1B(_0x433A.icon,"")
local _0x6545 = _0xD452.CalcTextSize(_0x2197)
_0x613C:AddText(_0xD452.ImVec2(_0xB223.x + 18, _0x2D7B - _0x6545.y / 2), 0xFFFFFFFF, _0x2197)
_0xD452.PopStyleColor(3)
end
_0xD452.SetWindowFontScale(1.0)
end
_0xD452.EndChild()
endlocal function _0xCFAC(_0xE31B, _0x6E23, _0xD02A)
if _0x6E23 <= 2 then _0xE31B = _0xE31B - 1 end
local _0x3429 = math.floor(_0xE31B / 400)
local _0xC2C4 = _0xE31B - _0x3429 * 400
local _0xC1CB = (_0x6E23 + 9) % 12
local _0xE0F6 = math.floor((153 * _0xC1CB + 2) / 5) + _0xD02A - 1
local _0x4904 = _0xC2C4 * 365 + math.floor(_0xC2C4 / 4) - math.floor(_0xC2C4 / 100) + _0xE0F6
return _0x3429 * 146097 + _0x4904 - 719468
end
local function _0xDBBD(_0xE31B, _0x6E23, _0xD02A, _0x097D)
return _0xCFAC(_0xE31B, _0x6E23, _0xD02A) * 86400 + _0x097D * 3600
end
local function _0xF1E4(_0xE31B, _0x6E23, _0xD02A)return (_0xCFAC(_0xE31B, _0x6E23, _0xD02A) + 4) % 7
end
local function _0x1962(_0xE31B, _0x6E23, _0x72E2)
local _0xE608 = 1 + (7 - _0xF1E4(_0xE31B, _0x6E23, 1)) % 7
return _0xE608 + (_0x72E2 - 1) * 7
end
local function _0x0B08(_0xE31B, _0x6E23)
local _0x4081 = ({31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31})[_0x6E23]
return _0x4081 - _0xF1E4(_0xE31B, _0x6E23, _0x4081)
end
local function _0x0158(rule, std_offset, _0x723A)
local _0xE31B = tonumber(os.date("!%Y", _0x723A))
if rule =="eu"then
local _0x6984 = _0xDBBD(_0xE31B, 3, _0x0B08(_0xE31B, 3), 1)
local _0x93C7 = _0xDBBD(_0xE31B, 10, _0x0B08(_0xE31B, 10), 1)
return _0x723A >= _0x6984 and _0x723A < _0x93C7
elseif rule =="us"then
local _0x6984 = _0xDBBD(_0xE31B, 3, _0x1962(_0xE31B, 3, 2), 2) - std_offset * 3600
local _0x93C7 = _0xDBBD(_0xE31B, 11, _0x1962(_0xE31B, 11, 1), 2) - (std_offset + 1) * 3600
return _0x723A >= _0x6984 and _0x723A < _0x93C7
end
return false
end
local function _0x4FFB()
local _0x723A = os.time()
local _0x433A = os.date("*t", _0x723A)
local _0x25A4 = os.date("!*t", _0x723A)
_0x25A4.isdst = _0x433A.isdst
return os.difftime(os.time(_0x433A), os.time(_0x25A4)) / 3600
end
local _0xAC82 = {
{ _0x9851 ="Азербайджан", _0x44CA = 4 },
{ _0x9851 ="Армения", _0x44CA = 4 },
{ _0x9851 ="Беларусь", _0x44CA = 3 },
{ _0x9851 ="Великобритания", _0x44CA = 0, dst ="eu"},
{ _0x9851 ="Германия", _0x44CA = 1, dst ="eu"},
{ _0x9851 ="Грузия", _0x44CA = 4 },
{ _0x9851 ="Индия", _0x44CA = 5.5 },
{ _0x9851 ="Казахстан", _0x44CA = 5 },
{ _0x9851 ="Китай", _0x44CA = 8 },
{ _0x9851 ="Кыргызстан", _0x44CA = 6 },
{ _0x9851 ="Москва (время Аризоны)", _0x44CA = 3 },
{ _0x9851 ="ОАЭ", _0x44CA = 4 },
{ _0x9851 ="Польша", _0x44CA = 1, dst ="eu"},
{ _0x9851 ="Россия, Владивосток", _0x44CA = 10 },
{ _0x9851 ="Россия, Екатеринбург", _0x44CA = 5 },
{ _0x9851 ="Россия, Новосибирск", _0x44CA = 7 },
{ _0x9851 ="США, Лос-Анджелес", _0x44CA = -8, dst ="us"},
{ _0x9851 ="США, Нью-Йорк", _0x44CA = -5, dst ="us"},
{ _0x9851 ="Таджикистан", _0x44CA = 5 },
{ _0x9851 ="Таиланд", _0x44CA = 7 },
{ _0x9851 ="Турция", _0x44CA = 3 },
{ _0x9851 ="Узбекистан", _0x44CA = 5 },
{ _0x9851 ="Украина", _0x44CA = 2, dst ="eu"},
{ _0x9851 ="Япония", _0x44CA = 9 },
}
local _0xD56B = 1
for _0x7AB2, _0xCD49 in ipairs(_0xAC82) do
if _0xCD49.name =="Узбекистан"then _0xD56B = _0x7AB2 end
end
local function _0x4F16(_0xCD49)
local _0x723A = os.time()
local _0x44CA
if _0xCD49.pc then
_0x44CA = _0x4FFB()
else
_0x44CA = _0xCD49.off
if _0xCD49.dst and _0x0158(_0xCD49.dst, _0xCD49.off, _0x723A) then _0x44CA = _0x44CA + 1 end
end
local _0xB99C = _0x723A + _0x44CA * 3600
return os.date("!%H:%M:%S", _0xB99C), os.date("!%d.%m.%Y", _0xB99C)
end
local function _0x84F0(_0x9C52, _0x4AD0)
local _0x0A19 = _0xD452.GetCursorScreenPos()
_0xD452.GetWindowDrawList():AddText(_0xD452.ImVec2(_0x0A19.x + 1, _0x0A19.y + 1), 0xFF000000, _0x4AD0)
_0xD452.TextColored(_0x9C52, _0x4AD0)
end
local _0xFA40 = false
local _0x7A7D = { _0xB7FE = _0xD488.clock.x, _0xE31B = _0xD488.clock.y }
local _0x92F6 = false
local _0x7500 = nil
local _0x43D8 ="Время на экране###clock_modal"local function _0xDF06(_0x9851)
for _0x11D3, _0xCD49 in ipairs(_0xAC82) do
if _0xCD49.name == _0x9851 then return _0xCD49 end
end
return _0xAC82[1]
end
local function _0xA36B()
_0xD74D(_0xDC1B("GLOBE",""),"Время стран")
if _0xD452.BeginChild("##time_child", _0xD452.ImVec2(-1, _0x83B4.h - 79), true) then
local _0xD778 = _0xAC82[_0xD56B]
local _0x6C16, _0xAC20 = _0x4F16(_0xD778)
local _0x0239 = _0xD452.GetWindowWidth()
_0xD452.SetWindowFontScale(2.4)
local _0xBA57 = _0xD452.CalcTextSize(_0x6C16)
_0xD452.SetCursorPosX(math.max(5, (_0x0239 - _0xBA57.x) / 2))
_0xD452.TextColored(_0xD452.ImVec4(1.00, 0.85, 0.30, 1.00), _0x6C16)
_0xD452.SetWindowFontScale(1.0)
local _0x003F = _0xD778.name .."  |  ".. _0xAC20
local _0xCAA0 = _0xD452.CalcTextSize(_0x003F)
_0xD452.SetCursorPosX(math.max(5, (_0x0239 - _0xCAA0.x) / 2))
_0xD452.Text(_0x003F)
_0xD452.Spacing()
_0xD452.Separator()
_0xD452.Spacing()
if _0xD488.clock.enabled then
_0xD452.AlignTextToFramePadding()
_0xD452.Text("На экране: ".. _0xD488.clock.country)
_0xD452.SameLine()
if not _0xFA40 then
if _0xD452.Button("Передвинуть##clock_move") then _0xFA40 = true end
else
if _0xD452.Button(_0x0833.FLOPPY_DISK .." Сохранить положение##clock_save") then
_0xD488.clock.x = _0x7A7D.x
_0xD488.clock.y = _0x7A7D.y
_0x167A()
_0xFA40 = false
end
end
_0xD452.SameLine()
if _0xD452.Button("Убрать с экрана##clock_hide") then
_0xD488.clock.enabled = false
_0xFA40 = false
_0x167A()
end
if _0xFA40 then
_0xD452.TextColored(_0xD452.ImVec4(0.45, 1.00, 0.55, 1.00),"Перетащи надпись мышкой, затем нажми «Сохранить положение».")
end
_0xD452.Spacing()
_0xD452.Separator()
_0xD452.Spacing()
end
if _0xD452.BeginChild("##time_list", _0xD452.ImVec2(-1, -1), false) then
local _0xC1FE = math.floor((_0xD452.GetContentRegionAvail().x - 10 - 16) / 3)
for _0x7AB2, _0xCD49 in ipairs(_0xAC82) do
if (_0x7AB2 - 1) % 3 ~= 0 then _0xD452.SameLine() end
local _0x1202 = _0x4F16(_0xCD49)
local _0xBC52 = (_0x7AB2 == _0xD56B)
if _0xBC52 then
_0xD452.PushStyleColor(_0xD452.Col.Button, _0x6FB3(1.0))
end
if _0xD452.Button(_0xCD49.name .."\n".. _0x1202 .."###country_".. _0x7AB2, _0xD452.ImVec2(_0xC1FE, 44)) then
_0xD56B = _0x7AB2
_0x7500 = _0x7AB2
_0x92F6 = true
local _0xBB93, _0x842A = _0x4F16(_0xCD49)
local _0x02AB = _0x8A46:decode("{33AAFF}[Arizona Prices] {FFFFFF}Время (".. _0xCD49.name .."): {33AAFF}".. _0xBB93 .." {FFFFFF}(".. _0x842A ..")")
_0xEECB(function() sampAddChatMessage(_0x02AB, -1) end)
end
if _0xBC52 then _0xD452.PopStyleColor(1) end
end
end
_0xD452.EndChild()
if _0x92F6 then
_0xD452.OpenPopup(_0x43D8)
_0x92F6 = false
end
local _0xC51A, _0xB2A7 = getScreenResolution()
_0xD452.SetNextWindowPos(_0xD452.ImVec2(_0xC51A / 2, _0xB2A7 / 2), _0xD452.Cond.Always, _0xD452.ImVec2(0.5, 0.5))
_0xD452.SetNextWindowSize(_0xD452.ImVec2(400, 135), _0xD452.Cond.Always)
if _0xD452.BeginPopupModal(_0x43D8, nil, bit.bor(_0xD452.WindowFlags.NoCollapse, _0xD452.WindowFlags.NoResize)) then
local _0xB268 = _0xAC82[_0x7500 or _0xD56B]
_0xD452.TextColored(_0xD452.ImVec4(1.00, 0.85, 0.30, 1.00), _0xB268.name)
_0xD452.TextWrapped("Показывать время этой страны на экране?")
_0xD452.Spacing()
local _0x0AA7 = (_0xD452.GetContentRegionAvail().x - 5) / 2
if _0xD452.Button(_0xDC1B("CIRCLE_CHECK","") .." Да##clock_yes", _0xD452.ImVec2(_0x0AA7, 34)) then
_0xD488.clock.enabled = true
_0xD488.clock.country = _0xB268.name
_0x167A()
_0xD452.CloseCurrentPopup()
end
_0xD452.SameLine()
if _0xD452.Button(_0x0833.CIRCLE_XMARK .." Нет##clock_no", _0xD452.ImVec2(_0x0AA7, 34)) then
_0xD452.CloseCurrentPopup()
end
_0xD452.EndPopup()
end
end
_0xD452.EndChild()
end
local _0x9194
_0x9194 = _0xD452.OnFrame(
function()
_0x9194.HideCursor = not _0xFA40
return _0xD488.clock.enabled
end,
_0xFBE9("clock", function()
if _0xFA40 and not _0xC2A7[0] then _0xFA40 = false end
local _0x1D09 = bit.bor(_0xD452.WindowFlags.NoTitleBar, _0xD452.WindowFlags.AlwaysAutoResize, _0xD452.WindowFlags.NoScrollbar, _0xD452.WindowFlags.NoSavedSettings)
if not _0xFA40 then
_0x1D09 = bit.bor(_0x1D09, _0xD452.WindowFlags.NoMove, _0xD452.WindowFlags.NoInputs, _0xD452.WindowFlags.NoBackground)
_0xD452.SetNextWindowPos(_0xD452.ImVec2(_0x7A7D.x, _0x7A7D.y), _0xD452.Cond.Always)
end
_0xD452.SetNextWindowBgAlpha(0.45)
_0xD452.Begin("##clock_overlay", nil, _0x1D09)
_0xD452.SetWindowFontScale(_0x8800.overlay_scale)
local _0xCD49 = _0xDF06(_0xD488.clock.country)
_0x84F0(_0xD452.ImVec4(0.55, 0.85, 1.00, 1.00), _0xCD49.name ..": ".. _0x4F16(_0xCD49))
if _0xFA40 then
local _0x4220 = _0xD452.GetWindowPos()
_0x7A7D.x, _0x7A7D.y = _0x4220.x, _0x4220.y
end
_0xD452.End()
end, function() _0xD488.clock.enabled = false end)
)local _0xBC05 ="3.2"local _0xEB14 ="https://raw.githubusercontent.com/hydracrmpdesign-commits/arizona-prices/main/"local _0xEE92 = 1800local _0x5250 = getWorkingDirectory() .."\\config\\"local _0xCAB8 = _0x5250 .."arizona_prices_state.json"local _0xDB37 = { prices_sig ="", auto_prices = true }
local _0xAB2A = { available = false, version ="", _0x0EF4 = false, status =""}
local _0xB6CC = {}
local _0x9C59 = false
local _0x2A5A = false
local _0xCAE7 = 0
local _0x135A, _0xE2F0 = pcall(require,'moonloader')
local _0x92E4 = _0x135A and _0xE2F0.download_status or nil
local function _0x75AB(_0xCE87)
local _0xA75A = io.open(_0xCE87,"rb")
if not _0xA75A then return nil end
local _0xCD49 = _0xA75A:read("*a")
_0xA75A:close()
return _0xCD49
end
local function _0x4343(_0xCE87, content)
local _0xA75A = io.open(_0xCE87,"wb")
if not _0xA75A then return false end
_0xA75A:write(content)
_0xA75A:close()
return true
end
local function _0x4651()
local _0xCD49 = _0x75AB(_0xCAB8)
if _0xCD49 then
local _0x48FB, _0xD02A = pcall(decodeJson, _0xCD49)
if _0x48FB and type(_0xD02A) =="table"then
if type(_0xD02A.prices_sig) =="string"then _0xDB37.prices_sig = _0xD02A.prices_sig end
if _0xD02A.auto_prices == false then _0xDB37.auto_prices = false end
end
end
end
local function _0x1B0F()
if not doesDirectoryExist(_0x5250) then createDirectory(_0x5250) end
_0x5BFC(_0xCAB8, encodeJson(_0xDB37))
end
_0x3271("load_state", _0x4651)
local _0x43E0 = _0xD452.new.bool(_0xDB37.auto_prices)
local function _0xE6CE(_0x057C, current)
local _0xF1FB, _0x385E = {}, {}
for _0x72E2 in tostring(_0x057C):gmatch("%d+") do _0xF1FB[#_0xF1FB + 1] = tonumber(_0x72E2) end
for _0x72E2 in tostring(current):gmatch("%d+") do _0x385E[#_0x385E + 1] = tonumber(_0x72E2) end
for _0x7AB2 = 1, math.max(#_0xF1FB, #_0x385E) do
local _0xB7FE, _0xE31B = _0xF1FB[_0x7AB2] or 0, _0x385E[_0x7AB2] or 0
if _0xB7FE ~= _0xE31B then return _0xB7FE > _0xE31B end
end
return false
end
local function _0xE869(_0x6984)
local _0x13BF = 0
for _0x7AB2 = 1, #_0x6984 do _0x13BF = (_0x13BF * 31 + _0x6984:byte(_0x7AB2)) % 4294967291 end
return #_0x6984 ..":".. _0x13BF
endlocal function _0x9809(_0x9851, _0x72CC, flag)
os.remove(_0x72CC)
if not _0x92E4 or not downloadUrlToFile then
_0xAB2A.status ="Загрузка недоступна"return false
end
local _0xC781 = _0xEB14 .. _0x9851 .."?t=".. os.time()
local _0x48FB = pcall(downloadUrlToFile, _0xC781, _0x72CC, function(_0xF753, status, _0x7B4B, p2)
if status == _0x92E4.STATUSEX_ENDDOWNLOAD then
_0xB6CC[flag] = true
end
end)
return _0x48FB
end
local function _0x5792()
if not doesDirectoryExist(_0x5250) then createDirectory(_0x5250) end
_0x9809("version.txt", _0x5250 .."arizona_prices_remote_version.txt","version")
if _0xDB37.auto_prices then
_0x9809("item_prices.json", _0x5250 .."arizona_prices_remote.json","prices")
end
end
local function _0x5DD7()
local _0xCE87 = _0x5250 .."arizona_prices_remote_version.txt"local _0xCD49 = _0x75AB(_0xCE87)
os.remove(_0xCE87)
local _0x3C2B = _0xCD49 and _0xCD49:match("%d[%d%.]*")
if _0x3C2B and _0xE6CE(_0x3C2B, _0xBC05) then
if not _0xAB2A.available then
_0x75BC("Вышла новая версия ".. _0x3C2B .."! Откройте /prices и нажмите «Обновить»","info", 8)
end
_0xAB2A.available = true
_0xAB2A.version = _0x3C2B
_0xAB2A.status =""elseif _0x2A5A then
_0xAB2A.status = _0x3C2B and"У вас последняя версия"or"Не удалось проверить"end
_0x2A5A = false
end
local function _0x523F()
local _0x72CC = _0x5250 .."arizona_prices_update.lua"local _0xCD49 = _0x75AB(_0x72CC)
_0xAB2A.busy = false
if not _0xCD49 or #_0xCD49 < 2000 then
_0xAB2A.status ="Ошибка загрузки"return
end
if not loadstring(_0xCD49) then
_0xAB2A.status ="Файл повреждён"return
end
local _0x572C = thisScript().path
local _0xB3DE = _0x75AB(_0x572C)
if _0xB3DE then _0x4343(_0x5250 .."Table_Prices.lua.bak", _0xB3DE) end
if _0x4343(_0x572C, _0xCD49) then
os.remove(_0x72CC)
_0xAB2A.status ="Готово, перезапуск..."_0x9C59 = true
else
_0xAB2A.status ="Не удалось записать файл"end
end
local function _0x2CE5()
local _0xCE87 = _0x5250 .."arizona_prices_remote.json"local _0xCD49 = _0x75AB(_0xCE87)
os.remove(_0xCE87)
if not _0xCD49 or #_0xCD49 < 2 then return end
local _0x02DA = _0xE869(_0xCD49)
local _0x48FB, _0x057C = pcall(decodeJson, _0xCD49)
if not _0x48FB or type(_0x057C) ~="table"then return endif not _0x5E6F.on then
local _0x6E74 = {}
for _0x11D3, _0x0458 in ipairs(_0x057C) do
local _0x49E1 = type(_0x0458) =="table"and tonumber(_0x0458.buy) or nil
local _0x8AAB = type(_0x0458) =="table"and tonumber(_0x0458.sell) or nil
if _0x49E1 and _0x8AAB and type(_0x0458.item) =="string"then
_0x6E74[#_0x6E74 + 1] = { _0x2A2B = _0x0458.item, _0x49E1 = _0x49E1, _0x8AAB = _0x8AAB, _0xF92D = _0x5E6F.valid_liq(_0x0458.liq) }
end
end
if #_0x6E74 == 0 then return end
local _0x4219 = false
local _0x94BA, _0x31D8, _0x5868 = pcall(function() return encodeJson(_0x6E74), encodeJson(_0xC12B) end)
if _0x94BA and _0x31D8 == _0x5868 then _0x4219 = true end
if not _0x4219 then
_0xC12B = _0x6E74
_0x4A95()
if _0x02DA ~= _0xDB37.prices_sig then _0x75BC("Цены обновлены из канала","ok", 5) end
end
_0xDB37.prices_sig = _0x02DA
_0x1B0F()
return
endif _0x02DA == _0xDB37.prices_sig then return end
local _0xB14C = {}
for _0x7AB2, it in ipairs(_0xC12B) do
if it.item then _0xB14C[it.item] = _0x7AB2 end
end
local _0x900D, _0x9BD1 = 0, 0
for _0x11D3, _0x0458 in ipairs(_0x057C) do
local _0x49E1 = type(_0x0458) =="table"and tonumber(_0x0458.buy) or nil
local _0x8AAB = type(_0x0458) =="table"and tonumber(_0x0458.sell) or nil
if _0x49E1 and _0x8AAB and type(_0x0458.item) =="string"then
local _0x7AB2 = _0xB14C[_0x0458.item]
if _0x7AB2 then
local _0x433A = _0xC12B[_0x7AB2]
if tonumber(_0x433A.buy) ~= _0x49E1 or tonumber(_0x433A.sell) ~= _0x8AAB then
_0x433A.buy, _0x433A.sell = _0x49E1, _0x8AAB
_0x9BD1 = _0x9BD1 + 1
end
else
_0xC12B[#_0xC12B + 1] = { _0x2A2B = _0x0458.item, _0x49E1 = _0x49E1, _0x8AAB = _0x8AAB, _0xF92D = _0x5E6F.valid_liq(_0x0458.liq) }
_0xB14C[_0x0458.item] = #_0xC12B
_0x900D = _0x900D + 1
end
end
end
_0xDB37.prices_sig = _0x02DA
_0x1B0F()
if _0x900D + _0x9BD1 > 0 then
_0x4A95()
_0x75BC("Цены обновлены: новых ".. _0x900D ..", изменено ".. _0x9BD1,"ok", 5)
end
end
local function _0xF7AB()
if _0xB6CC.version then _0xB6CC.version = nil; pcall(_0x5DD7) end
if _0xB6CC.script then _0xB6CC.script = nil; pcall(_0x523F) end
if _0xB6CC.prices then _0xB6CC.prices = nil; pcall(_0x2CE5) end
if _0xAB2A.busy and os.time() - _0xCAE7 > 40 then
_0xAB2A.busy = false
_0xAB2A.status ="Не удалось скачать"end
end
local _0x21DF = _0xD452.new.bool(false)
local function _0xD21E()
_0xAB2A.busy = true
_0xAB2A.status =""_0xCAE7 = os.time()
if not _0x9809("Table_Prices.lua", _0x5250 .."arizona_prices_update.lua","script") then
_0xAB2A.busy = false
if _0xAB2A.status ==""then _0xAB2A.status ="Ошибка загрузки"end
end
end
local function _0xB61C()
_0xAB2A.busy = true
_0xAB2A.status =""_0xCAE7 = os.time()
_0xEECB(_0xD21E)
end
local function _0xCBA5()
_0xD452.SetCursorPos(_0xD452.ImVec2(5, _0x83B4.block_y))
_0xD452.TextDisabled("Версия ".. _0xBC05)
_0xD452.SetCursorPosX(5)
if _0xAB2A.available then
_0xD452.TextColored(_0xD452.ImVec4(0.45, 1.00, 0.55, 1.00),"Вышла версия ".. _0xAB2A.version)
_0xD452.SetCursorPosX(5)
if _0xAB2A.busy then
_0xD452.TextDisabled("Скачивание...")
elseif _0xD452.Button(_0xDC1B("DOWNLOAD","") .." Обновить##do_update", _0xD452.ImVec2(_0x67A4 - 10, 32)) then
_0xB61C()
end
else
if _0xD452.Button(_0xDC1B("ARROWS_ROTATE","") .." Проверить##check_update", _0xD452.ImVec2(_0x67A4 - 10, 28)) then
_0x2A5A = true
_0xAB2A.status ="Проверка..."_0xEECB(_0x5792)
end
end
if _0xAB2A.status ~=""then
_0xD452.SetCursorPosX(5)
_0xD452.TextDisabled(_0xAB2A.status)
end
_0xD452.SetCursorPosX(5)
if _0xD452.Checkbox(" Автообновление цен##auto_prices", _0x43E0) then
_0xDB37.auto_prices = _0x43E0[0]
_0x1B0F()
if _0xDB37.auto_prices then _0xEECB(_0x5792) end
end
endlocal _0x27B6 = { binding = false, typing = false }
local _0x3CF2, _0x0A7B = pcall(require,'vkeys')
local function _0x7392(_0xBE59)
if not _0xBE59 or _0xBE59 == 0 then return"Не задана"end
if _0x3CF2 and _0x0A7B.id_to_name then
local _0x72E2 = _0x0A7B.id_to_name(_0xBE59)
if _0x72E2 then return _0x72E2 end
end
return"VK ".. tostring(_0xBE59)
end
local _0xDA21 = {
accent = _0xD452.new.float[3](_0x8800.accent[1], _0x8800.accent[2], _0x8800.accent[3]),
opacity = _0xD452.new.float(_0x8800.opacity),
_0xFA37 = _0xD452.new.float(_0x8800.overlay_scale),
_0x37FA = _0xD452.new.bool(_0x8800.toasts),
border_speed = _0xD452.new.float(_0x8800.border_speed),
shadow = _0xD452.new.bool(_0x8800.shadow),
bg_fx = _0xD452.new.bool(_0x8800.bg_fx),
splash = _0xD452.new.bool(_0x8800.splash),
halloween = _0xD452.new.bool(_0x8800.halloween),
font_pending = false,
}
local _0xBBEF = nil
local function _0xA151()
_0xBBEF = os.clock()
end
local function _0xD1D5(force)
if _0xBBEF and (force or os.clock() - _0xBBEF > 0.8) then
_0xBBEF = nil
_0x167A()
end
endlocal _0x8E29 = {
ACCESS_CODE ="PRICES2026",
_0xCE87 = getWorkingDirectory() .."\\config\\arizona_prices_auth.json",
_0x2AAF = _0xD452.new.bool(false),
_0x8AB3 = _0xD452.new.char[48](),
_0xBE59 = _0xD452.new.char[48](),
error ="",
_0x48FB = false,
}do
local _0xD02A = _0x73C3(_0x8E29.path)
if type(_0xD02A) =="table"and tostring(_0xD02A.code or""):lower() == _0x8E29.ACCESS_CODE:lower() then
_0x8E29.ok = true
end
end
function _0x8E29.try_login()
local _0x8AB3 = _0x2A38.string(_0x8E29.nick):gsub("^%s+",""):gsub("%s+$","")
local _0xBE59 = _0x2A38.string(_0x8E29.code):gsub("%s","")
if _0x8AB3 ==""then _0x8E29.error ="Введите ваш никнейм"; return end
if _0xBE59 ==""then _0x8E29.error ="Введите код из телеграм-канала"; return end
if _0x8E29.loading then return end
_0x8E29.error =""_0x8E29.loading = { _0xDDCC = _0xD452.GetTime(), _0x8AB3 = _0x8AB3, _0xBE59 = _0xBE59 }
endfunction _0x8E29.finish()
local _0x8AB3, _0xBE59 = _0x8E29.loading.nick, _0x8E29.loading.code
_0x8E29.loading = nil
if _0xBE59:lower() ~= _0x8E29.ACCESS_CODE:lower() then
_0x8E29.error ="Неверный код. Получите актуальный код в телеграм-канале"return
end
_0x8E29.ok = true
_0x8E29.error =""_0x8E29.open[0] = false
local _0x24EF = getWorkingDirectory() .."\\config"if not doesDirectoryExist(_0x24EF) then createDirectory(_0x24EF) end
_0x081E(_0x8E29.path, encodeJson({ _0x8AB3 = _0x8AB3, _0xBE59 = _0xBE59 }))
_0x75BC("Доступ открыт. Добро пожаловать, ".. _0x8AB3 .."!","ok", 5)
_0xC2A7[0] = true
end
_0xD452.OnFrame(function() return _0x8E29.open[0] end, _0xFBE9("auth", function()
local _0xC51A, _0xB2A7 = getScreenResolution()
local _0xEFBB, _0x6AC1 = 560, 380
_0xD452.SetNextWindowPos(_0xD452.ImVec2(_0xC51A / 2, _0xB2A7 / 2), _0xD452.Cond.Always, _0xD452.ImVec2(0.5, 0.5))
_0xD452.SetNextWindowSize(_0xD452.ImVec2(_0xEFBB, _0x6AC1), _0xD452.Cond.Always)
_0xD452.PushStyleColor(_0xD452.Col.WindowBg, _0xD452.ImVec4(0.075, 0.07, 0.095, 1.0))
_0xD452.Begin("##auth_window", nil, bit.bor(_0xD452.WindowFlags.NoTitleBar, _0xD452.WindowFlags.NoResize,
_0xD452.WindowFlags.NoCollapse, _0xD452.WindowFlags.NoScrollbar, _0xD452.WindowFlags.NoSavedSettings))
local _0x0A19 = _0xD452.GetWindowPos()
local _0x4EDA = _0x8800.accent
_0xD452.GetWindowDrawList():AddRectFilled(_0x0A19, _0xD452.ImVec2(_0x0A19.x + _0xEFBB, _0x0A19.y + 5), _0xEB5D(_0x4EDA[1], _0x4EDA[2], _0x4EDA[3], 1))
_0xD452.SetCursorPos(_0xD452.ImVec2(26, 24))
_0xD452.SetWindowFontScale(1.7)
_0xD452.TextColored(_0x6FB3(1.2), _0xDC1B("LOCK","") .." Авторизация")
_0xD452.SetWindowFontScale(1.15)
_0xD452.SetCursorPos(_0xD452.ImVec2(26, 76))
_0xD452.PushTextWrapPos(_0xEFBB - 26)
_0xD452.TextWrapped("Вы попали в окно авторизации. Введите свой никнейм и код. Код можно получить в телеграм-канале.")
_0xD452.PopTextWrapPos()
if _0x8E29.loading thenlocal _0x723A = _0xD452.GetTime()
local _0x562D = _0x997A((_0x723A - _0x8E29.loading.t) / 3.0, 0, 1)
local _0x613C = _0xD452.GetWindowDrawList()
local _0xB2EB, _0x2D7B = _0x0A19.x + _0xEFBB / 2, _0x0A19.y + 165
for _0x7AB2 = 0, 11 do
local _0xDFD1 = _0x7AB2 / 12 * math.pi * 2 - _0x723A * 6
local _0x2192 = ((_0x7AB2 / 12) - (_0x723A * 1.5) % 1) % 1
_0x613C:AddCircleFilled(_0xD452.ImVec2(_0xB2EB + math.cos(_0xDFD1) * 34, _0x2D7B + math.sin(_0xDFD1) * 34), 5.5,
_0xEB5D(_0x4EDA[1], _0x4EDA[2], _0x4EDA[3], 0.15 + 0.85 * (1 - _0x2192)), 12)
end
local _0x4304 = {"Подключение к серверу...","Проверка кода...","Верификация никнейма...","Доступ разрешён"}
local _0x5315 = _0x4304[math.min(#_0x4304, 1 + math.floor(_0x562D * #_0x4304))]
_0xD452.SetCursorPos(_0xD452.ImVec2(0, 232))
_0xD452.SetWindowFontScale(1.6)
local _0x2B6D = string.rep(".", math.floor(_0x723A * 3) % 4)
local _0xB775 ="Загрузка".. _0x2B6D
_0xD452.SetCursorPosX((_0xEFBB - _0xD452.CalcTextSize("Загрузка...").x) / 2)
_0xD452.Text(_0xB775)
_0xD452.SetWindowFontScale(1.1)
_0xD452.SetCursorPosX((_0xEFBB - _0xD452.CalcTextSize(_0x5315).x) / 2)
_0xD452.TextColored(_0xD452.ImVec4(0.65, 0.65, 0.72, 1), _0x5315)
_0xD452.SetCursorPos(_0xD452.ImVec2(60, _0x6AC1 - 46))
_0xD452.PushStyleColor(_0xD452.Col.PlotHistogram, _0x6FB3(1.1))
_0xD452.ProgressBar(_0x562D, _0xD452.ImVec2(_0xEFBB - 120, 10),"")
_0xD452.PopStyleColor(1)
_0xD452.SetWindowFontScale(1.0)
_0xD452.End()
_0xD452.PopStyleColor(1)
if _0x562D >= 1 then _0x8E29.finish() end
return
end
_0xD452.SetCursorPos(_0xD452.ImVec2(26, 150))
_0xD452.SetNextItemWidth(_0xEFBB - 52)
_0xD452.InputTextWithHint("##auth_nick","Ваш никнейм", _0x8E29.nick, _0x2A38.sizeof(_0x8E29.nick))
_0xD452.SetCursorPosX(26)
_0xD452.SetNextItemWidth(_0xEFBB - 52)
local _0x56D1 = _0xD452.InputTextWithHint("##auth_code","Код из телеграм-канала", _0x8E29.code, _0x2A38.sizeof(_0x8E29.code), _0xD452.InputTextFlags.EnterReturnsTrue)
if _0x56D1 then _0x8E29.try_login() end
_0xD452.SetCursorPosX(26)
if _0x8E29.error ~=""then
_0xD452.TextColored(_0xD452.ImVec4(1.0, 0.4, 0.4, 1.0), _0x8E29.error)
else
_0xD452.Text(" ")
end
_0xD452.SetCursorPos(_0xD452.ImVec2(26, _0x6AC1 - 26 - 46))
local _0xC1FE = (_0xEFBB - 52 - 20) / 3
_0xD452.PushStyleColor(_0xD452.Col.Button, _0x6FB3(1.0))
_0xD452.PushStyleColor(_0xD452.Col.ButtonHovered, _0x6FB3(1.15))
_0xD452.PushStyleColor(_0xD452.Col.ButtonActive, _0x6FB3(0.85))
if _0xD452.Button(_0xDC1B("RIGHT_TO_BRACKET","") .." Войти##auth_go", _0xD452.ImVec2(_0xC1FE, 46)) then _0x8E29.try_login() end
_0xD452.PopStyleColor(3)
_0xD452.SameLine()
if _0xD452.Button(_0xDC1B("PAPER_PLANE","") .." Получить код##auth_tg", _0xD452.ImVec2(_0xC1FE + 40, 46)) then
_0x2A70("https://t.me/arizona_prices")
end
_0xD452.SameLine()
if _0xD452.Button(_0x0833.CIRCLE_XMARK .." Закрыть##auth_close", _0xD452.ImVec2(_0xC1FE - 40, 46)) then _0x8E29.open[0] = false end
_0xD452.SetWindowFontScale(1.0)
_0xD452.End()
_0xD452.PopStyleColor(1)
end, function() _0x8E29.open[0] = false; _0x8E29.loading = nil end))
local function _0x6898()
if not _0x8E29.ok then_0xC2A7[0] = false
_0x8E29.loading = nil
_0x8E29.open[0] = not _0x8E29.open[0]
if _0x8E29.open[0] and _0x2A38.string(_0x8E29.nick) ==""then
local _0x6496, _0xF753 = pcall(function() local _0x11D3, _0x7AB2 = sampGetPlayerIdByCharHandle(PLAYER_PED); return sampGetPlayerNickname(_0x7AB2) end)
if _0x6496 and _0xF753 then _0xD452.StrCopy(_0x8E29.nick, _0xF753) end
end
return
end
_0xC2A7[0] = not _0xC2A7[0]
if _0xC2A7[0] and _0xAB2A.available then
_0x21DF[0] = true
end
end
local function _0xE643(msg, wparam, lparam)
if msg ~= 0x100 and msg ~= 0x104 then return end
local _0x360F = bit.band(lparam, 0x40000000) ~= 0
if _0x27B6.binding then
consumeWindowMessage(true, true)
if _0x360F then return end
_0x27B6.binding = false
if wparam == 0x08 then
_0x8800.open_key = 0
_0xA151()
_0x75BC("Горячая клавиша убрана","info")
elseif wparam ~= 0x1B then
_0x8800.open_key = wparam
_0xA151()
_0x75BC("Клавиша открытия меню: ".. _0x7392(wparam),"ok")
end
return
end
if _0x360F then return endif _0xC2A7[0] and _0xB6FD.alpha > 0.5 and not _0x27B6.typing then
local _0x94BA, _0x0EF4 = pcall(function() return sampIsChatInputActive() or sampIsDialogActive() end)
if not (_0x94BA and _0x0EF4) then
if wparam >= 0x31 and wparam <= 0x38 then
_0xB6FD.pending_tab = _0xB6FD.TAB_ORDER[wparam - 0x30]
consumeWindowMessage(true, true)
return
elseif wparam == 0x46 then
local _0x65FF, _0xEB69 = pcall(isKeyDown, 0x11)
if _0x65FF and _0xEB69 then
_0xB6FD.pending_tab = 1
_0xB6FD.focus_search = true
consumeWindowMessage(true, true)
return
end
end
end
end
local _0x2890 = _0x8800.open_key
if _0x2890 and _0x2890 ~= 0 and wparam == _0x2890 then
local _0x94BA, _0x0EF4 = pcall(function() return sampIsChatInputActive() or sampIsDialogActive() end)
if _0x94BA and _0x0EF4 then return end
if _0xC2A7[0] and _0x27B6.typing then return end
_0x6898()
end
end
local function _0x8BAE()
local _0x79E1 = {}
local function _0x675D(_0xDDCC) _0x79E1[#_0x79E1 + 1] = _0xDDCC end
_0x675D("Arizona Prices - отчёт об ошибке")
_0x675D("Версия скрипта: ".. _0xBC05)
_0x675D("Журнал ошибок: moonloader\\config\\arizona_prices_errors.log")
_0x675D("Дата: ".. os.date("%Y-%m-%d %H:%M:%S"))
local _0x89FA, _0x2185 = pcall(function() return getMoonloaderVersion() end)
_0x675D("MoonLoader: ".. (_0x89FA and tostring(_0x2185) or"?"))
_0x675D("Lua: ".. tostring(_VERSION) .. (jit and (" / ".. tostring(jit.version)) or""))
local _0x9039, _0x15F6, _0x1935 = pcall(getScreenResolution)
_0x675D("Экран: ".. (_0x9039 and (tostring(_0x15F6) .."x".. tostring(_0x1935)) or"?"))
_0x675D("Предметов в списке: ".. #_0xC12B)
_0x675D("Автообновление цен: ".. tostring(_0xDB37.auto_prices))
_0x675D("Загрузка файлов: ".. ((downloadUrlToFile and _0x92E4) and"доступна"or"недоступна"))
_0x675D("Уведомления: ".. tostring(_0x8800.toasts) ..", горячая клавиша: ".. _0x7392(_0x8800.open_key))
if #_0x6EE0 > 0 then
_0x675D("Последние ошибки:")
for _0x11D3, _0x93C7 in ipairs(_0x6EE0) do _0x675D("  ".. _0x93C7) end
else
_0x675D("Ошибок в журнале нет")
end
_0x675D("")
_0x675D("Что вы делали перед ошибкой:")
return table.concat(_0x79E1,"\n")
end
local function _0xFCEE()
local _0x48FB, _0x4AD0 = pcall(_0x8BAE)
local _0xC235 = _0x48FB and _0x4AD0 or ("Arizona Prices ".. _0xBC05)
_0xD452.SetClipboardText("Привет. Заметил о баге:\n\n\n".. _0xC235)
_0x2A70("https://t.me/xi_vivide")
_0x75BC("Сообщение скопировано - допишите, что случилось, и отправьте (Ctrl+V)","ok", 6)
end
local _0x164B = {
{ _0x9851 ="Океан", _0xCD49 = {0.18, 0.45, 0.85} }, { _0x9851 ="Изумруд", _0xCD49 = {0.20, 0.70, 0.45} },
{ _0x9851 ="Аметист", _0xCD49 = {0.60, 0.35, 0.90} }, { _0x9851 ="Рубин", _0xCD49 = {0.90, 0.30, 0.35} },
{ _0x9851 ="Янтарь", _0xCD49 = {0.95, 0.60, 0.15} }, { _0x9851 ="Бирюза", _0xCD49 = {0.15, 0.72, 0.78} },
{ _0x9851 ="Сакура", _0xCD49 = {0.90, 0.40, 0.70} }, { _0x9851 ="Неон", _0xCD49 = {0.55, 1.00, 0.20} },
}
local _0x5F8F = {"Выключена","Переливы цвета","Радуга","Статичная"}
local _0xA593 = {
{ _0x9851 ="Справа снизу", _0x3C2B = 3 }, { _0x9851 ="Справа сверху", _0x3C2B = 1 },
{ _0x9851 ="Слева снизу", _0x3C2B = 2 }, { _0x9851 ="Слева сверху", _0x3C2B = 0 },
}
local function _0xB461(icon_name, _0x4AD0)
_0xD452.Spacing()
_0xD452.TextColored(_0x6FB3(1.2), _0xDC1B(icon_name,"") .." ".. _0x4AD0)
_0xD452.Separator()
_0xD452.Spacing()
end
local function _0x933D()
_0xD74D(_0xDC1B("GEAR",""),"Настройки")
if _0xD452.BeginChild("##settings_child", _0xD452.ImVec2(-1, _0x83B4.h - 79), true) then
_0xB461("PALETTE","Темы оформления")
for _0x7AB2, th in ipairs(_0x164B) do
local _0xCD49 = th.c
_0xD452.PushStyleColor(_0xD452.Col.Button, _0xD452.ImVec4(_0xCD49[1] * 0.55, _0xCD49[2] * 0.55, _0xCD49[3] * 0.55, 1.0))
_0xD452.PushStyleColor(_0xD452.Col.ButtonHovered, _0xD452.ImVec4(_0xCD49[1] * 0.80, _0xCD49[2] * 0.80, _0xCD49[3] * 0.80, 1.0))
_0xD452.PushStyleColor(_0xD452.Col.ButtonActive, _0xD452.ImVec4(_0xCD49[1], _0xCD49[2], _0xCD49[3], 1.0))
if _0xD452.Button(th.name .."##theme".. _0x7AB2, _0xD452.ImVec2(110, 30)) then
_0x8800.accent = { _0xCD49[1], _0xCD49[2], _0xCD49[3] }
_0xDA21.accent[0], _0xDA21.accent[1], _0xDA21.accent[2] = _0xCD49[1], _0xCD49[2], _0xCD49[3]
apply_theme()
_0xA151()
end
_0xD452.PopStyleColor(3)
if _0x7AB2 % 4 ~= 0 and _0x7AB2 < #_0x164B then _0xD452.SameLine() end
end
_0xD452.Spacing()
if _0xD452.ColorEdit3("Свой цвет##accent_custom", _0xDA21.accent, _0xD452.ColorEditFlags.NoInputs) then
_0x8800.accent = { _0xDA21.accent[0], _0xDA21.accent[1], _0xDA21.accent[2] }
apply_theme()
_0xA151()
end
_0xD452.SetNextItemWidth(260)
if _0xD452.SliderFloat("Прозрачность окна##opacity", _0xDA21.opacity, 0.3, 1.0,"%.2f") then
_0x8800.opacity = _0xDA21.opacity[0]
apply_theme()
_0xA151()
end
_0xB461("WAND_MAGIC_SPARKLES","Рамка и эффекты")
_0xD452.SetNextItemWidth(220)
if _0xD452.BeginCombo("Рамка окна##border_mode", _0x5F8F[_0x8800.border_mode + 1] or _0x5F8F[2]) then
for _0x7AB2, _0x9851 in ipairs(_0x5F8F) do
if _0xD452.Selectable(_0x9851 .."##bm".. _0x7AB2, _0x8800.border_mode == _0x7AB2 - 1) then
_0x8800.border_mode = _0x7AB2 - 1
_0xA151()
end
end
_0xD452.EndCombo()
end
if _0x8800.border_mode == 1 or _0x8800.border_mode == 2 then
_0xD452.SetNextItemWidth(260)
if _0xD452.SliderFloat("Скорость переливов##border_speed", _0xDA21.border_speed, 0.2, 3.0,"%.1f") then
_0x8800.border_speed = _0xDA21.border_speed[0]
_0xA151()
end
end
if _0xD452.Checkbox("Тень под окном##shadow", _0xDA21.shadow) then
_0x8800.shadow = _0xDA21.shadow[0]
_0xA151()
end
if _0xD452.Checkbox("Анимированный фон##bgfx", _0xDA21.bg_fx) then
_0x8800.bg_fx = _0xDA21.bg_fx[0]
_0xA151()
end
if _0xD452.Checkbox("Заставка при первом открытии меню##splash", _0xDA21.splash) then
_0x8800.splash = _0xDA21.splash[0]
_0xA151()
end
if _0xD452.Checkbox("Хэллоуин: тыквы, летучие мыши, паутина##halloween", _0xDA21.halloween) then
_0x8800.halloween = _0xDA21.halloween[0]
local _0xCD49 = _0x8800.halloween and { 0.98, 0.55, 0.12 } or { 0.18, 0.45, 0.85 }
_0x8800.accent = _0xCD49
_0xDA21.accent[0], _0xDA21.accent[1], _0xDA21.accent[2] = _0xCD49[1], _0xCD49[2], _0xCD49[3]
apply_theme()
_0xA151()
end
_0xB461("FONT","Шрифт")
local _0xF0DC = _0x776F[1].name
for _0x11D3, _0xA75A in ipairs(_0x776F) do
if _0xA75A.key == _0x8800.font then _0xF0DC = _0xA75A.name end
end
_0xD452.SetNextItemWidth(260)
if _0xD452.BeginCombo("Шрифт интерфейса##font", _0xF0DC) then
for _0x11D3, _0xA75A in ipairs(_0x776F) do
if _0xD452.Selectable(_0xA75A.name .."##font_".. _0xA75A.key, _0x8800.font == _0xA75A.key) then
_0x8800.font = _0xA75A.key
_0xDA21.font_pending = true
_0xA151()
end
end
_0xD452.EndCombo()
end
if _0xDA21.font_pending then
if _0xD452.Button(_0xDC1B("ARROWS_ROTATE","") .." Применить шрифт (перезапуск скрипта)##apply_font", _0xD452.ImVec2(360, 28)) then
_0xEECB(function()
_0xD1D5(true)
thisScript():reload()
end)
end
else
_0xD452.TextDisabled("Шрифт меняется после перезапуска скрипта. Берётся из папки Fonts в Windows.")
end
_0xB461("EXPAND","Надписи на экране")
_0xD452.SetNextItemWidth(260)
if _0xD452.SliderFloat("Размер надписей на экране##overlay_scale", _0xDA21.scale, 0.7, 2.0,"%.1f") then
_0x8800.overlay_scale = _0xDA21.scale[0]
_0xA151()
end
_0xD452.TextDisabled("Касается надписей PayDay и часов, которые показываются поверх игры.")
_0xD452.Spacing()
if _0xD452.Button(_0xDC1B("ROTATE_LEFT","") .." Сбросить внешний вид##reset_look", _0xD452.ImVec2(230, 28)) then
_0x8800.accent = _0x8800.halloween and { 0.98, 0.55, 0.12 } or { 0.18, 0.45, 0.85 }
_0x8800.opacity = 1.0
_0x8800.overlay_scale = 1.0
_0x8800.border_mode = 1
_0x8800.border_speed = 1.0
_0x8800.shadow = true
if _0x8800.font ~="seguisb"then
_0x8800.font ="seguisb"_0xDA21.font_pending = true
end
_0xDA21.accent[0], _0xDA21.accent[1], _0xDA21.accent[2] = _0x8800.accent[1], _0x8800.accent[2], _0x8800.accent[3]
_0xDA21.opacity[0] = 1.0
_0xDA21.scale[0] = 1.0
_0xDA21.border_speed[0] = 1.0
_0xDA21.shadow[0] = true
apply_theme()
_0xA151()
end
_0xD452.SameLine()
if _0xD452.Button(_0xDC1B("EXPAND","") .." Сбросить размер окна##reset_size", _0xD452.ImVec2(230, 28)) then
_0x83B4.force = true
end
_0xB461("KEYBOARD","Управление")
_0xD452.AlignTextToFramePadding()
_0xD452.Text("Клавиша открытия меню:")
_0xD452.SameLine()
local _0x5240 = _0x27B6.binding and"Нажмите клавишу..."or _0x7392(_0x8800.open_key)
if _0xD452.Button(_0x5240 .."##bind_open_key", _0xD452.ImVec2(190, 26)) then
_0x27B6.binding = not _0x27B6.binding
end
_0xD452.TextDisabled("Esc - отмена, Backspace - убрать клавишу. Команда /prices работает всегда.")
_0xB461("BELL","Уведомления")
if _0xD452.Checkbox("Всплывающие карточки вместо сообщений в чате", _0xDA21.toasts) then
_0x8800.toasts = _0xDA21.toasts[0]
_0xA151()
end
local _0x8D63 = _0xA593[1].name
for _0x11D3, _0xCD49 in ipairs(_0xA593) do
if _0xCD49.v == _0x8800.toast_corner then _0x8D63 = _0xCD49.name end
end
_0xD452.SetNextItemWidth(220)
if _0xD452.BeginCombo("Угол экрана##toast_corner", _0x8D63) then
for _0x11D3, _0xCD49 in ipairs(_0xA593) do
if _0xD452.Selectable(_0xCD49.name, _0xCD49.v == _0x8800.toast_corner) then
_0x8800.toast_corner = _0xCD49.v
_0xA151()
end
end
_0xD452.EndCombo()
end
if _0xD452.Button(_0xDC1B("BELL","") .." Показать пример##toast_test", _0xD452.ImVec2(230, 28)) then
_0x75BC("Так выглядят уведомления","ok")
end
_0xB461("BUG","Поддержка")
if _0xD452.Button(_0xDC1B("BUG","") .." Сообщить об ошибке##report_error", _0xD452.ImVec2(230, 30)) then
_0xFCEE()
end
_0xD452.TextDisabled("Скопирует версию скрипта и данные для диагностики и откроет Telegram разработчика.")
if #_0x6EE0 > 0 then
_0xD452.TextColored(_0xD452.ImVec4(1.0, 0.55, 0.40, 1.0),"Записей в журнале ошибок: ".. #_0x6EE0)
end
end
_0xD452.EndChild()
end
local function _0x6DC7()
_0xD74D(_0xDC1B("NOTE_STICKY",""),"Заметки")
if _0xD452.BeginChild("##notes_child", _0xD452.ImVec2(-1, _0x83B4.h - 79), true) then
_0xD452.TextDisabled("Записывай сюда всё важное: цены, договорённости, ники. Сохраняется само.")
_0xD452.Spacing()
_0xD452.SetWindowFontScale(1.15)
local _0x097D = _0xD452.GetContentRegionAvail().y - 48
if _0xD452.InputTextMultiline("##notes_text", _0xB6FD.notes, _0x2A38.sizeof(_0xB6FD.notes), _0xD452.ImVec2(-1, math.max(80, _0x097D))) then
_0xD488.notes = _0x2A38.string(_0xB6FD.notes)
_0xA151()
end
_0xD452.SetWindowFontScale(1.0)
local _0x9202 = math.floor(#_0xD488.notes / 81.91)
_0xD452.AlignTextToFramePadding()
_0xD452.TextDisabled("Заполнено: ".. _0x9202 .."%")
_0xD452.SameLine()
if _0xD452.Button(_0xDC1B("TRASH_CAN","") .." Очистить##notes_clear", _0xD452.ImVec2(130, 28)) then
_0xD452.StrCopy(_0xB6FD.notes,"")
_0xD488.notes =""_0xA151()
end
end
_0xD452.EndChild()
end
local function _0x0BEF(_0xF753)
if _0xF753 == 3 then
_0x61FA()
elseif _0xF753 == 4 then
_0x0342()
elseif _0xF753 == 5 then
_0x5602()
elseif _0xF753 == 6 then
_0xA36B()
elseif _0xF753 == 7 then
_0x933D()
elseif _0xF753 == 8 then
_0x6DC7()
end
end
local _0x9AB4
_0x9AB4 = _0xD452.OnFrame(
function()
_0x9AB4.HideCursor = not _0x675B
return _0x54F3[0]
end,
_0xFBE9("payday", function()
if _0x675B and not _0xC2A7[0] then _0x675B = false end
local _0x1D09 = bit.bor(_0xD452.WindowFlags.NoTitleBar, _0xD452.WindowFlags.AlwaysAutoResize, _0xD452.WindowFlags.NoScrollbar, _0xD452.WindowFlags.NoSavedSettings)
if not _0x675B then
_0x1D09 = bit.bor(_0x1D09, _0xD452.WindowFlags.NoMove, _0xD452.WindowFlags.NoInputs, _0xD452.WindowFlags.NoBackground)
_0xD452.SetNextWindowPos(_0xD452.ImVec2(_0xCF55.x, _0xCF55.y), _0xD452.Cond.Always)
end
_0xD452.SetNextWindowBgAlpha(0.45)
_0xD452.Begin("##payday_overlay", nil, _0x1D09)
_0xD452.SetWindowFontScale(_0x8800.overlay_scale)
_0x84F0(_0xD452.ImVec4(1.00, 0.85, 0.30, 1.00), _0x03EB())
if _0x675B then
local _0x4220 = _0xD452.GetWindowPos()
_0xCF55.x, _0xCF55.y = _0x4220.x, _0x4220.y
end
_0xD452.End()
end, function() _0x54F3[0] = false end)
)
_0xD452.OnInitialize(function()_0x3271("fa_init", function() _0x7FE0.Init() end)_0x3271("custom_font", function()
local _0xCE87
for _0x11D3, _0xA75A in ipairs(_0x776F) do
if _0xA75A.key == _0x8800.font and _0xA75A.path then _0xCE87 = _0xA75A.path end
end
if not _0xCE87 thenlocal _0x48FB, _0x24EF = pcall(getFolderPath, 0x14)
if _0x48FB and _0x24EF then
for _0x11D3, _0x9851 in ipairs({"trebucbd.ttf","trebuc.ttf","arial.ttf"}) do
if doesFileExist(_0x24EF .."\\".. _0x9851) then _0xCE87 = _0x24EF .."\\".. _0x9851 break end
end
end
end
if not _0xCE87 then return end
local _0xCBE1 = _0xD452.GetIO()
local _0x4A5B = _0xCBE1.Fonts:AddFontFromFileTTF(_0xCE87, 28, nil, _0xCBE1.Fonts:GetGlyphRangesCyrillic())
if _0x4A5B ~= nil thenif not pcall(_0x7FE0.Init, 28) then pcall(_0x7FE0.Init) end
_0xCBE1.FontDefault = _0x4A5B
_0xCBE1.FontGlobalScale = 0.5
end
end)
_0x3271("apply_theme", apply_theme)
_0x3271("load_data", _0xF4C6)
end)local _0x58E2 = { on = false, _0xC859 = 0, _0xAF45 = 0, _0x11F5 = 0, _0x097D = 0 }
local function _0xF88C()local _0x7FF8, _0xD08F = _0xD452.GetWindowPos(), _0xD452.GetWindowSize()
local _0xB2EB, _0x2D7B = _0x7FF8.x + _0xD08F.x, _0x7FF8.y + _0xD08F.y_0xD452.SetCursorPos(_0xD452.ImVec2(_0xD08F.x - 28, _0xD08F.y - 28 + _0xD452.GetScrollY()))
_0xD452.InvisibleButton("##resize_grip", _0xD452.ImVec2(20, 20))
local _0xC1CB = _0xD452.GetMousePos()
local _0xE10A = _0xC1CB.x >= _0xB2EB - 34 and _0xC1CB.x <= _0xB2EB + 4 and _0xC1CB.y >= _0x2D7B - 34 and _0xC1CB.y <= _0x2D7B + 4
if not _0x58E2.on and _0xE10A and _0xD452.IsMouseClicked(0) then
_0x58E2.on = true
_0x58E2.mx, _0x58E2.my, _0x58E2.w, _0x58E2.h = _0xC1CB.x, _0xC1CB.y, _0x83B4.w, _0x83B4.h
end
if _0x58E2.on then
if _0xD452.IsMouseDown(0) then
local _0xC51A, _0xB2A7 = getScreenResolution()
_0x83B4.req = {
_0x11F5 = _0x997A(_0x58E2.w + _0xC1CB.x - _0x58E2.mx, 700, math.max(700, _0xC51A - 20)),
_0x097D = _0x997A(_0x58E2.h + _0xC1CB.y - _0x58E2.my, 400, math.max(400, _0xB2A7 - 20)),
}
else
_0x58E2.on = false
end
end
local _0x4EDA = _0x8800.accent
local _0xF1FB = (_0xE10A or _0x58E2.on) and 0.95 or 0.55
_0xD452.GetWindowDrawList():AddTriangleFilled(
_0xD452.ImVec2(_0xB2EB - 6, _0x2D7B - 6), _0xD452.ImVec2(_0xB2EB - 6, _0x2D7B - 22), _0xD452.ImVec2(_0xB2EB - 22, _0x2D7B - 6),
_0xEB5D(_0x4EDA[1], _0x4EDA[2], _0x4EDA[3], _0xF1FB))
endlocal function _0xC8E2(wsz)
if wsz.x < 700 or wsz.y < 400 then
wsz = _0xD452.ImVec2(math.max(700, wsz.x), math.max(400, wsz.y))
_0xD452.SetWindowSize(wsz, _0xD452.Cond.Always)
end
_0x83B4.w, _0x83B4.h = wsz.x, wsz.y
_0x83B4.tab_h = _0x997A(math.floor((_0x83B4.h - 161) / 8) - 5, 26, 42)
_0x83B4.block_y = 5 + 8 * (_0x83B4.tab_h + 5) + 6
local _0x11F5, _0x097D = math.floor(wsz.x + 0.5), math.floor(wsz.y + 0.5)
if _0x11F5 ~= _0x8800.win_w or _0x097D ~= _0x8800.win_h then
_0x8800.win_w, _0x8800.win_h = _0x11F5, _0x097D
_0xA151()
end
endfunction _0xB6FD.draw_splash(_0x5025)
if not _0xB6FD.splash_t then return end
local _0x660C = _0xD452.ImVec2
local _0x8FF3 = _0xD452.GetTime() - _0xB6FD.splash_t
local _0x6326 = 2.0
if _0x8FF3 >= _0x6326 then
_0xB6FD.splash_t = nil
return
end
_0xD452.SetCursorPos(_0x660C(0, 0))
if _0xD452.InvisibleButton("##splash_block", _0x660C(_0x83B4.w, _0x83B4.h)) then
_0xB6FD.splash_t = nil
return
end
local _0xF1FB = (_0x8FF3 < 1.35) and 1 or _0x997A(1 - (_0x8FF3 - 1.35) / (_0x6326 - 1.35), 0, 1)
local _0x4EDA = _0x8800.accent
local _0x613C = _0xD452.GetWindowDrawList()
local _0x111C, _0x7E78 = _0x5025.x + _0x83B4.w, _0x5025.y + _0x83B4.h
_0x613C:AddRectFilled(_0x5025, _0x660C(_0x111C, _0x7E78), _0xEB5D(0.04, 0.035, 0.06, 0.98 * _0xF1FB), 12)
local _0xB2EB, _0x2D7B = (_0x5025.x + _0x111C) / 2, (_0x5025.y + _0x7E78) / 2 - 24
for _0x7AB2 = 5, 1, -1 do
_0x613C:AddCircleFilled(_0x660C(_0xB2EB, _0x2D7B), 40 + _0x7AB2 * 26, _0xEB5D(_0x4EDA[1], _0x4EDA[2], _0x4EDA[3], 0.035 * _0xF1FB), 40)
end
if _0x8800.halloween then _0xB6FD.hw_safe(_0xB6FD.hw_pumpkin, _0x613C, _0xB2EB, _0x2D7B - 92, 30, _0xF1FB, true) end
local _0x9C47 = 1 + 0.12 * (1 - _0x997A(_0x8FF3 / 0.7, 0, 1)) ^ 2
local _0xB775 ="Arizona Prices"_0xD452.SetWindowFontScale(2.6 * _0x9C47)
local _0xBA57 = _0xD452.CalcTextSize(_0xB775)
_0x613C:AddText(_0x660C(_0xB2EB - _0xBA57.x / 2 + 2, _0x2D7B - _0xBA57.y / 2 + 2), _0xEB5D(0, 0, 0, 0.6 * _0xF1FB), _0xB775)
_0x613C:AddText(_0x660C(_0xB2EB - _0xBA57.x / 2, _0x2D7B - _0xBA57.y / 2), _0xEB5D(1, 1, 1, _0xF1FB), _0xB775)
_0xD452.SetWindowFontScale(1.2)
local _0xCFC4 ="Версия ".. _0xBC05 .."  |  t.me/arizona_prices"local _0x9FB5 = _0xD452.CalcTextSize(_0xCFC4)
_0x613C:AddText(_0x660C(_0xB2EB - _0x9FB5.x / 2, _0x2D7B + _0xBA57.y / 2 + 12), _0xEB5D(0.75, 0.78, 0.9, _0xF1FB), _0xCFC4)
_0xD452.SetWindowFontScale(1.0)
local _0xC1FE = 240
local _0x376D, _0x8D20 = _0xB2EB - _0xC1FE / 2, _0x2D7B + _0xBA57.y / 2 + 62
_0x613C:AddRectFilled(_0x660C(_0x376D, _0x8D20), _0x660C(_0x376D + _0xC1FE, _0x8D20 + 6), _0xEB5D(1, 1, 1, 0.10 * _0xF1FB), 3)
_0x613C:AddRectFilled(_0x660C(_0x376D, _0x8D20), _0x660C(_0x376D + _0xC1FE * _0x997A(_0x8FF3 / (_0x6326 - 0.3), 0, 1), _0x8D20 + 6), _0xEB5D(_0x4EDA[1], _0x4EDA[2], _0x4EDA[3], _0xF1FB), 3)
if _0x8800.halloween then
_0xD452.SetWindowFontScale(1.1)
local _0x1990 = _0xD452.CalcTextSize("Happy Halloween")
_0x613C:AddText(_0x660C(_0xB2EB - _0x1990.x / 2, _0x8D20 + 20), _0xEB5D(1.0, 0.60, 0.15, _0xF1FB),"Happy Halloween")
_0xD452.SetWindowFontScale(1.0)
end
end
_0xD452.OnFrame(function() return _0xC2A7[0] or _0x2D04[0] or _0xB6FD.alpha > 0 end,
_0xFBE9("menu", function(player)
_0xB6FD.tick()
if _0xC2A7[0] or _0xB6FD.alpha > 0 then
_0xB6FD.set_alpha(_0xB6FD.alpha)
local _0xC51A, _0xB2A7 = getScreenResolution()
_0xD452.SetNextWindowPos(_0xD452.ImVec2(_0xC51A / 2, _0xB2A7 / 2), _0xD452.Cond.FirstUseEver, _0xD452.ImVec2(0.5, 0.5))
if _0x83B4.force then
_0x83B4.force = false
_0xD452.SetNextWindowSize(_0xD452.ImVec2(835, 500), _0xD452.Cond.Always)
elseif _0x83B4.req then
_0xD452.SetNextWindowSize(_0xD452.ImVec2(_0x83B4.req.w, _0x83B4.req.h), _0xD452.Cond.Always)
_0x83B4.req = nil
else
_0xD452.SetNextWindowSize(_0xD452.ImVec2(_0x8800.win_w, _0x8800.win_h), _0xD452.Cond.FirstUseEver)
end
pcall(_0xD452.SetNextWindowSizeConstraints, _0xD452.ImVec2(700, 400), _0xD452.ImVec2(math.max(700, _0xC51A - 20), math.max(400, _0xB2A7 - 20)))
if _0xD452.Begin(_0x8A46("Arizona Prices##main_window"), _0xC2A7[0] and _0xC2A7 or nil, bit.bor(_0xD452.WindowFlags.NoCollapse, _0xD452.WindowFlags.NoResize, _0xD452.WindowFlags.NoTitleBar, _0xD452.WindowFlags.NoScrollbar, _0xD452.WindowFlags.NoScrollWithMouse)) then
_0xC8E2(_0xD452.GetWindowSize())
local _0x5025 = _0xD452.GetWindowPos()
local _0xA71A, _0x2902 = _0x5025.x + _0x83B4.w / 2, _0x5025.y + _0x83B4.h / 2
_0x27B6.typing = _0xD452.GetIO().WantTextInput_0x2276(_0x5025)
_0xD452.SetCursorPos(_0xD452.ImVec2(5, 5))
_0x1C05(_0x0833.CIRCLE_DOLLAR .. _0x8A46(" Arizona Prices"), 1,"Таблица цен предметов (клавиша 1)\nCtrl+F - быстрый поиск")
_0x1C05(_0xDC1B("CALCULATOR","") .." Калькулятор", 2,"Калькулятор с историей (клавиша 2)")
_0x1C05(_0xDC1B("CLOCK","") .." Отчет до PayDay", 3,"Таймер до PayDay на экране (клавиша 3)")
_0x1C05(_0xDC1B("COMMENT_DOTS","") .." Фразы", 4,"Быстрые фразы в чат (клавиша 4)")
_0x1C05(_0xDC1B("NOTE_STICKY","") .." Заметки", 8,"Ваши заметки (клавиша 5)")
_0x1C05(_0xDC1B("GLOBE","") .." Время стран", 6,"Время в других странах (клавиша 6)")
_0x1C05(_0xDC1B("CIRCLE_INFO","") .." О скрипте", 5,"Соцсети и разработчик (клавиша 7)")
_0x1C05(_0xDC1B("GEAR","") .." Настройки", 7,"Тема, шрифт, прозрачность (клавиша 8)")
_0xB6FD.draw_bar(_0x5025)
_0xCBA5()local _0x383B = _0x997A((_0xD452.GetTime() - _0xB6FD.tab_t) / 0.30, 0, 1)
local _0x36E4 = 1 - (1 - _0x383B) ^ 3
local _0x7974 = (1 - _0x36E4) * 30
_0xB6FD.base = _0xB6FD.alpha * _0x36E4
_0xB6FD.set_alpha(_0xB6FD.base)
_0xD452.SetCursorPos(_0xD452.ImVec2(_0x67A4 + _0x7974, 0))
local _0xEC1E = _0xD452.WindowFlags.AlwaysUseWindowPadding or 0
if not (_0xE6E2 == 2 and (_0x83B4.h < 495 or _0x83B4.w < 830)) then
_0xEC1E = bit.bor(_0xEC1E, _0xD452.WindowFlags.NoScrollbar, _0xD452.WindowFlags.NoScrollWithMouse)
end
local _0x191E = _0xD452.BeginChild("##content", _0xD452.ImVec2(_0x83B4.w - _0x67A4 - _0x7974, _0x83B4.h), false, _0xEC1E)
if _0x191E then
if _0x8800.bg_fx then pcall(_0xB6FD.draw_bg) end
if _0x8800.halloween then _0xB6FD.hw_safe(_0xB6FD.hw_bg) end
if _0xE6E2 == 1 then
_0xD452.AlignTextToFramePadding()
_0xD452.SetCursorPosX(9)
local _0xF61A = _0xD452.GetCursorScreenPos()
_0xD452.Text(_0x0833.CIRCLE_DOLLAR .. _0x8A46(' Arizona Prices'))
if _0xD452.IsItemHovered() then
local _0xB901, _0x38C4 = _0xD452.GetItemRectMin(), _0xD452.GetItemRectMax()
_0xD452.GetWindowDrawList():AddLine(_0xD452.ImVec2(_0xB901.x, _0x38C4.y), _0xD452.ImVec2(_0x38C4.x, _0x38C4.y), _0xEB5D(_0x8800.accent[1], _0x8800.accent[2], _0x8800.accent[3], 1), 1.5)
_0xD452.SetTooltip("Открыть наш Telegram-канал @arizona_prices")
if _0xD452.IsMouseClicked(0) then _0x2A70("https://t.me/arizona_prices") end
end
_0xD452.SameLine(140)
_0xD452.SetNextItemWidth(math.max(90, _0x83B4.w - _0x67A4 - 329))
if _0xB6FD.focus_search then
_0xD452.SetKeyboardFocusHere()
_0xB6FD.focus_search = false
end
_0xD452.InputTextWithHint("##search", _0x0833.MAGNIFYING_GLASS .." Поиск", _0xAF5C, _0x2A38.sizeof(_0xAF5C))
_0xD452.SameLine()
_0xD452.SetNextItemWidth(150)
local _0xA586 = {"По умолчанию","Сначала дорогие","Сначала дешёвые","По алфавиту"}
local _0xB716 = _0xA586[_0xCBFB[0] + 1] or"Сортировка"if _0xD452.BeginCombo("##sort_combo", _0xB716) then
for _0x7AB2, _0x9851 in ipairs(_0xA586) do
local _0x7857 = _0xCBFB[0] == (_0x7AB2 - 1)
if _0xD452.Selectable(_0x9851, _0x7857) then
_0xCBFB[0] = _0x7AB2 - 1
end
if _0x7857 then
_0xD452.SetItemDefaultFocus()
end
end
_0xD452.EndCombo()
end
_0xD452.SameLine(_0x83B4.w - _0x67A4 - 29)
_0xD452.PushStyleColor(_0xD452.Col.Button, _0xD452.ImVec4(0, 0, 0, 0))
if _0xD452.Button(_0x0833.CIRCLE_XMARK .."##close", _0xD452.ImVec2(24, 24)) then
_0xC2A7[0] = false
end
if _0xD452.IsItemHovered() then _0xD452.SetTooltip("Закрыть") end
_0xD452.PopStyleColor(1)
_0xD452.Spacing()
local _0xF560 = _0x2A38.string(_0xAF5C)
if _0xF560 ~= _0xB6FD.last_q or _0xCBFB[0] ~= _0xB6FD.last_sort then
_0xB6FD.last_q, _0xB6FD.last_sort = _0xF560, _0xCBFB[0]
_0xB6FD.table_t = _0xD452.GetTime()
end
if not _0xB6FD.hint_shown then
_0xB6FD.hint_shown = true
_0x75BC("Подсказка: правая кнопка мыши по предмету - быстрые действия, звёздочка - избранное","info", 7)
end
if _0xD452.BeginChild("##table_child", _0xD452.ImVec2(-1, _0x83B4.h - 79), true) then
local _0xDEAB = _0xD452.GetStyle()
local _0xC272 = _0xD452.GetCursorScreenPos().x
local _0x3CF1 = _0xD452.GetCursorScreenPos().y - _0xDEAB.WindowPadding.y
local _0x3CED = _0xDEAB.ItemSpacing.y
local _0x3DBE = 110
local _0x1292, _0x5783, _0x5275 = 140, 120, _0x5E6F.on and 108 or 44
local _0x4F14 = math.max(110, math.floor(_0xD452.GetContentRegionAvail().x) - (_0x3DBE + _0x1292 + _0x5783 + _0x5275))
_0xD452.Columns(5,"item_table", false)
_0xD452.SetColumnWidth(0, _0x4F14)
_0xD452.SetColumnWidth(1, _0x3DBE)
_0xD452.SetColumnWidth(2, _0x1292)
_0xD452.SetColumnWidth(3, _0x5783)
_0xD452.SetColumnWidth(4, _0x5275)
do
local _0x8605 = _0xD452.CalcTextSize("Предмет")
_0xD452.SetCursorPosX(_0xD452.GetCursorPosX() + math.max(0, (_0x4F14 - _0x8605.x) * 0.5))
_0xD452.TextColored(_0x6FB3(1.3),"Предмет")
end
_0xD452.NextColumn()
do
local _0x8605 = _0xD452.CalcTextSize("Ликвидность")
_0xD452.SetCursorPosX(_0xD452.GetCursorPosX() + math.max(0, (_0x3DBE - _0x8605.x) * 0.5))
_0xD452.TextColored(_0x6FB3(1.3),"Ликвидность")
end
_0xD452.NextColumn()
do
local _0x8605 = _0xD452.CalcTextSize("Скупочная цена")
_0xD452.SetCursorPosX(_0xD452.GetCursorPosX() + math.max(0, (_0x1292 - _0x8605.x) * 0.5))
_0xD452.TextColored(_0x6FB3(1.3),"Скупочная цена")
end
_0xD452.NextColumn()
do
local _0x8605 = _0xD452.CalcTextSize("Продажа")
_0xD452.SetCursorPosX(_0xD452.GetCursorPosX() + math.max(0, (_0x5783 - _0x8605.x) * 0.5))
_0xD452.TextColored(_0x6FB3(1.3),"Продажа")
end
_0xD452.NextColumn()
do
local _0x8605 = _0xD452.CalcTextSize("Действия")
_0xD452.SetCursorPosX(_0xD452.GetCursorPosX() + math.max(0, (_0x5275 - _0x8605.x) * 0.5))
_0xD452.TextColored(_0x6FB3(1.3),"Действия")
end
_0xD452.NextColumn()
_0xD452.Separator()
local _0x0A0E = _0xD452.GetCursorScreenPos().y - _0x3CED - 1.0
local _0xAF4B = {}
local _0x1B49 = _0x4D89(_0x2A38.string(_0xAF5C))
for _0x7AB2, _0x3C2B in ipairs(_0xC12B) do
local _0xE753 = _0x4D89(_0x3C2B.item or"")
if _0x1B49 ==""or _0xE753:find(_0x1B49, 1, true) then
table.insert(_0xAF4B, _0x7AB2)
end
end
if _0xCBFB[0] == 1 then
table.sort(_0xAF4B, function(_0xF1FB, _0x385E) return tonumber(_0xC12B[_0xF1FB].sell or 0) > tonumber(_0xC12B[_0x385E].sell or 0) end)
elseif _0xCBFB[0] == 2 then
table.sort(_0xAF4B, function(_0xF1FB, _0x385E) return tonumber(_0xC12B[_0xF1FB].sell or 0) < tonumber(_0xC12B[_0x385E].sell or 0) end)
elseif _0xCBFB[0] == 3 then
table.sort(_0xAF4B, function(_0xF1FB, _0x385E) local _0x1002 = (_0xC12B[_0xF1FB].item or""):lower() local _0x436F = (_0xC12B[_0x385E].item or""):lower() return _0x1002 < _0x436F end)
end
if next(_0xD488.favs) thenlocal _0x44D5, _0xBD2C = {}, {}
for _0x11D3, ix in ipairs(_0xAF4B) do
if _0xC12B[ix] and _0xD488.favs[_0xC12B[ix].item] then
_0x44D5[#_0x44D5 + 1] = ix
else
_0xBD2C[#_0xBD2C + 1] = ix
end
end
for _0x11D3, ix in ipairs(_0xBD2C) do _0x44D5[#_0x44D5 + 1] = ix end
_0xAF4B = _0x44D5
end
local _0x2310 = _0xD452.GetTime()
for ri, _0x0FEB in ipairs(_0xAF4B) do
local _0x2A2B = _0xC12B[_0x0FEB]
if _0x2A2B then
local _0x68DF = _0xD452.GetCursorPosY()
local _0xB13B = _0x997A((_0x2310 - _0xB6FD.table_t - math.min(ri, 14) * 0.03) / 0.22, 0, 1)
_0xB6FD.set_alpha(_0xB6FD.base * _0xB13B)
do
local _0xCD6D = _0xD452.GetCursorScreenPos()
local _0x5C96 = _0xC272 + _0x4F14 + _0x3DBE + _0x1292 + _0x5783 + _0x5275
local _0xB901, _0x38C4 = _0xD452.ImVec2(_0xC272, _0xCD6D.y - 2), _0xD452.ImVec2(_0x5C96, _0xCD6D.y + 27)
local _0x4A02 = _0xD452.IsMouseHoveringRect(_0xB901, _0x38C4)
if _0x4A02 and _0xD452.IsWindowHovered() and _0xD452.IsMouseClicked(1) then
_0x5B27 = _0x2A2B.item
_0xB6FD.ctx_open = true
end
if _0x4A02 and _0xD452.IsWindowHovered() and _0xD452.IsMouseClicked(0) then
_0x5B27 = _0x2A2B.item
end
if _0x5B27 ~= nil and _0x2A2B.item == _0x5B27 then
_0xD452.GetWindowDrawList():AddRectFilled(_0xB901, _0x38C4, _0xEB5D(_0x8800.accent[1], _0x8800.accent[2], _0x8800.accent[3], 0.30), 6)
elseif _0x4A02 then
_0xD452.GetWindowDrawList():AddRectFilled(_0xB901, _0x38C4, _0xEB5D(_0x8800.accent[1], _0x8800.accent[2], _0x8800.accent[3], 0.14), 6)
elseif ri % 2 == 0 then
_0xD452.GetWindowDrawList():AddRectFilled(_0xB901, _0x38C4, _0xEB5D(1, 1, 1, 0.025), 6)
end
end
local _0x2CB0 = _0x2A2B.item or""local _0x8605 = _0xD452.CalcTextSize(_0x2CB0)
_0xD452.SetCursorPosY(_0x68DF + math.max(0, (24 - _0x8605.y) * 0.5))
local _0xD35D = _0xD452.CalcTextSize(_0x0833.CIRCLE_QUESTION).x
local _0xFE49 = _0x4F14 - _0xD35D - 12
if _0x8605.x > _0xFE49 then
local _0x3FA6 = _0x2CB0
while #_0x3FA6 > 3 and _0xD452.CalcTextSize(_0x3FA6 .."...").x > _0xFE49 do
local _0x5D5E = #_0x3FA6
local _0x4220 = _0x5D5E
while _0x4220 > 0 and _0x3FA6:byte(_0x4220) >= 128 and _0x3FA6:byte(_0x4220) < 192 do
_0x4220 = _0x4220 - 1
end
_0x3FA6 = _0x3FA6:sub(1, _0x4220 - 1)
end
_0x3FA6 = _0x3FA6 .."..."_0xD452.Text(_0x3FA6)
if _0xD452.IsItemHovered() then _0xD452.SetTooltip((_0x2CB0:gsub("%%","%%%%"))) end
_0xD452.SameLine(_0x4F14 - _0xD35D - 6)
_0xD452.Text(_0x0833.CIRCLE_QUESTION)
if _0xD452.IsItemHovered() then _0xD452.SetTooltip((_0x2CB0:gsub("%%","%%%%"))) end
else
_0xD452.SetCursorPosX(_0xD452.GetCursorPosX() + math.max(0, (_0x4F14 - _0x8605.x) * 0.5))
_0xD452.TextUnformatted(_0x2CB0)
end
_0xD452.NextColumn()
do
local _0xF92D = _0x2A2B.liq
local _0x2612 = _0xF92D or"-"local _0x6482 = _0xB6FD.liq_color(_0xF92D)
if _0x5E6F.on then_0xD452.SetCursorPosY(_0x68DF)
_0xD452.PushStyleColor(_0xD452.Col.Text, _0x6482)
if _0xD452.Button(_0x2612 .."##liq_".. _0x0FEB, _0xD452.ImVec2(_0x3DBE - 14, 24)) then
_0x2A2B.liq = _0xB6FD.liq_next(_0xF92D)
_0x4A95()
end
_0xD452.PopStyleColor(1)
else
local _0x8605 = _0xD452.CalcTextSize(_0x2612)
_0xD452.SetCursorPosY(_0x68DF + math.max(0, (24 - _0x8605.y) * 0.5))
_0xD452.SetCursorPosX(_0xD452.GetCursorPosX() + math.max(0, (_0x3DBE - _0x8605.x) * 0.5))
_0xD452.TextColored(_0x6482, _0x2612)
end
end
_0xD452.NextColumn()
do
local _0x8605 = _0xD452.CalcTextSize(_0x7B79(_0x2A2B.buy))
_0xD452.SetCursorPosY(_0x68DF + math.max(0, (24 - _0x8605.y) * 0.5))
_0xD452.SetCursorPosX(_0xD452.GetCursorPosX() + math.max(0, (_0x1292 - _0x8605.x) * 0.5))
_0xD452.TextColored(_0xD452.ImVec4(0.55, 0.92, 0.65, 1.0), _0x7B79(_0x2A2B.buy))
end
_0xD452.NextColumn()
do
local _0xE706 = tonumber(_0x2A2B.sell) or 0
local _0x3783 = _0x7B79(_0x2A2B.sell)
local _0x8605 = _0xD452.CalcTextSize(_0x3783)
_0xD452.SetCursorPosY(_0x68DF + math.max(0, (24 - _0x8605.y) * 0.5))
_0xD452.SetCursorPosX(_0xD452.GetCursorPosX() + math.max(0, (_0x5783 - _0x8605.x - 20) * 0.5))
_0xD452.TextColored(_0xD452.ImVec4(1.0, 0.85, 0.45, 1.0), _0x3783)
local _0xD35D = _0xD452.CalcTextSize(_0x0833.BADGE_PERCENT).x
_0xD452.SameLine(_0x5783 - _0xD35D - 6)
_0xD452.Text(_0x0833.BADGE_PERCENT)
if _0xD452.IsItemHovered() then
_0xD452.SetTooltip("1%% - ".. _0x7B79(math.floor(_0xE706 * 0.99 + 0.5)) .."\n".."3%% - ".. _0x7B79(math.floor(_0xE706 * 0.97 + 0.5)) .."\n".."4%% - ".. _0x7B79(math.floor(_0xE706 * 0.96 + 0.5)) .."\n".."5%% - ".. _0x7B79(math.floor(_0xE706 * 0.95 + 0.5)))
end
end
_0xD452.NextColumn()
local _0x468A = _0x5E6F.on and (28 * 3 + 10) or 28
_0xD452.SetCursorPosY(_0x68DF)
_0xD452.SetCursorPosX(_0xD452.GetCursorPosX() + math.max(0, (_0x5275 - _0x468A) * 0.5))
local _0xC627 = _0xD488.favs[_0x2A2B.item] == true
_0xD452.PushStyleColor(_0xD452.Col.Text, _0xC627 and _0xD452.ImVec4(1.0, 0.82, 0.25, 1.0) or _0xD452.ImVec4(0.50, 0.52, 0.58, 1.0))
if _0xD452.Button(_0xDC1B("STAR","*") .."##fav_".. _0x0FEB, _0xD452.ImVec2(28, 24)) then
_0xB6FD.toggle_fav(_0x2A2B.item)
end
_0xD452.PopStyleColor(1)
if _0xD452.IsItemHovered() then _0xD452.SetTooltip(_0xC627 and"Убрать из избранного"or"В избранное") end
if _0x5E6F.on then
_0xD452.SameLine()
if _0xD452.Button(_0x0833.PEN_LINE .."##edit_".. _0x0FEB, _0xD452.ImVec2(28, 24)) then
_0xB174(_0x0FEB)
end
_0xD452.SameLine()
if _0xD452.Button(_0x0833.TRASH_CAN .."##del_".. _0x0FEB, _0xD452.ImVec2(28, 24)) then
_0xE5A5 = _0x0FEB
_0xA336 = true
end
end
_0xD452.NextColumn()
_0xD452.Separator()
_0x0A0E = _0xD452.GetCursorScreenPos().y - _0x3CED - 1.0
end
end
_0xD452.Columns(1)
_0xB6FD.set_alpha(_0xB6FD.base)
if _0xB6FD.ctx_open then
_0xD452.OpenPopup("##row_ctx")
_0xB6FD.ctx_open = false
end
if _0xD452.BeginPopup("##row_ctx") then
local _0x572C
for _0x11D3, _0x3C2B in ipairs(_0xC12B) do
if _0x3C2B.item == _0x5B27 then _0x572C = _0x3C2B; break end
end
if _0x572C then
local _0x9D1B = _0x572C.item ..": скупка ".. _0x7B79(_0x572C.buy) .." / продажа ".. _0x7B79(_0x572C.sell)
_0xD452.TextColored(_0x6FB3(1.3), _0x572C.item)
_0xD452.Separator()
if _0xD452.Selectable(_0xDC1B("COMMENT_DOTS","") .."  Вставить в строку чата##ctx_chat") then
_0xEECB(function()
sampSetChatInputEnabled(true)
sampSetChatInputText(_0x8A46:decode(_0x9D1B))
end)
end
if _0xD452.Selectable(_0xDC1B("COPY","") .."  Скопировать в буфер##ctx_copy") then
_0xD452.SetClipboardText(_0x9D1B)
_0x75BC("Скопировано: ".. _0x9D1B,"ok", 4)
end
local _0xA447 = _0xD488.favs[_0x572C.item] == true
if _0xD452.Selectable(_0xDC1B("STAR","*") .. (_0xA447 and"  Убрать из избранного"or"  В избранное") .."##ctx_fav") then
_0xB6FD.toggle_fav(_0x572C.item)
end
else
_0xD452.Text("Предмет не найден")
end
_0xD452.EndPopup()
end
if _0x0A0E > _0x3CF1 then
local _0xF75C = _0xD452.GetWindowDrawList()
local _0x83CA = _0xD452.GetColorU32(_0xD452.Col.Separator)
local _0xB7FE = _0xC272
local _0xA5B9 = {_0x4F14, _0x3DBE, _0x1292, _0x5783}
for _0x7AB2 = 1, 4 do
_0xB7FE = _0xB7FE + _0xA5B9[_0x7AB2]
_0xF75C:AddLine(_0xD452.ImVec2(_0xB7FE, _0x3CF1), _0xD452.ImVec2(_0xB7FE, _0x0A0E), _0x83CA, 1.0)
end
end
_0xD452.EndChild()
end
local _0x68D1 = _0xD452.GetContentRegionAvail().x - 95
if _0x5E6F.on then
if _0xD452.Button(_0x0833.CIRCLE_PLUS .." Добавить предмет", _0xD452.ImVec2(_0x68D1, 30)) then
_0x4DC9()
end
else
if _0xD452.Button(_0xDC1B("PAPER_PLANE","") .." Актуальные цены - в нашем ТГК @arizona_prices##open_tg", _0xD452.ImVec2(_0x68D1, 30)) then
_0x2A70("https://t.me/arizona_prices")
end
end
_0xD452.SameLine()
if _0xD452.Button(_0x0833.TRIANGLE_EXCLAMATION .."##report_prices", _0xD452.ImVec2(30, 30)) then
if _0x5B27 and _0x5B27 ~=""then
_0xD452.SetClipboardText("Привет. Заметил что цена предмета \"".. _0x5B27 .."\" изменилась, прошу обновить")
_0x2A70("https://t.me/xi_vivide")
_0x75BC("Сообщение скопировано - вставьте его в чат (Ctrl+V)","ok", 6)
else
_0x75BC("Сначала нажмите на предмет в таблице, цена которого устарела","warn", 5)
end
end
if _0xD452.IsItemHovered() then _0xD452.SetTooltip("Сообщить об устаревших ценах\n(сначала нажмите на предмет в таблице)") end
_0xD452.SameLine()
if _0xD452.Button(_0x0833.BUG .."##report_bug", _0xD452.ImVec2(30, 30)) then
_0xFCEE()
end
if _0xD452.IsItemHovered() then _0xD452.SetTooltip("Сообщить о баге (скопирует данные для разработчика)") end
if _0x9AF0 then
_0xD452.OpenPopup(_0xD7A8 and _0x6895 or _0x7FD1)
_0x9AF0 = false
end
if _0x2D04[0] then
local _0x6640 = _0xD7A8 and _0x6895 or _0x7FD1
_0xD452.SetNextWindowPos(_0xD452.ImVec2(_0xA71A, _0x2902), _0xD452.Cond.Always, _0xD452.ImVec2(0.5, 0.5))
_0xD452.SetNextWindowSize(_0xD452.ImVec2(300, 171), _0xD452.Cond.Always)
if _0xD452.BeginPopupModal(_0x6640, _0x2D04, bit.bor(_0xD452.WindowFlags.NoCollapse, _0xD452.WindowFlags.NoResize)) then
local _0x30EA = _0x0833.LAYER_GROUP .." Предмет"local _0x7755 = _0x0833.HANDS_HOLDING_DOLLAR .." Скупочная цена"local _0xC20E = _0x0833.HAND_HOLDING_DOLLAR .." Продажа"if _0x2CB1 then
local _0xDEB5 = os.clock() - _0x460F
if _0xDEB5 >= 1.2 then
_0x2CB1 = false
else
local _0xA52D = (_0xDEB5 % 0.4) < 0.2
if _0x08EC and _0xA52D then _0x30EA =""end
if _0x2A09 and _0xA52D then _0x7755 =""end
if _0x553F and _0xA52D then _0xC20E =""end
end
end
if _0xD452.BeginChild("##modal", _0xD452.ImVec2(-1, 102), true) then
_0xD452.SetNextItemWidth(-1)
_0xD452.InputTextWithHint("##modal_item", _0x30EA, _0x0AD7, _0x2A38.sizeof(_0x0AD7))
_0xD452.Separator()
_0xD452.SetNextItemWidth(-1)
_0xD452.InputTextWithHint("##modal_buy", _0x7755, _0x227D, _0x2A38.sizeof(_0x227D), _0xD452.InputTextFlags.CharsDecimal)
_0xD452.Separator()
_0xD452.SetNextItemWidth(-1)
_0xD452.InputTextWithHint("##modal_sell", _0xC20E, _0x86B7, _0x2A38.sizeof(_0x86B7), _0xD452.InputTextFlags.CharsDecimal)
_0xD452.EndChild()
end
if _0xD7A8 then
if _0xD452.Button(_0x0833.FLOPPY_DISK .." Сохранить", _0xD452.ImVec2(142, 30)) then
local _0xE234 = _0x2A38.string(_0x0AD7)
local _0x7E18 = _0x2A38.string(_0x227D)
local _0x6AEF = _0x2A38.string(_0x86B7)
_0x08EC = (_0xE234 =="")
_0x2A09 = (_0x7E18 =="")
_0x553F = (_0x6AEF =="")
if _0x08EC or _0x2A09 or _0x553F then
_0x2CB1 = true
_0x460F = os.clock()
else
local _0x9851 = _0xE234
local _0x49E1 = tonumber(_0x7E18)
local _0x8AAB = tonumber(_0x6AEF)
if _0x49E1 and _0x8AAB and _0x0BED and _0xC12B[_0x0BED] then
_0xC12B[_0x0BED] = {_0x2A2B = _0x9851, _0x49E1 = _0x49E1, _0x8AAB = _0x8AAB, _0xF92D = _0xC12B[_0x0BED].liq}
_0x4A95()
_0xAE5A()
end
end
end
_0xD452.SameLine()
if _0xD452.Button(_0x0833.CIRCLE_XMARK .." Отменить", _0xD452.ImVec2(142, 30)) then
_0xAE5A()
end
else
if _0xD452.Button(_0x0833.CIRCLE_PLUS .." Добавить", _0xD452.ImVec2(-1, 30)) then
local _0xE234 = _0x2A38.string(_0x0AD7)
local _0x7E18 = _0x2A38.string(_0x227D)
local _0x6AEF = _0x2A38.string(_0x86B7)
_0x08EC = (_0xE234 =="")
_0x2A09 = (_0x7E18 =="")
_0x553F = (_0x6AEF =="")
if _0x08EC or _0x2A09 or _0x553F then
_0x2CB1 = true
_0x460F = os.clock()
else
local _0x9851 = _0xE234
local _0x49E1 = tonumber(_0x7E18)
local _0x8AAB = tonumber(_0x6AEF)
if _0x49E1 and _0x8AAB then
table.insert(_0xC12B, {_0x2A2B = _0x9851, _0x49E1 = _0x49E1, _0x8AAB = _0x8AAB})
_0x4A95()
_0xAE5A()
end
end
end
end
_0xD452.EndPopup()
end
end
if _0xA336 then
_0xD452.OpenPopup(_0x0833.TRASH_CAN ..' Подтверждение удаления##delete_modal')
_0xA336 = false
end
_0xD452.SetNextWindowPos(_0xD452.ImVec2(_0xA71A, _0x2902), _0xD452.Cond.Always, _0xD452.ImVec2(0.5, 0.5))
_0xD452.SetNextWindowSize(_0xD452.ImVec2(415, 88), _0xD452.Cond.Always)
if _0xD452.BeginPopupModal(_0x0833.TRASH_CAN ..' Подтверждение удаления##delete_modal', nil, bit.bor(_0xD452.WindowFlags.NoCollapse, _0xD452.WindowFlags.NoResize)) then
_0xD452.TextWrapped(_0x0833.CIRCLE_QUESTION ..' Вы действительно хотите удалить этот предмет из справочника?')
_0xD452.Spacing()
if _0xD452.Button(_0x0833.TRASH_CAN ..' Да, удалить', _0xD452.ImVec2(200, 30)) then
if _0xE5A5 and _0xC12B[_0xE5A5] then
table.remove(_0xC12B, _0xE5A5)
_0x4A95()
end
_0xE5A5 = nil
_0xD452.CloseCurrentPopup()
end
_0xD452.SameLine()
if _0xD452.Button(_0x0833.CIRCLE_XMARK ..' Отменить', _0xD452.ImVec2(200, 30)) then
_0xE5A5 = nil
_0xD452.CloseCurrentPopup()
end
_0xD452.EndPopup()
end
elseif _0xE6E2 == 2 then
_0xCE5F()
else
_0x0BEF(_0xE6E2)
end
end
if _0x191E then pcall(_0xF88C) end
_0xD452.EndChild()
_0xB6FD.set_alpha(_0xB6FD.alpha)
_0xB6FD.draw_splash(_0x5025)
_0x99D9(_0x5025.x, _0x5025.y, _0x5025.x + _0x83B4.w, _0x5025.y + _0x83B4.h)
_0xD452.End()
else
_0xD452.End()
end
_0xB6FD.set_alpha(1)
end
end, function() _0xC2A7[0] = false; _0x2D04[0] = false; _0x27B6.binding = false; _0xB6FD.alpha = 0; _0xB6FD.set_alpha(1) end)
)_0xD452.OnFrame(function() return _0x21DF[0] end, _0xFBE9("outdated", function()
local _0xC51A, _0xB2A7 = getScreenResolution()
_0xD452.SetNextWindowPos(_0xD452.ImVec2(_0xC51A / 2, _0xB2A7 / 2), _0xD452.Cond.Always, _0xD452.ImVec2(0.5, 0.5))
_0xD452.SetNextWindowSize(_0xD452.ImVec2(580, 290), _0xD452.Cond.Always)
_0xD452.SetNextWindowFocus()
local _0x1D09 = bit.bor(_0xD452.WindowFlags.NoTitleBar, _0xD452.WindowFlags.NoResize, _0xD452.WindowFlags.NoMove,
_0xD452.WindowFlags.NoCollapse, _0xD452.WindowFlags.NoScrollbar, _0xD452.WindowFlags.NoSavedSettings)_0xD452.PushStyleColor(_0xD452.Col.WindowBg, _0xD452.ImVec4(0.075, 0.07, 0.095, 1.0))
_0xD452.Begin("##outdated_window", nil, _0x1D09)
local _0x0A19 = _0xD452.GetWindowPos()
_0xD452.GetWindowDrawList():AddRectFilled(_0x0A19, _0xD452.ImVec2(_0x0A19.x + 580, _0x0A19.y + 5), _0xD452.ColorConvertFloat4ToU32(_0xD452.ImVec4(1.00, 0.75, 0.15, 1.00)))
_0xD452.SetCursorPos(_0xD452.ImVec2(24, 28))
_0xD452.SetWindowFontScale(1.9)
_0xD452.TextColored(_0xD452.ImVec4(1.00, 0.80, 0.20, 1.00), _0xDC1B("TRIANGLE_EXCLAMATION","") .." Внимание!")
_0xD452.SetWindowFontScale(1.0)
_0xD452.SetCursorPos(_0xD452.ImVec2(24, 90))
_0xD452.SetWindowFontScale(1.3)
_0xD452.PushTextWrapPos(556)
_0xD452.TextWrapped("У вас старая версия скрипта. Обновите для комфортного использования.")
_0xD452.PopTextWrapPos()
_0xD452.SetWindowFontScale(1.0)
_0xD452.SetCursorPos(_0xD452.ImVec2(24, 160))
_0xD452.TextDisabled("Ваша версия: ".. _0xBC05 .."    Новая версия: ".. _0xAB2A.version)
if _0xAB2A.status ~=""then
_0xD452.SetCursorPosX(24)
_0xD452.TextDisabled(_0xAB2A.status)
end
_0xD452.SetCursorPos(_0xD452.ImVec2(24, 290 - 24 - 44))
local _0x0AA7 = (580 - 48 - 10) / 2
_0xD452.PushStyleColor(_0xD452.Col.Button, _0x6FB3(1.0))
_0xD452.PushStyleColor(_0xD452.Col.ButtonHovered, _0x6FB3(1.15))
_0xD452.PushStyleColor(_0xD452.Col.ButtonActive, _0x6FB3(0.85))
if _0xAB2A.busy then
_0xD452.Button("Скачивание...##outdated_busy", _0xD452.ImVec2(_0x0AA7, 44))
elseif _0xD452.Button(_0xDC1B("DOWNLOAD","") .." Обновить##outdated_update", _0xD452.ImVec2(_0x0AA7, 44)) then
_0xB61C()
end
_0xD452.PopStyleColor(3)
_0xD452.SameLine()
if _0xD452.Button(_0x0833.CIRCLE_XMARK .." Закрыть##outdated_close", _0xD452.ImVec2(_0x0AA7, 44)) then
_0x21DF[0] = false
end
_0xD452.End()
_0xD452.PopStyleColor(1)
end, function() _0x21DF[0] = false end))
function main()
while not isSampAvailable() do wait(0) end
_0x3271("load_data", _0xF4C6)
sampAddChatMessage(_0x8A46:decode("{33AAFF}[Arizona Prices V2.0] {FFFFFF}Скрипт успешно загружен! Для активации - {33AAFF}/prices{FFFFFF}. ТГК - {33AAFF}@arizona_prices"), -1)
sampRegisterChatCommand('prices', _0x6898)
sampRegisterChatCommand('pradmin', function(arg)
arg = tostring(arg or""):gsub("%s","")
if arg =="off"then
_0x5E6F.disable()
sampAddChatMessage(_0x8A46:decode("{33AAFF}[Arizona Prices] {FFFFFF}Режим разработчика выключен"), -1)
elseif arg ~=""and _0x5E6F.enable(arg) then
sampAddChatMessage(_0x8A46:decode("{33AAFF}[Arizona Prices] {55FF55}Режим разработчика включён{FFFFFF}. Правка цен и ликвидности открыта"), -1)
else
sampAddChatMessage(_0x8A46:decode("{33AAFF}[Arizona Prices] {FF5555}Неверный код"), -1)
end
end)
addEventHandler('onWindowMessage', function(msg, wparam, lparam)
_0x3271("hotkey", _0xE643, msg, wparam, lparam)
end)
local _0x8790 = os.time() + 5
while true do
wait(100)
if _0x7C6A then
local _0xC781 = _0x7C6A
_0x7C6A = nil
pcall(function() _0x4D27.ShellExecuteA(nil,"open", _0xC781, nil, nil, 1) end)
end
while #_0x35B6 > 0 do
_0x3271("action", table.remove(_0x35B6, 1))
end
if not _0xC2A7[0] and _0x27B6.binding then _0x27B6.binding = false end
_0x3271("updates", _0xF7AB)
if #_0x84CA > 0 then
local _0x72E2 = table.remove(_0x84CA, 1)
_0x3271("notice", _0x75BC, _0x72E2.text, _0x72E2.kind)
end
_0x3271("save_ui", _0xD1D5)
if os.time() >= _0x8790 then
_0x8790 = os.time() + _0xEE92
_0x3271("start_checks", _0x5792)
end
if _0x9C59 then
_0x9C59 = false
wait(700)
thisScript():reload()
end
end
end
function onScriptTerminate(scr, quit)
if scr == thisScript() then
pcall(_0xD1D5, true)
end
end