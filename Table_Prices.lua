local ffi = require('ffi')
local encoding = require('encoding')
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local SCRIPT_VERSION = "3.7" -- Метка для старых версий

-- Проверка библиотек: если чего-то не хватает, скрипт не вылетает с непонятной ошибкой,
-- а пишет в чат, что именно нужно установить
local ok_imgui, imgui = pcall(require, 'mimgui')
local ok_fa, fa = pcall(require, 'fAwesome6')
if not ok_imgui or not ok_fa then
    local missing = {}
    if not ok_imgui then missing[#missing + 1] = "mimgui" end
    if not ok_fa then missing[#missing + 1] = "fAwesome6" end
    function main()
        while not isSampAvailable() do wait(100) end
        sampAddChatMessage(u8:decode("{FF5555}[Arizona Prices] {FFFFFF}Не найдены библиотеки: {FFCC33}" .. table.concat(missing, ", ") .. "{FFFFFF}. Положите их в папку {FFCC33}moonloader\\lib{FFFFFF} и перезапустите игру."), -1)
        sampAddChatMessage(u8:decode("{FF5555}[Arizona Prices] {FFFFFF}Где скачать, смотрите в нашем ТГК: {33AAFF}@arizona_prices"), -1)
        thisScript():unload()
    end
    return
end

-- иконки: если в вашей версии fAwesome6 такой иконки нет, будет пустое место, а не вылет скрипта
local FA = setmetatable({}, { __index = function(_, k) return fa[k] or "" end })

ffi.cdef[[
    int ShellExecuteA(void* hwnd, const char* op, const char* file, const char* params, const char* dir, int show);
]]
local shell32 = ffi.load('shell32')
local pending_url = nil
-- ссылка открывается не прямо из кадра отрисовки (это могло ронять игру), а из основного потока
local function open_url(url)
    pending_url = url
end

local main_window = imgui.new.bool(false) 
local modal_window = imgui.new.bool(false) 
local MODAL_ID_ADD = FA.CIRCLE_PLUS .. " Добавить предмет###item_modal"
local MODAL_ID_EDIT = FA.PEN_LINE .. " Редактировать предмет###item_modal"

local buf_search = imgui.new.char[256]() 
local buf_item = imgui.new.char[256]() 
local buf_buy = imgui.new.char[64]() 
local buf_sell = imgui.new.char[64]()

local current_sort = imgui.new.int(0) 
local is_editing = false 
local edit_index = nil 
local pending_modal_open = false 
local pending_delete_open = false 
local pending_delete_index = nil
local selected_item_name = nil -- строка таблицы, на которую нажали (для «Сообщить об устаревших ценах»)
local is_blinking = false 
local blink_start_time = 0

local empty_item_field = false 
local empty_buy_field = false 
local empty_sell_field = false 
local items_list = {} 
local datadir = getWorkingDirectory() .. "\\config\\item_prices.json"

-- ===================== Защита данных и журнал ошибок =====================
local pending_notices = {}
local function queue_notice(text, kind)
    pending_notices[#pending_notices + 1] = { text = text, kind = kind }
end

local err_log = {}
local function tb(e)
    return debug.traceback(tostring(e), 2)
end

local function log_error(where, err)
    local text = tostring(err)
    err_log[#err_log + 1] = os.date("%H:%M:%S") .. " [" .. tostring(where) .. "] " .. (text:sub(1, 300):gsub("%s+", " "))
    if #err_log > 8 then table.remove(err_log, 1) end
    pcall(function()
        print("[Arizona Prices] " .. tostring(where) .. ": " .. text)
        local dir = getWorkingDirectory() .. "\\config"
        if not doesDirectoryExist(dir) then createDirectory(dir) end
        local path = dir .. "\\arizona_prices_errors.log"
        local f = io.open(path, "ab")
        if f then
            if (f:seek("end") or 0) > 200000 then
                f:close()
                f = io.open(path, "wb")
            end
            if f then
                f:write(os.date("%Y-%m-%d %H:%M:%S") .. " [" .. tostring(where) .. "] " .. text .. "\n\n")
                f:close()
            end
        end
    end)
end

-- вызов функции без риска уронить скрипт: ошибка попадает в журнал
local function safe_call(where, fn, ...)
    local args = { ... }
    local ok, err = xpcall(function() return fn(unpack(args)) end, tb)
    if not ok then log_error(where, err) end
    return ok
end

-- действия, которые нельзя выполнять прямо из кадра отрисовки (скачивание, отправка в чат):
-- кадр только кладёт их в очередь, выполняет основной поток
local ui_actions = {}
local function defer(fn)
    ui_actions[#ui_actions + 1] = fn
end

-- обёртка для окон: ошибка внутри окна не роняет скрипт, а попадает в журнал
local function guard_frame(name, fn, on_fail)
    return function(...)
        local args = { ... }
        local n = select("#", ...)
        local ok, err = xpcall(function() return fn(unpack(args, 1, n)) end, tb)
        if not ok then
            log_error("frame:" .. name, err)
            queue_notice("Ошибка в окне (" .. name .. "). Откройте Настройки и нажмите «Сообщить об ошибке»", "err")
            if on_fail then pcall(on_fail) end
        end
    end
end

local function read_file_raw(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local c = f:read("*a")
    f:close()
    return c
end

local function write_file_raw(path, content)
    local f = io.open(path, "wb")
    if not f then return false end
    local ok = f:write(content)
    f:close()
    return ok ~= nil and ok ~= false
end

local function json_ok(str)
    if type(str) ~= "string" or str == "" then return false end
    local ok, d = pcall(decodeJson, str)
    return ok and type(d) == "table"
end

-- безопасная запись: сначала во временный файл, проверка, копия старой версии (.bak), потом замена
local function safe_write(path, content)
    if type(content) ~= "string" or content == "" then return false end
    local tmp = path .. ".tmp"
    if not write_file_raw(tmp, content) then os.remove(tmp); return false end
    if read_file_raw(tmp) ~= content then os.remove(tmp); return false end
    local old = read_file_raw(path)
    if old and json_ok(old) then write_file_raw(path .. ".bak", old) end
    os.remove(path)
    if not os.rename(tmp, path) then
        local ok = write_file_raw(path, content)
        os.remove(tmp)
        return ok
    end
    return true
end

-- безопасное чтение: если файл повреждён, берём резервную копию
local function safe_read_json(path)
    local c = read_file_raw(path)
    if json_ok(c) then return decodeJson(c) end
    local b = read_file_raw(path .. ".bak")
    if json_ok(b) then
        if c and c ~= "" then
            queue_notice("Файл данных был повреждён - восстановили из резервной копии", "warn")
            write_file_raw(path .. ".broken", c)
        end
        write_file_raw(path, b)
        return decodeJson(b)
    end
    if c and c ~= "" then
        write_file_raw(path .. ".broken", c)
        queue_notice("Файл данных повреждён и копии нет - начинаем с чистого листа", "err")
    end
    return nil
end

-- ===================== Режим разработчика (правка цен и ликвидности только у владельца) =====================
-- Остальные игроки видят цены только на чтение: их список всегда приводится к списку из нашего канала.
local ADM = {
    on = false,
    HASH = 888940931,
    LIQ = { ["Ликвид"] = true, ["Средне"] = true, ["Неликвид"] = true },
    path = getWorkingDirectory() .. "\\config\\arizona_prices_admin.json",
}

function ADM.hash(code)
    local s = "arzp|" .. tostring(code):lower()
    local h = 5381
    for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967296 end
    return h
end

function ADM.valid_liq(v)
    if type(v) == "string" and ADM.LIQ[v] then return v end
    return nil
end

function ADM.enable(code)
    if ADM.hash(code) ~= ADM.HASH then return false end
    ADM.on = true
    local dir = getWorkingDirectory() .. "\\config"
    if not doesDirectoryExist(dir) then createDirectory(dir) end
    write_file_raw(ADM.path, encodeJson({ hash = ADM.HASH }))
    return true
end

function ADM.disable()
    ADM.on = false
    os.remove(ADM.path)
end

do
    local d = safe_read_json(ADM.path)
    if type(d) == "table" and tonumber(d.hash) == ADM.HASH then ADM.on = true end
end

local function load_data()
    local data = safe_read_json(datadir)
    if data then
        local clean = {}
        for _, v in ipairs(data) do
            if type(v) == "table" then
                clean[#clean + 1] = { item = tostring(v.item or ""), buy = tonumber(v.buy) or 0, sell = tonumber(v.sell) or 0, liq = ADM.valid_liq(v.liq) }
            end
        end
        items_list = clean
    elseif not doesFileExist(datadir) then
        items_list = {}
    end
end

local function save_data()
    local dir = getWorkingDirectory() .. "\\config"
    if not doesDirectoryExist(dir) then
        createDirectory(dir)
    end
    local ok, json = pcall(encodeJson, items_list)
    if ok and type(json) == "string" and json ~= "" then
        if not safe_write(datadir, json) then
            queue_notice("Не удалось сохранить список предметов", "err")
        end
    end
end

local function format_price(amount)
    local num = tonumber(amount)
    if not num then return tostring(amount) end
    local sign = num < 0 and "-" or ""
    num = math.abs(num)
    local s = (num == math.floor(num)) and string.format("%.0f", num) or tostring(num)
    local int, frac = s:match("^(%d+)(.*)$")
    if not int then return sign .. s end
    int = int:reverse():gsub("(%d%d%d)", "%1."):reverse()
    if int:sub(1, 1) == "." then int = int:sub(2) end
    return sign .. int .. frac
end

local function lower_cp1251(str) 
    local dec_ok, dec = pcall(function() return u8:decode(tostring(str or "")) end)
    str = dec_ok and dec or tostring(str or "")
    return (str:gsub(".", function(char) 
        local byte = char:byte() 
        if byte >= 192 and byte <= 223 then 
            return string.char(byte + 32) 
        elseif byte == 168 then 
            return string.char(184) 
        end 
        return char:lower() 
    end)) 
end

local function close_modal() 
    modal_window[0] = false 
    imgui.CloseCurrentPopup() 
end

local function open_add_modal() 
    is_editing = false 
    edit_index = nil 
    imgui.StrCopy(buf_item, "") 
    imgui.StrCopy(buf_buy, "") 
    imgui.StrCopy(buf_sell, "") 
    modal_window[0] = true 
    pending_modal_open = true 
end

local function open_edit_modal(index) 
    local item = items_list[index] 
    if not item then return end 
    is_editing = true 
    edit_index = index
    imgui.StrCopy(buf_item, item.item or "") 
    imgui.StrCopy(buf_buy, tostring(item.buy or 0)) 
    imgui.StrCopy(buf_sell, tostring(item.sell or 0)) 
    modal_window[0] = true 
    pending_modal_open = true
end

-- ===================== Внешний вид (настраивается во вкладке «Настройки») =====================
local UI_CFG = {
    accent = {0.98, 0.55, 0.12}, opacity = 1.0, overlay_scale = 1.0, open_key = 0, toasts = true, toast_corner = 3,
    halloween = true, -- Хэллоуин: фиолетовый фон, тыквы, летучие мыши, паутина
    border_mode = 1, border_speed = 1.0, shadow = true, font = "seguisb",
    win_w = 835, win_h = 500, bg_fx = true, splash = true,
}

-- Все эффекты интерфейса (плавное открытие, анимации вкладок и таблицы, фон, заставка) лежат в одной таблице UIFX
local UIFX = {
    alpha = 0,        -- текущая прозрачность окна (плавно растёт при открытии, падает при закрытии)
    m = 1,            -- множитель прозрачности для ручного рисования (см. col32)
    base = 1,         -- прозрачность содержимого вкладки
    tab_t = -10,      -- момент смены вкладки
    table_t = -10,    -- момент начала каскадной анимации строк таблицы
    was_open = false,
    splashed = false, -- заставка уже показана в этой игровой сессии
    TAB_ORDER = { 1, 2, 3, 4, 5, 7 }, -- порядок вкладок слева (цифры 1-6 на клавиатуре)
}

-- шрифты берём из системной папки Windows (там есть кириллица), ничего скачивать не нужно
local FONT_LIST = {
    { key = "seguisb",     name = "Segoe UI Semibold", file = "seguisb.ttf" },
    { key = "segoeui",     name = "Segoe UI",          file = "segoeui.ttf" },
    { key = "bahnschrift", name = "Bahnschrift",       file = "bahnschrift.ttf" },
    { key = "corbel",      name = "Corbel",            file = "corbel.ttf" },
    { key = "candara",     name = "Candara",           file = "candara.ttf" },
    { key = "calibri",     name = "Calibri",           file = "calibri.ttf" },
    { key = "verdana",     name = "Verdana",           file = "verdana.ttf" },
    { key = "tahoma",      name = "Tahoma",            file = "tahoma.ttf" },
}
local FONT_AVAILABLE = { { key = "default", name = "Системный (Trebuchet)" } }
pcall(function()
    local dir = getFolderPath(0x14)
    for _, f in ipairs(FONT_LIST) do
        local path = dir .. "\\" .. f.file
        if doesFileExist(path) then
            FONT_AVAILABLE[#FONT_AVAILABLE + 1] = { key = f.key, name = f.name, path = path }
        end
    end
end)

local function clamp(x, lo, hi)
    return math.max(lo, math.min(hi, x))
end

local function accent_vec(mult, alpha)
    local a = UI_CFG.accent
    local m = mult or 1.0
    return imgui.ImVec4(math.min(1, a[1] * m), math.min(1, a[2] * m), math.min(1, a[3] * m), alpha or 1.0)
end

-- ===================== Оформление: цвета, рамка с переливами, тень =====================
local function col32(r, g, b, a)
    return imgui.ColorConvertFloat4ToU32(imgui.ImVec4(r, g, b, a * UIFX.m))
end

local function hsv_to_rgb(h, s, v)
    h = h % 1
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then return v, t, p
    elseif i == 1 then return q, v, p
    elseif i == 2 then return p, v, t
    elseif i == 3 then return p, q, v
    elseif i == 4 then return t, p, v
    end
    return v, p, q
end

local function rgb_to_hsv(r, g, b)
    local mx, mn = math.max(r, g, b), math.min(r, g, b)
    local d = mx - mn
    local h = 0
    if d > 0 then
        if mx == r then h = ((g - b) / d) % 6
        elseif mx == g then h = (b - r) / d + 2
        else h = (r - g) / d + 4 end
        h = h / 6
    end
    return h, (mx == 0) and 0 or d / mx, mx
end

-- тёмный цвет с лёгким оттенком акцента
local function dark(l, a)
    local ac = UI_CFG.accent
    if UI_CFG.halloween then
        return imgui.ImVec4(math.min(1, l + 0.022), math.min(1, l + 0.002), math.min(1, l + 0.058), a or 1.0)
    end
    return imgui.ImVec4(math.min(1, l + ac[1] * 0.04), math.min(1, l + ac[2] * 0.04), math.min(1, l + ac[3] * 0.06), a or 1.0)
end

-- тёмный цвет, подмешанный к акценту (k от 0 до 1)
local function blend(l, k, a)
    local ac = UI_CFG.accent
    local d = dark(l)
    return imgui.ImVec4(d.x + (ac[1] - d.x) * k, d.y + (ac[2] - d.y) * k, d.z + (ac[3] - d.z) * k, a or 1.0)
end

-- список для рисования поверх окон; если нет, берём запасной
local function fg_list(fallback)
    if imgui.GetForegroundDrawList then
        local ok, dl = pcall(imgui.GetForegroundDrawList)
        if ok and dl ~= nil then return dl end
    end
    return fallback()
end

local function rounded_path(x0, y0, x1, y1, r)
    local xs, ys = {}, {}
    local function add(x, y) xs[#xs + 1] = x; ys[#ys + 1] = y end
    local function line(ax, ay, bx, by)
        local len = math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
        local n = math.max(1, math.floor(len / 14))
        for i = 0, n - 1 do
            local t = i / n
            add(ax + (bx - ax) * t, ay + (by - ay) * t)
        end
    end
    local function arc(cx, cy, a0)
        for i = 0, 5 do
            local a = a0 + (math.pi / 2) * (i / 5)
            add(cx + math.cos(a) * r, cy + math.sin(a) * r)
        end
    end
    line(x0 + r, y0, x1 - r, y0)
    arc(x1 - r, y0 + r, -math.pi / 2)
    line(x1, y0 + r, x1, y1 - r)
    arc(x1 - r, y1 - r, 0)
    line(x1 - r, y1, x0 + r, y1)
    arc(x0 + r, y1 - r, math.pi / 2)
    line(x0, y1 - r, x0, y0 + r)
    arc(x0 + r, y0 + r, math.pi)
    return xs, ys
end

-- рамка: 1 = переливы цвета акцента, 2 = радуга, 3 = статичная
local function draw_border(x0, y0, x1, y1)
    local xs, ys = rounded_path(x0 + 1, y0 + 1, x1 - 1, y1 - 1, 12)
    local n = #xs
    local pts = {}
    for i = 1, n do pts[i] = imgui.ImVec2(xs[i], ys[i]) end
    local dl = fg_list(imgui.GetWindowDrawList)
    local ac = UI_CFG.accent
    local mode = UI_CFG.border_mode
    local t = os.clock() * UI_CFG.border_speed
    local lr, lg, lb = 1, 1, 1
    if mode == 1 then
        local h, sat = rgb_to_hsv(ac[1], ac[2], ac[3])
        lr, lg, lb = hsv_to_rgb(h + 0.08, math.max(0.35, sat * 0.75), 1.0)
    end
    for i = 1, n do
        local j = i % n + 1
        local f = (i - 1) / n
        local r, g, b
        if mode == 1 then
            local w = 0.5 + 0.5 * math.sin((f * 2 - t * 0.6) * math.pi * 2)
            local dr, dg, db = ac[1] * 0.55, ac[2] * 0.55, ac[3] * 0.55
            r, g, b = dr + (lr - dr) * w, dg + (lg - dg) * w, db + (lb - db) * w
        elseif mode == 2 then
            r, g, b = hsv_to_rgb(f - t * 0.3, 0.75, 1.0)
        else
            r, g, b = ac[1], ac[2], ac[3]
        end
        dl:AddLine(pts[i], pts[j], col32(r, g, b, 0.16), 5.0)
        dl:AddLine(pts[i], pts[j], col32(r, g, b, 0.95), 2.0)
    end
end

-- тень и рамка главного окна; при любой ошибке эффекты просто отключаются
local border_broken = false
local function draw_window_fx(x0, y0, x1, y1)
    if border_broken then return end
    local ok, err = pcall(function()
        if UI_CFG.shadow then
            local bl = imgui.GetBackgroundDrawList()
            for i = 1, 6 do
                local e = i * 3
                bl:AddRectFilled(imgui.ImVec2(x0 - e, y0 - e + 5), imgui.ImVec2(x1 + e, y1 + e + 5), col32(0, 0, 0, 0.045), 12 + e)
            end
        end
        if UI_CFG.border_mode ~= 0 then draw_border(x0, y0, x1, y1) end
    end)
    if not ok then
        border_broken = true
        log_error("window_fx", err)
    end
    if UI_CFG.halloween then UIFX.hw_safe(UIFX.hw_front, x0, y0, x1, y1) end
end

function apply_theme()
    local style = imgui.GetStyle()
    local clr = style.Colors
    local ac = UI_CFG.accent
    local function sets(name, v) pcall(function() style[name] = v end) end
    local function setc(name, v)
        local idx = imgui.Col[name]
        if idx ~= nil then clr[idx] = v end
    end
    -- размеры (отступы не меняем: вёрстка окон рассчитана на них)
    sets("WindowPadding", imgui.ImVec2(5, 5))
    sets("FramePadding", imgui.ImVec2(5, 5))
    sets("ItemSpacing", imgui.ImVec2(5, 5))
    sets("ItemInnerSpacing", imgui.ImVec2(2, 2))
    sets("WindowTitleAlign", imgui.ImVec2(0.5, 0.5))
    sets("ScrollbarSize", 10)
    sets("WindowBorderSize", 0)
    sets("PopupBorderSize", 0)
    sets("ChildBorderSize", 1)
    sets("FrameBorderSize", 0)
    -- скругления
    sets("WindowRounding", 12)
    sets("ChildRounding", 8)
    sets("FrameRounding", 6)
    sets("PopupRounding", 10)
    sets("ScrollbarRounding", 8)
    sets("GrabRounding", 6)
    sets("TabRounding", 6)
    -- цвета
    setc("Text", imgui.ImVec4(0.93, 0.94, 0.97, 1.00))
    setc("TextDisabled", imgui.ImVec4(0.52, 0.55, 0.62, 1.00))
    setc("WindowBg", dark(0.058, UI_CFG.opacity))
    setc("ChildBg", dark(0.080, 0.50))
    setc("PopupBg", dark(0.085, 0.98))
    setc("Border", imgui.ImVec4(ac[1], ac[2], ac[3], 0.20))
    setc("TitleBg", dark(0.058))
    setc("TitleBgActive", dark(0.058))
    setc("TitleBgCollapsed", dark(0.058))
    setc("FrameBg", dark(0.105))
    setc("FrameBgHovered", blend(0.105, 0.14))
    setc("FrameBgActive", blend(0.105, 0.22))
    setc("Button", dark(0.115))
    setc("ButtonHovered", blend(0.115, 0.30))
    setc("ButtonActive", blend(0.115, 0.50))
    setc("Header", blend(0.115, 0.22))
    setc("HeaderHovered", blend(0.115, 0.34))
    setc("HeaderActive", blend(0.115, 0.48))
    setc("ScrollbarBg", imgui.ImVec4(0, 0, 0, 0))
    setc("ScrollbarGrab", blend(0.12, 0.30))
    setc("ScrollbarGrabHovered", blend(0.12, 0.50))
    setc("ScrollbarGrabActive", blend(0.12, 0.75))
    setc("Separator", imgui.ImVec4(1, 1, 1, 0.07))
    setc("ModalWindowDimBg", imgui.ImVec4(0, 0, 0, 0.65))
    setc("CheckMark", accent_vec(1.15))
    setc("SliderGrab", accent_vec(1.0))
    setc("SliderGrabActive", accent_vec(1.25))
    setc("PlotHistogram", accent_vec(1.0))
    setc("TextSelectedBg", imgui.ImVec4(ac[1], ac[2], ac[3], 0.35))
    setc("ResizeGrip", imgui.ImVec4(ac[1], ac[2], ac[3], 0.45))
    setc("ResizeGripHovered", imgui.ImVec4(ac[1], ac[2], ac[3], 0.75))
    setc("ResizeGripActive", imgui.ImVec4(ac[1], ac[2], ac[3], 1.00))
end

-- ===================== Левая панель и калькулятор =====================
local SIDEBAR_W = 200
local LAYOUT = { w = 835, h = 500, tab_h = 46, block_y = 266, force = false } -- текущие размеры главного окна
local current_tab = 1 -- 1 = Arizona Prices, 2 = Калькулятор, 3 = Отчет до PayDay, 4 = Коллекционные сеты, 5 = О скрипте, 7 = Настройки

local calc_expr = ""
local calc_prev = ""
local calc_error = nil
local calc_fresh = false
local CALCFX = { hover = {}, press = {}, ripple = {}, hist = {}, hist_open = false, pop_t = -10, grown = false }

local function ic(name, fallback)
    return fa[name] or fallback
end

-- ===================== Всплывающие уведомления =====================
local toasts = {}
local TOAST_KINDS = {
    info = { icon = "CIRCLE_INFO",          color = nil },
    ok   = { icon = "CIRCLE_CHECK",         color = {0.30, 0.78, 0.45} },
    warn = { icon = "TRIANGLE_EXCLAMATION", color = {1.00, 0.75, 0.20} },
    err  = { icon = "CIRCLE_XMARK",         color = {0.92, 0.32, 0.32} },
}

local toast_broken = false

local function toast(text, kind, dur)
    if UI_CFG.toasts == false or toast_broken then return false end
    toasts[#toasts + 1] = { text = tostring(text), kind = TOAST_KINDS[kind] and kind or "info", t0 = os.clock(), dur = dur or 3.5 }
    if #toasts > 5 then table.remove(toasts, 1) end
    return true
end

-- уведомление: всплывающая карточка, а если они выключены - обычное сообщение в чат
local function notify(text, kind, dur)
    if not toast(text, kind, dur) then
        if sampAddChatMessage then
            pcall(sampAddChatMessage, u8:decode("{33AAFF}[Arizona Prices] {FFFFFF}" .. tostring(text)), -1)
        end
    end
end

-- карточки рисуются прямо на экране (без отдельных окон ImGui), поэтому ломать стек окон им нечем
local function draw_toasts()
    local now = os.clock()
    for i = #toasts, 1, -1 do
        if now - toasts[i].t0 > toasts[i].dur then table.remove(toasts, i) end
    end
    if #toasts == 0 then return end
    local dl = fg_list(imgui.GetBackgroundDrawList)
    local sw, sh = getScreenResolution()
    local corner = UI_CFG.toast_corner or 3 -- 0 слева сверху, 1 справа сверху, 2 слева снизу, 3 справа снизу
    local right = (corner == 1 or corner == 3)
    local bottom = (corner == 2 or corner == 3)
    local H, GAP, MARGIN = 46, 8, 20
    for i, t in ipairs(toasts) do
        local kind = TOAST_KINDS[t.kind] or TOAST_KINDS.info
        local ts = imgui.CalcTextSize(t.text)
        local w = math.min(760, ts.x + 84)
        local age = now - t.t0
        local pr = math.min(1, age / 0.25)
        local ease = 1 - (1 - pr) ^ 3
        local alpha = math.max(0, math.min(1, (t.dur - age) / 0.4))
        local off = (1 - ease) * (w + MARGIN + 10)
        local slot = #toasts - i
        local x = right and (sw - MARGIN - w + off) or (MARGIN - off)
        local y = bottom and (sh - MARGIN - 80 - H - slot * (H + GAP)) or (MARGIN + slot * (H + GAP))
        local c = kind.color or UI_CFG.accent
        local ty = y + (H - ts.y) / 2
        local p0, p1 = imgui.ImVec2(x, y), imgui.ImVec2(x + w, y + H)
        local cx, cy = x + 28, y + H / 2
        dl:AddRectFilled(p0, p1, col32(0.07, 0.075, 0.09, 0.96 * alpha), 10)
        pcall(function()
            dl:AddRect(p0, p1, col32(c[1], c[2], c[3], 0.60 * alpha), 10, 0, 1.5)
            dl:AddCircleFilled(imgui.ImVec2(cx, cy), 17, col32(c[1], c[2], c[3], 0.20 * alpha), 28)
        end)
        -- значок рисуем линиями, поэтому его размер не зависит от шрифта
        local icol = col32(c[1], c[2], c[3], alpha)
        local function seg(ax, ay, bx, by)
            dl:AddLine(imgui.ImVec2(cx + ax, cy + ay), imgui.ImVec2(cx + bx, cy + by), icol, 3.0)
        end
        if t.kind == "ok" then
            seg(-7, 0.5, -2.5, 5.5)
            seg(-2.5, 5.5, 7.5, -5.5)
            dl:AddCircleFilled(imgui.ImVec2(cx - 2.5, cy + 5.5), 1.5, icol, 12)
        elseif t.kind == "err" then
            seg(-6, -6, 6, 6)
            seg(-6, 6, 6, -6)
        elseif t.kind == "warn" then
            seg(0, -8, 0, 2)
            dl:AddCircleFilled(imgui.ImVec2(cx, cy + 7), 2.0, icol, 12)
        else
            dl:AddCircleFilled(imgui.ImVec2(cx, cy - 7), 2.0, icol, 12)
            seg(0, -2.5, 0, 8)
        end
        dl:AddText(imgui.ImVec2(x + 56, ty), col32(1, 1, 1, alpha), t.text)
    end
end

local toast_frame
toast_frame = imgui.OnFrame(
    function()
        toast_frame.HideCursor = true
        return #toasts > 0
    end,
    function()
        local ok, err = xpcall(draw_toasts, tb)
        if not ok then
            toast_broken = true
            toasts = {}
            log_error("toast", err)
            queue_notice("Карточки уведомлений отключены из-за ошибки, сообщения будут в чате", "warn")
        end
    end
)

-- CALC_LOGIC_BEGIN
local function group_digits(s)
    if s == "" then return "0" end
    local r = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
    if r:sub(1, 1) == "." then r = r:sub(2) end
    return r
end

local function calc_format_expr(expr)
    local out = expr:gsub("[%d%.]+", function(num)
        local ip, dp = num:match("^(%d*)%.(%d*)$")
        if ip then
            return group_digits(ip) .. "," .. dp
        end
        return group_digits(num)
    end)
    out = out:gsub("%*", " x "):gsub("/", " / "):gsub("%+", " + "):gsub("%-", " - ")
    out = out:gsub("^%s+", ""):gsub("%s+$", "")
    out = out:gsub("^%- ", "-")
    return out
end

local function calc_raw_number(x)
    if x >= 0 then
        x = math.floor(x * 100 + 0.5) / 100
    else
        x = -math.floor(-x * 100 + 0.5) / 100
    end
    local s = string.format("%.2f", x)
    s = s:gsub("0+$", ""):gsub("%.$", "")
    if s == "-0" or s == "" then s = "0" end
    return s
end

local function calc_eval(expr)
    local tokens = {}
    local i, n = 1, #expr
    while i <= n do
        local c = expr:sub(i, i)
        if c:match("[%d%.]") then
            local num = expr:match("^[%d%.]+", i)
            i = i + #num
            local v = tonumber(num)
            if not v then return nil, "Ошибка" end
            local pct = false
            if expr:sub(i, i) == "%" then
                pct = true
                i = i + 1
            end
            tokens[#tokens + 1] = {num = v, pct = pct}
        elseif c:match("[%+%-%*/]") then
            tokens[#tokens + 1] = {op = c}
            i = i + 1
        else
            return nil, "Ошибка"
        end
    end

    if tokens[#tokens] and tokens[#tokens].op then tokens[#tokens] = nil end

    local idx, sign = 1, 1
    if tokens[1] and tokens[1].op == "-" then
        sign = -1
        idx = 2
    end
    if idx > #tokens then return nil, "Ошибка" end

    local total, cur_op, first = 0, "+", true
    while idx <= #tokens do
        local tk = tokens[idx]
        if not tk.num then return nil, "Ошибка" end
        local term = tk.pct and (tk.num / 100) or tk.num
        local single = true
        idx = idx + 1

        while tokens[idx] and (tokens[idx].op == "*" or tokens[idx].op == "/") do
            local nx = tokens[idx + 1]
            if not nx or not nx.num then return nil, "Ошибка" end
            local val = nx.pct and (nx.num / 100) or nx.num
            if tokens[idx].op == "*" then
                term = term * val
            else
                if val == 0 then return nil, "Деление на ноль" end
                term = term / val
            end
            single = false
            idx = idx + 2
        end

        if first then
            term = term * sign
            total = term
            first = false
        else
            if single and tk.pct then term = total * tk.num / 100 end
            if cur_op == "+" then total = total + term else total = total - term end
        end

        local nxt = tokens[idx]
        if nxt then
            if nxt.op ~= "+" and nxt.op ~= "-" then return nil, "Ошибка" end
            cur_op = nxt.op
            idx = idx + 1
        end
    end
    return total
end

local function calc_reset_if_fresh()
    if calc_fresh then
        calc_expr = ""
        calc_prev = ""
        calc_fresh = false
    end
end

local function calc_digit(d)
    calc_error = nil
    calc_reset_if_fresh()
    if #calc_expr > 45 then return end
    if calc_expr:sub(-1) == "%" then return end
    local last = calc_expr:match("[%d%.]*$")
    if d == "000" then
        if last == "" or last == "0" then return end
        calc_expr = calc_expr .. "000"
        return
    end
    if last == "0" then
        if d == "0" then return end
        calc_expr = calc_expr:sub(1, -2) .. d
    else
        calc_expr = calc_expr .. d
    end
end

local function calc_dot()
    calc_error = nil
    calc_reset_if_fresh()
    if #calc_expr > 45 then return end
    if calc_expr:sub(-1) == "%" then return end
    local last = calc_expr:match("[%d%.]*$")
    if last:find(".", 1, true) then return end
    if last == "" then
        calc_expr = calc_expr .. "0."
    else
        calc_expr = calc_expr .. "."
    end
end

local function calc_op(op)
    calc_error = nil
    if calc_fresh then
        calc_fresh = false
        calc_prev = ""
    end
    if calc_expr == "" then
        if op == "-" then calc_expr = "-" end
        return
    end
    local lastc = calc_expr:sub(-1)
    if lastc:match("[%+%-%*/]") then
        if #calc_expr == 1 then return end
        calc_expr = calc_expr:sub(1, -2) .. op
    else
        if lastc == "." then calc_expr = calc_expr:sub(1, -2) end
        calc_expr = calc_expr .. op
    end
end

local function calc_percent()
    calc_error = nil
    if calc_fresh then
        calc_fresh = false
        calc_prev = ""
    end
    if calc_expr:sub(-1):match("%d") then
        calc_expr = calc_expr .. "%"
    end
end

local function calc_back()
    calc_error = nil
    if calc_fresh then
        calc_fresh = false
        calc_prev = ""
    end
    calc_expr = calc_expr:sub(1, -2)
end

local function calc_clear()
    calc_expr = ""
    calc_prev = ""
    calc_error = nil
    calc_fresh = false
end

local function calc_equals()
    if calc_expr == "" or calc_fresh then return end
    local res, err = calc_eval(calc_expr)
    if not res then
        calc_error = err or "Ошибка"
        return
    end
    local shown_expr = calc_format_expr(calc_expr)
    calc_prev = shown_expr .. " ="
    calc_expr = calc_raw_number(res)
    calc_fresh = true
    CALCFX.pop_t = imgui.GetTime()
    CALCFX.hist[#CALCFX.hist + 1] = { expr = shown_expr, res = calc_format_expr(calc_expr), raw = calc_expr }
    if #CALCFX.hist > 15 then table.remove(CALCFX.hist, 1) end
end
-- CALC_LOGIC_END

local function draw_sidebar_bg(wpos)
    local dl = imgui.GetWindowDrawList()
    local col = imgui.ColorConvertFloat4ToU32(dark(0.088, UIFX.m))
    dl:AddRectFilled(wpos, imgui.ImVec2(wpos.x + SIDEBAR_W - 1, wpos.y + LAYOUT.h), col, 12)
    dl:AddRectFilled(imgui.ImVec2(wpos.x + 14, wpos.y), imgui.ImVec2(wpos.x + SIDEBAR_W - 1, wpos.y + LAYOUT.h), col)
    dl:AddLine(imgui.ImVec2(wpos.x + SIDEBAR_W - 1, wpos.y + 8), imgui.ImVec2(wpos.x + SIDEBAR_W - 1, wpos.y + LAYOUT.h - 8), imgui.GetColorU32(imgui.Col.Separator), 1.0)
    if UI_CFG.halloween then UIFX.hw_safe(UIFX.hw_web, dl, wpos.x + 7, wpos.y + LAYOUT.h - 7, 84, 1, -1, 0.18) end
end

-- ===================== Эффекты интерфейса =====================
-- Устанавливает прозрачность всего, что рисуется дальше (и стандартных виджетов, и ручного рисования)
-- цвет и следующее значение ликвидности (клик по значению у разработчика переключает по кругу)
function UIFX.liq_color(l)
    if l == "Ликвид" then return imgui.ImVec4(0.45, 0.95, 0.55, 1) end
    if l == "Средне" then return imgui.ImVec4(1.00, 0.85, 0.40, 1) end
    if l == "Неликвид" then return imgui.ImVec4(1.00, 0.45, 0.45, 1) end
    return imgui.ImVec4(0.50, 0.52, 0.58, 1)
end

function UIFX.liq_next(l)
    if l == nil then return "Ликвид" end
    if l == "Ликвид" then return "Средне" end
    if l == "Средне" then return "Неликвид" end
    return nil
end

function UIFX.set_alpha(a)
    a = clamp(a, 0, 1)
    UIFX.m = a
    pcall(function() imgui.GetStyle().Alpha = a end)
end

-- Переключение вкладки с запуском анимации
function UIFX.go_tab(id)
    if id ~= current_tab then
        current_tab = id
        local now = imgui.GetTime()
        UIFX.tab_t, UIFX.table_t = now, now
    end
end

-- Вызывается в начале каждого кадра меню: плавное появление и исчезновение окна, заставка, горячие клавиши
function UIFX.tick()
    local dt = imgui.GetIO().DeltaTime
    local open = main_window[0]
    local target = open and 1 or 0
    UIFX.alpha = UIFX.alpha + (target - UIFX.alpha) * math.min(1, dt * (open and 11 or 15))
    if not open and UIFX.alpha < 0.03 then UIFX.alpha = 0 end
    if open and UIFX.alpha > 0.99 then UIFX.alpha = 1 end
    if open and not UIFX.was_open then
        local now = imgui.GetTime()
        UIFX.table_t, UIFX.tab_t = now, now
        if UI_CFG.splash and not UIFX.splashed then
            UIFX.splash_t = now
            UIFX.splashed = true
        end
    end
    UIFX.was_open = open
    if UIFX.pending_tab then
        UIFX.go_tab(UIFX.pending_tab)
        UIFX.pending_tab = nil
    end
end

-- Бегущая полоска слева у активной вкладки: плавно «переезжает» на новую
function UIFX.draw_bar(wpos)
    if not UIFX.bar_ty then return end
    local dt = imgui.GetIO().DeltaTime
    if not UIFX.bar_cur then UIFX.bar_cur = UIFX.bar_ty end
    UIFX.bar_cur = UIFX.bar_cur + (UIFX.bar_ty - UIFX.bar_cur) * math.min(1, dt * 16)
    local ac = UI_CFG.accent
    local x, y = wpos.x + UIFX.bar_x, wpos.y + UIFX.bar_cur
    imgui.GetWindowDrawList():AddRectFilled(imgui.ImVec2(x, y - 13), imgui.ImVec2(x + 3, y + 13),
        col32(math.min(1, ac[1] * 1.15), math.min(1, ac[2] * 1.15), math.min(1, ac[3] * 1.15), 1), 2)
end

-- Анимированный фон вкладки: медленные цветные пятна и поднимающиеся искры (рисуется под содержимым)
function UIFX.draw_bg()
    local p, s = imgui.GetWindowPos(), imgui.GetWindowSize()
    local dl = imgui.GetWindowDrawList()
    local t, ac = imgui.GetTime(), UI_CFG.accent
    for i = 1, 3 do
        local cx = p.x + s.x * (0.5 + 0.38 * math.sin(t * 0.11 * i + i * 2.1))
        local cy = p.y + s.y * (0.5 + 0.38 * math.cos(t * 0.09 * i + i * 1.3))
        for r = 4, 1, -1 do
            dl:AddCircleFilled(imgui.ImVec2(cx, cy), r * 55, col32(ac[1], ac[2], ac[3], 0.014), 32)
        end
    end
    for i = 1, 26 do
        local sp = 10 + (i * 7) % 17
        local x = p.x + ((i * 137) % 100) / 100 * s.x + math.sin(t * 0.5 + i) * 12
        local y = p.y + s.y - ((t * sp + i * 61) % (s.y + 20)) + 10
        local tw = 0.5 + 0.5 * math.sin(t * 1.5 + i * 1.7)
        dl:AddCircleFilled(imgui.ImVec2(x, y), 1.2 + (i % 3) * 0.7,
            col32(ac[1] * 0.5 + 0.5, ac[2] * 0.5 + 0.5, ac[3] * 0.5 + 0.5, 0.05 + 0.14 * tw), 8)
    end
end

-- ===================== Хэллоуин =====================
-- Всё рисуется простыми фигурами (круги, треугольники, линии). При любой ошибке украшения сами отключаются.
function UIFX.hw_safe(fn, ...)
    if UIFX.hw_broken then return end
    local ok, err = pcall(fn, ...)
    if not ok then
        UIFX.hw_broken = true
        pcall(log_error, "halloween", err)
    end
end

-- закрашенный треугольник (вершины переставляются, чтобы обход всегда был по часовой)
function UIFX.hw_tri(dl, col, ax, ay, bx, by, cx, cy)
    local V = imgui.ImVec2
    if (bx - ax) * (cy - ay) - (by - ay) * (cx - ax) < 0 then
        bx, by, cx, cy = cx, cy, bx, by
    end
    dl:AddTriangleFilled(V(ax, ay), V(bx, by), V(cx, cy), col)
end

-- тыква: cx, cy - центр, r - размер, k - прозрачность, hat - ведьмина шляпа
function UIFX.hw_pumpkin(dl, cx, cy, r, k, hat)
    local V = imgui.ImVec2
    local t = imgui.GetTime()
    local fl = 0.85 + 0.15 * math.sin(t * 7 + cx * 0.05) * math.sin(t * 3.1 + cy * 0.1) -- мерцание свечи внутри
    for i = 3, 1, -1 do
        dl:AddCircleFilled(V(cx, cy), r * (1.0 + i * 0.45), col32(1.0, 0.45, 0.05, 0.04 * k * fl), 28)
    end
    local top = cy - r * 0.78
    local side = col32(0.80, 0.33, 0.03, k)
    local body = col32(1.00, 0.52, 0.08, k)
    dl:AddCircleFilled(V(cx - r * 0.45, cy + r * 0.03), r * 0.62, side, 22)
    dl:AddCircleFilled(V(cx + r * 0.45, cy + r * 0.03), r * 0.62, side, 22)
    dl:AddCircleFilled(V(cx, cy), r * 0.78, body, 28)
    dl:AddCircleFilled(V(cx - r * 0.38, cy - r * 0.38), r * 0.13, col32(1.0, 0.82, 0.55, 0.35 * k), 12)
    -- лицо светится изнутри
    local fc = col32(1.0, 0.88, 0.30, k * fl)
    UIFX.hw_tri(dl, fc, cx - r * 0.55, cy - r * 0.02, cx - r * 0.18, cy - r * 0.02, cx - r * 0.36, cy - r * 0.34)
    UIFX.hw_tri(dl, fc, cx + r * 0.18, cy - r * 0.02, cx + r * 0.55, cy - r * 0.02, cx + r * 0.36, cy - r * 0.34)
    UIFX.hw_tri(dl, fc, cx - r * 0.08, cy + r * 0.14, cx + r * 0.08, cy + r * 0.14, cx, cy + r * 0.03)
    dl:AddRectFilled(V(cx - r * 0.58, cy + r * 0.26), V(cx + r * 0.58, cy + r * 0.48), fc, r * 0.06)
    for j = -2, 2, 2 do
        local x = cx + j * r * 0.22
        UIFX.hw_tri(dl, body, x - r * 0.09, cy + r * 0.26, x + r * 0.09, cy + r * 0.26, x, cy + r * 0.37)
    end
    for j = -1, 1, 2 do
        local x = cx + j * r * 0.22
        UIFX.hw_tri(dl, body, x - r * 0.09, cy + r * 0.48, x + r * 0.09, cy + r * 0.48, x, cy + r * 0.37)
    end
    if hat then
        local hc = col32(0.22, 0.10, 0.38, k)
        local hb = top + r * 0.12
        UIFX.hw_tri(dl, hc, cx - r * 0.55, hb - r * 0.05, cx + r * 0.55, hb - r * 0.05, cx + r * 0.22, hb - r * 1.35)
        dl:AddRectFilled(V(cx - r * 0.44, hb - r * 0.30), V(cx + r * 0.44, hb - r * 0.10), body, 2)
        dl:AddRectFilled(V(cx - r * 0.95, hb - r * 0.10), V(cx + r * 0.95, hb + r * 0.08), hc, r * 0.08)
    else
        local sc = col32(0.30, 0.45, 0.10, k)
        UIFX.hw_tri(dl, sc, cx - r * 0.10, top + r * 0.08, cx + r * 0.14, top + r * 0.08, cx + r * 0.20, top - r * 0.28)
        UIFX.hw_tri(dl, sc, cx - r * 0.10, top + r * 0.08, cx + r * 0.20, top - r * 0.28, cx - r * 0.02, top - r * 0.30)
    end
end

-- летучая мышь: x, y - центр, s - размер, fl - взмах крыльев (-1..1), k - прозрачность
function UIFX.hw_bat(dl, x, y, s, fl, k)
    local V = imgui.ImVec2
    local c = col32(0.36, 0.23, 0.52, 0.90 * k)
    local f = fl * s * 0.55
    for d = -1, 1, 2 do
        UIFX.hw_tri(dl, c, x, y - s * 0.15, x + d * s * 1.35, y - s * 0.45 + f, x + d * s * 0.85, y + s * 0.05)
        UIFX.hw_tri(dl, c, x, y - s * 0.15, x + d * s * 0.85, y + s * 0.05, x + d * s * 0.45, y + s * 0.32)
        UIFX.hw_tri(dl, c, x, y - s * 0.05, x + d * s * 0.45, y + s * 0.32, x, y + s * 0.22)
    end
    dl:AddCircleFilled(V(x, y + s * 0.02), s * 0.30, c, 12)
    UIFX.hw_tri(dl, c, x - s * 0.26, y - s * 0.12, x - s * 0.06, y - s * 0.22, x - s * 0.24, y - s * 0.52)
    UIFX.hw_tri(dl, c, x + s * 0.06, y - s * 0.22, x + s * 0.26, y - s * 0.12, x + s * 0.24, y - s * 0.52)
    local eye = col32(1.0, 0.40, 0.10, k)
    dl:AddCircleFilled(V(x - s * 0.11, y), s * 0.05, eye, 6)
    dl:AddCircleFilled(V(x + s * 0.11, y), s * 0.05, eye, 6)
end

-- паутина в углу: cx, cy - угол, size - размер, dx/dy - куда расходится (±1), a - прозрачность
function UIFX.hw_web(dl, cx, cy, size, dx, dy, a)
    local V = imgui.ImVec2
    local col = col32(0.85, 0.85, 1.0, a)
    local n = 5
    for k = 0, n do
        local ang = (k / n) * (math.pi / 2)
        dl:AddLine(V(cx, cy), V(cx + dx * math.cos(ang) * size, cy + dy * math.sin(ang) * size), col, 1.0)
    end
    for j = 1, 4 do
        local rr = size * j / 4
        for k = 0, n - 1 do
            local a1, a2, am = (k / n) * (math.pi / 2), ((k + 1) / n) * (math.pi / 2), ((k + 0.5) / n) * (math.pi / 2)
            local x1, y1 = cx + dx * math.cos(a1) * rr, cy + dy * math.sin(a1) * rr
            local x2, y2 = cx + dx * math.cos(a2) * rr, cy + dy * math.sin(a2) * rr
            local xm, ym = cx + dx * math.cos(am) * rr * 0.86, cy + dy * math.sin(am) * rr * 0.86
            dl:AddLine(V(x1, y1), V(xm, ym), col, 1.0)
            dl:AddLine(V(xm, ym), V(x2, y2), col, 1.0)
        end
    end
end

-- фон вкладки: луна, фиолетовое свечение, летучие мыши, паутина (рисуется под содержимым, внутри ##content)
function UIFX.hw_bg()
    local p, s = imgui.GetWindowPos(), imgui.GetWindowSize()
    local dl = imgui.GetWindowDrawList()
    local V = imgui.ImVec2
    local t = imgui.GetTime()
    local mx, my = p.x + s.x - 78, p.y + 70
    for i = 5, 1, -1 do
        dl:AddCircleFilled(V(mx, my), 40 + i * 14, col32(1.0, 0.82, 0.45, 0.012), 40)
    end
    dl:AddCircleFilled(V(mx, my), 40, col32(1.0, 0.90, 0.62, 0.15), 40)
    dl:AddCircleFilled(V(mx - 12, my - 8), 9, col32(0.9, 0.7, 0.4, 0.08), 16)
    dl:AddCircleFilled(V(mx + 14, my + 10), 6, col32(0.9, 0.7, 0.4, 0.08), 16)
    dl:AddCircleFilled(V(mx + 6, my - 20), 5, col32(0.9, 0.7, 0.4, 0.08), 16)
    local gx, gy = p.x + s.x * (0.30 + 0.20 * math.sin(t * 0.13)), p.y + s.y * (0.65 + 0.15 * math.cos(t * 0.10))
    for r = 4, 1, -1 do
        dl:AddCircleFilled(V(gx, gy), r * 60, col32(0.55, 0.20, 0.85, 0.016), 36)
    end
    for i = 1, 4 do
        local span = s.x + 140
        local bx = p.x - 70 + ((t * (22 + i * 6) + i * 173) % span)
        local by = p.y + s.y * (0.12 + 0.17 * i) + math.sin(t * 0.8 + i * 2.0) * 16
        UIFX.hw_bat(dl, bx, by, 10 + (i % 3) * 4, math.sin(t * 9 + i * 1.7), 0.85)
    end
    UIFX.hw_web(dl, p.x + s.x - 6, p.y + 6, 80, -1, 1, 0.20)
    UIFX.hw_web(dl, p.x + s.x - 6, p.y + s.y - 6, 100, -1, -1, 0.17)
end

-- тыквы сидят на верхней рамке окна (рисуются поверх, как и сама рамка)
function UIFX.hw_front(x0, y0, x1, y1)
    local dl = fg_list(imgui.GetWindowDrawList)
    UIFX.hw_pumpkin(dl, x1 - 135, y0 + 3 - 22 * 0.78, 22, 1, true)
    UIFX.hw_pumpkin(dl, x1 - 66, y0 + 3 - 16 * 0.78, 16, 1, false)
    UIFX.hw_pumpkin(dl, x0 + 80, y0 + 3 - 19 * 0.78, 19, 1, false)
end

local function sidebar_tab(label, id, tip)
    local active = (current_tab == id)
    local ac = UI_CFG.accent
    if active then
        imgui.PushStyleColor(imgui.Col.Button, blend(0.115, 0.28))
    end
    imgui.SetWindowFontScale(1.15)
    local clicked = imgui.Button(label .. "##tab" .. id, imgui.ImVec2(SIDEBAR_W - 10, LAYOUT.tab_h))
    local hovered = imgui.IsItemHovered()
    imgui.SetWindowFontScale(1.0)
    if clicked then UIFX.go_tab(id) end
    if hovered and tip then imgui.SetTooltip(tip) end
    if active then
        imgui.PopStyleColor(1)
        local rmin, rmax = imgui.GetItemRectMin(), imgui.GetItemRectMax()
        local wp = imgui.GetWindowPos()
        UIFX.bar_ty = (rmin.y + rmax.y) / 2 - wp.y
        UIFX.bar_x = rmin.x + 2 - wp.x
        -- мягкое свечение вокруг активной вкладки
        local dl = imgui.GetWindowDrawList()
        for i = 3, 1, -1 do
            dl:AddRect(imgui.ImVec2(rmin.x - i * 1.5, rmin.y - i * 1.5), imgui.ImVec2(rmax.x + i * 1.5, rmax.y + i * 1.5),
                col32(ac[1], ac[2], ac[3], 0.07 * (4 - i)), 8 + i, 15, 1.2)
        end
    end
end

-- ===================== Калькулятор: крупный экран, анимации, история =====================
-- Все вспомогательные функции лежат внутри таблицы CALCFX (так не расходуются локальные переменные скрипта)
function CALCFX.step(tbl, key, target, speed, dt)
    local v = tbl[key] or 0
    v = v + (target - v) * math.min(1, dt * speed)
    tbl[key] = v
    return v
end

-- Рисует одну кнопку калькулятора: плавная подсветка, свечение, "волна" от клика, нажатие вдавливает кнопку
function CALCFX.button(id, label, kind, w, h, action)
    local dl = imgui.GetWindowDrawList()
    local p = imgui.GetCursorScreenPos()
    local now = imgui.GetTime()
    local dt = imgui.GetIO().DeltaTime

    local clicked = imgui.InvisibleButton("##cb" .. id, imgui.ImVec2(w, h))
    local hovered, held = imgui.IsItemHovered(), imgui.IsItemActive()
    if clicked then
        local m = imgui.GetMousePos()
        CALCFX.ripple[id] = { t = now, x = m.x, y = m.y }
        action()
    end

    local hv = CALCFX.step(CALCFX.hover, id, hovered and 1 or 0, 14, dt)
    local pr = CALCFX.step(CALCFX.press, id, held and 1 or 0, 24, dt)

    -- базовый цвет по типу кнопки: 0 цифра, 1 действие, 2 "=", 3 сброс
    local br, bg, bb
    if kind == 2 then
        local a = UI_CFG.accent
        br, bg, bb = a[1], a[2], a[3]
    elseif kind == 3 then
        br, bg, bb = 0.55, 0.18, 0.20
    elseif kind == 1 then
        br, bg, bb = 0.20, 0.20, 0.23
    else
        br, bg, bb = 0.145, 0.145, 0.165
    end
    local lift = 0.07 * hv - 0.05 * pr
    local r, g, b = clamp(br + lift, 0, 1), clamp(bg + lift, 0, 1), clamp(bb + lift, 0, 1)

    local pad = 2.5 * pr -- при нажатии кнопка чуть уменьшается
    local x1, y1 = p.x + pad, p.y + pad
    local x2, y2 = p.x + w - pad, p.y + h - pad
    local round = 11

    -- мягкое свечение вокруг кнопки при наведении (у "=" пульсирует всегда)
    local ac = UI_CFG.accent
    local glow = hv
    if kind == 2 then glow = math.max(hv, 0.35 + 0.25 * math.sin(now * 3.0)) end
    if glow > 0.02 then
        for i = 3, 1, -1 do
            dl:AddRect(imgui.ImVec2(x1 - i * 1.6, y1 - i * 1.6), imgui.ImVec2(x2 + i * 1.6, y2 + i * 1.6),
                col32(ac[1], ac[2], ac[3], 0.10 * glow * (4 - i) / 3), round + i, 15, 1.4)
        end
    end

    dl:AddRectFilled(imgui.ImVec2(x1, y1), imgui.ImVec2(x2, y2), col32(r, g, b, 1), round)
    -- блик сверху
    dl:AddRectFilled(imgui.ImVec2(x1 + 2, y1 + 2), imgui.ImVec2(x2 - 2, y1 + (y2 - y1) * 0.45), col32(1, 1, 1, 0.045 + 0.03 * hv), round - 2)
    -- рамка
    local ba = 0.10 + 0.75 * hv
    dl:AddRect(imgui.ImVec2(x1, y1), imgui.ImVec2(x2, y2), col32(ac[1], ac[2], ac[3], ba), round, 15, 1.2)

    -- волна от места клика
    local rp = CALCFX.ripple[id]
    if rp then
        local k = (now - rp.t) / 0.5
        if k >= 1 then
            CALCFX.ripple[id] = nil
        else
            dl:PushClipRect(imgui.ImVec2(x1, y1), imgui.ImVec2(x2, y2), true)
            dl:AddCircleFilled(imgui.ImVec2(rp.x, rp.y), k * math.max(w, h) * 1.1, col32(1, 1, 1, 0.30 * (1 - k)), 32)
            dl:PopClipRect()
        end
    end

    -- подпись по центру
    local ts = imgui.CalcTextSize(label)
    dl:AddText(imgui.ImVec2(p.x + (w - ts.x) / 2, p.y + (h - ts.y) / 2 + pr), col32(1, 1, 1, 0.95), label)
end

-- Крупный экран: прошлое выражение сверху, результат крупно, при "=" цифры "выпрыгивают"
function CALCFX.display(w, h)
    local now = imgui.GetTime()
    local ac = UI_CFG.accent
    local p = imgui.GetCursorScreenPos()
    local dl = imgui.GetWindowDrawList()

    local flash = clamp(1 - (now - CALCFX.pop_t) / 0.6, 0, 1)
    dl:AddRectFilled(p, imgui.ImVec2(p.x + w, p.y + h), col32(0.075, 0.075, 0.09, 1), 14)
    dl:AddRectFilled(p, imgui.ImVec2(p.x + w, p.y + h), col32(ac[1], ac[2], ac[3], 0.05 + 0.10 * flash), 14)
    dl:AddRect(p, imgui.ImVec2(p.x + w, p.y + h), col32(ac[1], ac[2], ac[3], 0.35 + 0.55 * flash), 14, 15, 1.5)

    local fs = clamp(h / 100 * 1.9, 1.7, 3.2)
    local shown, color
    if calc_error then
        shown, color = calc_error, { 1.0, 0.38, 0.38 }
    else
        shown, color = (calc_expr == "") and "0" or calc_format_expr(calc_expr), { 1, 1, 1 }
    end

    -- предыдущее выражение (мелко, справа сверху)
    imgui.SetWindowFontScale(1.1)
    local prev = calc_prev ~= "" and calc_prev or ""
    local ps = imgui.CalcTextSize(prev)
    dl:AddText(imgui.ImVec2(p.x + w - 16 - ps.x, p.y + 10), col32(0.62, 0.62, 0.68, 1), prev)

    -- основной текст: подбираем размер, чтобы влез, плюс "прыжок" после "="
    local pop = 1 + 0.16 * flash * flash
    local scale = fs
    imgui.SetWindowFontScale(scale)
    while scale > 0.9 and imgui.CalcTextSize(shown).x > (w - 36) / pop do
        scale = scale - 0.1
        imgui.SetWindowFontScale(scale)
    end
    local ts = imgui.CalcTextSize(shown)
    local s2 = scale * pop
    imgui.SetWindowFontScale(s2)
    ts = imgui.CalcTextSize(shown)
    local tx = p.x + w - 18 - ts.x
    local ty = p.y + h - 12 - ts.y + 4 * (1 - flash)
    dl:AddText(imgui.ImVec2(tx + 1.5, ty + 1.5), col32(0, 0, 0, 0.5), shown)
    dl:AddText(imgui.ImVec2(tx, ty), col32(color[1], color[2], color[3], 1), shown)
    imgui.SetWindowFontScale(1.0)

    imgui.Dummy(imgui.ImVec2(w, h))
end

-- Панель истории: клик по записи подставляет результат обратно в калькулятор
function CALCFX.history(w, h)
    local ac = UI_CFG.accent
    if imgui.BeginChild("##calc_hist", imgui.ImVec2(w, h), true) then
        imgui.TextColored(accent_vec(1.2), ic("CLOCK_ROTATE_LEFT", "") .. " История")
        imgui.Separator()
        if #CALCFX.hist == 0 then
            imgui.TextColored(imgui.ImVec4(0.55, 0.55, 0.6, 1), "Пока пусто")
        else
            for i = #CALCFX.hist, 1, -1 do
                local e = CALCFX.hist[i]
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0, 0, 0, 0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, accent_vec(1.0, 0.25))
                imgui.PushStyleColor(imgui.Col.ButtonActive, accent_vec(1.0, 0.4))
                if imgui.Button(e.res .. "##h" .. i, imgui.ImVec2(-1, 34)) then
                    calc_expr, calc_prev, calc_error, calc_fresh = e.raw, "", nil, false
                end
                imgui.PopStyleColor(3)
                imgui.TextColored(imgui.ImVec4(0.55, 0.55, 0.6, 1), e.expr)
                imgui.Spacing()
            end
        end
        if #CALCFX.hist > 0 then
            if imgui.Button("Очистить##hclr", imgui.ImVec2(-1, 28)) then CALCFX.hist = {} end
        end
    end
    imgui.EndChild()
end

local function draw_calculator()
    local sw, sh = getScreenResolution()
    -- при первом заходе во вкладку растягиваем окно, чтобы калькулятору хватило места
    if not CALCFX.grown then
        CALCFX.grown = true
        if LAYOUT.w < 960 or LAYOUT.h < 640 then
            LAYOUT.req = { w = math.min(math.max(LAYOUT.w, 980), sw - 40), h = math.min(math.max(LAYOUT.h, 660), sh - 40) }
        end
    end

    -- Шапка
    imgui.AlignTextToFramePadding()
    imgui.SetCursorPosX(9)
    imgui.Text(ic("CALCULATOR", "") .. " Калькулятор")
    imgui.SameLine(LAYOUT.w - SIDEBAR_W - 76)
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0, 0, 0, 0))
    if imgui.Button(ic("CLOCK_ROTATE_LEFT", "H") .. "##calc_hist_btn", imgui.ImVec2(30, 24)) then
        CALCFX.hist_open = not CALCFX.hist_open
    end
    imgui.SameLine(LAYOUT.w - SIDEBAR_W - 29)
    if imgui.Button(FA.CIRCLE_XMARK .. "##close_calc", imgui.ImVec2(24, 24)) then
        main_window[0] = false
    end
    if imgui.IsItemHovered() then imgui.SetTooltip("Закрыть") end
    imgui.PopStyleColor(1)
    imgui.Spacing()

    local avail = imgui.GetContentRegionAvail()
    local gap = 9
    local hist_w = CALCFX.hist_open and 200 or 0
    local area_w = avail.x - hist_w - (hist_w > 0 and 12 or 0) - 16
    local cw = clamp(area_w, 300, 720)
    local disp_h = clamp(avail.y * 0.25, 92, 160)
    local btn_h = clamp((avail.y - disp_h - 6 * gap - 6) / 5, 40, 110)
    local btn_w = (cw - 3 * gap) / 4
    local x0 = 8 + math.max(0, (area_w - cw) / 2)
    local y0 = imgui.GetCursorPosY()

    imgui.SetCursorPos(imgui.ImVec2(x0, y0))
    CALCFX.display(cw, disp_h)

    local function d(n) return function() calc_digit(n) end end
    local function o(n) return function() calc_op(n) end end
    local rows = {
        { {"C", calc_clear, 3}, {ic("DELETE_LEFT", "<"), calc_back, 1}, {ic("PERCENT", "%"), calc_percent, 1}, {ic("DIVIDE", "/"), o("/"), 1} },
        { {"7", d("7"), 0}, {"8", d("8"), 0}, {"9", d("9"), 0}, {ic("XMARK", "x"), o("*"), 1} },
        { {"4", d("4"), 0}, {"5", d("5"), 0}, {"6", d("6"), 0}, {ic("MINUS", "-"), o("-"), 1} },
        { {"1", d("1"), 0}, {"2", d("2"), 0}, {"3", d("3"), 0}, {ic("PLUS", "+"), o("+"), 1} },
        { {"0", d("0"), 0}, {"000", d("000"), 0}, {",", calc_dot, 0}, {ic("EQUALS", "="), calc_equals, 2} },
    }

    imgui.SetWindowFontScale(clamp(btn_h / 54 * 1.25, 1.2, 2.0))
    for r, row in ipairs(rows) do
        imgui.SetCursorPos(imgui.ImVec2(x0, y0 + disp_h + gap + (r - 1) * (btn_h + gap)))
        for c, b in ipairs(row) do
            if c > 1 then imgui.SameLine(0, gap) end
            CALCFX.button(r .. "_" .. c, b[1], b[3], btn_w, btn_h, b[2])
        end
    end
    imgui.SetWindowFontScale(1.0)

    if hist_w > 0 then
        imgui.SetCursorPos(imgui.ImVec2(x0 + cw + 12 + math.max(0, (area_w - cw) / 2) * 0, y0))
        CALCFX.history(hist_w, disp_h + 5 * (btn_h + gap))
    end
end

-- ===================== Новые разделы: PayDay, фразы, о скрипте =====================
local settings_path = getWorkingDirectory() .. "\\config\\arizona_prices_settings.json"
local settings = { ui = UI_CFG, favs = {}, notes = "", payday = { enabled = false, x = 20, y = 300 }, phrases = {}, clock = { enabled = false, country = "Узбекистан", x = 20, y = 340 } }

local function load_settings()
    local data = safe_read_json(settings_path)
    if not data then return end
    if type(data.payday) == "table" then
        settings.payday.enabled = (data.payday.enabled == true)
        settings.payday.x = tonumber(data.payday.x) or 20
        settings.payday.y = tonumber(data.payday.y) or 300
    end
    if type(data.phrases) == "table" then
        local ph = {}
        for _, v in ipairs(data.phrases) do
            if type(v) == "string" and v ~= "" then ph[#ph + 1] = v end
        end
        settings.phrases = ph
    end
    if type(data.clock) == "table" then
        settings.clock.enabled = (data.clock.enabled == true)
        if type(data.clock.country) == "string" then settings.clock.country = data.clock.country end
        settings.clock.x = tonumber(data.clock.x) or 20
        settings.clock.y = tonumber(data.clock.y) or 340
    end
    if type(data.favs) == "table" then
        local f = {}
        for k, v in pairs(data.favs) do
            if type(k) == "string" and v == true then f[k] = true end
        end
        settings.favs = f
    end
    if type(data.notes) == "string" then settings.notes = data.notes:sub(1, 8000) end
    if type(data.ui) == "table" then
        local u = data.ui
        if type(u.accent) == "table" and tonumber(u.accent[1]) and tonumber(u.accent[2]) and tonumber(u.accent[3]) then
            UI_CFG.accent = { clamp(tonumber(u.accent[1]), 0, 1), clamp(tonumber(u.accent[2]), 0, 1), clamp(tonumber(u.accent[3]), 0, 1) }
        end
        UI_CFG.opacity = clamp(tonumber(u.opacity) or 1.0, 0.3, 1.0)
        UI_CFG.overlay_scale = clamp(tonumber(u.overlay_scale) or 1.0, 0.7, 2.0)
        UI_CFG.open_key = math.max(0, math.floor(tonumber(u.open_key) or 0))
        UI_CFG.toasts = (u.toasts ~= false)
        UI_CFG.toast_corner = clamp(math.floor(tonumber(u.toast_corner) or 3), 0, 3)
        UI_CFG.border_mode = clamp(math.floor(tonumber(u.border_mode) or 1), 0, 3)
        UI_CFG.border_speed = clamp(tonumber(u.border_speed) or 1.0, 0.2, 3.0)
        UI_CFG.shadow = (u.shadow ~= false)
        UI_CFG.bg_fx = (u.bg_fx ~= false)
        UI_CFG.splash = (u.splash ~= false)
        if u.halloween == nil then
            UI_CFG.halloween = true
            UI_CFG.accent = { 0.98, 0.55, 0.12 }
        else
            UI_CFG.halloween = (u.halloween == true)
        end
        if type(u.font) == "string" then UI_CFG.font = u.font end
        UI_CFG.win_w = clamp(math.floor(tonumber(u.win_w) or 835), 700, 2400)
        UI_CFG.win_h = clamp(math.floor(tonumber(u.win_h) or 500), 400, 1400)
    end
end

local function save_settings()
    local dir = getWorkingDirectory() .. "\\config"
    if not doesDirectoryExist(dir) then
        createDirectory(dir)
    end
    local ok, json = pcall(encodeJson, settings)
    if ok and type(json) == "string" and json ~= "" then
        safe_write(settings_path, json)
    end
end

safe_call("load_settings", load_settings)

-- избранные предметы

function UIFX.toggle_fav(name)
    if settings.favs[name] then settings.favs[name] = nil else settings.favs[name] = true end
    save_settings()
end

local payday_on = imgui.new.bool(settings.payday.enabled)
local payday_edit = false
local payday_pos = { x = settings.payday.x, y = settings.payday.y }

local function minutes_to_payday()
    local m = tonumber(os.date("%M")) or 0
    if m < 30 then return 30 - m end
    return 60 - m
end

local function payday_text()
    local d = os.date("*t")
    local left = 1800 - ((d.min % 30) * 60 + d.sec)
    return "До PayDay: " .. math.floor(left / 60) .. " мин " .. string.format("%02d", left % 60) .. " сек"
end

local function minutes_word(n)
    local n10, n100 = n % 10, n % 100
    if n100 >= 11 and n100 <= 14 then return "минут" end
    if n10 == 1 then return "минута" end
    if n10 >= 2 and n10 <= 4 then return "минуты" end
    return "минут"
end

local function section_header(icon, title)
    imgui.AlignTextToFramePadding()
    imgui.SetCursorPosX(9)
    imgui.Text(icon .. " " .. title)
    imgui.SameLine(LAYOUT.w - SIDEBAR_W - 29)
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0, 0, 0, 0))
    if imgui.Button(FA.CIRCLE_XMARK .. "##close_section", imgui.ImVec2(24, 24)) then
        main_window[0] = false
    end
    if imgui.IsItemHovered() then imgui.SetTooltip("Закрыть") end
    imgui.PopStyleColor(1)
    imgui.Spacing()
end

local function draw_payday_tab()
    section_header(ic("CLOCK", ""), "Отчет до PayDay")
    if imgui.BeginChild("##payday_child", imgui.ImVec2(-1, LAYOUT.h - 79), true) then
        imgui.SetWindowFontScale(1.35)
        imgui.TextWrapped("На экране появится надпись «До PayDay: N мин N сек». PayDay выплачивается каждые 30 минут: в :00 и :30.")
        imgui.Spacing()
        if imgui.Checkbox(" Включить", payday_on) then
            settings.payday.enabled = payday_on[0]
            save_settings()
        end
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()
        imgui.Text("Положение надписи на экране:")
        imgui.Spacing()
        if not payday_edit then
            if imgui.Button(ic("UP_DOWN_LEFT_RIGHT", "") .. " Передвинуть надпись", imgui.ImVec2(360, 56)) then
                payday_edit = true
                payday_on[0] = true
            end
        else
            imgui.TextColored(imgui.ImVec4(0.45, 1.00, 0.55, 1.00), "Перетащи надпись мышкой, затем нажми «Сохранить».")
            if imgui.Button(FA.FLOPPY_DISK .. " Сохранить положение", imgui.ImVec2(360, 56)) then
                settings.payday.x = payday_pos.x
                settings.payday.y = payday_pos.y
                settings.payday.enabled = payday_on[0]
                save_settings()
                payday_edit = false
                notify("Положение надписи сохранено", "ok")
            end
        end
        imgui.Spacing()
        imgui.TextDisabled("Сейчас: " .. payday_text())
        imgui.SetWindowFontScale(1.0)
    end
    imgui.EndChild()
end

local about_links = {
    { icon = "PAPER_PLANE", logo = "tg", title = "Telegram-канал",              sub = "Актуальные цены и новости",    url = "https://t.me/arizona_prices",                 color = {0.16, 0.62, 0.86} },
    { icon = "COMMENTS",    logo = "ds", title = "Discord-канал",               sub = "Общение и обновления",         url = "https://discord.gg/z4UmCnRwd",                color = {0.35, 0.40, 0.95} },
    { icon = "MUSIC",       logo = "tt", title = "TikTok-канал",                sub = "Видео и обзоры",               url = "https://www.tiktok.com/@cosmychesky_jetpack", color = {0.86, 0.15, 0.40} },
    { icon = "USER",        logo = "ds", title = "Discord разработчика",        sub = "Нажми, чтобы скопировать ник", copy = "sawnoff_karabin07", color = {0.35, 0.40, 0.95} },
    { icon = "PAPER_PLANE", logo = "tg", title = "ЛС Разработчика",             sub = "Баги, идеи, предложения",      url = "https://t.me/xi_vivide",                      color = {0.16, 0.62, 0.86} },
    { icon = "PAPER_PLANE", logo = "tg", title = "ЛС Разработчика 2",           sub = "Кодер",                        url = "https://t.me/obrezik",                        color = {0.16, 0.62, 0.86} },
}

-- ===================== Вкладка "О скрипте" =====================
UIFX.about = { hv = {} }

-- светлая версия цвета (k: 0 = белый, 1 = сам цвет) сразу в формате col32
function UIFX.alc(c, k, a)
    return col32(c[1] * k + (1 - k), c[2] * k + (1 - k), c[3] * k + (1 - k), a)
end

function UIFX.about_body()
    local V = imgui.ImVec2
    local now = imgui.GetTime()
    local dt = imgui.GetIO().DeltaTime
    local ac = UI_CFG.accent
    local dl = imgui.GetWindowDrawList()
    local avail = imgui.GetContentRegionAvail().x
    local p = imgui.GetCursorScreenPos()
    local appear = clamp((now - UIFX.table_t) / 0.9, 0, 1)
    local ae = 1 - (1 - appear) ^ 3

    -- ---------- шапка ----------
    local hh = 150
    local x0, y0, x1, y1 = p.x, p.y, p.x + avail, p.y + hh
    local bg = dark(0.055)
    dl:AddRectFilled(V(x0, y0), V(x1, y1), col32(bg.x, bg.y, bg.z, 1), 14)
    for i = 0, 7 do
        local k = i / 8
        dl:AddRectFilled(V(x0, y0), V(x1, y0 + hh * (1 - k)), col32(ac[1], ac[2], ac[3], 0.040), 14)
    end
    dl:PushClipRect(V(x0, y0), V(x1, y1), true)
    for i = 1, 3 do
        local ox = avail * (0.25 + 0.25 * i) + math.sin(now * (0.5 + i * 0.17) + i) * 40
        local oy = y0 + hh * 0.5 + math.cos(now * (0.4 + i * 0.13) + i * 2) * 26
        for r = 6, 1, -1 do
            dl:AddCircleFilled(V(x0 + ox, oy), 18 * r * 0.9, col32(ac[1], ac[2], ac[3], 0.018), 32)
        end
    end
    dl:PopClipRect()
    dl:AddRect(V(x0, y0), V(x1, y1), col32(ac[1], ac[2], ac[3], 0.55), 14, 0, 1.4)

    -- значок
    local ls = 96
    local lx, ly = x0 + 24, y0 + (hh - ls) / 2 - 2 * math.sin(now * 1.6)
    for k = 4, 1, -1 do
        dl:AddRectFilled(V(lx - k * 3, ly - k * 3), V(lx + ls + k * 3, ly + ls + k * 3), col32(ac[1], ac[2], ac[3], 0.05), 22 + k * 3)
    end
    local logo = UIFX.logo_tex and UIFX.logo_tex() or nil
    if logo then
        UIFX.photo(dl, logo, V(lx, ly), V(lx + ls, ly + ls), 0, col32(1, 1, 1, 1), ls / 2)
        dl:AddCircle(V(lx + ls / 2, ly + ls / 2), ls / 2, col32(ac[1], ac[2], ac[3], 0.9), 48, 1.6)
    else
        -- запасной вариант, если картинка не загрузилась: старый значок с долларом
        dl:AddRectFilled(V(lx, ly), V(lx + ls, ly + ls), col32(ac[1], ac[2], ac[3], 1), 20)
        UIFX.grad(dl, lx + 3, ly + 3, lx + ls - 3, ly + ls * 0.55, 0.35, 0.0, 1, 1, 1)
        imgui.SetWindowFontScale(2.6)
        local gi = ic("CIRCLE_DOLLAR", "$")
        local gs = imgui.CalcTextSize(gi)
        dl:AddText(V(lx + (ls - gs.x) / 2, ly + (ls - gs.y) / 2), col32(0.06, 0.05, 0.04, 1), gi)
    end

    -- название
    local tx = lx + ls + 22
    imgui.SetWindowFontScale(2.0)
    local ts = imgui.CalcTextSize("ARIZONA PRICES")
    local ty = y0 + 26
    dl:AddText(V(tx + 2, ty + 2), col32(0, 0, 0, 0.55), "ARIZONA PRICES")
    dl:AddText(V(tx, ty), col32(1, 1, 1, 1), "ARIZONA PRICES")
    imgui.SetWindowFontScale(1.1)
    dl:AddText(V(tx, ty + ts.y + 4), UIFX.alc(ac, 0.55, 0.95), "Актуальные цены на аксессуары и скины")
    imgui.SetWindowFontScale(1.0)

    -- плашки: версия и автообновление
    local by = y1 - 38
    local vtxt = "v" .. SCRIPT_VERSION
    local vs = imgui.CalcTextSize(vtxt)
    dl:AddRectFilled(V(tx, by), V(tx + vs.x + 22, by + 24), col32(ac[1], ac[2], ac[3], 0.22), 12)
    dl:AddRect(V(tx, by), V(tx + vs.x + 22, by + 24), col32(ac[1], ac[2], ac[3], 0.9), 12, 0, 1.2)
    dl:AddText(V(tx + 11, by + (24 - vs.y) / 2), UIFX.alc(ac, 0.4, 1), vtxt)
    local on = UIFX.get_auto and UIFX.get_auto() or false
    local stxt = on and "Автообновление цен включено" or "Автообновление цен выключено"
    local ss = imgui.CalcTextSize(stxt)
    local sx = tx + vs.x + 22 + 10
    local sc = on and { 0.30, 0.85, 0.45 } or { 0.90, 0.45, 0.35 }
    dl:AddRectFilled(V(sx, by), V(sx + ss.x + 36, by + 24), col32(sc[1], sc[2], sc[3], 0.14), 12)
    local pulse = 0.55 + 0.45 * math.sin(now * 3)
    dl:AddCircleFilled(V(sx + 14, by + 12), 6, col32(sc[1], sc[2], sc[3], 0.25 * pulse), 16)
    dl:AddCircleFilled(V(sx + 14, by + 12), 3.5, col32(sc[1], sc[2], sc[3], 1), 16)
    dl:AddText(V(sx + 26, by + (24 - ss.y) / 2), UIFX.alc(sc, 0.5, 1), stxt)
    imgui.Dummy(V(avail, hh + 12))

    -- ---------- цифры ----------
    local nitems = #items_list
    local stats = {
        { label = "Предметов в базе",      value = nitems,              icon = "LIST" },
        { label = "Коллекционных сетов",   value = #(UIFX.SETS or {}),  icon = "LAYER_GROUP" },
        { label = "Ссылок и контактов",    value = #about_links,        icon = "LINK" },
    }
    local gap = 10
    local cw = math.floor((avail - gap * 2) / 3)
    local ch = 62
    for i, st in ipairs(stats) do
        if i > 1 then imgui.SameLine(0, gap) end
        local q = imgui.GetCursorScreenPos()
        imgui.Dummy(V(cw, ch))
        local ra = clamp((now - UIFX.table_t - 0.10 - (i - 1) * 0.07) / 0.35, 0, 1)
        local re = 1 - (1 - ra) ^ 3
        UIFX.set_alpha(UIFX.base * re)
        local cb = dark(0.085)
        local qy = q.y + (1 - re) * 12
        dl:AddRectFilled(V(q.x, qy), V(q.x + cw, qy + ch), col32(cb.x, cb.y, cb.z, 1), 12)
        dl:AddRect(V(q.x, qy), V(q.x + cw, qy + ch), col32(ac[1], ac[2], ac[3], 0.28), 12, 0, 1.0)
        dl:AddRectFilled(V(q.x + 12, qy + 14), V(q.x + 15, qy + ch - 14), col32(ac[1], ac[2], ac[3], 1), 2)
        imgui.SetWindowFontScale(1.55)
        local num = tostring(math.floor(st.value * re + 0.5))
        dl:AddText(V(q.x + 26, qy + 7), UIFX.alc(ac, 0.55, 1), num)
        imgui.SetWindowFontScale(1.0)
        dl:AddText(V(q.x + 26, qy + ch - 24), col32(1, 1, 1, 0.55), st.label)
        local gl = ic(st.icon, "")
        local gls = imgui.CalcTextSize(gl)
        dl:AddText(V(q.x + cw - gls.x - 16, qy + (ch - gls.y) / 2), col32(ac[1], ac[2], ac[3], 0.55), gl)
    end
    UIFX.set_alpha(UIFX.base)
    imgui.Dummy(V(0, 8))

    -- ---------- заголовок раздела ----------
    local hp = imgui.GetCursorScreenPos()
    imgui.SetWindowFontScale(1.15)
    dl:AddText(V(hp.x + 4, hp.y), col32(1, 1, 1, 0.92), "Мы в соцсетях и связь с разработчиком")
    local hs = imgui.CalcTextSize("Мы в соцсетях и связь с разработчиком")
    imgui.SetWindowFontScale(1.0)
    dl:AddRectFilled(V(hp.x + 4, hp.y + hs.y + 3), V(hp.x + 4 + 46, hp.y + hs.y + 5), col32(ac[1], ac[2], ac[3], 1), 1)
    dl:AddRectFilled(V(hp.x + 56, hp.y + hs.y + 3.5), V(hp.x + avail, hp.y + hs.y + 4.5), col32(1, 1, 1, 0.08), 1)
    imgui.Dummy(V(avail, hs.y + 14))

    -- ---------- карточки ссылок ----------
    local cols = (avail >= 500) and 2 or 1
    local lw = math.floor((avail - gap * (cols - 1)) / cols)
    local lh = 66
    for i, l in ipairs(about_links) do
        if (i - 1) % cols ~= 0 then imgui.SameLine(0, gap) end
        local q = imgui.GetCursorScreenPos()
        local clicked = imgui.InvisibleButton("##about_link" .. i, V(lw, lh + gap - 2))
        local hv = imgui.IsItemHovered() and 1 or 0
        if hv == 1 then pcall(function() imgui.SetMouseCursor(imgui.MouseCursor.Hand) end) end
        local cur = UIFX.about.hv[i] or 0
        cur = cur + (hv - cur) * math.min(1, dt * 14)
        UIFX.about.hv[i] = cur
        if clicked then
            if l.url then
                open_url(l.url)
            elseif l.copy then
                imgui.SetClipboardText(l.copy)
                notify("Ник скопирован: " .. l.copy, "ok")
            end
        end
        local ra = clamp((now - UIFX.table_t - 0.25 - (i - 1) * 0.06) / 0.30, 0, 1)
        local re = 1 - (1 - ra) ^ 3
        UIFX.set_alpha(UIFX.base * re)
        local c = l.color
        local cx0, cy0 = q.x, q.y + (1 - re) * 14 - cur * 2
        local cx1, cy1 = cx0 + lw, cy0 + lh
        if cur > 0.02 then
            for k = 4, 1, -1 do
                dl:AddRectFilled(V(cx0 - k * 2, cy0 - k * 2), V(cx1 + k * 2, cy1 + k * 2 + 2), col32(c[1], c[2], c[3], 0.05 * cur), 14 + k * 2)
            end
        end
        local cb = dark(0.085 + 0.02 * cur)
        dl:AddRectFilled(V(cx0, cy0), V(cx1, cy1), col32(cb.x, cb.y, cb.z, 1), 12)
        dl:AddRectFilled(V(cx0, cy0), V(cx1, cy1), col32(c[1], c[2], c[3], 0.04 + 0.14 * cur), 12)
        dl:AddRect(V(cx0, cy0), V(cx1, cy1), col32(c[1], c[2], c[3], 0.25 + 0.65 * cur), 12, 0, 1.0 + 0.6 * cur)
        -- иконка в цветном круге
        local cr = 25
        local ccx, ccy = cx0 + 16 + cr, cy0 + lh / 2
        local ltex = l.logo and UIFX.icon_tex and UIFX.icon_tex(l.logo) or nil
        dl:AddCircleFilled(V(ccx, ccy), cr + 3 + 3 * cur, col32(c[1], c[2], c[3], 0.20 + 0.12 * cur), 40)
        if ltex then
            -- официальный логотип занимает весь кружок
            UIFX.photo(dl, ltex, V(ccx - cr, ccy - cr), V(ccx + cr, ccy + cr), 0, col32(1, 1, 1, 1), cr)
        else
            dl:AddCircleFilled(V(ccx, ccy), cr - 3, col32(c[1], c[2], c[3], 1), 32)
            imgui.SetWindowFontScale(1.2)
            local gl = ic(l.icon, "")
            local gls = imgui.CalcTextSize(gl)
            dl:AddText(V(ccx - gls.x / 2, ccy - gls.y / 2), 0xFFFFFFFF, gl)
            imgui.SetWindowFontScale(1.0)
        end
        -- текст
        local tx2 = ccx + cr + 16
        imgui.SetWindowFontScale(1.1)
        dl:AddText(V(tx2, cy0 + 13), col32(1, 1, 1, 0.97), l.title)
        imgui.SetWindowFontScale(1.0)
        dl:AddText(V(tx2, cy0 + 37), col32(1, 1, 1, 0.50), l.sub or "")
        -- стрелка справа
        local ar = ic(l.copy and "COPY" or "ARROW_UP_RIGHT_FROM_SQUARE", ">")
        local ars = imgui.CalcTextSize(ar)
        dl:AddText(V(cx1 - ars.x - 18 + cur * 2, cy0 + (lh - ars.y) / 2), col32(c[1], c[2], c[3], 0.45 + 0.55 * cur), ar)
    end
    UIFX.set_alpha(UIFX.base)

    -- ---------- подпись ----------
    imgui.Dummy(V(0, 6))
    local fp = imgui.GetCursorScreenPos()
    local msg = "Спасибо, что пользуешься скриптом!  Нашёл ошибку или есть идея - пиши разработчику."
    local ms = imgui.CalcTextSize(msg)
    dl:AddText(V(fp.x + math.max(0, (avail - ms.x) / 2), fp.y), col32(1, 1, 1, 0.45), msg)
    imgui.Dummy(V(avail, ms.y + 14))
end

local function draw_about_tab()
    section_header(ic("CIRCLE_INFO", ""), "О скрипте")
    if imgui.BeginChild("##about_child", imgui.ImVec2(-1, LAYOUT.h - 79), true) then
        local ok, err = pcall(UIFX.about_body)
        if not ok then
            UIFX.set_alpha(UIFX.base)
            imgui.SetWindowFontScale(1.0)
            log_error("about_tab", err)
            imgui.TextWrapped("Вкладка временно недоступна. Подробности в файле arizona_prices_errors.log")
        end
    end
    imgui.EndChild()
end

local function shadow_text(color, text)
    local p = imgui.GetCursorScreenPos()
    imgui.GetWindowDrawList():AddText(imgui.ImVec2(p.x + 1, p.y + 1), 0xFF000000, text)
    imgui.TextColored(color, text)
end

-- ===================== Автообновление (скрипт и цены) =====================
-- (версия задана в начале файла: SCRIPT_VERSION)
local UPDATE_BASE = "https://raw.githubusercontent.com/hydracrmpdesign-commits/arizona-prices/main/"
local CHECK_EVERY = 1800 -- проверять обновления раз в 30 минут
local cfg_dir = getWorkingDirectory() .. "\\config\\"
local state_path = cfg_dir .. "arizona_prices_state.json"
local state = { prices_sig = "", auto_prices = true }
function UIFX.get_auto() return state.auto_prices ~= false end
local update_info = { available = false, version = "", busy = false, status = "" }
local dl_done = {}
local need_reload = false
local manual_check = false
local busy_since = 0

local ok_moon, moon = pcall(require, 'moonloader')
local dlstatus = ok_moon and moon.download_status or nil

local function read_file(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local c = f:read("*a")
    f:close()
    return c
end

local function write_file(path, content)
    local f = io.open(path, "wb")
    if not f then return false end
    f:write(content)
    f:close()
    return true
end

local function load_state()
    local c = read_file(state_path)
    if c then
        local ok, d = pcall(decodeJson, c)
        if ok and type(d) == "table" then
            if type(d.prices_sig) == "string" then state.prices_sig = d.prices_sig end
            if d.auto_prices == false then state.auto_prices = false end
        end
    end
end

local function save_state()
    if not doesDirectoryExist(cfg_dir) then createDirectory(cfg_dir) end
    safe_write(state_path, encodeJson(state))
end

safe_call("load_state", load_state)

local auto_prices_cb = imgui.new.bool(state.auto_prices)

local function version_newer(remote, current)
    local a, b = {}, {}
    for n in tostring(remote):gmatch("%d+") do a[#a + 1] = tonumber(n) end
    for n in tostring(current):gmatch("%d+") do b[#b + 1] = tonumber(n) end
    for i = 1, math.max(#a, #b) do
        local x, y = a[i] or 0, b[i] or 0
        if x ~= y then return x > y end
    end
    return false
end

local function signature(s)
    local sum = 0
    for i = 1, #s do sum = (sum * 31 + s:byte(i)) % 4294967291 end
    return #s .. ":" .. sum
end

-- скачивание: сам колбэк только ставит флаг, всю работу делает основной поток
local function fetch(name, dest, flag)
    os.remove(dest)
    if not dlstatus or not downloadUrlToFile then
        update_info.status = "Загрузка недоступна"
        return false
    end
    local url = UPDATE_BASE .. name .. "?t=" .. os.time()
    local ok = pcall(downloadUrlToFile, url, dest, function(id, status, p1, p2)
        if status == dlstatus.STATUSEX_ENDDOWNLOAD then
            dl_done[flag] = true
        end
    end)
    return ok
end

local function start_checks()
    if not doesDirectoryExist(cfg_dir) then createDirectory(cfg_dir) end
    fetch("version.txt", cfg_dir .. "arizona_prices_remote_version.txt", "version")
    if state.auto_prices then
        fetch("item_prices.json", cfg_dir .. "arizona_prices_remote.json", "prices")
    end
end

local function handle_version()
    local path = cfg_dir .. "arizona_prices_remote_version.txt"
    local c = read_file(path)
    os.remove(path)
    local v = c and c:match("%d[%d%.]*")
    if v and version_newer(v, SCRIPT_VERSION) then
        if not update_info.available then
            notify("Вышла новая версия " .. v .. "! Откройте /prices и нажмите «Обновить»", "info", 8)
        end
        update_info.available = true
        update_info.version = v
        update_info.status = ""
    elseif manual_check then
        update_info.status = v and "У вас последняя версия" or "Не удалось проверить"
    end
    manual_check = false
end

local function handle_script()
    local dest = cfg_dir .. "arizona_prices_update.lua"
    local c = read_file(dest)
    update_info.busy = false
    if not c or #c < 2000 then
        update_info.status = "Ошибка загрузки"
        return
    end
    if not loadstring(c) then
        update_info.status = "Файл повреждён"
        return
    end
    local cur = thisScript().path
    local old = read_file(cur)
    if old then write_file(cfg_dir .. "Table_Prices.lua.bak", old) end
    if write_file(cur, c) then
        os.remove(dest)
        update_info.status = "Готово, перезапуск..."
        need_reload = true
    else
        update_info.status = "Не удалось записать файл"
    end
end

local function handle_prices()
    local path = cfg_dir .. "arizona_prices_remote.json"
    local c = read_file(path)
    os.remove(path)
    if not c or #c < 2 then return end
    local sig = signature(c)
    local ok, remote = pcall(decodeJson, c)
    if not ok or type(remote) ~= "table" then return end

    -- обычный игрок: список всегда ТОЧНО равен списку из канала (так нельзя подкрутить цены у себя и обмануть другого)
    if not ADM.on then
        local fresh = {}
        for _, r in ipairs(remote) do
            local buy = type(r) == "table" and tonumber(r.buy) or nil
            local sell = type(r) == "table" and tonumber(r.sell) or nil
            if buy and sell and type(r.item) == "string" then
                fresh[#fresh + 1] = { item = r.item, buy = buy, sell = sell, liq = ADM.valid_liq(r.liq) }
            end
        end
        if #fresh == 0 then return end
        local same = false
        local okc, a1, a2 = pcall(function() return encodeJson(fresh), encodeJson(items_list) end)
        if okc and a1 == a2 then same = true end
        if not same then
            items_list = fresh
            save_data()
            if sig ~= state.prices_sig then notify("Цены обновлены из канала", "ok", 5) end
        end
        state.prices_sig = sig
        save_state()
        return
    end

    -- разработчик: свои правки не затираем, только подтягиваем новые предметы и цены
    if sig == state.prices_sig then return end
    local index = {}
    for i, it in ipairs(items_list) do
        if it.item then index[it.item] = i end
    end
    local added, changed = 0, 0
    for _, r in ipairs(remote) do
        local buy = type(r) == "table" and tonumber(r.buy) or nil
        local sell = type(r) == "table" and tonumber(r.sell) or nil
        if buy and sell and type(r.item) == "string" then
            local i = index[r.item]
            if i then
                local l = items_list[i]
                if tonumber(l.buy) ~= buy or tonumber(l.sell) ~= sell then
                    l.buy, l.sell = buy, sell
                    changed = changed + 1
                end
            else
                items_list[#items_list + 1] = { item = r.item, buy = buy, sell = sell, liq = ADM.valid_liq(r.liq) }
                index[r.item] = #items_list
                added = added + 1
            end
        end
    end
    state.prices_sig = sig
    save_state()
    if added + changed > 0 then
        save_data()
        notify("Цены обновлены: новых " .. added .. ", изменено " .. changed, "ok", 5)
    end
end

local function process_updates()
    if dl_done.version then dl_done.version = nil; pcall(handle_version) end
    if dl_done.script then dl_done.script = nil; pcall(handle_script) end
    if dl_done.prices then dl_done.prices = nil; pcall(handle_prices) end
    if update_info.busy and os.time() - busy_since > 40 then
        update_info.busy = false
        update_info.status = "Не удалось скачать"
    end
end

local outdated_popup = imgui.new.bool(false)

local function start_update()
    update_info.busy = true
    update_info.status = ""
    busy_since = os.time()
    if not fetch("Table_Prices.lua", cfg_dir .. "arizona_prices_update.lua", "script") then
        update_info.busy = false
        if update_info.status == "" then update_info.status = "Ошибка загрузки" end
    end
end

local function request_update()
    update_info.busy = true
    update_info.status = ""
    busy_since = os.time()
    defer(start_update)
end

local function draw_update_block()
    imgui.SetCursorPos(imgui.ImVec2(5, LAYOUT.block_y))
    imgui.TextDisabled("Версия " .. SCRIPT_VERSION)
    imgui.SetCursorPosX(5)
    if update_info.available then
        imgui.TextColored(imgui.ImVec4(0.45, 1.00, 0.55, 1.00), "Вышла версия " .. update_info.version)
        imgui.SetCursorPosX(5)
        if update_info.busy then
            imgui.TextDisabled("Скачивание...")
        elseif imgui.Button(ic("DOWNLOAD", "") .. " Обновить##do_update", imgui.ImVec2(SIDEBAR_W - 10, 32)) then
            request_update()
        end
    else
        if imgui.Button(ic("ARROWS_ROTATE", "") .. " Проверить##check_update", imgui.ImVec2(SIDEBAR_W - 10, 28)) then
            manual_check = true
            update_info.status = "Проверка..."
            defer(start_checks)
        end
    end
    if update_info.status ~= "" then
        imgui.SetCursorPosX(5)
        imgui.TextDisabled(update_info.status)
    end
    imgui.SetCursorPosX(5)
    if imgui.Checkbox(" Автообновление цен##auto_prices", auto_prices_cb) then
        state.auto_prices = auto_prices_cb[0]
        save_state()
        if state.auto_prices then defer(start_checks) end
    end
end

-- ===================== Настройки, отчёт об ошибке, горячая клавиша =====================
local hk = { binding = false, typing = false }
local vkeys_ok, vkeys = pcall(require, 'vkeys')

local function key_name(code)
    if not code or code == 0 then return "Не задана" end
    if vkeys_ok and vkeys.id_to_name then
        local n = vkeys.id_to_name(code)
        if n then return n end
    end
    return "VK " .. tostring(code)
end

local sui = {
    accent = imgui.new.float[3](UI_CFG.accent[1], UI_CFG.accent[2], UI_CFG.accent[3]),
    opacity = imgui.new.float(UI_CFG.opacity),
    scale = imgui.new.float(UI_CFG.overlay_scale),
    toasts = imgui.new.bool(UI_CFG.toasts),
    border_speed = imgui.new.float(UI_CFG.border_speed),
    shadow = imgui.new.bool(UI_CFG.shadow),
    bg_fx = imgui.new.bool(UI_CFG.bg_fx),
    splash = imgui.new.bool(UI_CFG.splash),
    halloween = imgui.new.bool(UI_CFG.halloween),
    font_pending = false,
}

local ui_dirty_at = nil
local function mark_ui_dirty()
    ui_dirty_at = os.clock()
end

local function flush_ui_save(force)
    if ui_dirty_at and (force or os.clock() - ui_dirty_at > 0.8) then
        ui_dirty_at = nil
        save_settings()
    end
end

-- ===================== Окно авторизации (код из телеграм-канала) =====================
-- ВАЖНО: чтобы сменить код, поменяй ACCESS_CODE и выложи новую версию скрипта.
-- Все данные окна лежат в одной таблице AUTH, чтобы не тратить локальные переменные.
local AUTH = {
    ACCESS_CODE = "PRICES2026",
    path = getWorkingDirectory() .. "\\config\\arizona_prices_auth.json",
    open = imgui.new.bool(false),
    nick = imgui.new.char[48](),
    code = imgui.new.char[48](),
    error = "",
    ok = false,
}

-- уже входил с этим кодом раньше?
do
    local d = safe_read_json(AUTH.path)
    if type(d) == "table" and tostring(d.code or ""):lower() == AUTH.ACCESS_CODE:lower() then
        AUTH.ok = true
    end
end

function AUTH.try_login()
    local nick = ffi.string(AUTH.nick):gsub("^%s+", ""):gsub("%s+$", "")
    local code = ffi.string(AUTH.code):gsub("%s", "")
    if nick == "" then AUTH.error = "Введите ваш никнейм"; return end
    if code == "" then AUTH.error = "Введите код из телеграм-канала"; return end
    if AUTH.loading then return end
    AUTH.error = ""
    AUTH.loading = { t = imgui.GetTime(), nick = nick, code = code }
end

-- фаза 2 (через 3 секунды): проверяем код и открываем меню
function AUTH.finish()
    local nick, code = AUTH.loading.nick, AUTH.loading.code
    AUTH.loading = nil
    if code:lower() ~= AUTH.ACCESS_CODE:lower() then
        AUTH.error = "Неверный код. Получите актуальный код в телеграм-канале"
        return
    end
    AUTH.ok = true
    AUTH.error = ""
    AUTH.open[0] = false
    local dir = getWorkingDirectory() .. "\\config"
    if not doesDirectoryExist(dir) then createDirectory(dir) end
    write_file_raw(AUTH.path, encodeJson({ nick = nick, code = code }))
    notify("Доступ открыт. Добро пожаловать, " .. nick .. "!", "ok", 5)
    main_window[0] = true
end

imgui.OnFrame(function() return AUTH.open[0] end, guard_frame("auth", function()
    local sw, sh = getScreenResolution()
    local W, H = 560, 380
    imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(W, H), imgui.Cond.Always)
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.075, 0.07, 0.095, 1.0))
    imgui.Begin("##auth_window", nil, bit.bor(imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.NoResize,
        imgui.WindowFlags.NoCollapse, imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoSavedSettings))
    local p = imgui.GetWindowPos()
    local ac = UI_CFG.accent
    imgui.GetWindowDrawList():AddRectFilled(p, imgui.ImVec2(p.x + W, p.y + 5), col32(ac[1], ac[2], ac[3], 1))

    imgui.SetCursorPos(imgui.ImVec2(26, 24))
    imgui.SetWindowFontScale(1.7)
    imgui.TextColored(accent_vec(1.2), ic("LOCK", "") .. " Авторизация")
    imgui.SetWindowFontScale(1.15)
    imgui.SetCursorPos(imgui.ImVec2(26, 76))
    imgui.PushTextWrapPos(W - 26)
    imgui.TextWrapped("Вы попали в окно авторизации. Введите свой никнейм и код. Код можно получить в телеграм-канале.")
    imgui.PopTextWrapPos()

    if AUTH.loading then
        -- экран «Загрузка...»: крутящийся индикатор, меняющиеся статусы и полоска прогресса
        local now = imgui.GetTime()
        local k = clamp((now - AUTH.loading.t) / 3.0, 0, 1)
        local dl = imgui.GetWindowDrawList()
        local cx, cy = p.x + W / 2, p.y + 165
        for i = 0, 11 do
            local ang = i / 12 * math.pi * 2 - now * 6
            local fade = ((i / 12) - (now * 1.5) % 1) % 1
            dl:AddCircleFilled(imgui.ImVec2(cx + math.cos(ang) * 34, cy + math.sin(ang) * 34), 5.5,
                col32(ac[1], ac[2], ac[3], 0.15 + 0.85 * (1 - fade)), 12)
        end
        local steps = { "Подключение к серверу...", "Проверка кода...", "Верификация никнейма...", "Доступ разрешён" }
        local st = steps[math.min(#steps, 1 + math.floor(k * #steps))]
        imgui.SetCursorPos(imgui.ImVec2(0, 232))
        imgui.SetWindowFontScale(1.6)
        local dots = string.rep(".", math.floor(now * 3) % 4)
        local title = "Загрузка" .. dots
        imgui.SetCursorPosX((W - imgui.CalcTextSize("Загрузка...").x) / 2)
        imgui.Text(title)
        imgui.SetWindowFontScale(1.1)
        imgui.SetCursorPosX((W - imgui.CalcTextSize(st).x) / 2)
        imgui.TextColored(imgui.ImVec4(0.65, 0.65, 0.72, 1), st)
        imgui.SetCursorPos(imgui.ImVec2(60, H - 46))
        imgui.PushStyleColor(imgui.Col.PlotHistogram, accent_vec(1.1))
        imgui.ProgressBar(k, imgui.ImVec2(W - 120, 10), "")
        imgui.PopStyleColor(1)
        imgui.SetWindowFontScale(1.0)
        imgui.End()
        imgui.PopStyleColor(1)
        if k >= 1 then AUTH.finish() end
        return
    end

    imgui.SetCursorPos(imgui.ImVec2(26, 150))
    imgui.SetNextItemWidth(W - 52)
    imgui.InputTextWithHint("##auth_nick", "Ваш никнейм", AUTH.nick, ffi.sizeof(AUTH.nick))
    imgui.SetCursorPosX(26)
    imgui.SetNextItemWidth(W - 52)
    local enter = imgui.InputTextWithHint("##auth_code", "Код из телеграм-канала", AUTH.code, ffi.sizeof(AUTH.code), imgui.InputTextFlags.EnterReturnsTrue)
    if enter then AUTH.try_login() end

    imgui.SetCursorPosX(26)
    if AUTH.error ~= "" then
        imgui.TextColored(imgui.ImVec4(1.0, 0.4, 0.4, 1.0), AUTH.error)
    else
        imgui.Text(" ")
    end

    imgui.SetCursorPos(imgui.ImVec2(26, H - 26 - 46))
    local bw = (W - 52 - 20) / 3
    imgui.PushStyleColor(imgui.Col.Button, accent_vec(1.0))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, accent_vec(1.15))
    imgui.PushStyleColor(imgui.Col.ButtonActive, accent_vec(0.85))
    if imgui.Button(ic("RIGHT_TO_BRACKET", "") .. " Войти##auth_go", imgui.ImVec2(bw, 46)) then AUTH.try_login() end
    imgui.PopStyleColor(3)
    imgui.SameLine()
    if imgui.Button(ic("PAPER_PLANE", "") .. " Получить код##auth_tg", imgui.ImVec2(bw + 40, 46)) then
        open_url("https://t.me/arizona_prices")
    end
    imgui.SameLine()
    if imgui.Button(FA.CIRCLE_XMARK .. " Закрыть##auth_close", imgui.ImVec2(bw - 40, 46)) then AUTH.open[0] = false end
    imgui.SetWindowFontScale(1.0)
    imgui.End()
    imgui.PopStyleColor(1)
end, function() AUTH.open[0] = false; AUTH.loading = nil end))

local function toggle_menu()
    if not AUTH.ok then
        -- нет доступа: показываем окно авторизации вместо меню
        main_window[0] = false
        AUTH.loading = nil
        AUTH.open[0] = not AUTH.open[0]
        if AUTH.open[0] and ffi.string(AUTH.nick) == "" then
            local okn, id = pcall(function() local _, i = sampGetPlayerIdByCharHandle(PLAYER_PED); return sampGetPlayerNickname(i) end)
            if okn and id then imgui.StrCopy(AUTH.nick, id) end
        end
        return
    end
    main_window[0] = not main_window[0]
    if main_window[0] and update_info.available then
        outdated_popup[0] = true
    end
end

local function on_window_message(msg, wparam, lparam)
    if msg ~= 0x100 and msg ~= 0x104 then return end
    local is_repeat = bit.band(lparam, 0x40000000) ~= 0

    if hk.binding then
        consumeWindowMessage(true, true)
        if is_repeat then return end
        hk.binding = false
        if wparam == 0x08 then
            UI_CFG.open_key = 0
            mark_ui_dirty()
            notify("Горячая клавиша убрана", "info")
        elseif wparam ~= 0x1B then
            UI_CFG.open_key = wparam
            mark_ui_dirty()
            notify("Клавиша открытия меню: " .. key_name(wparam), "ok")
        end
        return
    end

    if is_repeat then return end

    -- горячие клавиши внутри открытого меню: цифры 1-6 переключают вкладки, Ctrl+F - поиск по таблице
    if main_window[0] and UIFX.alpha > 0.5 and not hk.typing then
        local okc, busy = pcall(function() return sampIsChatInputActive() or sampIsDialogActive() end)
        if not (okc and busy) then
            if wparam >= 0x31 and wparam <= 0x36 then
                UIFX.pending_tab = UIFX.TAB_ORDER[wparam - 0x30]
                consumeWindowMessage(true, true)
                return
            elseif wparam == 0x46 then
                local okk, ctrl = pcall(isKeyDown, 0x11)
                if okk and ctrl then
                    UIFX.pending_tab = 1
                    UIFX.focus_search = true
                    consumeWindowMessage(true, true)
                    return
                end
            end
        end
    end

    local key = UI_CFG.open_key
    if key and key ~= 0 and wparam == key then
        local okc, busy = pcall(function() return sampIsChatInputActive() or sampIsDialogActive() end)
        if okc and busy then return end
        if main_window[0] and hk.typing then return end
        toggle_menu()
    end
end

local function build_report()
    local lines = {}
    local function add(t) lines[#lines + 1] = t end
    add("Arizona Prices - отчёт об ошибке")
    add("Версия скрипта: " .. SCRIPT_VERSION)
    add("Журнал ошибок: moonloader\\config\\arizona_prices_errors.log")
    add("Дата: " .. os.date("%Y-%m-%d %H:%M:%S"))
    local okv, mv = pcall(function() return getMoonloaderVersion() end)
    add("MoonLoader: " .. (okv and tostring(mv) or "?"))
    add("Lua: " .. tostring(_VERSION) .. (jit and (" / " .. tostring(jit.version)) or ""))
    local okr, rw, rh = pcall(getScreenResolution)
    add("Экран: " .. (okr and (tostring(rw) .. "x" .. tostring(rh)) or "?"))
    add("Предметов в списке: " .. #items_list)
    add("Автообновление цен: " .. tostring(state.auto_prices))
    add("Загрузка файлов: " .. ((downloadUrlToFile and dlstatus) and "доступна" or "недоступна"))
    add("Уведомления: " .. tostring(UI_CFG.toasts) .. ", горячая клавиша: " .. key_name(UI_CFG.open_key))
    if #err_log > 0 then
        add("Последние ошибки:")
        for _, e in ipairs(err_log) do add("  " .. e) end
    else
        add("Ошибок в журнале нет")
    end
    add("")
    add("Что вы делали перед ошибкой:")
    return table.concat(lines, "\n")
end

local function send_bug_report()
    local ok, text = pcall(build_report)
    local body = ok and text or ("Arizona Prices " .. SCRIPT_VERSION)
    imgui.SetClipboardText("Привет. Заметил о баге:\n\n\n" .. body)
    open_url("https://t.me/xi_vivide")
    notify("Сообщение скопировано - допишите, что случилось, и отправьте (Ctrl+V)", "ok", 6)
end

local THEMES = {
    { name = "Океан",   c = {0.18, 0.45, 0.85} }, { name = "Изумруд", c = {0.20, 0.70, 0.45} },
    { name = "Аметист", c = {0.60, 0.35, 0.90} }, { name = "Рубин",   c = {0.90, 0.30, 0.35} },
    { name = "Янтарь",  c = {0.95, 0.60, 0.15} }, { name = "Бирюза",  c = {0.15, 0.72, 0.78} },
    { name = "Сакура",  c = {0.90, 0.40, 0.70} }, { name = "Неон",    c = {0.55, 1.00, 0.20} },
}
local BORDER_MODES = { "Выключена", "Переливы цвета", "Радуга", "Статичная" }

local CORNERS = {
    { name = "Справа снизу", v = 3 }, { name = "Справа сверху", v = 1 },
    { name = "Слева снизу", v = 2 }, { name = "Слева сверху", v = 0 },
}

local function sub_title(icon_name, text)
    imgui.Spacing()
    imgui.TextColored(accent_vec(1.2), ic(icon_name, "") .. " " .. text)
    imgui.Separator()
    imgui.Spacing()
end

local function draw_settings_tab()
    section_header(ic("GEAR", ""), "Настройки")
    if imgui.BeginChild("##settings_child", imgui.ImVec2(-1, LAYOUT.h - 79), true) then
        sub_title("PALETTE", "Темы оформления")
        for i, th in ipairs(THEMES) do
            local c = th.c
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(c[1] * 0.55, c[2] * 0.55, c[3] * 0.55, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(c[1] * 0.80, c[2] * 0.80, c[3] * 0.80, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(c[1], c[2], c[3], 1.0))
            if imgui.Button(th.name .. "##theme" .. i, imgui.ImVec2(110, 30)) then
                UI_CFG.accent = { c[1], c[2], c[3] }
                sui.accent[0], sui.accent[1], sui.accent[2] = c[1], c[2], c[3]
                apply_theme()
                mark_ui_dirty()
            end
            imgui.PopStyleColor(3)
            if i % 4 ~= 0 and i < #THEMES then imgui.SameLine() end
        end
        imgui.Spacing()
        if imgui.ColorEdit3("Свой цвет##accent_custom", sui.accent, imgui.ColorEditFlags.NoInputs) then
            UI_CFG.accent = { sui.accent[0], sui.accent[1], sui.accent[2] }
            apply_theme()
            mark_ui_dirty()
        end
        imgui.SetNextItemWidth(260)
        if imgui.SliderFloat("Прозрачность окна##opacity", sui.opacity, 0.3, 1.0, "%.2f") then
            UI_CFG.opacity = sui.opacity[0]
            apply_theme()
            mark_ui_dirty()
        end

        sub_title("WAND_MAGIC_SPARKLES", "Рамка и эффекты")
        imgui.SetNextItemWidth(220)
        if imgui.BeginCombo("Рамка окна##border_mode", BORDER_MODES[UI_CFG.border_mode + 1] or BORDER_MODES[2]) then
            for i, name in ipairs(BORDER_MODES) do
                if imgui.Selectable(name .. "##bm" .. i, UI_CFG.border_mode == i - 1) then
                    UI_CFG.border_mode = i - 1
                    mark_ui_dirty()
                end
            end
            imgui.EndCombo()
        end
        if UI_CFG.border_mode == 1 or UI_CFG.border_mode == 2 then
            imgui.SetNextItemWidth(260)
            if imgui.SliderFloat("Скорость переливов##border_speed", sui.border_speed, 0.2, 3.0, "%.1f") then
                UI_CFG.border_speed = sui.border_speed[0]
                mark_ui_dirty()
            end
        end
        if imgui.Checkbox("Тень под окном##shadow", sui.shadow) then
            UI_CFG.shadow = sui.shadow[0]
            mark_ui_dirty()
        end
        if imgui.Checkbox("Анимированный фон##bgfx", sui.bg_fx) then
            UI_CFG.bg_fx = sui.bg_fx[0]
            mark_ui_dirty()
        end
        if imgui.Checkbox("Заставка при первом открытии меню##splash", sui.splash) then
            UI_CFG.splash = sui.splash[0]
            mark_ui_dirty()
        end
        if imgui.Checkbox("Хэллоуин: тыквы, летучие мыши, паутина##halloween", sui.halloween) then
            UI_CFG.halloween = sui.halloween[0]
            local c = UI_CFG.halloween and { 0.98, 0.55, 0.12 } or { 0.18, 0.45, 0.85 }
            UI_CFG.accent = c
            sui.accent[0], sui.accent[1], sui.accent[2] = c[1], c[2], c[3]
            apply_theme()
            mark_ui_dirty()
        end

        sub_title("FONT", "Шрифт")
        local font_name = FONT_AVAILABLE[1].name
        for _, f in ipairs(FONT_AVAILABLE) do
            if f.key == UI_CFG.font then font_name = f.name end
        end
        imgui.SetNextItemWidth(260)
        if imgui.BeginCombo("Шрифт интерфейса##font", font_name) then
            for _, f in ipairs(FONT_AVAILABLE) do
                if imgui.Selectable(f.name .. "##font_" .. f.key, UI_CFG.font == f.key) then
                    UI_CFG.font = f.key
                    sui.font_pending = true
                    mark_ui_dirty()
                end
            end
            imgui.EndCombo()
        end
        if sui.font_pending then
            if imgui.Button(ic("ARROWS_ROTATE", "") .. " Применить шрифт (перезапуск скрипта)##apply_font", imgui.ImVec2(360, 28)) then
                defer(function()
                    flush_ui_save(true)
                    thisScript():reload()
                end)
            end
        else
            imgui.TextDisabled("Шрифт меняется после перезапуска скрипта. Берётся из папки Fonts в Windows.")
        end

        sub_title("EXPAND", "Надписи на экране")
        imgui.SetNextItemWidth(260)
        if imgui.SliderFloat("Размер надписей на экране##overlay_scale", sui.scale, 0.7, 2.0, "%.1f") then
            UI_CFG.overlay_scale = sui.scale[0]
            mark_ui_dirty()
        end
        imgui.TextDisabled("Касается надписей PayDay и часов, которые показываются поверх игры.")
        imgui.Spacing()
        if imgui.Button(ic("ROTATE_LEFT", "") .. " Сбросить внешний вид##reset_look", imgui.ImVec2(230, 28)) then
            UI_CFG.accent = UI_CFG.halloween and { 0.98, 0.55, 0.12 } or { 0.18, 0.45, 0.85 }
            UI_CFG.opacity = 1.0
            UI_CFG.overlay_scale = 1.0
            UI_CFG.border_mode = 1
            UI_CFG.border_speed = 1.0
            UI_CFG.shadow = true
            if UI_CFG.font ~= "seguisb" then
                UI_CFG.font = "seguisb"
                sui.font_pending = true
            end
            sui.accent[0], sui.accent[1], sui.accent[2] = UI_CFG.accent[1], UI_CFG.accent[2], UI_CFG.accent[3]
            sui.opacity[0] = 1.0
            sui.scale[0] = 1.0
            sui.border_speed[0] = 1.0
            sui.shadow[0] = true
            apply_theme()
            mark_ui_dirty()
        end
        imgui.SameLine()
        if imgui.Button(ic("EXPAND", "") .. " Сбросить размер окна##reset_size", imgui.ImVec2(230, 28)) then
            LAYOUT.force = true
        end

        sub_title("KEYBOARD", "Управление")
        imgui.AlignTextToFramePadding()
        imgui.Text("Клавиша открытия меню:")
        imgui.SameLine()
        local bind_label = hk.binding and "Нажмите клавишу..." or key_name(UI_CFG.open_key)
        if imgui.Button(bind_label .. "##bind_open_key", imgui.ImVec2(190, 26)) then
            hk.binding = not hk.binding
        end
        imgui.TextDisabled("Esc - отмена, Backspace - убрать клавишу. Команды /prices и /pr работают всегда.")

        sub_title("BELL", "Уведомления")
        if imgui.Checkbox("Всплывающие карточки вместо сообщений в чате", sui.toasts) then
            UI_CFG.toasts = sui.toasts[0]
            mark_ui_dirty()
        end
        local corner_name = CORNERS[1].name
        for _, c in ipairs(CORNERS) do
            if c.v == UI_CFG.toast_corner then corner_name = c.name end
        end
        imgui.SetNextItemWidth(220)
        if imgui.BeginCombo("Угол экрана##toast_corner", corner_name) then
            for _, c in ipairs(CORNERS) do
                if imgui.Selectable(c.name, c.v == UI_CFG.toast_corner) then
                    UI_CFG.toast_corner = c.v
                    mark_ui_dirty()
                end
            end
            imgui.EndCombo()
        end
        if imgui.Button(ic("BELL", "") .. " Показать пример##toast_test", imgui.ImVec2(230, 28)) then
            notify("Так выглядят уведомления", "ok")
        end

        sub_title("BUG", "Поддержка")
        if imgui.Button(ic("BUG", "") .. " Сообщить об ошибке##report_error", imgui.ImVec2(230, 30)) then
            send_bug_report()
        end
        imgui.TextDisabled("Скопирует версию скрипта и данные для диагностики и откроет Telegram разработчика.")
        if #err_log > 0 then
            imgui.TextColored(imgui.ImVec4(1.0, 0.55, 0.40, 1.0), "Записей в журнале ошибок: " .. #err_log)
        end
    end
    imgui.EndChild()
end

-- ===================== Коллекционные сеты =====================
-- Фото сетов вшиты прямо в скрипт (base64). Чтобы добавить новый сет, добавь запись в UIFX.SETS
-- (have/total - собрано предметов, c - цвет сета).
UIFX.SETS = {
    { key = "bear", name = "Сет Медведя", have = 11, total = 11, c = { 0.55, 0.85, 1.00 }, data = [[
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
]] },
    { key = "magic", name = "Магический Сет", have = 11, total = 11, c = { 0.72, 0.42, 1.00 }, data = [[
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
aJlRvcOqEKIp/9k=
]] },
    { key = "army", name = "Армейский Сет", have = 11, total = 11, c = { 0.92, 0.30, 0.30 }, data = [[
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
]] },
    { key = "police", name = "Полицейский Сет", have = 11, total = 11, c = { 1.00, 0.80, 0.25 }, data = [[
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
UIUH/9k=
]] },
    { key = "frieren", name = "Сет Фрирен", have = 11, total = 11, c = { 0.30, 0.85, 0.90 }, data = [[
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
]] },
    { key = "witch", name = "Сет Ведьмы", have = 11, total = 11, c = { 0.98, 0.55, 0.20 }, data = [[
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
]] },
    { key = "lich", name = "Сет Лича", have = 11, total = 11, c = { 0.32, 0.52, 1.00 }, data = [[
/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBUODAsLDBkSEw8VHhsgHx4bHR0hJTApISMtJB0dKjkqLTEzNjY2ICg7Pzo0PjA1NjP/
2wBDAQkJCQwLDBgODhgzIh0iMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzP/wAARCAF3ASwDASIAAhEBAxEB/8QA
HAAAAgIDAQEAAAAAAAAAAAAAAAECAwQFBgcI/8QAQhAAAQQBAwIEBAMFBgQFBQAAAQACAxEEBRIhMUEGE1FhInGBkRQyoQdCscHRFSMzUuHwJENiolNyc4KS
FjREsvH/xAAZAQEBAQEBAQAAAAAAAAAAAAAAAQMCBAX/xAAmEQEBAAIDAQACAgICAwAAAAAAAQIRAxIhMSJBBBMjYTJRcbHR/9oADAMBAAIRAxEAPwDp0qTQ
vWpITpKkAmDxXZArqUUewKAHRMDkKTWkj0SLSFNrpJ+2xagWgn4VKtx4pMNpym9LraIbbTxRSA4pWpUm10pLSkQQrqFoNd1eydVKFc4AtVVKy7SzRJoQqgTS
QoGkhNAkimhAkJoVCTQirQFpgphqdBcqSRUqRSbEKSpTpMNTZpENtTDOFICk1zasiO0J7VJCm1UITpOlo5RpFJoRCpS3OAq0kUoJtd/mPCi424pIpRdm38yn
Y4VY4KkT8PulWJ2EKDeqmVNOpQokJ2g0gVcUoEUVMFIqxzUEJ0il0hITpFIEhOkUgSE6RSBITpCBJgITATYYCKQpALmqW1OkwmubQqRSaEUIQhQCaSEFaEIW
jkIQikAhCECpCaYbai6RTTISQ0YNIJtJCBITQqEmhCBJoQiEhNCBUnSFiarlfgdJy8rdtMUTnNPvXH60gniZUebCZYnAtD3MNG+WkhXrmvAkksmgPLmOEfnk
xuf1cC1pJ+5K6ZdZyTKyJj7NhKk0Ll0E0ICgYQhCimE0gmoBCaFAkJoRSQhOlRCkx6FJMdVdoVIpSI5UU2aFBFIRRKApHRFIVDJsKKdIUCQnSdJs0ihSISpN
miQnSKV2EhOkUhokLWw6mJfEeTpg21FjskBsWXE8j7Ef7K2dK3Gz6kuyXK+PcrytEjxWup2TKGkB1EtHJ+nRbXNy52+IdMw8b4twkfktvhsdABx/93Rch45z
PP12LEa74caK6/63c/wpc0re+C5icTMxiHVDMCLPABb0H/xXTrifB2Sx2vZrGlwbNHuaO3wu/oV0mjZ02c7URO3Y+DLfEIz1a0AV9+v1QjZIUqWO/Mhjz4MJ
1+dMx72gdg2rv7qz1V9JgJ0mudhUik6QikmhCAQhCgEIQgEJJoFSE0Uug1EhSSK5XSKASUJt6q7TQqklJJNmgEuqaE2uiTQkps0aSEIBCEz06KwY+Xm4uBAZ
svIigiH78jw0ev1XPy/tB8NRSuj/AB7pK/ejge5p+Rpc14/0fXcvLnzm4z5sCEf3YZMHFgA5dt6gcLzk7nfG2IBnd26wumVysr1HQMuHM8e6tqsOSJMGODcw
hpc92/bQr81ijxXoFvNU1/WcdsjsPw5kmJgJM2QQ0UB12g39/wBFzvgDwvM6HH1rKlj8qRrvLhDSXEctBJ7d+PlysjxhGNEibHBmZDo822vxnvJBaO9ntzVL
rPLt6YzUaiLVdfyMr+2oTCDl5DMVrgG/nHIaAeQ3n5HuqNRhzotWm/tJoGWX7pCHB13VdOOnZXRS5bdO0yOIA45yBPiRgNJMgeW/FXPU1z7LE1TPyJdTndmt
dHll1ytc3aQa6V24r6LMX6RlZ+HnmfTofOnia95ZVgsAN2LHA6rO03xFqWlat5+Vp0spzoWEMbwZe7XNHToef5LRQZI3PEd73RvbYuwCCCePms7Pz5jBo8k+
+M4cVY8mx1yAOBDuRXBAHCD0DS/F2kao9kTZzBkOHEWQNhPyPQ/QrUZGTlP/AGrY2MB8EeNusO48otN3Y6l3ZZ2EzWNbghycmTBix3hr45WQte8tPPG6wPTl
bmPTYY9XfqXBnfjNgLiOSA4mz2Pbt2WmGXXf+4tm9M5CSFm7O0WkhAWi0UilQ7RaSFA0JIQNFpIQNNToIpTaoJFTUSEVFA6pptb3UCQpgJ0FUVIUyPZFBRUE
lPalSCNIU9qW1URTCdIpELpyvBPFOA3TvFOo4zWtjjbMXMaOaa74h/Fe+UvIvHOlzy+Msp7HtbC+KN75ZTtayxVX36dueUu/05yk167XwBqTtR8KwMeS6TEd
+HJLasAAt/7SPsuL8Y539o+JchrX3HjgRt9AB1P1N/ZbXwS9uha23SPxDJ5M5vmP+Et8va0kUPU+9dFpPE3h6TRdTjfJnHJyM2N8s/w7QDv44+R79wVbLPrm
3c8at+rvg1DCdZlgw5WujYaH7we4fUhZPifxHHr2XBlx4LMd4YWvp25z+eCTQ6BaV8BZKXOFhlkj0J4CTYi6O+1kfVRxtvBrWm43hXIwWYD26hNsLsoPBDgH
h1c8jp0CxjlzZuDEyWYv/D2yNpJ+FpJP8T/Bat0e4vjrcaNex6/yV+O2SIGUW6huA+QQ29X8AZbsjw8YHA/8NKWA+x5H25XVUuQ8BaBn6HDP+JnbNj5MMU0T
mkgAkEkUe4BHK7KkbY/EaRSlSKVVFCaECTQhQJCaKVCRSkhTYjSKUkJs0khCFFKkipIKCFWpN6IApMcIBCdpWqBJNCgVJUpJIBKk0IBRe5rGF7yGtAsk9lJa
LxfPJj6BJIwHYHAyOHUAAkfd20fVWfStjpmp42rYX4rFcSze5hBqwWmjdff5Ly/XsmTI8Y6pn5rdsGmu2RMIoOIHwfO+v2XN+H/Euo+Hsx8+I8ObL/ixSC2P
9/mPVbHxHrTtawn5rgGOnmawta3be1vcd+3K1nHZWF5JY1uiahJF4pw9Rla+V7cgSPDepF8raazq/wDbWt5WYC4MedkTT2YOg/ifqtFkZDcCIQYrg57wDJMP
3h6N9v4qhkri87Sar7Lvl48pJlrxzL+mXMCHbSaa7qPWuVZbIceLcaMgPTsL6qeFKM/GeJBtfH/zK+E/M9lizRkTObIHddo46BYWWEsqzJYYsyQNNPa8j4T9
FfEC2I802vonDCGY4yMk8ht1Vk1xYHp7rBmznTMc9rSxg6AdR7lTXm13Hs/gfUxqPhqFhfulxf7l/Nmh+W/p/BdJS8//AGdui0rSs+TUMiLGL5xTZZgOA0Wa
+oWdn/tK0LFyGQY7pMpznUXtG2NvvZ6/QLuceeXyNZlNeuk1jVMfRdKn1DJI8uIcN3UXOPRo9yrcDMi1HBhy4b8uVu4A9R7Lxbxl4py/EOcYS10GFA4iPHv9
7pud6n+C7n9l+e7J0CbGe4kwSccdj7pcNY7SZ7y07mkqTQuGhUhNCBIpNCApFIQoCkUhCBoQhAIQhAIQhAIQhUCEIUCQhCAQhCK0nizUcrSPD82fhuaJYXNN
ObYIvkELzuXxtmeIW5eHK0sZkRHy4GgENcB2PX16r0zxDhO1Hw9n4ja3SQnbfqOf5L5/x5ZMTKZKyxJC4EfMLXjkrDktlVtHCzmEy6YYxyYZN9DrRFH+Cjlx
N84zsJ8iY7g70J6gqhsj8eQPjcL7EdCtb77GXxKYeZicAEwuvcO7Hf0P8VLDdjxtd5vL7G2+hHur4om5DtzAGCdro3Cr2uqxXzIWPsD4I2V5b21uBH3td583
+G4knq0YQhhe7zZGQvHNHgj090NOW2MiMksHDfNaHOH+/RY8dxvax4NX8IPS/b5rpMaH8wex0jJm8bQCDfrfReHPls1tphhK0gx8prZmOyZA93wzMI5+R56K
zG2YTf8AFLXAFrhXLw7gj7JajkvOe90byH1s3R8HaOFjQx7Xb5q21ZBPJXfe2TbnrJbpOWQ75YyTTHuAB7Cyte+yfUrN1B16jM8AASU6h7gH+apghbK8ueS2
Fv5nDqfYe5X3bySYTKs9Li45OGJH/wCJFTCf8w7fUf0XVeCdex/DOHlZuZ57opiWRRRtve8Uep4FDv7rlpXOnLWNaB2ZEwcNCeaQxkWM02IQQSP8x5P+/mvm
Z6yrqXXr1nwd4rzPE+r5z5Y2wYkUY8uFp3Ub6k9yfsuzXnX7J8Itwc7OIcN7xG30Pf8AovRV5spNvRhuz0IQhcujQkhFNCSEDRaSEEkIQihCEIBCEIBCEIBC
EIEhCEAhC0mbq0rsw4uG4DZxJIW3z7fJcZ5TCbqyW3Ubp1BpLqDe5PReLeNNBxsLU5J9NlbKxx3SRsN7L9/99l1WsZz4S4TzSyu/6ncfZcu2d8uoREi2v+Hb
XVc8fP75PHHLh565mGZ8QO2RoB6td0P0QZoJDUsTWE/vxcEfRd9h+B58svy8yOPCx2gu3SNtxA5uu31WiZj4eTmeWyItgPQPrdXvx1XruUvrzWWRpcfGlY5w
aI5oJOD8YAPujNGI3UXxMeXeUdocTZcB1tdph+GdNhYcg7nUOG0Bz8+q53X8L8Jqrfw8bTA8B4s8sPQ/wXOX5Y7SZTemmIIA5Ekfr6ei6/C8tnhOTMq5Ig5g
5HJugf8Au/Rci5jS0BrHRPs03sfVddj5minwzkacco/2k6MhsRG1gcHWee5ofW6Xm5JvU/234/N1yIa4vd5bQPV56ewUo4GvnY0ybyeALoE+pUdjA1wkL3G6
LW9h2CsbiyzSS+RhPL42XuDb2gV0WuM3ZGV+Hl6a8Bj3TRNbsaHOc4kWBXYH2UXxxRwRgl3kN56U6V/c+w9FlRTZw8yXIfJG3yvL3ObuPUVwewWHK6AyF807
539g0bR8l7OXLL/jv44nzYbkyBhEEbYm9y0c/dVwY5yp2xbtrLt8h6NHcq7fj7bOGa/9QpB02a4YuHAWtPVrBZPzXHxXV+B4JNW8ShkMkzdLw/j8vcQ1xH5S
R0slewLnfBvh9ugaFHG8EZMwD5rHIPYfRdEsMruvThjqFSEWi1y6CKTQiikUkhA6RSSEEkIQgEIQqBCEWoBCLRaAQlaEAhCEGFrEssOkZUkLtsgZwfSyB/Nc
tjM8nG8wD4ux9V0mvOc3R5g0fnLWn5Ehc3FHJl5UOFHxvNE+g6k/ZeXnnbKYtMLqWsrF8PR6u38VnOeIyaYxpA3D1J6jn+C3en6HpumUcXFYJB/zXjc/7lZz
GNjY1jBtY0ANHoFJb44TGM7d1o/F+RJi+Fc+SNry4sDbZ2BcASfauvzXluPJCJGvY/i+h6j5r2HWXNZoeoOcxsjRjSEsf0dTTwV4gImP2uhfXHIceQVtj80x
5Jt1wzGnHYxrgebNFanPxcfL/EZL3yiSJlFrXCuBY+4WrMmTATZPTqD/ADCeFqDoNRbK87mvAa8O/eHz9uq7xk69WHT8t7azFyg63yAXGNy17Ji3JbL3D93r
3V2ex0ObMGjax7iRQoVfRYi+dnld6v6fY4uPGbs+VvWbXzS7HbWtZ5riBdNsAn6Xf0K3mmPi0gy5Yzo8hryYGCHo8/CSQfbp06rV6EfwEEuoTPPmvaYIYSPz
DiyT2CtyTHPlNnfNYafhbt28/RerDG5atfO5MZjesdVrmFiRZeJm448zT8toewu/UH3/AKrdQ+GvDMulumy4DG5zbaY5CCPvd/JWaTo41TwJiQOBD3XNDdX+
YkfQ/wA/ZaLT5ZcvJ82bcGMdQYeoA46KcufWeJjxW5f6Ev7LxNJ5mLnRfh3AFpcHAkH1A4/32XW+HfCeB4daXQF0k7hTpHfyHZZ+lSD8KIef7v8ALfcLPVx5
LnjK2/rmNJCEKgRSLQgE0k0UFJNKkAhFIpA77o3JxPIxpgCedvF+6ukwJmYxncW8Cy0dUNKNyW5V37rVPzJI9eEDY2lrw1rn0bqr6/NHNum5tFqrcPVPcPVN
qttK1VuCNwTYtv3RuVW4JbkF25Lcqt/0+a4I/tAZk5eSIciOHFjkcIyGW97W9/r/AEXOWWps22H7ScgR6DisEz4nvyht2P2k0133ANfosrwTj5TtJj1LPDRk
TspgA/c9T7uq/lS5nVM6DxccLH3Qyxtnbue+TY9jSQHbR05HqvR27WMDIw1rGgBrR0AHQLPD8srlWmWU6TGL7Raq3I3LZmsLgGklocAOR6+y8IIhnneQ4Y7i
91NP5RZPFjp6enC9c8Saq3S9Gkf5myaY+VD/AOY/0FleZYOFjZUToZGkSw8OINGux9wkykumXJ+mC5uVDYNkDm2m/wCCphex8sglaSS2281RWa7TpgP7iVr2
+hNFVYsb4ZgzKgNeY08tPQmjyPYrZlMpfjpsHR8CfADnxDIjmIkAl5o126UtBn6VgY0xhx42Mkc4n4rdQ/kF2Z/DaZp1k7MeFvck0OwXBZmQJZXSnf5kxJIJ
4AWeElttizLL9XxU/bI8XIdrPhHWvnS6jwVoGHrWXkSZbJJMfHDeL2te49j34AulrdI0zFyIHySsNA0G7q+Z/VdXpGvM0UDGkiH4LsI2gOYfX3/iu77PHWOt
+u6hjjghZDDG2OJjQ1rGig0DsFxuvYbcHWhM0AQ5YLqHZ4/N97B+q62LIjnhZLDI2SN4trmnghcz4w1DC8qHBM3/ABu8SMa0XQ6G/SwT19F5+THeL0S6bLTs
jy2xv/d6H5LeblyWPJWCxtEiuq6HCl34ULjX5ey8/wDFyvuLXlk8rMtFqrcjcvWyW2i1VuRuQW2i1VuRuQW2i1VuRuQW2i1VuRuQVNlc020kH5qw5s7mljpn
kHsXLFWVgMD53Ata74bpym0Vbz/so3muqrPUj3QoLN3yT3+4VSfb2VEw/wB093uVWmglu+aN1+qiuS8VeM4NHD8HALZ9TJ27atsXz9T7fdEt0yPH2pTaf4Tn
djvcySeRmPvaeWh12fsCPqvGWHyGbW9ui2ep69q+rMEWfnSzRNduDDQbfyA5WNHhSbdxc1li6cnk9rK3bEjyXyOdY+GjRABs/Xsu58O/tDl0zGiw8/HfPjtd
tZMHfExvpyPiA472B6qeH+zfNytHbkyZjIsl7dzMd0XHsHG+CfktDqWVqGNokGiZGnPxGY873yPc0jzXnpZPBr2PPHorPhqx7ZDPHkwsngkbJFINzHtNhw9Q
snHb5uRGw2Q51EA0vNf2X5OS852Kctpxog17cd3Lmk38QPYccj1K9LxXNjyonuNNa6yVGuN3Hm/7Xc3yNR03S4X7SwmdzS6+Tw2/+752ubl8+N0WTE4xTNbt
cWmx/qFk/tVbLkeJ8zU/OD8e2Y8bCORtbz+u4/Vcg3UMh0geJn/E1oJ3DigB079FnnLtnlZt12NqDXADIjLT/wCJF3+YW+0zLxdsgbOHPJFC6P2XJ4Iw8yJo
GqRw5X+WRlNd+t/opZbsrTntjzMXcD+SVg3NP17fVW82XXVcThw3uXTvJpohA8ZG1gLTW8cH7rnvM0+FtsjZK41TYWD9StFj5wnkEePjF8nUXwB6kl3ACeXl
fhxc2XjGWwPLY9z9t/5iBQUx5spPIuXDjb7XT6RMdS1vT8fJhDIJC+JrGu/K0Mc4m/Ww3p6LO17w/kYPmTRgy4oJIe0WWD/qH8x9aXDaJ4nyG+ItLlm2jHx5
xu2NohrgWk/9y7rxL4z1KLUZ9K0HF3TQnbLlO5DTQ4b245F/ZacWV+uvx66cxieIc/AGzAyyyKydopzTfU0fkqZtSfl6w7UsljTM8DeGDaCQKv7LUZsGoT5M
k+ZLC7IebebF/pwqGOyoeC3c3/pdf8V3ZL9c9rHo+DruLmQODWvYYI9zmurp7LqvDubh6jpQkxZC4Ne4O5731+RXkuianHj5hmJJLWkGMdXegIK6D9nWRPja
xLjFtsliJft/drkE+3b6hZY8Mwytkbf23LUr1HY33+6Njff7qrf7p+Yu3SzY33+6Njff7qvzEeYUFmxvv90bG+/3Ve9G/wB0Fmxvv90bG+/3Ve8+qN59UFmx
vv8AdGxvv91XvRv90RRt91fiSiCbcSSKIIHdYe6z/qmXcdAoL5S18z3g8EkhQ+Ed1WHkI3G7VRb8NItvoqrKNx9UFoI6gFMOHYKm/dcv4s8XR6Cz8NjBk2oO
AOx3LYh6u9z2CFum08S+I8XQNOc+V/8AxMrXCCMCyXV1IvoD1K8t8J6xp+mahNLqWLJM+SN9ZDXEvYSD+Uep6br4v5oZnYmojO1fXJZMrNcfKxsVhLbcRweO
jW+nr6rp/DngavIztXa0Ord+E29+28/yVZ7tvirwT4fOTq41t2MMbBiLvw8LiX7j0FX1A9fXovR/h/yt+wVdgDojcFGmM1Fu/wB1zXj2WH/6TnE8cslvZ5ez
o198E+3X5roN3sqcvHizcSbFnYHRSsLHD2KF9jxfSTqEecZdKzBiz+U4b94bY67bPFmuB3XovgXxNNrOJLhZspkzsfne7rIwngn3B4P0XCaz4X1bSMV5yIY3
4jZN4ma8Ej9350eOK6j2XR+CNKGPhzeJ55HSytZIGRtO3ht7r9Sa4H1VZ47lc9431E6jLOGSExnJeQ1zAC0N4HPfv9guU/DERMAc1xPv2Wy17NOZlW3/AA9z
3MFAGnOvmlhOFED0FLP+VZ/Z+Pzz/wBf/WOWWp6pMUtUQ4j7hbrHxM4QxOblSMjqw0kloPt6fZaoOcHEgn7rpNIdjZmjZUZY5+fFGSGl55bfUD2WGNtum8v4
SqdN8OZ+rzPZhxyTwRNMk0zIj5bA0Ekkngmlg5uJiYjhjguMgO5/qfQe3W10Wlao+DTXYt5uLEWhr2R8R5I3UO/5uapc1rcxk1Qb3MfMxgbM9n5S70HsOG/R
XKahjn6w3HimjaPQLa4uVMc6ImRxBdXJPNrVHpayMOZtncfjaDt+Y6LX+JMcs+t/bDkxzw3f0ys6HbkSOBs7iTX6FUsL+jSbWfqNw5scrQOWtfRHFe6xZSxm
W5zGbY9xLWj09l9Xi48M+OWx5uTPLHOyU2SRSva3JBbXSRv5mldr4RxNTxNaglDseeGRlPkYLPl31P8AlNj6rkJYsZ0TZGv3bv3Wg7gfQr1PwdgnT/DWK2S/
NlBldfUbug+1fdYc/DeL5fK9HByf2X2ex0e4o3Krdz1RvHqvK9i3cjcqt4Rvvogt3I3Kov8AUfVRdM1otzmge5QX2jcsV2ZC0WZmV/5lWdSxgL84H5AobZ25
Pd7LWnVccA055PoGqs6xCP3JPsP6om4zNxRZ9FA39U77WoJWUc+q1Wr69g6KyJ2XJzI8M2x/E5oq7I9FmQZ2Lk4bMuHIjfA8W2S6BH1Q2yfqELWy69pEEzop
dTxGyCraZBxa5TxJ48ELn4mjOa99U7K6hp/6R3+aukuUjpPE+rxaRoeTJ+J8rJfGW44HLi89KH815dp2VpkuBmw5+NkvzZTuiy2O3EEdG0fXuef0WDkZWZq2
Z52VK/JmdQ3OPJH8gt9owbpGW3K8iCaVvMYkshh9R6lWRnbus7wrjYuj6jHJrOL5c7mCSB8gPwA9HV9+T046L0mKeKdgfDIyRp7tda4CXxDBq2e2DWomMxBE
7bJC07mPJB3buSOBXHrysXS58kasGYD5QHT02WhezvvA44HP1TW3Usj0wn5Iux/RcL4m8buwst+Hp0kfwj45m/HyeaHbp3XPO8U63l40jYtSksjpQBPyIFhW
YZWbLyYy6et2ei1OoeJdL0yWGKfKYZZnBobGQ7aD3dXQLy5niPVfwkuNLqORJHMNr2k25o9ief1VeTpEMWiR5zcqNxdJsMLG1Qo9+59vRXLjuP1P7N/GV4vk
B8W5r5Y5CNxDA4kV8IAI9r546rE03UM/EzI24Er3ecQx8A5bKD1Bb06Wr9V8R5mq6fjYGUyJ3lEHz9o3uoUBfb+azvCE7os+XGZi40hcwvE72XIzjbQPa7/i
ufjn9uWzmtGYyMXY6g9uf6UqSbcT7rK1dsTfEOcMQtOOyVwjokihxxawQXDq215eXLtna76Y2SWJ13U4MrIwclmRjyFkjDwR39j6hQt1cBQkJrkUspbt7cuH
CY6Z7NazGSSvY6Ngl/MxsY2/QHosBxLrPfqoNFrJjx3OFuO1vqV3ba4wwxxRa8GNZWl4jsnMIcQ1p730PRY/l7HE0K/grCDs279gd+nunDdck07/AJOPfj7X
9Oo1uPG8xtTB22NrANw4oLUscPLMZeXxH9wm69x6LAayNtGF394OQ4HlEkck+Q6R1b3HnaKH2C+pjny46kr5NwwvtjZw4OQ8POI1z3AcbfzBeoxa0x0DfJYw
tAoU7gV24XmHh2TK/tWLF8xgbJYDn9uCvQMTEhwsdsEby5oJNnqSTa55OTLk1Mp8d8WOOG9ftsDq0pHwtjB9rKrOp5JHBA+TP6qr4fVALTysurTsmc7LcP8A
Ef8AYBQORkvbRkfXoXoLgOjfuUF47UPmr1TujcpFF3/cSjy3eoB9gn5hB6X8gnuPQOCdad4QiPcn6Ck/K9XH6lRDwSQX0EDn4RfztXqndMRMrsfmbQGMHcfd
QIF0NwS+H0P1CdYnduDlQtNGZt/NVuzYAf8AEv5ArS7X/wCYD6J+W49XFZ6bdnF+NGOf4ilm3l7Jo2FhPFACq+VrSjIkbhthdK90bXEiMu+EE9wF0XjKCMS4
snmO84tILb423/GyuXMZdw2iPcqs79WHKBjLSyz+4fRUsbJ5jXgi7u7tNsRLg0loeeyzcmCHFyJYmWdruDXULTjwud05yulbw6Dyp7bukBINWPsEfj5y4W4A
D0Z/VZsjWu0Vh8shzJS5p7lp4/isGscdXPJ9mr0YYYsc8rB+IllcLpocaLlGXfT9r3vHAcC88BXNMLribG5okIG5x4HoiPY1zeAA47HA9CuphjLtO1sYbW7a
2tYK6cWrIt0Uge11WeVcZ3guAEbaNVtVbpXP4c5pAN8NAXeo4m2dmYrXRsy2kAP4kaP3Xf6qEMbcjGfiebtf/iRDtuHUH6Wp4eQTDJHTXHb+V3Q1/osZroJH
tkheYZAb2Sctv0B/qsbrVxrebvrOj8LatLLG10QDXtDvMcRTR7+/suzZht0vTX/hI4/OihLgS0fGWtJs+vRU4uf5mkfinlxdEw7xfp/sLBwclmUcuaaQlpxZ
QGXZJLSA0e9leXKeNJXBNEk5mnfI175HbnG6sk2U/IkAsgV62pY+DI/Kjx2u4c6i0/L1XZaR4Fjy3tfPl+XGByOo+q8HJ+P16+LeWcscZsHZ7PuqpI7obm/T
ldzrnguPCxpnYkscjgz+7NVZXC5mm6ljubHLES55oNj+I/onHj2m425efU1UTPDB+UW77lY0uZLIeu0ey2mNoIMY/Gumx5TztLOg7WDypz+GyYw7DnbK7u1/
wn6L0TjrxXktZmmaC3Jwmy+f5VNsuPT5m1W7G8ufY3Mjf7iq+xW30Z02PiRwZMRa9jdpB6Fc7LHGyV7Hs20aPsuv481lbfpyZXpJ+leZK8Ze2m74zRcwUCsi
DJY8AklpHUDqtr4txsXG1jyMHHijxg1hjaBz+Xnn5g/daSOSOOQOcyv1Xq4OSXWX6rz8uFm8W5xZYGalBKyZoEbw8F4rv0I+67+ORkkYfEdzHdCF5RH5TckE
yEtunWOoXpuj/h26VjjEt0O2w8nknvfva0zyxym5HGEyl9u2YTxR4SpnTm/YqR9ybQKPFUffus2hVfU0ECx2+6s2mrJr5IJaOo/VAms3DrR9FBzWjsLUiAGk
gAH3UDe390H1CIYJ6UK+Sl8AHA59gohvwgEk+9qR4NAooaT12nn0TL3NNbQhoIcSXfZTI55cCoMZ73DptSEjqrv7JEO6ik9rj1+FNRd1xfimZ8+qbBTvLYG8
dupI/Vc+dwPUAjsVvNaw5MXVMhxa4xudvD9pA+L3WucGvBDmgtKzv10wgf8AjIz7rZ5DY/xT8icF4cRsjHV5r9AsA4eyQSRO4B5B/qsjJfF54LpHse1tfksV
2WmF9c+6WfipMiLL30DtaQB0aAeixA7ddEWPUq6NzJGTxwNcXFnV3BPYAALEONJdO2h3pdkfZb4fvUZ5/paXMH5pefZRmdulLx+8NwR+DLGh7920mgdtAp+W
yhx04C0nrj5fRJMAdzmWXi7vqqzOCPhYb+at2tAHwih0sLIhixXxbpJWxuuq2ApldTdJjusfDl25LbPU91bJ5LHzM80s55aWE/b1TyDDCWjHeJNw5JYOPSlZ
MIjI4OhDnA/mtY5ZassaYz7K22k5UJ0DUIQ51Bg2hxrnt+vZa+HJkheHxOo/oszRcIZwyMbHY5txkkuN07ivp1Wsmjkx3uaQRRIPse4Xny++NI3GPmQ5OQzz
MSNswNiVvB4/2V02kZeJ5pZmte5haap5A/RcPgyF04JHTuF0GHIxsMnmk7WmwfZeH+T+VevguktRzpMRmQyF9NJAjDuaFrS4eYYtUx8iZxdUgJPdLVct88jp
iKa51D0Cx9PgORmwxuBIkeGgXRPPK34JrFjy5brZ+IZmt1l5bussbu3DvXb6UtYJATxwfmup13S2TxzZrHN3MYXPa7o8AfoaXH2yTmJ3/tK3sv1lKzo82eLo
+x6OFqqaUZGXjzmBgfG9pIb0eAbohYxe5hpwoq3E83Iyo44224uHPYe59lxbp1PW38UOhkixphFsmLNzWh24AWbF+o47LmonxOfUnF8cre+KZWR5GPjtFlsZ
cT8z/oufALNsjmnab2k911/H844c1/OmBFJIGu6HjkL03R8PHxNNhZjxNj3Rtc8DqXV1PuuL8NaY/L1OLJlhJxojv3OHwucOgHrzz9F6D5ouyVqzPkcBpS6u
FmvZMlxF7ifZR+EckO3ILDY638iUcHsLPooea/sB8igbi4m69AgkWOFOcf0QA0nhwr3CX9474S3dSkHfCQWiwiIkUeHCvZFVXe/ZMAEX0vsE2s2ncCgW1wPX
n2SpvcG1KyT+b62iiOwP1QY3xAhSN1/NMsqkiWkepRUJGCaF8Mg3xvBa5p6ELgtY0ybR8gBpL4X2WE9SB2+Y/VegC6rhaPXc/TpNNy8Z2RG/Ia07G1dPB4o+
q5yk0sceyQPALTwpzRY/nlzi97z+6FjRtLHuIHHXjsrzJ5m9zGAuAslxux8lxjbK6s8SDv7uVkcbWDZxtSxppsdj9oFuo880m3eYrkdfx1XSuEfCBw1vHRW8
lk0TCX1GfIlmGx73vAPSqAWLIXjq3rzRPTsskmUglraFdSa/gqHfFOA43VXX3Xo47tlnNLGwyN6Ob6c0Va1pP5i3j0CgxhP/ADnfQFW0Gi9zj7kLDkz35trh
hr3SsxGR4Y0gHqTXQDqVmadgZup5e2N1MB+JzgCGhVRs/umk8GY9fRo/qV2miz6e/BZHgStftb8dcOJ7khTGGVXYOl42nuLoGkPc0NcSfzfToFofFuJHiiLN
ijO6WQiUg/D04+vC6qrHNrR+KovM0JxJry5GuAHft/NaY4y3VcbctiOZ/iNbQJ5WyY7cwi6BFFabBd8LmXyCtpEXEdfoV4Oaazsenjv4jMbGzTnOLbLHhw9u
y3nhvCibp8WbIxpnmBIcedrb4A9FzWpl7MdwPLXUF2+hwGDQsJjgNwiBPPrz/Nej+PP8e/8AbLl/5MiQXE8VdtP8F5PywiraR+i9daGbwST155XlOY0tzJw4
EESusH5lezjm5WS2CWSZpaWg1x81s8Gd+mue52KQH1ZLT09isbRtgL9/tS6CXObjYE8m2yxpIv17L5/PlZncNbj08ePnbbR5uLPrOpPlx3MLXUGt3UWtA910
2F4ewGsxpsiPzHRxBojeQ5gPW6HUrS+GdCZqOM7LyJ5Gsa8sa2M10q7tduAwGqAC9OONxmmGV3do7GgAGg0dAOyNgBsDg91Mgn8oFe6lXS3BdIqDBu55BVvk
tq2k2okAn81+wUXObdV+qITzxRP3UQDusm/RN3w8MFH3U+S0cgFAw6hVqBdIXEANr0U+go8n1Sc7oO6ipNMtctr6qFvJvYVbbg0flT+Grd9gqKxZ5cyh6hMO
HZw+qmGi/hNBSLW3z/BTYxg/d+7wouDu1NHukGn3CiQAeefmg0PiDW3YwOFjnZK4fHLVEA9m+/uuUZi5mQ4tx4ZnbR8QawmvmvR9sLnC2h1dLF0r6DhQND3K
lmyPPodA1OcbhD5YDbBlcG7v9+6wC98M3xNAe11O5v5roNb1c5b3YeC/+4H55Bxv/wBP4rU+SXOa1jWECjbgK+651/06lHk/4jGjlrraD39vn0TMc7KDmOaT
68LYY+k5GZIXMxTW6jJMdrft1K20Phlop02TY7siYGj25VuEqzKyOUlx3vIuWt3oC4qH4Bwk+Jk5dV0Who/Vdk3w9jflkyMuRndrpFJnhjBbJ/z3xXflF/Fq
ztJpzdW7cjHDBH1LTub8IEu4k/QLKhw8lx3R4MsjDR3eUXUPkf8AfC7eLFggG1mPExvoGhXF5dyDadTs4d+Dkh4kdjZlmhukZxZ4HSlPDwdUxp/Mgx5RJH02
jaP1oV7LtAXXyaQTTu1Koqxnzvgactkcc3cNdYPv7LD8QQ+doWS3dW0B/T0INLZ2L4v7LWa5KIdIyPNNCQbGiupP/wDF1jdWVHARjZmFoIFnbytrDHO135HA
/otZJkRh5d5THEnusuDWMhuO6JuNjvY7gGRl18rWfNhjy57xd453CeoapJumih8xj9vLtpuj6LvNGf5uj4ri7cQzaT8uK/gvOnZkhcWvY1vsGAfyXaeFM9mT
gyY5AD4XWPcFaS444TCT4ltt23m0Am/1XmusC9azf/Xd/Fel+Vvf8RsLz7xKzb4iy2gfvN//AFC14frmnpOTi4chZlN+CWqdVhvzWx8Tvw4sHHhxi1xnduJb
/lH+tfZaKRsflsEhPA5Huq253kEGGNlt/KXDdX3XHLOP+ztPast06zwcSNPyIXcbJQ5vqQR1/RdO2iOQuF0fW5YtQfl573bJmBgDGgDjvXoP5rt4XxTxB8Lm
yMd0cDYUymX2zSSzepVpJ7chQJ/6KTFt/K3lMkdD1XKlYaAQlzdkD5oMfHLj8lLaCBTuQiKyDuulIDueVMsIHW1WIyTW5FMkk10CZPQfqlQbwTyjaSeaPzQT
3beNoKXDu9eyQG011Cua1lXxaQV1tIF0FIv54dx8lFzebr7I2/8ASVBil3olW7r0Ur5oNTcaHPRUNtDhRfJ/lr+KjuJ4aK9ypxhjOvJ9UGuGi4r37/wcTed3
SufksyLFgxwRDBG0k2drQOVlH428cKBaWj8w+ighTyeh+qkLB+I0PRSaHe6bmN6lUQfR5BFIG8j8x+iHEAcCkW4N4JPuggW9bB+6m1oDepChvJNKy2tARBQ4
4P1Uia7fooh7SeXIJaTfKKYJ9FyvjSc3iY4cKIc4j7BdUTfIXJeMMdolxsneTK4GPZ7Dm/1pWY9rImWXWbcxDA2R9yybWDqas/QeqzYoHZjnSbmwwRjaLF16
ADuVVLFLDL+GLPjBojvfosgh4jZCLpvAA6kr6XHxY4y/9PDlncleTjiOoZyHNq4pWdx/T26hbDwnMzG1nypCaljLGj1d1H81RlYWRB/w+QwtcORfb691jY/m
RSiXdUsLg9hJ4dXa1zycWOc3HWGeWF1XpEsgihfKTtaxpcePReZTzyZOXNk5DiXlxLrPf0Xo8GSzLxI522WysDqPv2XmupOjZlTRQu3RseQHevNL51tx8j2z
VYz3l7jzwmyBz3AdyaAUY/8AEbfqsvHZuyo2Hu6lvwcUy+sebkuPkTyS101Rm4mANafWu/3W60/O/sihG3fI5g8wF5Ad32j3HqtFMJGTODmgEGiB2pZU5AuR
xBvp817uuNl7PLLZZp6Bh5uPnYTMqFxDHWKd1BHUFXMkaOa+q4nQ89+O47nFuODcgIsHjr81vYfEGNI1rchj4b6Oq2/6L5nJMcctSvdj2s3Y3j3ucPhCI4xX
uq2RuewObRaRwQeqk3ixZv2XO1N28d0jurdVJx8X1KkBZ5CCLDu5c0EBN3BsH6KTmV1NBQHJ4dQUUzbjx0U9raruokADrSIy3q0G/dVEw7YCmCSLIKhudfNW
o+c4dUNsfc517OfcqIis8u3FXVTeSPkoNeQeAgsawMb+VRsdSOU7LhyVGq7hRT3k9eB6KxtV2+qrbtvjk+qHBwNkWUEy6u9/RRLr68KVfDzwo7WjoOfdUIbS
elqwURzVeipJd2CY4FucPkgTuTwKCDf+VBcewFJ3Y5q0RF4odQmAHDqkRbullTDTdAcoptHaj81xfiaZ/wDbQaCWthY3afQ9b/36LttvYn6BcX4ua3+1IWtY
GEwhz3A/m5NX8q/VacWcwy3XGeNymo0zC7Ie7afLYOrj/NZ0bnNoREg/+I78309FiwtBA/yD8o/mVlNdXK45OfLO+3x1hxY4/GRPHNEyN24lr2XtdyD6rXSR
7Tuj/u3H92/hPy/oVvc/UG5OmYsYjDTHYtah3xCjVLjHkywu8XeeEymq6Hws6d+mSgimMkPl2eQasivn/FcVkwzQZD48lhZMD8TXepXR+HdSOFnDEkBMOQ4N
B/yu7f0XSaho+DqVHJiJe0U17DTgPRd3PtduJj1mnmrW0N3qsmEubNDM08tcDfy5W5z/AAnlYzXOw3tyW3YafheP5Fc+yWaIlp+Ejgtc3+IXq4+XDGSMM+PL
K1kPyHODnnmR7i7d8+VWBfAFuJ+5VZu9zqv27K2EkHzT16NCz5ubt/4acXH1n+2wYA2NsA6N5efUrMxHQ+Y2OYXE404enutdGdo68nqVaD3Xk23jo9PmZpeo
uw3Tl+JLRicOgJ/hfQ+63xeHHgELgfMJZsPY20+i7PTJxnYMUrjyRThfccFdY1zlGc2QBu1oSc8g0pNiaOgUS0OdStQtwqyUwwEWEjGwHlysoAfCrEQDg0/E
CpGRrm/3ba+aC4XRbaA03Z4CCvdIeQpA2LLFZsa4WCobfdBAM46qLmsHVTD74AQWE9TSKrodikW33Ui0A9Sld8NCIiCWngKW8jko2knj7p7mtHSyipBxeOiL
UC5zxQ4CG0DXUoGbrhJsIPLrKkaB9VNsgqgOUCAaBVJbBfVKSSunVRDyOybFtCMdefRDS53QUk02L7qG54d0RFrmbe65jxNpkuTPFlxNdI1rdj2tFkVZB+XK
6TdfVSqh1CmtrHnDQBwp2u2ydP0/JcTNjsc8/vAUfuFiu8M4L3FzTO0H91rxQ+4XPWuuzlNxMQHYFR3LqW+GMd0puaby6/LxYPzr+S2EGi4GK62YrHEd3/F/
FOtO0czo2lT5eXFPsLIY3h+9w4NG6C7INcATSe8joOnolvcupNObUfL5tywtT0jA1KjPHUgFCVhpw/r9VsKcWkuKoolyqbctkeDnsJdj5LJB2bIC3+CwjoWf
ESXQGSjX92QfsPRdu/d0HRSYyhdKWbWVw/8AZGoD/wDCm/8Ain/Zeo1/9lP/APFdwC4u5ApSc1TqvauMh0LUZC0mAMBF294FfMdV0Wk4RwMQRPrzC4udtNj2
r6Us8sNcEJsbt9yrJpLbUxI4D8pUh8Z6Ugg1dJWQOOEDcxgHXlJrXdkmu55VjXA8BABv1UXWXc9FLlp6qL32aQRsNFBLa7t0VgDa5CkCK4CqMUOPRra909wH
U8pPJPAUANvzQWEE9B90qJ6kBKnVbnUECnDi0UFw6Xae3d7IDa6BM8BBW4BvAKm0CuKtVEFxoAp7TGLpEXeWTySlQCTZXOH5aCkOe3CKgRuPAQ5rqHKUj64C
GhxHPCCbW03jqgsrkkoBLTQNpuDnCuqBEN7DlRo3wFNrdnUIIJNgoIOYa54VsZoKsu7WpNJA6KaFpVe+jygPJNUpFjT+ZUQMvoEwLbaTgAeBQSLxt6qIbnmu
BaQdxyKKGn4b7IaN1nsqaQLnE+ynW4JkJB4CCW4AKHL/AGTDm2mA3rdIp8NACl0FgWqyQOnKk15IqqUFnncVSg7nlQ2m1KneiukSA44CkwBoN9SobyOyRJIU
VOzfJT3Ndx3SjfXVStpdYpEIQ0bL06pTsFvPVIBDTDHLuT9lOmk9aCiI66lMRgnlVVb3Xw0ceqbQ+uFftAHASI2jlNisvc0V1KG0evJT2tPJTFA8BREiDXAA
VbgXmhz81Y8ktVQeRwFVXNbQ5UZfQGkm7ymW11RBFEOpFlMx82VIPDWqsykuRUi0npwkDs72pi3C1W5hJQDjuSqxQUvLdSRJaKHJSIbGAHkKRP2Q1jnfm4Q9
zRwAgQeB05KBuJsoDmDsguLzx0QD6JoKJiFe6ujjoWeqg8Ec7kDbGNvul5RP7yg17ndOita4NFk8oRAtLeLUfK5tWF4d81DcQ7lFAYG9VJwBHCHtscJxNLG2
QiINa7sm5lG+6kNxPok4EBQTYQVYR8NhURmlMyEcUmxEkk8pXXZWtAd2TLWge6aVXt3dlEN2lT3Uot5dyqhlu4cFTa0gKO03wpb64QYu61IFCEEt3YJEAdUI
UUV3Q2OzZ6IQoG4gcAIbHfJQhWCXRJwtCEoiIu5PCeweiEIJ7g0Jb7FoQqKnOcehUGkg+pQhEZLC5zfRMMA7IQpViuRtIY4dEIRFhfTeFj2XOooQqi9rKaqn
NI6IQikx208hNx5tCFFDHOLvZZBdYQhVFd060nEuPshCCyNrQLKL3FCED3BjeFFrrKEKVUi0d1G+wCEKBtB9UFotCF0j/9k=
]] },
    { key = "druid", name = "Сет Друида", have = 11, total = 11, c = { 0.38, 0.82, 0.42 }, data = [[
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
]] },
    { key = "swordsman", name = "Сет Мечника", have = 11, total = 11, c = { 0.88, 0.22, 0.28 }, data = [[
/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBUODAsLDBkSEw8VHhsgHx4bHR0hJTApISMtJB0dKjkqLTEzNjY2ICg7Pzo0PjA1NjP/
2wBDAQkJCQwLDBgODhgzIh0iMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzP/wAARCAF3ASwDASIAAhEBAxEB/8QA
HAAAAgIDAQEAAAAAAAAAAAAAAAECAwQFBgcI/8QAPxAAAQMDAwIFAwEGBQIFBQAAAQACEQMEIQUSMUFRBhMiYXEygZGhFEJSscHRByMzYvAVFiQ0U5LhQ3KC
svH/xAAaAQEBAQEBAQEAAAAAAAAAAAAAAQIDBAUG/8QAKhEBAQACAgIABQMEAwAAAAAAAAECEQMSITEEIkFRYRMykXGxwdGBofD/2gAMAwEAAhEDEQA/AOoD
zwchScZbCimvUqstUdquSha2mlW1LarSEoTZpDamGqUIiFNmihSARKYU2qSkGzzwhrY5Up6LNrUgiAokoLu6hKki2mhRLglvWtM7SlEqsuS3K9Ta2QEt4VSI
V0m1u8J7gqYUgFNLtbKFEBMKKaEJQoJIShEIGkjaUQUAhOE4TYgiFOAnCbFcIhWbUQmxVEIU9qcJsVGQEpVhYHILZwDkLUqWIgoUeDCaqGkUIQNrZSIgwUpP
RSM8zKBAZwpD6o6qEqQBInqpSJ5/eSlJxJyQkJiVNKZUHFT6SolWCtCcIha2hJqQbKl5amzStMNJVopqQbClyXSDWKYamApLO1R2ohNCilCITQgSITQiEhNC
KEIhOECTQiVAJIlKUAhIoVCnbCrPMhS6zKXcrUmkt2HEuMlKE0lWQhCFQAdeiEwn6OxRUYUm4YYU8bJjCrnsAp7X0YlwyphsT2T6dE1m1ZENuEtk8qxEKbXS
rYgMVkIhXaaICE00KATSQgaSEIBCEIBAQgKBpJoQJCEIHKSJSJVDSlJCByhJCAQhNBCPSkmeEoWkEIhEIhVChEKUIQRThNCBIhNCCQ4QMpJhRpPhCjKYWdLs
IhNCGyhNCEQIhCrp16dZ1RtN4caTtr44Du0qKmhamw1oXur3lgaFWnUtw3cC2Q05mXcdo7rapLKuWNxuqaEkLTJoSQgaESkshpISVAhCEAiUkIBNCEAhCSB4
4SThELQSE0IhIUiJShNrokJohDRQpbcIhMCFNiMJwpIhNiMKQRCFAIQhFCEIQc/4o1S6sKVtRou/ZqdzUFN94TPlD2HeJyt1aW9G1tKVC3A8pjYbBmfeepPM
qF/Y0NSsatpcNmlUbBjkHoR2IXP6JfV9K1MeHdSq7oj9krERvb2/t+Oy526y8/V3xx78fy+5/wB/n/hfoYbV8S+Ibhs/6zKUH2atjd3JsdQtn1Cf2a4Ionn0
VOWn2ByPmFpPD95Rtv8Ar2oXdVlKk69JJPtP5J7JVK994ta1lvSfaaT5jd9R0eZVgjjsBz/yFnHL5fHt1z4r+pd+prf8f3dXCE+iF2eMkJpIBCEIEhOEQgSE
4RCBITQgSE0QgUJwmhECIThCoUIhNCAiQlCkEio0ipQl3Q3hNpo0IQgFp9a1x+kVKLf2R1RtQYqboE9vlbdYmp2X/ULCpQBa2oRNJ7hIa8cGCpTTQ6l4ou7P
y9tvSaXs3EOkwtho3iO21VopvijcjmmT9XuF5Bfa9rQvn0tQuqj6lJ5Y+lUjbIMR8LPsr+ndkGiTTrNzsJyI6g9f5rEyrPZ7SiVxei+Ln09tDUSXM4FUDI+e
67KlUp1qbalN4ex2Q4HBW5dtbTQgBCoFynjO6sH2jbRzfNvw4Gls+ql7ntPZWa3rl6dUboulUx+1P+qo4wRIn0/AMysqz0G00mwr1ntFe7NNzqtd5JLjE47D
HyuWV7y4x7OHGcNx5M/f0n+/x/dx/hyjY3Woso6lVfsDt1Kk/wCh7jgg9jx88L0xrQ1oa0AACAAIAXEaVoFDWPCYJ9N0a73UqnY4x8GP6rN8Na7VbXOj6m+L
qmdlJzuXEfuk9+x6rnw3rJL9Xp+OxvNllljf2+5/mOrQiJThel8okQnCIQJCcIhQKEQpJIpQjammgjtTgJoQKEJoQJEIlOUCSUoRCojCcJwhRChIqSRRUSgC
ZQVICAgUIUoRCCKSlCUIrzL/ABD8LVX3n/VrKlvbVEV6bRncP3vuP5LzkF1JwMnBkEctX0k5jXtLHNDmkQQcghcD4q8AU7gVL3TBsqZc6kOPt3/n8rFxYyx+
zidO1um8Np3rvYVxn/3f3Xe6Hc3Vi0uY8OoETEy1w7heT3FpUt6zqdRrqVUcj/nK2Wi+IrzSgbfcX27jL6BOD7t7FZlZle52GqW2oNIpOAqN+qmTkf3WbC8g
oagKxF3ZV3NcMkgw5h7Fdrovi+nXLbfUi2lV4bV/dd89luZNyrfEug3F41uo2NRwv7d4fTA6tH7v8z9yFY3V6er+Fr2qBtuGW7hWpt5a6Dx7HouhGQCDIOQR
1XI+JNMq2Dqt/prT/wCKY6ndUW8EESXAfaT/AP1Yzlx3Y9vBljyawy9z1f8ADM8GN2+GKLq0emo9252OvP8ANabVqrPE2vUrfSqYFS3JD7sSBjrPYdOp6LD0
Z95qtvaaSHOo6b5ha+pT5eSC7b8QD+V39jY22nWrba1pCnSb0HJPcnqfdYxnfGT6O/LZ8Py3P3ld6/H9f9LaLHU6LGPqGo9rQHPIguPdWIQu75oSTSRAhCEA
hEIhFBSTQiEhNCKSITRlUEIhCERJCEKKEIQgMJEJoQQiVIcJoQCEJIGkhCAgIQhBzniTwhZa9Sc8NFK65D24kryHWNCvdCuxTvKMt/dqR6Xe3sV9ArA1XSLT
WLR1vdUwQeHRkLNx2ln1j56oXVezuBUpu2dA8H9D3C6CjqtK4t6heG0rhrSdv7r8dO3wrfE3g670Ss4sY6rbHhwE/wDP5/zXLM3tOyNzIw6f5rHpzr07QPFV
zp1Om2rur2rgDsJyye39l27ry01bTDUt6tN4IiCQCCcQe3K8Utb6u+2ZSY7zXhuDt9TR25ysZ1xWqtA80kkzExCvb6OmNuOsr6e42un06Wq3lVtOd10KgnHl
/wCUG4Husz9saNWFiR6jb+eDHZ+0/wAwvHtI8VaxplQMoXxrcE0ajd7HR3JyMdiuj0LxJU1r/EC0uXUnUhVsXW7qbH7mbgS8H4/qtSxcuTtY9HlNJOVoCESi
UAhJCBoSQgaEShAIQhAIQhAIQhA0IQgEIQgEIQgEIQqBJNIoBCEIpSiU0KBITQgqr29K6ouo12B9N3LSvGvHei2WjavToWtQbq9PeWnG3MCenfK9qXnn+Jmt
6a/S36UwtrX7arC4BhPkgZPq6HIx7lTL0zlJp5rQqC1qgPpkluMOgg9we6zNSo0q7xeWtQAVBJacS7rHv7LUB/8AEZH6rIo130SQ2H03fXTOQ75Xnzwtsyx9
u3Bz4zC8XJPlv8y/dKneFrN7Ya9scDn3W88I6rQsvFFndXALaYc8GBJywgfPK58UH1ahNNpawHBPQJhtSjXZUYZLT6XDgFdNvL6r6MoV6VzRbVo1G1KbuHNM
gqxeVaTrN5pNVr6TpY6C+k4y13/O69C0jXbPWKX+U7ZWH1UnfUPcdwuku3SXbZoQhaUIQhAIQhAITQopITQqEhEIhECEIQSlJCIQCE4QgEIQooQhCoEk0kAg
oQUCQhCAQhCA4yOV4p438MVNAubes/Ual2bx1RxDm7SHAgnqZ5XtFWtSt6TqtZ4ZTb9Tj0Wp8MW4Oq1rrUj+03F1vA8w7m0WE4Yz+ERyRkqXG2Wz6OXJnjNS
+3gjqVSm5nm06lMOG5u5pbI7ieUN8sOktPOJM/ler+OP8Omiu660cRSMvFoTgHrsP49JwuB03Q7W5rvoXt5Wt6kxTDaG7PZwJkH2hccvE3Uxna6jX+c63qbb
e630WgQ5zcHGcH7pU9RrNpCgfIbScRO6kPycLoRouv8AhulcanYvFW2aTb1alNvfo5js/wA4K0Nrpde9pV30Gh3lt3FgOS3jHeFMfM8Vb4vmM2yqX9APY+k2
pbs4cX7fjZOTPbj3W1tLs+YyrQe9lRplpy1wPwudNStbtLDwW7ZcJkD3PTCdG9rtEB8RkGMj4KuO5PLWeWNy+Waj1PQ/HVO4v2abfNmqXCmyuwTvccQR/ULt
F5H/AIeaab3xI27cx3k2bDUkjG84b/Mn7L11dsfS47s8khNCqkmhCKEIQgE0k0AhCEAhCEDQq96N6CxCr3qx7CwA72n0h2OxQCFXvUH1xTcwEGHGN3QfKC9C
r3o3oLElXuRvQWIKr3pbkFiFXuRvQWIVe9Lf3MIOd8V3RNazsmHJd5jh+g/qpsv2svbY0wGCW+kdOi1taq7UdZq3JBaxmG7h+6MD88rU1tUa7UzsHpYdo94K
7Yy71+HzuTLtbl/7w9S1J/m2NJ/Z39FwHirwzU1Wb6w/86xh30//AFgM/wDuHTvx2XV218260yo0OyIMfdU0qzm1mOZyxwcCs8OEz4rKzyZ3DlmUeVXHirUd
Q0yna3dw6o2htLC8kuBDYye3t3WtoakLTUG1qL6gbEPbAkzzMcgroPHHheto2qftFd7XU9RqVKlN9FhDQ6ZLS3oczgkcrlLS6r2tRzKVSm0E+ouEiV87rZlt
+g4+bivDMf5O/qV6hY65pvpmrL6ReIFVsxIP2g/CVjYXN3UbToUS97nBonAknGTgLutH0bR9VaaFevXqUrqTVYHiGvP/ANRoj0uB7fGQuG1ll9ptzU0ivcOq
W9u8+W4D01Gzg+4/lld/Xt8u2W3Xp6HV8OatoFC3u7KsBWYwm4qURicYLTggzzxjot9pXjKwu6T239SlZXFIEv8AMdtYQOSCf5fzXKeD/Hr6t8LTV67Gtexr
KdV7gxtPaMCIjM894WR4g023rFt/aU6DLO7aBb1GfS4mSZHQnOBjCv7fMdpdvQbS8tb+2Zc2lenXoP8ApqU3bmlXYXjVCtqXhi6dW0+sQ9wl1M5p1gOAWyAP
nlet2lwbmzoV3BgdUptcQx25oJGQD1Wscpkb+7KwhV7kbltViFXuRuQWoVW5PegsQq96N6CxCr3o3oKpRuVO8e6N3t+qiLyYA9QM/osq2uLdjg+uwvLWwGgY
xwtbuT3FU2y7isytXc+mzY08N7LX3lky9fSL6rmimZG0Zn5+yy61I0m0zuJ3tnhUye6F8+1273RuVW4ok91BbuRunuqpKSG1u5G5VolDazcjcq0BDazcO60/
iC/qWtm2jbn/AD6xgT0aOT/T7rZVKjKNJ1WodrGCSVy9UvvripdVGkF2GA/ut6Bc+XPrFxx7HaXtXUarbCt/l13SGVAMe65vS7bza+wuBLapaSesFdpodpJN
25shpLKZjkjk/wBPyucYw0Nf1FjmwW3JdIPc/wBl04Lbi8nxGEx1Y6m1oi3tKtQmGlsQoVXXtVjW2ZpU6hcIFUEg/McLOdTA02pjIAP6rTHXWWTvMvLW5t2t
Mgloc05x6hjPuu/BlJhdvNy425zTA/xA8Q3NTS2aXqumttrtjxXBbV3scIIBaRkZnH5XLeB9M0/Wby8sL63p1Huol9N8w8Hg7c89fyqPFGqVfFHig1S5tKk9
zKbA94DaY4BJ/JKxKemUrTxhR059xVp0Dcta2vSPr2u+lzTxORleOfd7pqeFtza6j4P1V9pdOLA/NK4H0vb3Hb37LpLa40vXNObY6nQZUexhFKqMOaT1aV27
9HoXmk07DV3DUSxpBq1mAOJMiccGOoXmOv8AhTUfCrm3dnVN3YF8YBDqWcbvnuMSpyce46S9K0jdCdQ1BzalWbemcPaYL/7KvW6jwaLGN227WkAA4Dv7rPtb
l2p1fKt2PfXcf9JrSXT8LoWeCtUrNsnV6YbQrV2suGAzUZTPLo4/qOVNWmN1dxrvAvha/wBXo17irVqU9OcC0SZFV47A9AeT9vjd297c+E9ZOmVLn/LcwPLD
6mkn94duOF31laWmnWrbayt6dCg3hjBAH9z7rmfGfhUa1SF7ZNaL+m2HN485vae46fhdOmlv4Z9rr7SwG4Icw8VGD+i3bdz2Nc0EtcJB9l5zpHhTWrt1Clfk
2tjTcC8OI31B2gfjK9L8wdPwt47THaG1/wDCUbX/AMJU/MCPMVaQ2v8A4Sja/wDhKn5iN6Ihtf8AwlG1/wDCVPejeiobX/wlG1/Yqe9LegxIPZMNKganYoL+
xRlPaU9vRVl+Ov5Rv9lBnXdRlVlEMdJa2D7cLGj3VQdjhG4oq2B3T9KpDiOEbj3RFvpRIHRU7vdG5UXbh2RuHZU7ktwQX7/hG/7Kjctdr2sDQ9Iq37qBrCm5
oLA7byY5hBX4nu/Ls6FEOjzauYHIAn+cLHpu82xbTEtLnAbo7rmrnxhS1+jTYLI276T97XGqHE9COB/wKin4tZSqOs3WZJgu3eaIx9l5ObG5ZbjeGcm3ptNr
KFFtKmIaxsBeb19dsm+JdQrVKtSnTqPwKtMtcOMEcqB/xQuuRpltBJwazphczV87WtSrVjXtxcVnmo9jnEROYE8iCvT+p18xw5JOSaerN8V6HUsXhuqWwluA
520zPYrReIfENjc6JXtrS6t6taqWtAFUDqDmemFx9TwtqlGmHllBzRJG2pM/oo0PD+ouDYbbtMnD6gWMefrjcWb8PvKVZ4fsNFubq5/7g1KpZ02tHl+WNxe6
c5g4A/msfUbaxo6gxulXTrqiIcC8QQQfgduyvqeF9S3y99rud082J/RWWehOdcsp3Oq21q17tpfO6D94XOZY3w63DKeXslOq6pTZUc0sc5oJYeWk8hSJDmkO
gg8g8LT2Gv6Vd1KdrR1a2urnbBhwDnkDJj+gW0lejbTSf9t29t4rpa7ZgU3Pa9lzTGA7cPrHvPI6zPzv9yr3I3e6Glm5Pcqt/ulvCou3I3KneEeYgu3e6Nyp
3o3lBfuRuVG8o3FEX7kblRuPdG73RV+5G5UbvdG4d0FU+yJPQKJPulI7hRFklE+6huE8pbhPVBZPuifdV7xKPMEoLJRIVfmI3oLJCJVe8pFxJQWyicKqSlJ7
oLp91pPF/q8I6k0AuJpDAz+8FtZWBqOoWlvRqW9W6pMr1WFjKZd6i5wIAj3SleQ6dRFar5flMcHHJLQYCq1KjTZWcG02tgx6QqaINOWmQQ38Kyq7dQaTJPUl
c3Jj020+HEgdwJVtG5Za3TaxBuWsIhpdIJHGDxhQbEjHVYNSm87w1pkvxAUt0a3HZt1y81TXBZaZUNtSrloos8vc0Y9UyZGZPZdHUHhqswUa+rVre825qftD
dp99paPxMrzFtSvSLSx9RtSJ9JMtWVZWlxfVzve5oAy4rF6tYXK/Vuat3So3Qp1tUqXVvvIc+1Ay0dpPK1mparS1HUKb6FrTtaVNpbTYzOPc9T7rbaToNte3
vlXGosoUqX+tWqNJYMSB6QTJ4XPXVMW9xUY0RByR16rM1j6i55eN27ZNlX/Yr+3umwHUqrakx2Mr3YPDgHNPpOR8LwKQ5uDIIXtGjXbr3RLG5dO6pQaTPeIP
8l2wWNrPujcFTJS3gcuA+Suir9wRuCxTcURzVZj/AHKJvbcD/UB+AVTbM3hLesI6hRHG8/8A4qs6lTHDHfcgJo3Gy3pbytWdU6CmJ9yonUqp+ljR9iU0do22
9G4nqtOb66OQY9g0KBuLoiPMfHymk7Ru5KC4AwSB8rRE13/U8n5cUvLeTk/omk7N2a9Ic1WCP9wUP2y3/wDWYtR5R6k/hHl/7j/7ldHdt8o+6q3HuiVlVsju
jcJ5VQM9UTlBbuCNwVWQkXAcuA+Sgu8wI8z2WMbiiOarPyom8oAfXPwChtlbyjeVhG/og43n7KB1BnRjvuQmqbZ+8pbitcdSPRjR8lQOo1TwGj4aVdHaMvUb
0afp9xduBcKLC6B1Xk9StcXd8a7XPqXNR8g9S8nouw8U3hraa2lUqxNQO2YG4CenZcraU6Q1C2L5DPOZMH/csZe2bdtaWOpXFSk9u17SWOb2Iwf5KB/8vz+8
Vl31M09cu6bjJFZ8nvklYZEU3D3WUVnDSR0C29XRvM8NW2o21O4LnP2u3AAVMwCwTPI75zhYmm2A1S/o2e4U21D6nE8ACSfwF1uu3VtoduTbg+fUoinQpHAp
ACA7HXqPc9VnLXurjNyuDLX0i4PDm1J9QIggrd+GKlsb6q28DHDy5YapwDPutbqN/U1O8dcVY3O6gLCqN9OcrjbOzfHwcnW37u61Fgs786hTu6jKFYif2eoz
H+1zYMjC5LU6/wC1alcVRV80Od/qcbsBa5uBAVjHbT7ELWd3G+Pgl/dW60LRaus0qmyuymKJAIIJOfbtyvRLGnWsdPoWbKj3MosDASYn8LgfB19+xa55VQgU
7luzOBu5H6yPuvRfNmIA/K9PDNzccc/kuqRNV31OJ+XEpeW48kfhT3kdlHzT1B9l261jvAKR/iP2Cfk9yfykanAk/lBM5gJ1Tul5TOv809rAOirDts4J+0ID
pOAB7Eq9U7rQ5oGJP2R5jQeFAFxO5wIHsnk5kp1idqfmwJ2qQqk8NH4VZkDMSeqYwZ/kVdQ7VLzHDBM/ZG7d+9+qC4DnP2RzJhNJsi3qBz1lR2zwCfsrDBcA
TEIJgxyqgOpGMNYPcmVE6hUMQWj4bKoDWjGAguY3lwXHTv2Wm9rO4c77BQNxXcILnn7pb2BI1R/Dn5V61OwJqO5z8lINecSPwn5omAwp+bHMBXrU7QvLccbv
wE/JP8Tvyom4j+6YqyOU6nZIUBGc/dHlNHRqhvDjGfymXQYIEfCvVO6cNA5H2T9I6qndDpEu+ykXFwkNj7q9U7Vwvitr267UcQdr6bS0nqIg/qtPVJ8tu2QO
36/3XZ+KrI3WntuQIdbySI5aYn8LjA6W4IgGe68+c1WpdwqDTIeSZBwO6TgAKmZypvuAKTabCfT17/8AP6qDzIquHBysqz9BvLaw1B15cmG0aT3NE/U6IA/V
a7UbyvqN265rvJe/MHO0dArLSxub9xpW1E1XAbiPYJVbWq2o7zbSqwgwdomFz5Nt461phgOjJ/RRqbg3KzHW9RgG63qgHgwqXtAP+nUcR+7tOFyktr32444a
V0qJeNxw3urixrqe6m0lrTG4ZysOsbusYFGqG8QGFdd4ftK+n2dNl5bGk+oS4CoMlvuOi6XGybeac3zajS2VtXr3VI2w/wA0FsO6NJcIJ9uq9VDTGSJ6wtVp
NzZWtSrbadZN866I80zhvuD0W0LROeV2+Fvixy+Ku8u0BAHB+ZCAHzyAOycHvHshhBkEbh3XreYBoyAPwEBpBGPypmTkAffChuA55QD3TxA75UAJ9Qz9k9uC
MSnIHyEQEmImPhSaBs+oqPzBlTDsQGz/AERQGFsTKlsPSR8KORkyFLfPWPnqoIbW85lSaR0xHQqYEDDueiTi48xAVQ9wnDgO6fme6gBuP0yPdG13ZBiboOR9
yhzgfYKQ2gTtMpB0mCEaRiZAEqQbjIT354lPcCf6BEIyOgUd2PdSaJyJUgDGYlBEmW/SPsFEsHb8qwCOhP3ScBHAn5QRa1pPqMD8JnaD6CSkS7jH9k2tIMmT
79AgiWucZkwidjZH6pgkg7M+5TbSJ9TiSoK6tGpc0KlN8Cm9paSDmCFztPwZb0mvLbms5xB2zAAPRdSHR3ITG0iTClxl9m64Jvg/UST5j6DBmMlxPb8qLvDd
+ygAy2qGu4lrwY2gdwZXflwGOFotR8S22maibWrQqvAaHOewjE+x5XO8eM9tS0tA0caXRNSs3ZcOEPAduEBbLSKwF22mwUtzj6fMMBYX/W9PubaobW5D6m0x
TcNru3Cot3NplxqE7dsiOZHZeb4rWpjHo+H3La3lS8NzqdWlUoUqdSgNpNM4KsloJgQTyR1Wn0d1W4qXNw9oax7mhreoAlbba1pklej4fHrxxx5su2dWAlpE
OI+StZrNobm230s1aTtwB6g8rX+KNVutMoURbBrfOkeYclsdh9+VyFtrF/bXH7QLmo9xMva9xIf8hXkzmrizjPO3U6c/9nrE1qTnYgkYcCtmNftm6zR0wNqF
zx6nuxtO2QPcrCo65Zai9j2PDKhGWPMH/wCVzmpVH1fFk0QRUbWptbHcQMLx8OWUzenlk6eHomD9IM+6k07Qd+D7qJa58uDR7EFRLcSQZ919J40yWggAzPsm
Xt2enn3KqY+DhqsGyCSPyoJy4NmQSe6iSRnb8hRa9hIhwhSL2g91QxG3Mz79ECNwMwPdKdxwW/CYLScuDSPZBZzlwJ7YSIAxxPRVmoSf3o7qTZiMkKG0hjtK
YDiZn8oAMfSM+6bGkR6p+yoTXx1APWVI/wD3D7IDQHkuAMdUiymTOAorD2vJmICACCnuEy5xPsm4tdkAk9k2I/vcygAkdh3Q0Z9Q2j5UnOa0RuEnoqG07cSI
9knjtMoa4EZn4CcF/Ddo7qCIDi36YA/VKInBCbnmnhRL31HYBAVCkjAZko2y71z8DhTIaM9U8nj8oE0EyMJlpZyU/pxJTkfvD7lBAkkYATDpGZnumR2mEsDJ
5QSBBEgGB3XD+M2sff0qrHhxbT2PHYgz/Vdq8S07sg9Jhcz4qsLOjo7KtK3ZTqiqAHMaM4OCf+ZWOSW4rPblNPuWW9yHPHpIjd2XSO1G3pWpq1KzSCMAGZXL
1jQaxlOkJcPqeep9lX9MOHIK8eWErtjncfDv9KvnMGyna1KtLcNzqQktJ7jst8YGHYXO+F6FwdPpXQqU/LqzuZtg4MThdBkcw5erimsY5Z3d20Pim2fcaeHl
pNGk7e8Nb6vc+wXBVXU3PcaTCxs4BMleq3jaj7Ku1jRudTcACJnHC8qxs2xgdFjlnna4m2g42rq8jaDEHkn2Wdo1C5u9Woi3eBcSXNc84EDnqsD1lgYCS0GY
91tPDdJ1bXrMNc5u15e4jBAAMrnj7i16HZuu2Uy26FIPEQ5jpDvtAhTeSDLiM/wqTg1zuuFEQXL2ORxEEBxUonkkhMYySfhIQQSRA6IBgZ1AMeyl5bXEkNB/
RDIGCYQZOAcd1FAYAY2we4TNOBlxPZSY45nojd2x8lBAiGx1Sa47tu4gFW+r+H7lIvbEdT1QKY6hAMDpKIgZcAiBEjMqoe9xPGFYHADLSoNiIxHWVPdHAEIM
FwDgISO8Ny4pueJwoElx9k0ohsiXZVmwEek88kpMDR0H4UXVHTFMZ9lBI0w3EyiS7DRgd+FFrKnNQ47BP1cAFWCYa36nGSoyCcSm0EGHQAh07pBCBkYwCUCG
5Az7mUnbyMkx7KLWQZyPlBPe4lBI3Z/mgAHqSngfuoEY5GSmCQPU0x8pgxyITJkYQQxUxMLVeJbYVNAuQ0ZpgVM44P8AaVuAHTyAsPWKfn6TeMDw2aLsu4GF
m+ZSPLiA7kwe6ZYQ0bsDuDym6k5rWvPDuEOaQ1pPB4915HV6H4XB/wC3bUgY9f8A+xW3wB6futb4d8ijolClTreaGTuMRBOSI+62Z2RgL14+o5UhJcI/K8t1
Gkynqd4ymdzBWdtMzOSvRtSuX22l3ddrDup0iRnj3XmoBa4b5kd1z5r6jWKjK6XwdSe/Vaj4BFOieeQSQMfqtFWqsqFp2wQIgHlXWt3WtLmlc09zHt4dxI/q
uWN1dtWbj1ItdjEqJDhwMrX6XrFLUoFuypuDd1QO4Z7T1WwDy8E8/C9Uu3P0AHE+qAggnAH4QHB8NcMd1IwCAOFUIAkw5WGnsbMkqDQXP7DurOHfVhBWc4Lk
9zoALQfdWAtdIaI91CCTOT8KCQcXGI+6CAHcCUARMCD8pNbL5mSqo2Ev9Tj8KbqfESFFpMkE5UwHkSeFENjGw4YKCZ9lAgg8nPZG5zcbZQYZEDDcoJ2jMJbi
8+njuUNohx6uPcqiOXmGiB3VtMtbgNKkYY2MKJcemFFSc3MyAk1rpnKbSByI+Uy6MiUEXBo+r8KMy6Bj4T3z7qQI+FRU97gYKkCA2TypPMmGjChBkDACIkHt
PJKYLZ6yqzG7BlSDc8SUUyCcThTAACg7aDMSUxzJMDsgJ2z3K03iQVP+i1gHQHEbjE4mf6BbnAPqWFrlMXGiXbGAyKe7Htn+imU8UjzporVyGshx5ALkgTtI
wNp47d0MwKbvL3N9+CpVGmjVIiGk+mM4XkdnUeDa7WivauqNc6oPNaAMiMGf0XUyWGYB+V5vp12+zuBVFQU9h3OMZeP4fgr0a3qMubWncUjuY8SJ6ey78WU1
pzyiu7Ybm3q0nH01GFsRPI7Ly9xeQxr5lg2QRxB4XrBPpgxPstZX0fT7ms+o+1pGo8GXRz7/AD7q54dvSS6edU3Et2l3JOSptIJ8t5c5ozA6FZWpaNeaW4ec
wupA4rMBLTPc9CsZlQOpim/0mPqA/mvPZr26RKnVrWwFRjyycAsdH2/+F2Gl+J6Fd9KlXay0pMpwS4khxHEdlxgDW5Dh8kqTqjXOBJE9Y4Vxys9Fm3qFK4oV
yRRrMeAA6WmZB4VobPJELhdBvRZ3dF24ilUf5dYE4E/S78/zXcluzOfdejDLtHOzR4BALj8BTLogbRCgHsIMNJd3UNzzwOFtlaKgILSI+ENn6WkhREmCGkFW
BrnGCYHdAo2smD7kqTXNIGYKRb/ulTa1vIAlBW9oc6GxKntqMZ6XZ7FNzGh/VMPaBBBI91AMBcBwfhReXBxyVIlzMtHpTG52cJsYIjbPKgHGf7K5rYHCi50H
oqpSDykHDdgT8pjJ4USM4wmhNzczOVKIAnJVYa4jE/KkSG4Jk+yAdPTCrMMPrd9grDx29k2Ugcxn3QQ9ThLZASmRCtMjmITG3khBW2m4iY+FLbGHGT2CZPqy
YHZSO0DGSgjtEZ4UC3MgKRJI5ACTWk5k7R+qCLi52CEnUhVpPpP+l7S0/BEK0GT0CDJMNEpoeYXNv+yVqto9/qovLewPuobgWNaA0OGNwPIXQ6/4d1GvqNW7
oUxWZUgkNcNwPEQeVrKXhnV3u/8AJuZGfW8Nn9V5bjd+nSZRjeVsosrEhzS4jb8Lb+GNUezVTbucTTuAZHTcMiB06qTPDeoGydSqCix28ENc+enssnTvCj7S
8pXNa8b/AJRDmtptySPnorjjlvektjqMkTEBPbnsoUw975JwrCyXSTK9Lmi5gqNLXtD2nkESCua1Twk2pUNTT3MpFxzSeYaPjGF05MnmEgS50DKzlJl7WXTg
T4T1ncYtWuA6iq3+6yaHgzUHn/Pq0KQx+8XH9F3UvHZThoy4SsfpYr2rnbHwrZUWkV61S4J+oRtaft/8rfzsAEYGApBm52BCkGfdbkk9Ju32rLYMu9I9ky1h
EgpuB3eoyowX4WkMHbgKXAkuz2VW2o1wICsc+RIGUDdETlPAAKh5jgOAEzUMTEoJboUm/TJCrB/eVjXAiUIkX7m9lFtYARtCZVZbPLVNCgY+o/ZSPGAqyQw+
kSe5RuA+oknsFQj8/ZOAQOU88hseyUE5J/CKTtxxJj2SjoBnuVYTtbjlUtcd0/qiLTgR1TBd3wpNc3b0lIyQiq3S52Shv1xJKe5oMclSaQDxCCLoceqYBHTC
k4gNwECXNkmAgRcP3RCKZL3QSgBo6EoZ9XZTyJmkN0kqUAnCJBHKrLX9OFQOHum1omSosHqklE7nEDASITm7nz0Sc0E/UmGxgJBsGUNJRI2gmVLDWwSlkccq
MHdmSipBrXtUqbIOMJTwBgJvO2CDlQWOG3MqvJIISDieSpNGMoJsdJIjA5RiccqO8DEcp7SBIiEES6D6lYHbvhMNDmy4AlIjsIRNJA8hUiRI5JSLXlymXBo+
oAqhBvRyRAa6AU2udPqOEEgyQJUEhzgKwnaMAKDQ7ZuUw3AceSgiwkvnj2UyQSltkykWAHCDDaC6SUH/ACxJIlGwjrlSFIcnJVVU15mSCSrN4HTPZS27R2UD
THJP2RD2h/JPwEnBrWwGwrG4aYCr3w6Tkop06QiYQ8kHa0KQe53SE2j1SSiICltycuKZBjupvqjgJgyMBFRER6gFGTPQBIhxdhOIy7hQIy8wMBT2BuOSkyX/
AEiFJwHG7KqEA1mT+FKdwlRAY0STJTaHPxwEVWQ6Tt4Tax2wkqx/owBhJtTcIAREBIEQUnT0WRIDYJyqyQDACKrAcfZTMtCbyWiQgZpy/nsiK43ZkypsG7BU
gcfSkw+v2UE/KaBlQIHQq7e2IUdhPCUV7Z6o3uB29FMNAOUiQTASCW8tHBMqTTIwoDmCpOe1ojuqCeyqNMF3qEqdOdxJ4U+fUgYADeEhTBMyrA9pb0UHGBI4
U2qxoIb7JSX4VYqjapctwiJbS1IuCiKxODKcNOUGGCVPd06oQqpHnOSkWyYCEKCUBrYyUNp9ShCRUpUC0uPKEJQeWFYXBoiEIREXPjgQVSXOLs8IQqi+mSWw
MJmmI7lCFKqoCHK4ODRKEIikudUcQSplu1uEIVRXPqym9wkQEIUVKk7ecgQrKhHZCFRFzoEKVOnPqJQhQG0E4Uy7bDQhCKREqGB8oQoVKSQltEe6ELSAh22E
2GGwhCgYYXFSLfTB4QhBAADEIDiHx3QhUTcIMBHlnuhCg//Z
]] },
}

function UIFX.b64(s)
    local idx, chars = {}, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    for i = 1, #chars do idx[chars:byte(i)] = i - 1 end
    local out, n, acc, bits = {}, 0, 0, 0
    for i = 1, #s do
        local v = idx[s:byte(i)]
        if v then
            acc = acc * 64 + v
            bits = bits + 6
            if bits >= 8 then
                bits = bits - 8
                local div = 2 ^ bits
                local byte = math.floor(acc / div)
                acc = acc - byte * div
                n = n + 1
                out[n] = string.char(byte)
            end
        end
    end
    return table.concat(out)
end

-- фото грузим в текстуру не больше одной за кадр (чтобы не было подвисаний при первом открытии вкладки)
function UIFX.set_tex(s)
    if s.tex ~= nil or s.failed then return s.tex end
    if (UIFX.tex_budget or 1) <= 0 then return nil end
    UIFX.tex_budget = (UIFX.tex_budget or 1) - 1
    local ok, tex = pcall(function()
        local path = cfg_dir .. "arizona_set_" .. s.key .. ".jpg"
        local need = math.floor(#(s.data:gsub("[^%w%+/]", "")) * 6 / 8)
        local have = 0
        local f = io.open(path, "rb")
        if f then have = f:seek("end") or 0; f:close() end
        if have ~= need then
            if not write_file(path, UIFX.b64(s.data)) then error("write failed") end
        end
        return imgui.CreateTextureFromFile(path)
    end)
    if ok and tex then s.tex = tex else s.failed = true end
    return s.tex
end

-- логотип скрипта (шапка вкладки "О скрипте"): грузим один раз, при неудаче рисуем старый значок
UIFX.LOGO = [[
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
qHW0gZhQqkDev//Z
]]
function UIFX.logo_tex()
    if UIFX.logo ~= nil or UIFX.logo_failed then return UIFX.logo end
    local ok, tex = pcall(function()
        local path = cfg_dir .. "arizona_logo.jpg"
        local need = math.floor(#(UIFX.LOGO:gsub("[^%w%+/]", "")) * 6 / 8)
        local have = 0
        local f = io.open(path, "rb")
        if f then have = f:seek("end") or 0; f:close() end
        if have < need - 2 or have > need + 2 then
            if not write_file(path, UIFX.b64(UIFX.LOGO)) then error("write failed") end
        end
        return imgui.CreateTextureFromFile(path)
    end)
    if ok and tex then UIFX.logo = tex else UIFX.logo_failed = true end
    return UIFX.logo
end

-- логотипы Telegram / Discord / TikTok для вкладки "О скрипте" (PNG, грузим при первом показе)
UIFX.ICONS = {
    tg = [[
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
jVNN4/8DbPSg6vMcCXIAAAAASUVORK5CYII=
]],
    ds = [[
iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAYAAADDPmHLAAAh90lEQVR42u19e5RU1Znv79t7n0d1VXfzEgF5iYDQKBk0golcG5/xNZM4pMQHWSaxR50ks26yMl4nJpmms+YaiTfRezMx
6JAH1yfU9ZrcJEtjVGhjYtQYM0ZaBHygBAQa7HdVnbP3/u4fp06/BOymq6ob6b1WLVhdj3PO/n3v/T0IR91iSqch9taAGhtI9383/QVOSQQzKNTzQDSHiE9kxjSAJ1g2kwlCge0EkFAA
F75FAFsNEs0MqwXJ3QA1E+EdZnoTzNvYUVsM3B2Zu6ij/zVr61lNbAJnMrAA8dG0m3Q0gQ4AmQyZ3u+suD57kgSfxjCLwbQIhDnMdpKUviuEE32bLZgNmA0AhrXRv/23QggJgEAkCy8B
ALA2hDG5gEi8C8Y2EL9EkM8b0J/W35N4vQ8BpllG93l0EMOIJoD6ehabNkE0NvZw+sqvctJ05pYS40IGn8tsFrhuyiECrAWMCcA2hLXGEkUoM0fPSRQ/Lx3iuTn+PBc+1f19IaQg4UBK
F0JEnwyCjpBIbibQU0x4XCb9Z+77LnV2S4ZaVsuWwTY0kB0lgEGsdJplTQ043rhrr2U/TOTPYWuXg+h8Kd0ZQggYY2B0FoA1YDAIBIYo4FvsZ2MwAwTbfS0IKVUCUkpYa2FMsAPMT5AQ
DztZb+O6dZSLCbmpCdRfeo0SwEGA7y06P/OPufmW+TPW2rRU/mwhBLTOw+i8JcAyICKupmF6DmZmcHwvUnlCKS8iBp3bLoTICKJ77/2h/2pvVTaSCIFGDvA9m3LlDdkLCLgRzJc6bsIz
OoDWWUtElpkEUWQPjDhLhWGJ2DKzUCohpHIRBtk8iH7FwJqH7k785lDPfEwSQH09CwCIRf1VN+aWE+PLJMRSIRyEQQfAVkecTiMS9MPIBkuABQnluClYG4KtfYYJdz64xn/4YM9/DBEA
U23tJtnYeI6OOL79AiJVr6R/FrNFGHTEBpwYPvFeRLkAWGaQ46YEkYA2ud8x64aH7q78TWQsblSNjcvMcHgNZd/c3qIvfX37qUrIBknu5SCCDjsMMxOREPgQLmZriYiVk5JghuHgEW1N
feaeyr8Ml1qgcnJ9bACl028n1LjjbiHgJql8L8i3WYDxYQX+YIQAEFyvShidyzNwuz6w79ZMZnq2vyFc6lWWDY90HXEmQ+aKupZPuOMnvuA6/jes1V6YbzVEJI4V8KP4ghBEJMJ8q7FW
e67jf8MdP/GFK+paPhFJAOLYPjjqJUBtLavGRtIXXbTVGzt96reldL7CAHTYpYkgj34dXxRX0iinQhEAY8I73nt759cee2xuPt67o5YA4gdYcV3bfOm4P3Ucb3Eue2yJ+8GqBT9RJcIw
/7wJg8+u/1HVq6UmghKBwFRfz6KxkfRVde3XKMd7VghncS7bqo81cT9YtZDLtmohnMXK8Z69qq79msZG0pE6YDoqJEB9PYvYr736hs7bpKq4WYddYNYGIDkK9YAYyBApqZwKGN21+oG7
k//Sf29HJAGk0xtkJnOFuez6v1ZU0bifOq6fzufaNbOVRIJGgR2USmAiYTy/UoVBLtPGBz77y3tO6Ir3eMQRQOzDXr5y90Q/OSbjuv7ZuWxbSETOKJxDMhFDP1HlBEHu6VxnS/qR+ybv
LWa8gIoJfvraPZMcv+oJ5fgL8rlR8ItJBJ5f5egwtznMtZ2fWXf8u8UiAlFM8JVX+aRU/oJ8rlWPgl9MA5GcfK5VS+UvUF7lk+lr90yKAmosh5UAIn3UA75yEjVBvlUTCTUKW9G9BBXk
W7VyEjV9iWDDkIjgiFVAbJFedX3bBEA1joJfNuNQu1610mG2CdC1D95T1TwU70Ac4V1QJAHeTjDEI447Cn65JYHjJmoY4pF0+u1Eb0zKQABMtasgGxrIyuqx93pecmlk8I2CX04iyOfa
Qs9LLpXVY+9taCBbuwrySIJFgyaA2nrIxgbSK+paVnuJ1PJRV2/4DMNcti30EqnlK+paVjc2kK6tx6DtARoc+KwaG0in61quSvjVDwRBRwjmUfCHlxJC10052Vzr1Zm1Yx6MMSq6BKiv
ZxFxfutcR3r36DBrYM2o2B/uZY3SYdY40rtnRV3r3MaG+OygqBKgUJhRAyl2dfzBcSoW6aDDgEZj+yPENTDKTckw7HrJTkmdiSaYgSaVDIhSaus3yUyGjNjZutr3U4vCoF2Pgj+i1IAM
g3bt+6lFYmfr6kyGTG39JlkUCRBH+q6saz9XuYkndZjVAI+K/pFJCVo5CaWD7HkPra18aiDhYvFBor+mBnzttewzYQ2zZWYzepY/cjWBYLbMhDXXXst+TQ34g1zDw4KZ3gDR0EA257Z9
3fdTc0yYNaPJHCM6PiBMmDW+n5qTc9u+3tBANr3h8BjT4az+hgbwNTe2zbXs/IWtlYChkZzDR4W7syUqs4iLQplHthwAJJMQRlB46v1rqrbW14MOFSo+JHU0NYEAYq35dqUSDljzSANf
CEAWXkRAEAJdXaVDpyvLCMPoWvF1R548JAJrVirhaM23A8QRloOQALHxsOK69mWOl9iowy4DQI4UDicAxgK5PEPr6G+uS5g8UWDCeMKWbaWprTh5tkTzfos9+xj5ICoWVgrwPYIUUceB
ESQhjHIqZJjPnrP+R5WbDmUQHtSar6kBMzNd+Q9tqwtiBcNZRhhzmdYR6MxAwicsmKdwyjyJyccLnDBZYNoUCc8DbvtfXXj2BY1UkoasDqQA2jsZS5c4uOlLCeTyjJ27LN7ZZbFzl8XW
7QZbXzfo7GIQRcSgCrtqh7UrQIEKya5m5jNXrQIPSAKkN7DMXEHm6hvaPilV5c/CfNuwBHyIIuB7gz5ujMDCBRKnzFOYe5LEjGnioBrwrbcNbv5WF5TqUVrUb2v6c2ksWfptH5iBMARu
+9cKzJohD6oEd7xjsfV1g1e2aLy82eBAi+1DDNYOk1RgNo5XJY1u/9QDd1f9PMb2sBKgZnP07MbwLUIaLjfjx4ZWPg8EIaMyRThjkcJ/OdPBwhqFMdXUB6SYy6jXd0+cIXHGIoVNvwvh
+xGAUW+H6IOxDu8jL2OQuCDvCHAcIJcDas9ycNJMCWt7jEzudb8zpgnMmCZwwTIHLa2Ml5s0fvuHEJu3GLS2MVyH4HmlNVAPpeCZDRvDtwD4eYztISVAXJe24rqWWuUmN+owa8tZlk0U
GVpSRCB+7AwHH/uowpRJPbcQb744hD8Sg7Rlm8H/+EEWU6cIHDdeoKICmDpZwHUJvk+oTPb9cmu7RRAAQcDYuduiqwvYtz8S8//8xQTmzZFgPrjRxxx1iCD0fX/XuxbP/lHj2RdCvLnD
wDJQ4RMsl1MIsFVOQuig85z1PxrT2L9BxUFsAGJG65eFcEDIWpSpflAQkA+A0z+i8MmLXZwyT3VvZmxYxWphIPbC/LkSd92ehOcOVIQdXMvlA+7+jUP5QESApPff65RJAssvc3H5JS5e
eVUj84sATVs0fJ/KJgkIsEI4giG+DNCm/s2xqK/fT3blF1pmW+1stmydwoepHGI/m2XMnS1x2zeTfcSyGGLkIQaEBxD86P8ZKsK1LfeomyAEvvz1DuxtZrhO2ewCBgiCRChUuOC+u8Zs
751C1s1Pmwr/DwP5eeVWuGBrymX6MwNCEupW+pG1b3os8KECEEsNKfr67gd79f8M0dBA6m1raA24DlC30ofWXM6ICoGtUW6FGwby872x7s8M9E//xO6ebNsWR/kztc6VRf9LCbS2MS6/
1MXnr/Zh7UgMrhRnxc/2P+/O4snfhqhKEYwtB4OxVcoXoc69dXyiat73v09BLPBEbPwB4L351lrXTc4sNGQqOQxU0PuTJgpc8Umvm2M/rCuWKCvTHqqrCNqUR8QSkdA6a103OXNvvrUW
AMc1BX1BtnKFEJIJ5WlaRATk84xrPu0hlaRjhgDGjxP41CUuOjoZokwRFgJZISTDyhX9PUUCiNNf4YRob9sulT/FmnzJrf/Y8Js3V+LWrycLTf/woV+xTREEjJu/1YWduyxctywGoRXS
E0bndtnKqtmZOygLMIm4B6/s6ljquMkpRufK5voZC/z9pd77TXB8+KWA5xFWpj2E5TMIhdE567jJKbKrY2mk+iHE3ppIDbHhiyPxj5KLfyGigM8p8xRO/4g6ZIDlw7riiOXpH1E4ZZ5C
Nstlef4oJiCZDV8MAHtrQKKxASZSA3y+NYa4TNzPDFx+qTtkV+toVgVE0R6YMgWFGBDWGAL4fICpsQFGAMTpupaZRGK+NjkQlVYgCQKyOWDOLHlMcv9wSgEioghjMT9d1zIToCh/XDB9
1PVSCtaUPvhDgNaMyy48drl/GKUAwRrjeiklmD7a4waSWFKAnUtLgZHfP2OqwMcXO8cs9x9MCpw6XyGbK8t+RCe8JJb0IgBexNFxVsnFf5BnXHKBC0cd29zf7ZsVpMC5ZzvQYRlO3wkU
Yc2LAECsXLk7CWCuNSFK6f7FOXsTjxOo/ZjT/bdjfcWxj0WnRLkOYek7BYsC1nNXrtydFJxMziDQRGvDkqp/QVFmz5kfVaiooO5z+2N9xUkiY8cQzjgtMgalKK0IsDYEgSZyMjlDaG3m
Sem7zMaWkgJsIYFy6ZLRYuJDrQtqI9VY4oQRYjZWSt/V2swTAM0V0impAUgUpWVNPl5g1gzRbQCNLvTZizmzJKadIBEEJZeOHGFOcwUEzSqHnssHjL85RcF1S5MNU6507FJdx9roaHzR
Qol8UJ7IIATNEsSYwWxLvmlSAEtOU0X/3e6kUOqJs5siZ+HG14n99pg7S5Hte9ZiB75X+pQxZgtizBAATYgGK5ZG/8fW/5TJAvPmqqKJ/9iIjH+ro4PRleXuLJxiBZl6ZxXFSasdndwd
wyhWpm/8HCfNlJg+VSBfQjXADIqYniYoEI5jq3sNVSyV+HfgOihKxo8tbP6udy0e3xTiL00aLa0MKaPkksWnKZxfW+CkIRwzx+Dn8ozG34d47o8aO3dbGANUVRJqTpb4xLkupp8givNc
hd+Yc5LEtjcMEh7BcEmYkthqgHCcYsAtZQAw/uX5cySKYWnGm7TxmRB3/+8cOjsZrktQMgKseb/Gi/+psfGZEDd9KYFJE8URJZrE33l3r8Xt/57Flm0Grgs4KqogaW1jbH/T4InGEDd+
1sc5S50hE0G8NwvnKzz6m6DEJ+QMBlxB4PHRLN3SCBxrozKu6VNln8DHUMB/8ukQ370rCzBQXUXw3MiAUgpIJAjjxhJef8vgX2/rQvMBO2h1EH+2+YDFN7/dhdffMhg3llCRiCp9lARc
N7o2CeB7P4xy/IQYmjqI92bOLIHKSoIpWVCIyFoDAo8XQO8p2qVx/yZNjGr3hhL9izlyzz6LnzyQQ7KCICVgTK/U74KxpjVQmSTs2Wdx55octB48JxIBP3kwj3f3WlSmCFr3GH3xy5gI
tFSSsOYnWWx93QyJCOK9mTBB4PjjBEJdSneQAQglSin+BUXlXbNnCUg5NO6ICeAXvw7Q2s7d9sShljZAZYrw51c0XngpBBEGdOJmC7UI294w+P3zIaoq6bAExBxJnyAE/u8v80MicgBg
G0XjTpgsoDWXOE2OS5z8URC9s0+UfUTrkYAfZxG98JJGwh9gOnXhe39+xcS3M+DV+PsQZoBZu9ZGhaDb37TdnsiRPmscBZw5PTIsS306JEp5BWujAsvpJ8ghi38AeOevFs37LdQATxIt
A45D2PaGicT1AMg9/szW1w2UGlgdXywFDrxn8fqbdkjEHu/RidMllCx1MSlBAJE/UKoAkO8Rxo+joRFA4d/m/TbKpR/E70gRWey5PH8gMPF72RyjtS1yKwcDnDbA/vfskLyd+NmmTBKo
SJQyIEQArBYM2i+ERLFjWvGGVKYIY6qoePeMoUmRkb5iAhg/TmD8ODFogh/obgghwaD9goCgVBLAGGBMdVSOPRQJEH9t3BgRtWIZBJiWIyvd9z74HuL3Ej6hMjU47ovD3dWVNFRajVrP
SOC4CVTCOkICAYEAYx8JBWYUXQIYw5gwTgyZA+MNOGGywJhqERlnA9gUQUAYMmbNFN2dOgZitwDAzGkCYThwK9wYoLpK4KQTh2bv9N6rsdWRIUhF538wRd7/PgFwM5FAYVx7UTUMc0TF
xSAAa6Pw65LTFbK5AZ6WUeRWfeyMwecgnHe2CykHpsuljMLFp8yXqKosXrJLKlUyNcNR6Sc3CybsKEkdaMEVikXiUHVwvKGXX+IiWUEI9eGteiWBjk7GR05ROH3hwNPPhYjUxvy5Emee
7qCtnbubPh2OOKUA/u4it2jGM4DueslSaGgiASbsELD8Rqk8ACJgTLUYsgHXvdEc5RR+7ioPXV0MYyLu624fVzi1Uwro7Ir6C934OX/AnNxfen32Kg+TJgq0d0REEJ/+xS9ZOH9oaWOs
TPuYe5Isanl7bLeUzk/nNwTAWwtJglQCIQCniBlgosBtF57j4ovX+aDCoUw+iIhB6yhYdOA9xtQTJP7ta0mcMCk6DBpMRC2WNscfJ7Dqv1VgxlSJ91oYXV1RX0JjgCCIrm0M8KXP+/j7
y9zigV+4fmWKSlU7QRHmvFUpJbcYkwuIpMtsiyZw4uDI2IIEKBZ1xbH2i851sbBG4dEnA7y23aD5QGQXTJ0scWqNwqXnO1EvniM8Do4lzgmTBb6zKoknGgO8+J8a7/zVdns3c2ZJXHhO
1EGsFDUOnkul8ACYSApjcoFScouizs4dnKjYK4Uz1ZgchrMh5GCJYMokgeuuidrKtHdEBJCsoD5EOJRYuogreV3g0gtcXHqBi86C6kmlqPu3i93VJL7lqkoatNs7kLCaEA60ye2lzq4d
4r77JncC2FpIDLU4SlZcVROfCVSmCMkK6pMSVgzu6Z9mlqwgVFVStzqyJaxuKlHwyhaw3nrffZM7C046vUSCCjkCR8/q3YSpd3u2oTaXOtR1YmKIgRHiKGxqweAIa3oJiPsEsn2uAD2V
AqRyhlA/LNcp5SNEvXLtc0ChFMwS/zHId2gIKVGkBIHYP27vKBzCYHSNAGJjCCmDfIe2xH8sEABTZu2Yt5jtq0r6YC6e5rEcuWXF1Ikj+VCn2PemdXEZh5k5wti+mlk75i2ASUTTJokB
ekLI4reIkbJ4m9t7IshIIoQ4FY2oOIQQf72lzQ743GOA3oUVUjJATwDEtfWQYmJToR+spEetLX6LmFyOh1zrFoNvbRTh687H5+Ejhhh026tuIJZ2Qwas0GK2M55+UiQCYEBYa4gkPQoA
E5vAKhowCJiK1DPc3rarWG3iYot5/3vRiVqocURVrzG4O3dbfO+uLDo6GRcuc3DWEgeTj+9JaPqgLuLFVkGil6exe4/F754P8eunQowbS/jnLya6T0GP5F6sBRwJHHiPe9rcF0EjS+WL
MOjcZSurngGATAZWAcTpNMvMHZRdUdf+mFLu5wKdsxjiCVGcDt74+xB/c4rC/LnyiIMmRIDRQEUiSvdesy6Hnz0aYGGNwtkfc7BgnkRlit53/e6wZq9hEB8ESG9pEjeZJvQ9B4gDT5u3
GDz9bIiXmzTe3WuRrCBMnaKOOIsn3hvHAV7davDbZ0MkipUVxGyVcsno4LHMHZSNR8j0PecSZr215vMMFkMtFIrn6TTvZ6z6Thcuv9TF8ss8OM7guoDHn5kxTeDfbqnAX5oMfvF4Hi/+
WeOJxgDPPBdi4gSBk2dLfGSBRM3JCpMmisOe4MUgM94vYXvfU+//Gwvs2WuxZZvBn17W2LLNYM8+i1yOUV1FuKDWxSXnOzi1Rh2ZOikklIQh8PAv83jkVwGMQdGaSDJYWGsIwqw/WNQR
KFGz6FgVtHcwTp4tUbfSPyJpEG9CDMpr2w0efTLAy5sNOjoZQcCwFkgmCRMnCJw4Q2D2idE8oQnjBDwvKuRI+IenujgfMAyBvc0Wu/dYbH/T4K13LPbus+jojDJ0PI9QlSIsWqhw/tkO
Tp4tD3qfA+V6IOL6tffl8Np2U9SDoMM1i+6+zXjs+Iq69ls9P/W1INemQVS0cl4pC9NAJOET5zhYfpmHsWOoW68OlBBiazve4Dd2GHzz2109qsJEXBSGkfEpZXSoImUULh43ViBZET0+
iZ4JZFRoX9e836K9IyKmfJ6hC8UfjlOoClI9oN32zSSmThF97IMjeY73WhgP/zKPX28MYQyjIlHkqiBm7fpVKp/r+Pb6tZW39B4x3w3wMsA2AnBc82MddH0VJOKRBkWxQYyJbAJm4OeP
Bnj2BY2rl3s472ynT4h1oBNBtI7AeO5FjfaO6Ow/3jTXjTiU0DNXyNpoo/c160N6JYIApahb31dU9PxGn2ogAbS1M/7wYohPT/G672UgXN+/qvnJp0M88HAee5ujCiTXKXpJGIOE1EFX
4Ljmx72xfp+DERsGV1zX+jPPr/pkmC+uFOgtDeL5PHNnS3zqYhcfX+z04aTDTeuIxeLeZouvfKNzwClY3ZPBaGjBpljSeB7wvW8lMf4DLP6DEffvnw/xs0cDbN1u4LoE10VpagGZteNV
qXyu7ecbflT9qf7zAw8CLhOh5U5rw0+WqoG3MRHHOA5h+xsGt/8giwVPhvjbC10sOV31acAAev9NxJv50CN5dHTygAcvdI+OKUJcwnGAllbG/Q/n8V+vTxyUCG1hCllvl/HpZ0M8vinE
5i0ahMhmiSVLSVxXQERNoeydBxsk/b4/xPNkVtS1Pue4yTN02GmB0s0NjLmiqytyeOfPlVi6xEHtx53us/3YSo7P54UAXnhJ47/f0YVkBQ3bgEYhomBN/U0VWHSq6hkrx329nM5ORuOz
IX77bIimrVEBaUWCeoi8dOEqo5ykCIPOF9avrV7Se1bQISVA04KIKKSkW4nkz0o9NDTegIoC2K9uNXjlVYOfPxpg2VkOlpyuMGuG7J7KRRRt+k8fzEEpGtaQcOTqEn58fw6r65NI+NRn
gtgbOwyee1Fj0+9C7N5joWSU6Fl64HvYn0iSlHRrb2wPKwFiKbBqFfjKf2j7g+MmF+uw05RSCvTnKkJUbZvNMZIVUSeO0xYqLKxRmD5V4Ptrs3h8Y4jqqlLW0A/cnmlpZXzqEhd1K33s
2GnxSpPGiy9rNL0WjZRN+BRNCUM5B0eyUU5ShkHn8w/9R9WZq1YdfIL4QQ28piYQEdkV17XfDGBjOdPE4g1SCt0A/+lljRdeimYBT5si8M4ui1Ry+MGP7ZnKFOGp34bY9obB2zujWIGU
kddTXRWpKFN2NRWfTImbiYjTaRaH+dT7V/cE8bqW/+d61X8b5lsNSAzLBPHYiIqzcV0XI3LFQybjSeLDNjyarXG8ahnkW3+xfu2YvzvU5HDgMAc+NTVggEkpuknrbAhSw9bc3doeK9nz
MGJXnMdv7HBODmcGKdI6GypFNwFMEZaHYK5DvdHQQDa9AeL+NdWvWRuu9vykAGPYhe6xlBByhIaf8fyksDZcff+a6tfSGyAOpvs/UAXEMYH6etBbb8HNuR0vK+XN1mEXE402eh2ZBGit
cipI6/x2P0gtnDkTQUMDOEr4GaQEKNAHNzWB1q2jHDFuJBJEJO3oVo/MRSQtkSBi3LhuHeWamkCHA38ABABkMmRq6zeqh9ZWPhXmO+70/JRitnp0u0cc92vPT6kw33HnQ2srn6qt36gO
ZfgNQgX0qIJ0GgI1kGJXxx8cp2KRDjoMiOTo1o8I9I1yUzIMu16yU1JnogkmyvSiD7RKBqjLiWtqwJkGCsD2SmuCDiEdgO1otvewg29ZSAfWBB1ge2WmgYLI6qcBYTOoCE98jpyua7kq
4Vc/EAQdIZhHJ0AMr+IPXTflZHOtV2fWjnmw91n/gGIsg7lWYwPp2npWmbVjHsznWr/jeSmHmcNRFIZL8nPoeSknn2v9zpGAP2gJENsDtfWQjQ2kr6xr/z9eIrU8l20LiWhUEpQZfD9R
5eSzHQ8/tLby0xH4MAMV/UMgAADMVL8K1NT0jifHjnvcdZNL87lWTSTUKDTlsvirVRB0PmPeO3BhTc20fMMqMIgGbZMdWUCncKFMZnqWYC8Pg2yT61WPuodlAt/1qlUYZJsI9vJMZnq2
NyblIQAUQsXpDfLBe6qadb79PB2OEkG5wNdhtknn28978J6q5nR6gzxcqLc0KqDXik+a0tfumaS8yieVk6gJ8qPqoNTgZ9Yd/+7hTvlKLgHilcmQSadZZtYd/67Ot59ndG6z51erUe+g
yNa+X62Mzm0uJvhFIYD+RJDtbDk3DHNP+4mqURexiNZ+GOaezna2nFtM8ItGAD1EsEE+ct/kve184OIwyGX8RJUDQPNoxPBIRD4D0H6iygmDXKadD1z8yH2T96bTG4oGflFsgP6rd+bp
1Td03iZVxc067AKzLlte4YcAfkOkpHIqYHTX6gfuTv5L/70dsQQQB4vq66MkxKvq2q8Ryv0BCVUdBu2jxuEAjD3HrVRsdavVwRcfXFt5fwT8wOP7I4AAolVby6qxkfSK69rmS8f9qeN4
i3PZNgswRpNK3ge8BQh+okqEYf55EwafXf+jqlfjPSzVdUue7hs/wEUXbfXGTp/6bSmdrzAAHXZpIsjRIfLMzDDKqVAEwJjwjvfe3vm1xx6bmy81+GUhgP6664q6lk84yv+uUt6CfL4D
YDNs2cbDj701ICk9LwWt85tDnfvqhrVjfl0qfT9sBBDbBek0ROQtvJ1Q4467hYCbpPK9IH9sqYVY3LtelTA6l2fgdn1g362ZzPRC546BJXMcZQQQrd4+bPr69lOVkA2S3MtBBB12GGam
DyshMFtLRKyclAQzDAePaGvqM/dU/qX/3pRrDZP+Zaqt3SQbG8/RAHDlDe0XEKl6Jf2zmC3CoMMWJpiIo99GYAZgmUGOmxJEAtrkfsesGx66u/I3kZ20UTU2LjPl4voRQAA9tgEQHSwB
wFU35pYT48skxFIhHIRBB8BWMyCoJGNNSmraWQIsSCjHTcHaEGztM0y488E1/sMHe/7hWCOCu/qLvitvyF5AwI1gvtRxE57RAbTOWiKyzCSIIEYor1sitswslEoIqVyEQTYPol8xsOah
uxO/OdQzH9ME0HdTegygz/xjbr5l/oy1Ni2VP1sIAa3zMDpvu8vwCTR8aoKZGRzfi1SeUMqDtRZG57YLITKC6N57f+i/2t8QHil7PiL1azrNsqYGHIvGa69lP0zkz2Frl4PofCndGUII
GGNgdBaANWAwCASGKNBD0aetFbo22u5rQUipEpBSRqCbYAeYnyAhHnay3sZ16ygXi/qmJtBIAn5EE0BvG2HTJojewZCVX+Wk6cwtJcaFDD6X2Sxw3ZQTt5I1JgDbENaa2JAEc6E1UHfz
w8N3H4pnKPb+vhBSkHAgpds9rCIIOkIiuZlATzHhcZn0n7nvu9TZOwi2bBnscOr4o5oA+scQgOjUsfc7K67PniTBpzHMYjAtAmEOs50kpe8KETeesmA2YDYAGNZG//bfimiELoFIFl6R
qWFtiGiukngXjG0gfokgnzegP62/J/F6f+kV3Wf5fPljgADeTwx7a0AHS4FOf4FTEsEMCvU8EM0h4hOZMQ3gCZbNZIJQYDsBhdGZ3dvAVoNEM8NqQXI3QM1EeIeZ3gTzNnbUFgN3R+Yu
6uh/zdp6VhObwEcL6L3X/wfOMrOs5lB+lAAAAABJRU5ErkJggg==
]],
    tt = [[
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
]],
}
UIFX.icon_cache = {}
function UIFX.icon_tex(key)
    local e = UIFX.icon_cache[key]
    if e == nil then e = {}; UIFX.icon_cache[key] = e end
    if e.tex ~= nil or e.failed then return e.tex end
    local data = UIFX.ICONS[key]
    if not data then e.failed = true; return nil end
    local ok, tex = pcall(function()
        local path = cfg_dir .. "arizona_icon_" .. key .. ".png"
        local need = math.floor(#(data:gsub("[^%w%+/]", "")) * 6 / 8)
        local have = 0
        local f = io.open(path, "rb")
        if f then have = f:seek("end") or 0; f:close() end
        if have < need - 2 or have > need + 2 then
            if not write_file(path, UIFX.b64(data)) then error("write failed") end
        end
        return imgui.CreateTextureFromFile(path)
    end)
    if ok and tex then e.tex = tex else e.failed = true end
    return e.tex
end

-- фото со скруглёнными углами и приближением (zoom 0..1); если не получится, рисуем обычное
function UIFX.photo(dl, tex, p0, p1, zoom, col, rounding)
    local z = (zoom or 0) * 0.05
    local uv0, uv1 = imgui.ImVec2(z, z), imgui.ImVec2(1 - z, 1 - z)
    if UIFX.round_mode ~= 2 then
        if pcall(dl.AddImageRounded, dl, tex, p0, p1, uv0, uv1, col, rounding or 8, 0) then
            UIFX.round_mode = 1
            return
        end
        UIFX.round_mode = 2
    end
    pcall(dl.AddImage, dl, tex, p0, p1, uv0, uv1, col)
end

-- вертикальный градиент цвета (r,g,b) от прозрачности a0 (сверху) до a1 (снизу)
function UIFX.grad(dl, x0, y0, x1, y1, a0, a1, r, g, b)
    if UIFX.grad_mode ~= 2 then
        local c0, c1 = col32(r, g, b, a0), col32(r, g, b, a1)
        if pcall(dl.AddRectFilledMultiColor, dl, imgui.ImVec2(x0, y0), imgui.ImVec2(x1, y1), c0, c0, c1, c1) then
            UIFX.grad_mode = 1
            return
        end
        UIFX.grad_mode = 2
    end
    local n = 8
    for i = 0, n - 1 do
        local t = (i + 0.5) / n
        dl:AddRectFilled(imgui.ImVec2(x0, y0 + (y1 - y0) * i / n), imgui.ImVec2(x1, y0 + (y1 - y0) * (i + 1) / n + 1),
            col32(r, g, b, a0 + (a1 - a0) * t), 0)
    end
end

-- плашка «✓ 11/11»
function UIFX.set_badge(dl, x, y, s, k)
    local txt = ic("CHECK", "") .. " " .. s.have .. "/" .. s.total
    local ts = imgui.CalcTextSize(txt)
    local w, h = ts.x + 16, 20
    dl:AddRectFilled(imgui.ImVec2(x, y), imgui.ImVec2(x + w, y + h), col32(0.04, 0.04, 0.07, 0.72 * k), h / 2)
    dl:AddRect(imgui.ImVec2(x, y), imgui.ImVec2(x + w, y + h), col32(s.c[1], s.c[2], s.c[3], 0.95 * k), h / 2, 0, 1.2)
    dl:AddText(imgui.ImVec2(x + 8, y + (h - ts.y) / 2), col32(s.c[1] * 0.35 + 0.65, s.c[2] * 0.35 + 0.65, s.c[3] * 0.35 + 0.65, k), txt)
    return w
end

-- полоса прогресса
function UIFX.bar(dl, x, y, w, h, ratio, c)
    dl:AddRectFilled(imgui.ImVec2(x, y), imgui.ImVec2(x + w, y + h), col32(1, 1, 1, 0.10), h / 2)
    if ratio > 0.001 then
        dl:AddRectFilled(imgui.ImVec2(x, y), imgui.ImVec2(x + math.max(h, w * ratio), y + h), col32(c[1], c[2], c[3], 0.95), h / 2)
    end
end

function UIFX.sets_totals()
    local full, have, total = 0, 0, 0
    for _, s in ipairs(UIFX.SETS) do
        have, total = have + s.have, total + s.total
        if s.have >= s.total then full = full + 1 end
    end
    return full, have, total
end

-- ---------- сетка карточек ----------
function UIFX.sets_grid(now)
    local dt = imgui.GetIO().DeltaTime
    local ac = UI_CFG.accent
    local dl = imgui.GetWindowDrawList()
    local avail = imgui.GetContentRegionAvail().x
    local appear = clamp((now - UIFX.table_t) / 0.9, 0, 1)
    local app_e = 1 - (1 - appear) ^ 3

    -- сводка коллекции
    local full, have, total = UIFX.sets_totals()
    local hp = imgui.GetCursorScreenPos()
    local hh = 54
    UIFX.grad(dl, hp.x, hp.y, hp.x + avail, hp.y + hh, 0.20, 0.06, ac[1], ac[2], ac[3])
    local bg = dark(0.075)
    dl:AddRectFilled(imgui.ImVec2(hp.x, hp.y), imgui.ImVec2(hp.x + avail, hp.y + hh), col32(bg.x, bg.y, bg.z, 0.55), 10)
    dl:AddRect(imgui.ImVec2(hp.x, hp.y), imgui.ImVec2(hp.x + avail, hp.y + hh), col32(ac[1], ac[2], ac[3], 0.35), 10, 0, 1.0)
    dl:AddText(imgui.ImVec2(hp.x + 16, hp.y + 9), col32(1, 1, 1, 0.55), "Моя коллекция")
    dl:AddText(imgui.ImVec2(hp.x + 16, hp.y + 28), col32(1, 1, 1, 0.95),
        "Сетов: " .. full .. " из " .. #UIFX.SETS .. "   ·   Предметов: " .. have .. "/" .. total)
    local pw = math.min(170, avail * 0.30)
    local px = hp.x + avail - pw - 64
    UIFX.bar(dl, px, hp.y + hh / 2 - 4, pw, 8, (total > 0 and have / total or 0) * app_e, ac)
    local pct = math.floor((total > 0 and have / total or 0) * 100 + 0.5) .. "%"
    local ps = imgui.CalcTextSize(pct)
    dl:AddText(imgui.ImVec2(hp.x + avail - 16 - ps.x, hp.y + (hh - ps.y) / 2), col32(ac[1] * 0.4 + 0.6, ac[2] * 0.4 + 0.6, ac[3] * 0.4 + 0.6, 1), pct)
    imgui.Dummy(imgui.ImVec2(avail, hh + 8))

    -- карточки
    local gap = 12
    local cols = clamp(math.floor((avail + gap) / (170 + gap)), 2, 5)
    local cw = math.floor((avail - gap * (cols - 1)) / cols)
    local pad = 7
    local iw = cw - pad * 2
    local ih = math.floor(iw * 1.25) -- фото 4:5
    local foot = 40
    local ch = pad + ih + foot
    for i, s in ipairs(UIFX.SETS) do
        if (i - 1) % cols ~= 0 then imgui.SameLine(0, gap) end
        local p = imgui.GetCursorScreenPos()
        if imgui.InvisibleButton("##set" .. i, imgui.ImVec2(cw, ch + gap - 5)) then
            UIFX.set_sel, UIFX.set_t = i, now
        end
        local hv = imgui.IsItemHovered() and 1 or 0
        s.hv = (s.hv or 0) + (hv - (s.hv or 0)) * math.min(1, dt * 14)
        local h = s.hv
        local ra = clamp((now - UIFX.table_t - 0.06 - (i - 1) * 0.05) / 0.30, 0, 1)
        local re = 1 - (1 - ra) ^ 3
        UIFX.set_alpha(UIFX.base * re)
        local c = s.c
        local x0, y0 = p.x, p.y + (1 - re) * 16 - h * 3
        local x1, y1 = x0 + cw, y0 + ch
        if h > 0.02 then
            for k = 4, 1, -1 do
                dl:AddRectFilled(imgui.ImVec2(x0 - k * 2, y0 - k * 2), imgui.ImVec2(x1 + k * 2, y1 + k * 2 + 3),
                    col32(c[1], c[2], c[3], 0.045 * h), 12 + k * 2)
            end
        end
        local cb = dark(0.085 + 0.03 * h)
        dl:AddRectFilled(imgui.ImVec2(x0, y0), imgui.ImVec2(x1, y1), col32(cb.x, cb.y, cb.z, 1.0), 10)
        -- фото
        local q0, q1 = imgui.ImVec2(x0 + pad, y0 + pad), imgui.ImVec2(x0 + pad + iw, y0 + pad + ih)
        local tex = UIFX.set_tex(s)
        if tex then
            UIFX.photo(dl, tex, q0, q1, h, col32(1, 1, 1, 1), 8)
        else
            dl:AddRectFilled(q0, q1, col32(0.12, 0.12, 0.15, 1.0), 8)
        end
        -- затемнение снизу и название сета
        UIFX.grad(dl, q0.x + 1, q1.y - 70, q1.x - 1, q1.y - 8, 0.0, 0.90, 0.03, 0.03, 0.06)
        dl:AddRectFilled(imgui.ImVec2(q0.x + 1, q1.y - 18), imgui.ImVec2(q1.x - 1, q1.y - 1), col32(0.03, 0.03, 0.06, 0.90), 7)
        local ts = imgui.CalcTextSize(s.name)
        local tx, ty = q0.x + (iw - ts.x) / 2, q1.y - 12 - ts.y / 2 - 3
        dl:AddText(imgui.ImVec2(tx + 1, ty + 1), col32(0, 0, 0, 0.85), s.name)
        dl:AddText(imgui.ImVec2(tx, ty), col32(1, 1, 1, 0.96), s.name)
        -- плашка 11/11 на фото
        UIFX.set_badge(dl, q0.x + 7, q0.y + 7, s, 1)
        -- подвал: статус и полоса прогресса
        local fy = q1.y + 9
        local done = s.have >= s.total
        dl:AddText(imgui.ImVec2(x0 + pad + 2, fy), col32(1, 1, 1, done and 0.65 or 0.85), done and "Сет собран" or "Собирается")
        local pr = s.have .. "/" .. s.total
        local prs = imgui.CalcTextSize(pr)
        dl:AddText(imgui.ImVec2(x1 - pad - 2 - prs.x, fy), col32(c[1] * 0.4 + 0.6, c[2] * 0.4 + 0.6, c[3] * 0.4 + 0.6, 1), pr)
        UIFX.bar(dl, x0 + pad + 2, fy + 19, cw - pad * 2 - 4, 5, (s.total > 0 and s.have / s.total or 0) * re, c)
        dl:AddRect(imgui.ImVec2(x0, y0), imgui.ImVec2(x1, y1), col32(c[1], c[2], c[3], 0.16 + 0.74 * h), 10, 0, 1.0 + 0.8 * h)
    end
    UIFX.set_alpha(UIFX.base)
    imgui.Dummy(imgui.ImVec2(0, 4))
end

-- ---------- подробный просмотр одного сета ----------
function UIFX.sets_detail(now)
    local n = #UIFX.SETS
    local s = UIFX.SETS[UIFX.set_sel]
    if not s then UIFX.set_sel = nil return end
    local c = s.c
    local e = 1 - (1 - clamp((now - (UIFX.set_t or now)) / 0.32, 0, 1)) ^ 3
    UIFX.set_alpha(UIFX.base * e)
    local slide = (1 - e) * 26
    local avail = imgui.GetContentRegionAvail()

    if imgui.Button(ic("CHEVRON_LEFT", "<") .. " Назад##set_back", imgui.ImVec2(100, 28)) then
        UIFX.set_sel = nil
        return
    end
    imgui.SameLine(avail.x - 128)
    if imgui.Button(ic("CHEVRON_LEFT", "<") .. "##set_prev", imgui.ImVec2(32, 28)) then
        UIFX.set_sel, UIFX.set_t = (UIFX.set_sel - 2) % n + 1, now
    end
    imgui.SameLine(0, 6)
    if imgui.Button(ic("CHEVRON_RIGHT", ">") .. "##set_next", imgui.ImVec2(32, 28)) then
        UIFX.set_sel, UIFX.set_t = UIFX.set_sel % n + 1, now
    end
    imgui.SameLine(0, 10)
    imgui.TextDisabled(UIFX.set_sel .. " / " .. n)
    if imgui.IsWindowHovered() and imgui.IsMouseClicked(1) then
        UIFX.set_sel = nil
        return
    end

    local dl = imgui.GetWindowDrawList()
    local lp, sp = imgui.GetCursorPos(), imgui.GetCursorScreenPos()
    local rem = imgui.GetContentRegionAvail()
    local ih = math.max(150, rem.y - 8)
    local iw = ih * 0.8
    if iw > avail.x * 0.50 then iw = avail.x * 0.50; ih = iw * 1.25 end
    local x0, y0 = sp.x + slide * 0.4, sp.y + 4

    -- фото с свечением цвета сета
    for k = 5, 1, -1 do
        dl:AddRectFilled(imgui.ImVec2(x0 - k * 3, y0 - k * 3), imgui.ImVec2(x0 + iw + k * 3, y0 + ih + k * 3),
            col32(c[1], c[2], c[3], 0.04), 12 + k * 3)
    end
    local p0, p1 = imgui.ImVec2(x0, y0), imgui.ImVec2(x0 + iw, y0 + ih)
    local tex = UIFX.set_tex(s)
    if tex then
        UIFX.photo(dl, tex, p0, p1, 0, col32(1, 1, 1, 1), 10)
    else
        dl:AddRectFilled(p0, p1, col32(0.12, 0.12, 0.15, 1.0), 10)
    end
    dl:AddRect(p0, p1, col32(c[1], c[2], c[3], 0.9), 10, 0, 2.0)

    -- правая панель
    local rx = lp.x + iw + 24 + slide
    local rsx = x0 + iw + 24 + slide - slide * 0.4
    local pw = math.max(120, avail.x - iw - 24 - 10)
    imgui.SetCursorPos(imgui.ImVec2(rx, lp.y + 6))
    imgui.SetWindowFontScale(1.5)
    imgui.TextColored(imgui.ImVec4(1, 1, 1, 1), s.name)
    imgui.SetWindowFontScale(1.0)
    imgui.SetCursorPos(imgui.ImVec2(rx, lp.y + 38))
    imgui.TextDisabled("Коллекционный сет")

    local done = s.have >= s.total
    local label = ic("CHECK", "") .. (done and " Собран полностью" or " Собирается")
    local ls = imgui.CalcTextSize(label)
    local by = sp.y + 66
    dl:AddRectFilled(imgui.ImVec2(rsx, by), imgui.ImVec2(rsx + ls.x + 24, by + 26), col32(c[1], c[2], c[3], 0.16), 13)
    dl:AddRect(imgui.ImVec2(rsx, by), imgui.ImVec2(rsx + ls.x + 24, by + 26), col32(c[1], c[2], c[3], 0.9), 13, 0, 1.2)
    dl:AddText(imgui.ImVec2(rsx + 12, by + (26 - ls.y) / 2), col32(c[1] * 0.35 + 0.65, c[2] * 0.35 + 0.65, c[3] * 0.35 + 0.65, 1), label)

    imgui.SetCursorPos(imgui.ImVec2(rx, lp.y + 108))
    imgui.TextDisabled("Прогресс сета")
    imgui.SetCursorPos(imgui.ImVec2(rx, lp.y + 126))
    imgui.SetWindowFontScale(1.4)
    imgui.TextColored(imgui.ImVec4(c[1] * 0.4 + 0.6, c[2] * 0.4 + 0.6, c[3] * 0.4 + 0.6, 1), s.have .. " / " .. s.total)
    imgui.SetWindowFontScale(1.0)
    local fill = (s.total > 0 and s.have / s.total or 0) * clamp((now - (UIFX.set_t or now) - 0.15) / 0.7, 0, 1)
    UIFX.bar(dl, rsx, sp.y + 158, pw, 10, fill, c)

    imgui.SetCursorPos(imgui.ImVec2(rx, lp.y + 186))
    imgui.TextDisabled("Предметы сета")
    local sz, sg = 30, 8
    local per = math.max(1, math.floor((pw + sg) / (sz + sg)))
    for k = 1, s.total do
        local col, row = (k - 1) % per, math.floor((k - 1) / per)
        local sx, sy = rsx + col * (sz + sg), sp.y + 210 + row * (sz + sg)
        local sa = clamp((now - (UIFX.set_t or now) - 0.25 - (k - 1) * 0.04) / 0.2, 0, 1)
        local filled = k <= s.have
        local aa = (filled and 1 or 0.4) * sa
        dl:AddRectFilled(imgui.ImVec2(sx, sy), imgui.ImVec2(sx + sz, sy + sz), col32(c[1], c[2], c[3], (filled and 0.20 or 0.06) * sa), 7)
        dl:AddRect(imgui.ImVec2(sx, sy), imgui.ImVec2(sx + sz, sy + sz), col32(c[1], c[2], c[3], 0.85 * aa), 7, 0, 1.3)
        if filled then
            local ck = ic("CHECK", "v")
            local cs = imgui.CalcTextSize(ck)
            dl:AddText(imgui.ImVec2(sx + (sz - cs.x) / 2, sy + (sz - cs.y) / 2), col32(c[1] * 0.35 + 0.65, c[2] * 0.35 + 0.65, c[3] * 0.35 + 0.65, sa), ck)
        end
    end
    local rows = math.ceil(s.total / per)
    imgui.SetCursorPos(imgui.ImVec2(rx, lp.y + 210 + rows * (sz + sg) + 6))
    imgui.TextDisabled("ПКМ - назад к списку")

    imgui.SetCursorPos(imgui.ImVec2(lp.x, lp.y))
    imgui.Dummy(imgui.ImVec2(avail.x, ih + 8))
    UIFX.set_alpha(UIFX.base)
end

function UIFX.sets_body()
    local now = imgui.GetTime()
    if UIFX.set_sel then UIFX.sets_detail(now) else UIFX.sets_grid(now) end
    UIFX.set_alpha(UIFX.base)
end

function UIFX.draw_sets_tab()
    section_header(ic("LAYER_GROUP", ""), "Коллекционные сеты")
    if UIFX.sets_tt ~= UIFX.table_t then
        UIFX.sets_tt = UIFX.table_t
        UIFX.set_sel = nil
    end
    UIFX.tex_budget = 1
    if imgui.BeginChild("##sets_child", imgui.ImVec2(-1, LAYOUT.h - 79), true) then
        local ok, err = pcall(UIFX.sets_body)
        if not ok then
            UIFX.set_alpha(UIFX.base)
            UIFX.set_sel = nil
            log_error("sets_tab", err)
        end
    end
    imgui.EndChild()
end


local function draw_extra_tab(id)
    if id == 3 then
        draw_payday_tab()
    elseif id == 4 then
        UIFX.draw_sets_tab()
    elseif id == 5 then
        draw_about_tab()
    elseif id == 7 then
        draw_settings_tab()
    end
end

local payday_frame
payday_frame = imgui.OnFrame(
    function()
        payday_frame.HideCursor = not payday_edit
        return payday_on[0]
    end,
    guard_frame("payday", function()
        if payday_edit and not main_window[0] then payday_edit = false end
        local flags = bit.bor(imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.AlwaysAutoResize, imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoSavedSettings)
        if not payday_edit then
            flags = bit.bor(flags, imgui.WindowFlags.NoMove, imgui.WindowFlags.NoInputs, imgui.WindowFlags.NoBackground)
            imgui.SetNextWindowPos(imgui.ImVec2(payday_pos.x, payday_pos.y), imgui.Cond.Always)
        end
        imgui.SetNextWindowBgAlpha(0.45)
        imgui.Begin("##payday_overlay", nil, flags)
        imgui.SetWindowFontScale(UI_CFG.overlay_scale)
        shadow_text(imgui.ImVec4(1.00, 0.85, 0.30, 1.00), payday_text())
        if payday_edit then
            local pos = imgui.GetWindowPos()
            payday_pos.x, payday_pos.y = pos.x, pos.y
        end
        imgui.End()
    end, function() payday_on[0] = false end)
)

imgui.OnInitialize(function()
    -- иконки в стандартный шрифт (его создаёт mimgui)
    safe_call("fa_init", function() fa.Init() end)
    -- шрифт рисуем в 2 раза крупнее и уменьшаем масштабом: так крупные надписи (SetWindowFontScale) остаются чёткими,
    -- а обычный текст выглядит как раньше
    safe_call("custom_font", function()
        local path
        for _, f in ipairs(FONT_AVAILABLE) do
            if f.key == UI_CFG.font and f.path then path = f.path end
        end
        if not path then
            -- "Системный": берём тот же Trebuchet, который mimgui использует по умолчанию
            local ok, dir = pcall(getFolderPath, 0x14)
            if ok and dir then
                for _, name in ipairs({ "trebucbd.ttf", "trebuc.ttf", "arial.ttf" }) do
                    if doesFileExist(dir .. "\\" .. name) then path = dir .. "\\" .. name break end
                end
            end
        end
        if not path then return end
        local io_ = imgui.GetIO()
        local font = io_.Fonts:AddFontFromFileTTF(path, 28, nil, io_.Fonts:GetGlyphRangesCyrillic())
        if font ~= nil then
            -- иконки в тот же крупный размер (если версия fAwesome6 не принимает размер, берётся обычный)
            if not pcall(fa.Init, 28) then pcall(fa.Init) end
            io_.FontDefault = font
            io_.FontGlobalScale = 0.5
        end
    end)
    safe_call("apply_theme", apply_theme)
    safe_call("load_data", load_data)
end)

-- свой уголок изменения размера: окно тянется по смещению мыши, форма курсора не меняется
local grip = { on = false, mx = 0, my = 0, w = 0, h = 0 }
local function draw_resize_grip()
    -- угол окна считаем по рабочей области (окно содержимого стоит в правом нижнем углу)
    local wp, ws = imgui.GetWindowPos(), imgui.GetWindowSize()
    local cx, cy = wp.x + ws.x, wp.y + ws.y
    -- невидимая кнопка не даёт окну "уехать" при перетаскивании за угол
    imgui.SetCursorPos(imgui.ImVec2(ws.x - 28, ws.y - 28 + imgui.GetScrollY()))
    imgui.InvisibleButton("##resize_grip", imgui.ImVec2(20, 20))
    local mp = imgui.GetMousePos()
    local hov = mp.x >= cx - 34 and mp.x <= cx + 4 and mp.y >= cy - 34 and mp.y <= cy + 4
    if not grip.on and hov and imgui.IsMouseClicked(0) then
        grip.on = true
        grip.mx, grip.my, grip.w, grip.h = mp.x, mp.y, LAYOUT.w, LAYOUT.h
    end
    if grip.on then
        if imgui.IsMouseDown(0) then
            local sw, sh = getScreenResolution()
            LAYOUT.req = {
                w = clamp(grip.w + mp.x - grip.mx, 700, math.max(700, sw - 20)),
                h = clamp(grip.h + mp.y - grip.my, 400, math.max(400, sh - 20)),
            }
        else
            grip.on = false
        end
    end
    local ac = UI_CFG.accent
    local a = (hov or grip.on) and 0.95 or 0.55
    imgui.GetWindowDrawList():AddTriangleFilled(
        imgui.ImVec2(cx - 6, cy - 6), imgui.ImVec2(cx - 6, cy - 22), imgui.ImVec2(cx - 22, cy - 6),
        col32(ac[1], ac[2], ac[3], a))
end

-- размеры окна: запоминаем в настройках, пересчитываем высоту вкладок левой панели
local function layout_update(wsz)
    if wsz.x < 700 or wsz.y < 400 then
        wsz = imgui.ImVec2(math.max(700, wsz.x), math.max(400, wsz.y))
        imgui.SetWindowSize(wsz, imgui.Cond.Always)
    end
    LAYOUT.w, LAYOUT.h = wsz.x, wsz.y
    LAYOUT.tab_h = clamp(math.floor((LAYOUT.h - 161) / 6) - 5, 26, 46)
    LAYOUT.block_y = 5 + 6 * (LAYOUT.tab_h + 5) + 6
    local w, h = math.floor(wsz.x + 0.5), math.floor(wsz.y + 0.5)
    if w ~= UI_CFG.win_w or h ~= UI_CFG.win_h then
        UI_CFG.win_w, UI_CFG.win_h = w, h
        mark_ui_dirty()
    end
end

-- Заставка при первом открытии меню: логотип, версия и полоска загрузки (клик по ней закрывает)
function UIFX.draw_splash(wpos)
    if not UIFX.splash_t then return end
    local V = imgui.ImVec2
    local el = imgui.GetTime() - UIFX.splash_t
    local dur = 2.0
    if el >= dur then
        UIFX.splash_t = nil
        return
    end
    imgui.SetCursorPos(V(0, 0))
    if imgui.InvisibleButton("##splash_block", V(LAYOUT.w, LAYOUT.h)) then
        UIFX.splash_t = nil
        return
    end
    local a = (el < 1.35) and 1 or clamp(1 - (el - 1.35) / (dur - 1.35), 0, 1)
    local ac = UI_CFG.accent
    local dl = imgui.GetWindowDrawList()
    local x1, y1 = wpos.x + LAYOUT.w, wpos.y + LAYOUT.h
    dl:AddRectFilled(wpos, V(x1, y1), col32(0.04, 0.035, 0.06, 0.98 * a), 12)
    local cx, cy = (wpos.x + x1) / 2, (wpos.y + y1) / 2 - 24
    for i = 5, 1, -1 do
        dl:AddCircleFilled(V(cx, cy), 40 + i * 26, col32(ac[1], ac[2], ac[3], 0.035 * a), 40)
    end
    if UI_CFG.halloween then UIFX.hw_safe(UIFX.hw_pumpkin, dl, cx, cy - 92, 30, a, true) end
    local grow = 1 + 0.12 * (1 - clamp(el / 0.7, 0, 1)) ^ 2
    local title = "Arizona Prices"
    imgui.SetWindowFontScale(2.6 * grow)
    local ts = imgui.CalcTextSize(title)
    dl:AddText(V(cx - ts.x / 2 + 2, cy - ts.y / 2 + 2), col32(0, 0, 0, 0.6 * a), title)
    dl:AddText(V(cx - ts.x / 2, cy - ts.y / 2), col32(1, 1, 1, a), title)
    imgui.SetWindowFontScale(1.2)
    local sub = "Версия " .. SCRIPT_VERSION .. "  |  t.me/arizona_prices"
    local ss = imgui.CalcTextSize(sub)
    dl:AddText(V(cx - ss.x / 2, cy + ts.y / 2 + 12), col32(0.75, 0.78, 0.9, a), sub)
    imgui.SetWindowFontScale(1.0)
    local bw = 240
    local bx, by = cx - bw / 2, cy + ts.y / 2 + 62
    dl:AddRectFilled(V(bx, by), V(bx + bw, by + 6), col32(1, 1, 1, 0.10 * a), 3)
    dl:AddRectFilled(V(bx, by), V(bx + bw * clamp(el / (dur - 0.3), 0, 1), by + 6), col32(ac[1], ac[2], ac[3], a), 3)
    if UI_CFG.halloween then
        imgui.SetWindowFontScale(1.1)
        local hs = imgui.CalcTextSize("Happy Halloween")
        dl:AddText(V(cx - hs.x / 2, by + 20), col32(1.0, 0.60, 0.15, a), "Happy Halloween")
        imgui.SetWindowFontScale(1.0)
    end
end

imgui.OnFrame(function() return main_window[0] or modal_window[0] or UIFX.alpha > 0 end,
    guard_frame("menu", function(player)
        UIFX.tick()
        if main_window[0] or UIFX.alpha > 0 then
        UIFX.set_alpha(UIFX.alpha)
            local sw, sh = getScreenResolution()
            imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5)) 
            if LAYOUT.force then
                LAYOUT.force = false
                imgui.SetNextWindowSize(imgui.ImVec2(835, 500), imgui.Cond.Always)
            elseif LAYOUT.req then
                imgui.SetNextWindowSize(imgui.ImVec2(LAYOUT.req.w, LAYOUT.req.h), imgui.Cond.Always)
                LAYOUT.req = nil
            else
                imgui.SetNextWindowSize(imgui.ImVec2(UI_CFG.win_w, UI_CFG.win_h), imgui.Cond.FirstUseEver)
            end
            pcall(imgui.SetNextWindowSizeConstraints, imgui.ImVec2(700, 400), imgui.ImVec2(math.max(700, sw - 20), math.max(400, sh - 20)))
            if imgui.Begin(u8("Arizona Prices##main_window"), main_window[0] and main_window or nil, bit.bor(imgui.WindowFlags.NoCollapse, imgui.WindowFlags.NoResize, imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoScrollWithMouse)) then
                layout_update(imgui.GetWindowSize())
                local wpos = imgui.GetWindowPos()
                local win_cx, win_cy = wpos.x + LAYOUT.w / 2, wpos.y + LAYOUT.h / 2
                hk.typing = imgui.GetIO().WantTextInput

                -- Левая панель с вкладками
                draw_sidebar_bg(wpos)
                imgui.SetCursorPos(imgui.ImVec2(5, 5))
                sidebar_tab(FA.CIRCLE_DOLLAR .. u8(" Arizona Prices"), 1, "Таблица цен предметов (клавиша 1)\nCtrl+F - быстрый поиск")
                sidebar_tab(ic("CALCULATOR", "") .. " Калькулятор", 2, "Калькулятор с историей (клавиша 2)")
                sidebar_tab(ic("CLOCK", "") .. " Отчет до PayDay", 3, "Таймер до PayDay на экране (клавиша 3)")
                sidebar_tab(ic("LAYER_GROUP", "") .. " Коллекционные сеты", 4, "Коллекционные сеты (клавиша 4)")
                sidebar_tab(ic("CIRCLE_INFO", "") .. " О скрипте", 5, "Соцсети и разработчик (клавиша 5)")
                sidebar_tab(ic("GEAR", "") .. " Настройки", 7, "Тема, шрифт, прозрачность (клавиша 6)")
                UIFX.draw_bar(wpos)
                draw_update_block()

                -- Правая часть (содержимое выбранной вкладки)
                local tk = clamp((imgui.GetTime() - UIFX.tab_t) / 0.30, 0, 1)
                local te = 1 - (1 - tk) ^ 3
                local slide = (1 - te) * 30
                UIFX.base = UIFX.alpha * te
                UIFX.set_alpha(UIFX.base)
                imgui.SetCursorPos(imgui.ImVec2(SIDEBAR_W + slide, 0))
                local content_flags = imgui.WindowFlags.AlwaysUseWindowPadding or 0
                if not (current_tab == 2 and (LAYOUT.h < 495 or LAYOUT.w < 830)) then
                    content_flags = bit.bor(content_flags, imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoScrollWithMouse)
                end
                local content_visible = imgui.BeginChild("##content", imgui.ImVec2(LAYOUT.w - SIDEBAR_W - slide, LAYOUT.h), false, content_flags)
                if content_visible then
                if UI_CFG.bg_fx then pcall(UIFX.draw_bg) end
                if UI_CFG.halloween then UIFX.hw_safe(UIFX.hw_bg) end
                if current_tab == 1 then
                imgui.AlignTextToFramePadding() 
                imgui.SetCursorPosX(9) 
                local hdr_pos = imgui.GetCursorScreenPos()
                imgui.Text(FA.CIRCLE_DOLLAR .. u8(' Arizona Prices'))
                if imgui.IsItemHovered() then
                    local r0, r1 = imgui.GetItemRectMin(), imgui.GetItemRectMax()
                    imgui.GetWindowDrawList():AddLine(imgui.ImVec2(r0.x, r1.y), imgui.ImVec2(r1.x, r1.y), col32(UI_CFG.accent[1], UI_CFG.accent[2], UI_CFG.accent[3], 1), 1.5)
                    imgui.SetTooltip("Открыть наш Telegram-канал @arizona_prices")
                    if imgui.IsMouseClicked(0) then open_url("https://t.me/arizona_prices") end
                end
                imgui.SameLine(140) 
                imgui.SetNextItemWidth(math.max(90, LAYOUT.w - SIDEBAR_W - 329)) 
                if UIFX.focus_search then
                    imgui.SetKeyboardFocusHere()
                    UIFX.focus_search = false
                end
                imgui.InputTextWithHint("##search", FA.MAGNIFYING_GLASS .. " Поиск", buf_search, ffi.sizeof(buf_search))
                imgui.SameLine() 
                imgui.SetNextItemWidth(150)
                
                local sort_items = {"По умолчанию", "Сначала дорогие", "Сначала дешёвые", "По алфавиту", "Коллекционные", "Прочее"}
                local sort_preview = sort_items[current_sort[0] + 1] or "Сортировка"
                if imgui.BeginCombo("##sort_combo", sort_preview) then
                    for i, name in ipairs(sort_items) do 
                        local is_selected = current_sort[0] == (i - 1) 
                        if imgui.Selectable(name, is_selected) then 
                            current_sort[0] = i - 1 
                        end 
                        if is_selected then 
                            imgui.SetItemDefaultFocus() 
                        end 
                    end 
                    imgui.EndCombo()
                end
                
                imgui.SameLine(LAYOUT.w - SIDEBAR_W - 29) 
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0, 0, 0, 0)) 
                if imgui.Button(FA.CIRCLE_XMARK .. "##close", imgui.ImVec2(24, 24)) then 
                    main_window[0] = false 
                end 
                if imgui.IsItemHovered() then imgui.SetTooltip("Закрыть") end
                imgui.PopStyleColor(1) 
                imgui.Spacing()

                local q_now = ffi.string(buf_search)
                if q_now ~= UIFX.last_q or current_sort[0] ~= UIFX.last_sort then
                    UIFX.last_q, UIFX.last_sort = q_now, current_sort[0]
                    UIFX.table_t = imgui.GetTime()
                end
                if not UIFX.hint_shown then
                    UIFX.hint_shown = true
                    notify("Подсказка: правая кнопка мыши по предмету - быстрые действия, звёздочка - избранное", "info", 7)
                end
                if imgui.BeginChild("##table_child", imgui.ImVec2(-1, LAYOUT.h - 79), true) then 
                    local table_style = imgui.GetStyle() 
                    local table_start_x = imgui.GetCursorScreenPos().x
                    local table_top_y = imgui.GetCursorScreenPos().y - table_style.WindowPadding.y 
                    local separator_spacing = table_style.ItemSpacing.y 
                    local col_wl = 110
                    local col_w1, col_w2, col_w3 = 140, 120, ADM.on and 108 or 44
                    local col_w0 = math.max(110, math.floor(imgui.GetContentRegionAvail().x) - (col_wl + col_w1 + col_w2 + col_w3))
                    
                    imgui.Columns(5, "item_table", false) 
                    imgui.SetColumnWidth(0, col_w0) 
                    imgui.SetColumnWidth(1, col_wl) 
                    imgui.SetColumnWidth(2, col_w1) 
                    imgui.SetColumnWidth(3, col_w2) 
                    imgui.SetColumnWidth(4, col_w3)

                    do 
                        local sz = imgui.CalcTextSize("Предмет")
                        imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w0 - sz.x) * 0.5)) 
                        imgui.TextColored(accent_vec(1.3), "Предмет")
                    end 
                    imgui.NextColumn()

                    do
                        local sz = imgui.CalcTextSize("Ликвидность")
                        imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_wl - sz.x) * 0.5))
                        imgui.TextColored(accent_vec(1.3), "Ликвидность")
                    end
                    imgui.NextColumn()
                    do 
                        local sz = imgui.CalcTextSize("Скупочная цена")
                        imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w1 - sz.x) * 0.5)) 
                        imgui.TextColored(accent_vec(1.3), "Скупочная цена")
                    end 
                    imgui.NextColumn()

                    do 
                        local sz = imgui.CalcTextSize("Продажа")
                        imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w2 - sz.x) * 0.5)) 
                        imgui.TextColored(accent_vec(1.3), "Продажа")
                    end 
                    imgui.NextColumn()

                    do 
                        local sz = imgui.CalcTextSize("Действия")
                        imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w3 - sz.x) * 0.5)) 
                        imgui.TextColored(accent_vec(1.3), "Действия")
                    end 
                    imgui.NextColumn() 
                    imgui.Separator()

                    local table_bottom_y = imgui.GetCursorScreenPos().y - separator_spacing - 1.0 
                    local display_indices = {} 
                    local search_query = lower_cp1251(ffi.string(buf_search))

                    -- фильтры "Коллекционные" / "Прочее" (пункты 4 и 5 в списке сортировки)
                    local flt = current_sort[0]
                    local coll_marks = { u8:decode("легендарн"), u8:decode("хлам"), u8:decode("редк") }
                    local prof_mark = u8:decode("проф.")
                    local function is_collectible(name)
                        -- метка стоит в скобках: "Нимб лича (Легендарный)", "(Хлам/Редкий)"
                        for grp in name:gmatch("%((.-)%)") do
                            for _, m in ipairs(coll_marks) do
                                if grp:find(m, 1, true) then return true end
                            end
                        end
                        for grp in name:gmatch("%[(.-)%]") do
                            for _, m in ipairs(coll_marks) do
                                if grp:find(m, 1, true) then return true end
                            end
                        end
                        return false
                    end
                    local function is_other(name)
                        return name:gsub("^%s+", ""):sub(1, #prof_mark) == prof_mark
                    end

                    for i, v in ipairs(items_list) do 
                        local item_name = lower_cp1251(v.item or "") 
                        if search_query == "" or item_name:find(search_query, 1, true) then 
                            if flt == 4 then
                                if is_collectible(item_name) then table.insert(display_indices, i) end
                            elseif flt == 5 then
                                if is_other(item_name) then table.insert(display_indices, i) end
                            else
                                table.insert(display_indices, i) 
                            end
                        end 
                    end

                    if current_sort[0] == 1 then 
                        table.sort(display_indices, function(a, b) return tonumber(items_list[a].sell or 0) > tonumber(items_list[b].sell or 0) end)
                    elseif current_sort[0] == 2 then 
                        table.sort(display_indices, function(a, b) return tonumber(items_list[a].sell or 0) < tonumber(items_list[b].sell or 0) end)
                    elseif current_sort[0] == 3 then 
                        table.sort(display_indices, function(a, b) local name_a = (items_list[a].item or ""):lower() local name_b = (items_list[b].item or ""):lower() return name_a < name_b end)
                    end

                    if next(settings.favs) then
                        -- избранные поднимаем наверх (порядок внутри групп сохраняется)
                        local favs_first, rest = {}, {}
                        for _, ix in ipairs(display_indices) do
                            if items_list[ix] and settings.favs[items_list[ix].item] then
                                favs_first[#favs_first + 1] = ix
                            else
                                rest[#rest + 1] = ix
                            end
                        end
                        for _, ix in ipairs(rest) do favs_first[#favs_first + 1] = ix end
                        display_indices = favs_first
                    end
                    local row_now = imgui.GetTime()
                    for ri, idx in ipairs(display_indices) do 
                        local item = items_list[idx]
                        if item then 
                            local row_y = imgui.GetCursorPosY() 
                            local ra = clamp((row_now - UIFX.table_t - math.min(ri, 14) * 0.03) / 0.22, 0, 1)
                            UIFX.set_alpha(UIFX.base * ra)
                            do
                                local rp = imgui.GetCursorScreenPos()
                                local rx1 = table_start_x + col_w0 + col_wl + col_w1 + col_w2 + col_w3
                                local r0, r1 = imgui.ImVec2(table_start_x, rp.y - 2), imgui.ImVec2(rx1, rp.y + 27)
                                local row_hover = imgui.IsMouseHoveringRect(r0, r1)
                                if row_hover and imgui.IsWindowHovered() and imgui.IsMouseClicked(1) then
                                    selected_item_name = item.item
                                    UIFX.ctx_open = true
                                end
                                if row_hover and imgui.IsWindowHovered() and imgui.IsMouseClicked(0) then
                                    selected_item_name = item.item
                                end
                                if selected_item_name ~= nil and item.item == selected_item_name then
                                    imgui.GetWindowDrawList():AddRectFilled(r0, r1, col32(UI_CFG.accent[1], UI_CFG.accent[2], UI_CFG.accent[3], 0.30), 6)
                                elseif row_hover then
                                    imgui.GetWindowDrawList():AddRectFilled(r0, r1, col32(UI_CFG.accent[1], UI_CFG.accent[2], UI_CFG.accent[3], 0.14), 6)
                                elseif ri % 2 == 0 then
                                    imgui.GetWindowDrawList():AddRectFilled(r0, r1, col32(1, 1, 1, 0.025), 6)
                                end
                            end
                            local item_text = item.item or "" 
                            local sz = imgui.CalcTextSize(item_text)
                            imgui.SetCursorPosY(row_y + math.max(0, (24 - sz.y) * 0.5)) 
                            local icon_w = imgui.CalcTextSize(FA.CIRCLE_QUESTION).x 
                            local max_w = col_w0 - icon_w - 12

                            if sz.x > max_w then 
                                local truncated = item_text
                                while #truncated > 3 and imgui.CalcTextSize(truncated .. "...").x > max_w do
                                    local len = #truncated 
                                    local pos = len 
                                    while pos > 0 and truncated:byte(pos) >= 128 and truncated:byte(pos) < 192 do 
                                        pos = pos - 1 
                                    end 
                                    truncated = truncated:sub(1, pos - 1)
                                end
                                truncated = truncated .. "..." 
                                imgui.Text(truncated) 
                                if imgui.IsItemHovered() then imgui.SetTooltip((item_text:gsub("%%", "%%%%"))) end 
                                imgui.SameLine(col_w0 - icon_w - 6) 
                                imgui.Text(FA.CIRCLE_QUESTION) 
                                if imgui.IsItemHovered() then imgui.SetTooltip((item_text:gsub("%%", "%%%%"))) end
                            else 
                                imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w0 - sz.x) * 0.5)) 
                                imgui.TextUnformatted(item_text)
                            end

                            imgui.NextColumn()
                            do
                                local liq = item.liq
                                local txt = liq or "-"
                                local lc = UIFX.liq_color(liq)
                                if ADM.on then
                                    -- режим разработчика: клик по значению переключает ликвидность
                                    imgui.SetCursorPosY(row_y)
                                    imgui.PushStyleColor(imgui.Col.Text, lc)
                                    if imgui.Button(txt .. "##liq_" .. idx, imgui.ImVec2(col_wl - 14, 24)) then
                                        item.liq = UIFX.liq_next(liq)
                                        save_data()
                                    end
                                    imgui.PopStyleColor(1)
                                else
                                    local sz = imgui.CalcTextSize(txt)
                                    imgui.SetCursorPosY(row_y + math.max(0, (24 - sz.y) * 0.5))
                                    imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_wl - sz.x) * 0.5))
                                    imgui.TextColored(lc, txt)
                                end
                            end
                            imgui.NextColumn()
                            do 
                                local sz = imgui.CalcTextSize(format_price(item.buy))
                                imgui.SetCursorPosY(row_y + math.max(0, (24 - sz.y) * 0.5)) 
                                imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w1 - sz.x) * 0.5)) 
                                imgui.TextColored(imgui.ImVec4(0.55, 0.92, 0.65, 1.0), format_price(item.buy))
                            end

                            imgui.NextColumn()
                            do 
                                local sale_value = tonumber(item.sell) or 0 
                                local sale_text = format_price(item.sell) 
                                local sz = imgui.CalcTextSize(sale_text)
                                imgui.SetCursorPosY(row_y + math.max(0, (24 - sz.y) * 0.5)) 
                                imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w2 - sz.x - 20) * 0.5)) 
                                imgui.TextColored(imgui.ImVec4(1.0, 0.85, 0.45, 1.0), sale_text)
                                local icon_w = imgui.CalcTextSize(FA.BADGE_PERCENT).x 
                                imgui.SameLine(col_w2 - icon_w - 6) 
                                imgui.Text(FA.BADGE_PERCENT)
                                if imgui.IsItemHovered() then 
                                    imgui.SetTooltip("1%% - " .. format_price(math.floor(sale_value * 0.99 + 0.5)) .. "\n" .. "3%% - " .. format_price(math.floor(sale_value * 0.97 + 0.5)) .. "\n" .. "4%% - " .. format_price(math.floor(sale_value * 0.96 + 0.5)) .. "\n" .. "5%% - " .. format_price(math.floor(sale_value * 0.95 + 0.5))) 
                                end
                            end

                            imgui.NextColumn()
                            local buttons_total_width = ADM.on and (28 * 3 + 10) or 28
                            imgui.SetCursorPosY(row_y) 
                            imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w3 - buttons_total_width) * 0.5))
                            
                            local is_fav = settings.favs[item.item] == true
                            imgui.PushStyleColor(imgui.Col.Text, is_fav and imgui.ImVec4(1.0, 0.82, 0.25, 1.0) or imgui.ImVec4(0.50, 0.52, 0.58, 1.0))
                            if imgui.Button(ic("STAR", "*") .. "##fav_" .. idx, imgui.ImVec2(28, 24)) then
                                UIFX.toggle_fav(item.item)
                            end
                            imgui.PopStyleColor(1)
                            if imgui.IsItemHovered() then imgui.SetTooltip(is_fav and "Убрать из избранного" or "В избранное") end
                            if ADM.on then
                            imgui.SameLine()
                            if imgui.Button(FA.PEN_LINE .. "##edit_" .. idx, imgui.ImVec2(28, 24)) then 
                                open_edit_modal(idx) 
                            end 
                            imgui.SameLine()
                            
                            if imgui.Button(FA.TRASH_CAN .. "##del_" .. idx, imgui.ImVec2(28, 24)) then 
                                pending_delete_index = idx 
                                pending_delete_open = true 
                            end
                            end

                            imgui.NextColumn() 
                            imgui.Separator() 
                            table_bottom_y = imgui.GetCursorScreenPos().y - separator_spacing - 1.0
                        end
                    end
                    imgui.Columns(1)
                    UIFX.set_alpha(UIFX.base)
                    if UIFX.ctx_open then
                        imgui.OpenPopup("##row_ctx")
                        UIFX.ctx_open = false
                    end
                    if imgui.BeginPopup("##row_ctx") then
                        local cur
                        for _, v in ipairs(items_list) do
                            if v.item == selected_item_name then cur = v; break end
                        end
                        if cur then
                            local line = cur.item .. ": скупка " .. format_price(cur.buy) .. " / продажа " .. format_price(cur.sell)
                            imgui.TextColored(accent_vec(1.3), cur.item)
                            imgui.Separator()
                            if imgui.Selectable(ic("COMMENT_DOTS", "") .. "  Вставить в строку чата##ctx_chat") then
                                defer(function()
                                    sampSetChatInputEnabled(true)
                                    sampSetChatInputText(u8:decode(line))
                                end)
                            end
                            if imgui.Selectable(ic("COPY", "") .. "  Скопировать в буфер##ctx_copy") then
                                imgui.SetClipboardText(line)
                                notify("Скопировано: " .. line, "ok", 4)
                            end
                            local isf = settings.favs[cur.item] == true
                            if imgui.Selectable(ic("STAR", "*") .. (isf and "  Убрать из избранного" or "  В избранное") .. "##ctx_fav") then
                                UIFX.toggle_fav(cur.item)
                            end
                        else
                            imgui.Text("Предмет не найден")
                        end
                        imgui.EndPopup()
                    end

                    if table_bottom_y > table_top_y then 
                        local draw_list = imgui.GetWindowDrawList() 
                        local border_col = imgui.GetColorU32(imgui.Col.Separator) 
                        local x = table_start_x 
                        local column_widths = {col_w0, col_wl, col_w1, col_w2}
                        for i = 1, 4 do 
                            x = x + column_widths[i] 
                            draw_list:AddLine(imgui.ImVec2(x, table_top_y), imgui.ImVec2(x, table_bottom_y), border_col, 1.0) 
                        end
                    end
                    imgui.EndChild()
                end

                local add_w = imgui.GetContentRegionAvail().x - 95
                if ADM.on then
                    if imgui.Button(FA.CIRCLE_PLUS .. " Добавить предмет", imgui.ImVec2(add_w, 30)) then
                        open_add_modal()
                    end
                else
                    if imgui.Button(ic("PAPER_PLANE", "") .. " Актуальные цены - в нашем ТГК @arizona_prices##open_tg", imgui.ImVec2(add_w, 30)) then
                        open_url("https://t.me/arizona_prices")
                    end
                end

                imgui.SameLine()
                if imgui.Button(FA.TRIANGLE_EXCLAMATION .. "##report_prices", imgui.ImVec2(30, 30)) then
                    if selected_item_name and selected_item_name ~= "" then
                        imgui.SetClipboardText("Привет. Заметил что цена предмета \"" .. selected_item_name .. "\" изменилась, прошу обновить")
                        open_url("https://t.me/xi_vivide")
                        notify("Сообщение скопировано - вставьте его в чат (Ctrl+V)", "ok", 6)
                    else
                        notify("Сначала нажмите на предмет в таблице, цена которого устарела", "warn", 5)
                    end
                end
                if imgui.IsItemHovered() then imgui.SetTooltip("Сообщить об устаревших ценах\n(сначала нажмите на предмет в таблице)") end

                imgui.SameLine()
                if imgui.Button(FA.BUG .. "##report_bug", imgui.ImVec2(30, 30)) then
                    send_bug_report()
                end
                if imgui.IsItemHovered() then imgui.SetTooltip("Сообщить о баге (скопирует данные для разработчика)") end

                if pending_modal_open then 
                    imgui.OpenPopup(is_editing and MODAL_ID_EDIT or MODAL_ID_ADD) 
                    pending_modal_open = false 
                end

                if modal_window[0] then 
                    local popup_title = is_editing and MODAL_ID_EDIT or MODAL_ID_ADD
                    imgui.SetNextWindowPos(imgui.ImVec2(win_cx, win_cy), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5)) 
                    imgui.SetNextWindowSize(imgui.ImVec2(300, 171), imgui.Cond.Always)
                    if imgui.BeginPopupModal(popup_title, modal_window, bit.bor(imgui.WindowFlags.NoCollapse, imgui.WindowFlags.NoResize)) then
                        local hint_item = FA.LAYER_GROUP .. " Предмет"
                        local hint_buy = FA.HANDS_HOLDING_DOLLAR .. " Скупочная цена"
                        local hint_sell = FA.HAND_HOLDING_DOLLAR .. " Продажа"
                        
                        if is_blinking then 
                            local elapsed = os.clock() - blink_start_time
                            if elapsed >= 1.2 then 
                                is_blinking = false
                            else 
                                local hide = (elapsed % 0.4) < 0.2 
                                if empty_item_field and hide then hint_item = "" end 
                                if empty_buy_field and hide then hint_buy = "" end 
                                if empty_sell_field and hide then hint_sell = "" end
                            end
                        end

                        if imgui.BeginChild("##modal", imgui.ImVec2(-1, 102), true) then
                            imgui.SetNextItemWidth(-1) 
                            imgui.InputTextWithHint("##modal_item", hint_item, buf_item, ffi.sizeof(buf_item)) 
                            imgui.Separator()

                            imgui.SetNextItemWidth(-1) 
                            imgui.InputTextWithHint("##modal_buy", hint_buy, buf_buy, ffi.sizeof(buf_buy), imgui.InputTextFlags.CharsDecimal) 
                            imgui.Separator()

                            imgui.SetNextItemWidth(-1) 
                            imgui.InputTextWithHint("##modal_sell", hint_sell, buf_sell, ffi.sizeof(buf_sell), imgui.InputTextFlags.CharsDecimal) 
                            imgui.EndChild()
                        end

                        if is_editing then
                            if imgui.Button(FA.FLOPPY_DISK .. " Сохранить", imgui.ImVec2(142, 30)) then
                                local name_str = ffi.string(buf_item) 
                                local buy_str = ffi.string(buf_buy) 
                                local sell_str = ffi.string(buf_sell)
                                empty_item_field = (name_str == "") 
                                empty_buy_field = (buy_str == "") 
                                empty_sell_field = (sell_str == "")

                                if empty_item_field or empty_buy_field or empty_sell_field then 
                                    is_blinking = true 
                                    blink_start_time = os.clock()
                                else 
                                    local name = name_str 
                                    local buy = tonumber(buy_str) 
                                    local sell = tonumber(sell_str)
                                    if buy and sell and edit_index and items_list[edit_index] then 
                                        items_list[edit_index] = {item = name, buy = buy, sell = sell, liq = items_list[edit_index].liq} 
                                        save_data() 
                                        close_modal() 
                                    end
                                end
                            end
                            imgui.SameLine()
                            if imgui.Button(FA.CIRCLE_XMARK .. " Отменить", imgui.ImVec2(142, 30)) then
                                close_modal() 
                            end
                        else
                            if imgui.Button(FA.CIRCLE_PLUS .. " Добавить", imgui.ImVec2(-1, 30)) then
                                local name_str = ffi.string(buf_item) 
                                local buy_str = ffi.string(buf_buy) 
                                local sell_str = ffi.string(buf_sell)
                                empty_item_field = (name_str == "") 
                                empty_buy_field = (buy_str == "") 
                                empty_sell_field = (sell_str == "")

                                if empty_item_field or empty_buy_field or empty_sell_field then 
                                    is_blinking = true 
                                    blink_start_time = os.clock()
                                else 
                                    local name = name_str 
                                    local buy = tonumber(buy_str) 
                                    local sell = tonumber(sell_str)
                                    if buy and sell then 
                                        table.insert(items_list, {item = name, buy = buy, sell = sell}) 
                                        save_data() 
                                        close_modal() 
                                    end
                                end
                            end
                        end
                        imgui.EndPopup()
                    end
                end

                if pending_delete_open then 
                    imgui.OpenPopup(FA.TRASH_CAN .. ' Подтверждение удаления##delete_modal')
                    pending_delete_open = false 
                end

                imgui.SetNextWindowPos(imgui.ImVec2(win_cx, win_cy), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5)) 
                imgui.SetNextWindowSize(imgui.ImVec2(415, 88), imgui.Cond.Always)
                if imgui.BeginPopupModal(FA.TRASH_CAN .. ' Подтверждение удаления##delete_modal', nil, bit.bor(imgui.WindowFlags.NoCollapse, imgui.WindowFlags.NoResize)) then
                    imgui.TextWrapped(FA.CIRCLE_QUESTION .. ' Вы действительно хотите удалить этот предмет из справочника?')
                    imgui.Spacing()
                    if imgui.Button(FA.TRASH_CAN .. ' Да, удалить', imgui.ImVec2(200, 30)) then
                        if pending_delete_index and items_list[pending_delete_index] then 
                            table.remove(items_list, pending_delete_index) 
                            save_data() 
                        end 
                        pending_delete_index = nil 
                        imgui.CloseCurrentPopup()
                    end
                    imgui.SameLine()
                    if imgui.Button(FA.CIRCLE_XMARK .. ' Отменить', imgui.ImVec2(200, 30)) then
                        pending_delete_index = nil 
                        imgui.CloseCurrentPopup() 
                    end
                    imgui.EndPopup()
                end

                elseif current_tab == 2 then
                    draw_calculator()
                else
                    draw_extra_tab(current_tab)
                end
                end
                if content_visible then pcall(draw_resize_grip) end
                imgui.EndChild()
                UIFX.set_alpha(UIFX.alpha)
                UIFX.draw_splash(wpos)

                draw_window_fx(wpos.x, wpos.y, wpos.x + LAYOUT.w, wpos.y + LAYOUT.h)
                imgui.End()
            else
                imgui.End()
            end
            UIFX.set_alpha(1)
        end
    end, function() main_window[0] = false; modal_window[0] = false; hk.binding = false; UIFX.alpha = 0; UIFX.set_alpha(1) end)
)

-- ===================== Большое окно «старая версия» =====================
imgui.OnFrame(function() return outdated_popup[0] end, guard_frame("outdated", function()
    local sw, sh = getScreenResolution()
    imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(580, 290), imgui.Cond.Always)
    imgui.SetNextWindowFocus()
    local flags = bit.bor(imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.NoResize, imgui.WindowFlags.NoMove,
        imgui.WindowFlags.NoCollapse, imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoSavedSettings)
    -- полностью непрозрачный фон, независимо от настройки прозрачности меню
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.075, 0.07, 0.095, 1.0))
    imgui.Begin("##outdated_window", nil, flags)
    local p = imgui.GetWindowPos()
    imgui.GetWindowDrawList():AddRectFilled(p, imgui.ImVec2(p.x + 580, p.y + 5), imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.00, 0.75, 0.15, 1.00)))

    imgui.SetCursorPos(imgui.ImVec2(24, 28))
    imgui.SetWindowFontScale(1.9)
    imgui.TextColored(imgui.ImVec4(1.00, 0.80, 0.20, 1.00), ic("TRIANGLE_EXCLAMATION", "") .. " Внимание!")
    imgui.SetWindowFontScale(1.0)

    imgui.SetCursorPos(imgui.ImVec2(24, 90))
    imgui.SetWindowFontScale(1.3)
    imgui.PushTextWrapPos(556)
    imgui.TextWrapped("У вас старая версия скрипта. Обновите для комфортного использования.")
    imgui.PopTextWrapPos()
    imgui.SetWindowFontScale(1.0)

    imgui.SetCursorPos(imgui.ImVec2(24, 160))
    imgui.TextDisabled("Ваша версия: " .. SCRIPT_VERSION .. "    Новая версия: " .. update_info.version)
    if update_info.status ~= "" then
        imgui.SetCursorPosX(24)
        imgui.TextDisabled(update_info.status)
    end

    imgui.SetCursorPos(imgui.ImVec2(24, 290 - 24 - 44))
    local half = (580 - 48 - 10) / 2
    imgui.PushStyleColor(imgui.Col.Button, accent_vec(1.0))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, accent_vec(1.15))
    imgui.PushStyleColor(imgui.Col.ButtonActive, accent_vec(0.85))
    if update_info.busy then
        imgui.Button("Скачивание...##outdated_busy", imgui.ImVec2(half, 44))
    elseif imgui.Button(ic("DOWNLOAD", "") .. " Обновить##outdated_update", imgui.ImVec2(half, 44)) then
        request_update()
    end
    imgui.PopStyleColor(3)
    imgui.SameLine()
    if imgui.Button(FA.CIRCLE_XMARK .. " Закрыть##outdated_close", imgui.ImVec2(half, 44)) then
        outdated_popup[0] = false
    end
    imgui.End()
    imgui.PopStyleColor(1)
end, function() outdated_popup[0] = false end))

function main()
    while not isSampAvailable() do wait(0) end
    safe_call("load_data", load_data)

    sampAddChatMessage(u8:decode("{33AAFF}[Arizona Prices] {FFFFFF}Скрипт успешно загружен! Для активации - {33AAFF}/prices{FFFFFF} или {33AAFF}/pr{FFFFFF}. ТГК - {33AAFF}@arizona_prices"), -1)

    sampRegisterChatCommand('prices', toggle_menu)
    sampRegisterChatCommand('pr', toggle_menu)
    sampRegisterChatCommand('pradmin', function(arg)
        arg = tostring(arg or ""):gsub("%s", "")
        if arg == "off" then
            ADM.disable()
            sampAddChatMessage(u8:decode("{33AAFF}[Arizona Prices] {FFFFFF}Режим разработчика выключен"), -1)
        elseif arg ~= "" and ADM.enable(arg) then
            sampAddChatMessage(u8:decode("{33AAFF}[Arizona Prices] {55FF55}Режим разработчика включён{FFFFFF}. Правка цен и ликвидности открыта"), -1)
        else
            sampAddChatMessage(u8:decode("{33AAFF}[Arizona Prices] {FF5555}Неверный код"), -1)
        end
    end)
    addEventHandler('onWindowMessage', function(msg, wparam, lparam)
        safe_call("hotkey", on_window_message, msg, wparam, lparam)
    end)

    local next_check = os.time() + 5
    while true do
        wait(100)
        if pending_url then
            local url = pending_url
            pending_url = nil
            pcall(function() shell32.ShellExecuteA(nil, "open", url, nil, nil, 1) end)
        end
        while #ui_actions > 0 do
            safe_call("action", table.remove(ui_actions, 1))
        end
        if not main_window[0] and hk.binding then hk.binding = false end
        safe_call("updates", process_updates)
        if #pending_notices > 0 then
            local n = table.remove(pending_notices, 1)
            safe_call("notice", notify, n.text, n.kind)
        end
        safe_call("save_ui", flush_ui_save)
        if os.time() >= next_check then
            next_check = os.time() + CHECK_EVERY
            safe_call("start_checks", start_checks)
        end
        if need_reload then
            need_reload = false
            wait(700)
            thisScript():reload()
        end
    end
end

function onScriptTerminate(scr, quit)
    if scr == thisScript() then
        pcall(flush_ui_save, true)
    end
end
