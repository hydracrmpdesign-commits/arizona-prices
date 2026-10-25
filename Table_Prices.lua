local ffi = require('ffi')
local encoding = require('encoding')
encoding.default = 'CP1251'
local u8 = encoding.UTF8

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
    TAB_ORDER = { 1, 2, 3, 4, 8, 6, 5, 7 }, -- порядок вкладок слева (цифры 1-8 на клавиатуре)
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
local LAYOUT = { w = 835, h = 500, tab_h = 42, block_y = 340, force = false } -- текущие размеры главного окна
local current_tab = 1 -- 1 = Arizona Prices, 2 = Калькулятор, 3 = Отчет до PayDay, 4 = Фразы, 5 = О скрипте, 6 = Время стран

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

-- избранные предметы и заметки
UIFX.notes = imgui.new.char[8192]()
imgui.StrCopy(UIFX.notes, settings.notes or "")

function UIFX.toggle_fav(name)
    if settings.favs[name] then settings.favs[name] = nil else settings.favs[name] = true end
    save_settings()
end

local payday_on = imgui.new.bool(settings.payday.enabled)
local payday_edit = false
local payday_pos = { x = settings.payday.x, y = settings.payday.y }
local phrase_buf = imgui.new.char[256]()

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

local function draw_phrases_tab()
    section_header(ic("COMMENT_DOTS", ""), "Фразы для автоотправки")
    imgui.SetWindowFontScale(1.3)
    imgui.SetNextItemWidth(imgui.GetContentRegionAvail().x - 190)
    local enter = imgui.InputTextWithHint("##phrase_input", "Введи фразу или команду (например /time)", phrase_buf, ffi.sizeof(phrase_buf), imgui.InputTextFlags.EnterReturnsTrue)
    imgui.SameLine()
    local add_clicked = imgui.Button(FA.CIRCLE_PLUS .. " Добавить##add_phrase", imgui.ImVec2(180, 0))
    if enter or add_clicked then
        local text = ffi.string(phrase_buf)
        if text:gsub("%s", "") ~= "" then
            table.insert(settings.phrases, text)
            save_settings()
            imgui.StrCopy(phrase_buf, "")
        end
    end
    imgui.Spacing()
    if imgui.BeginChild("##phrases_list", imgui.ImVec2(-1, -36), true) then
        if #settings.phrases == 0 then
            imgui.TextDisabled("Пока нет фраз. Добавь первую выше.")
        end
        local to_remove = nil
        for i, phrase in ipairs(settings.phrases) do
            if imgui.Button(FA.PAPER_PLANE .. "##send_phrase_" .. i, imgui.ImVec2(52, 40)) then
                local txt = phrase
                defer(function() sampSendChat(u8:decode(txt)) end)
            end
            if imgui.IsItemHovered() then imgui.SetTooltip("Отправить в чат") end
            imgui.SameLine()
            if imgui.Button(FA.TRASH_CAN .. "##del_phrase_" .. i, imgui.ImVec2(52, 40)) then
                to_remove = i
            end
            if imgui.IsItemHovered() then imgui.SetTooltip("Удалить фразу") end
            imgui.SameLine()
            imgui.AlignTextToFramePadding()
            imgui.TextUnformatted(phrase)
        end
        if to_remove then
            table.remove(settings.phrases, to_remove)
            save_settings()
        end
    end
    imgui.EndChild()
    imgui.SetWindowFontScale(1.0)
end

local about_links = {
    { icon = "PAPER_PLANE", title = "Telegram-канал",              url = "https://t.me/arizona_prices",                 color = {0.16, 0.62, 0.86} },
    { icon = "COMMENTS",    title = "Discord-канал",               url = "https://discord.gg/z4UmCnRwd",                color = {0.35, 0.40, 0.95} },
    { icon = "MUSIC",       title = "TikTok-канал",                url = "https://www.tiktok.com/@cosmychesky_jetpack", color = {0.86, 0.15, 0.40} },
    { icon = "USER",        title = "Discord разработчика",        copy = "sawnoff_karabin07", color = {0.35, 0.40, 0.95} },
    { icon = "PAPER_PLANE", title = "ЛС разработчика в Telegram",  url = "https://t.me/xi_vivide",                      color = {0.16, 0.62, 0.86} },
    { icon = "PAPER_PLANE", title = "ЛС разработчика в Telegram 2", url = "https://t.me/obrezik",                        color = {0.16, 0.62, 0.86} },
}

local function draw_about_tab()
    section_header(ic("CIRCLE_INFO", ""), "О скрипте")
    if imgui.BeginChild("##about_child", imgui.ImVec2(-1, LAYOUT.h - 79), true) then
        imgui.SetWindowFontScale(1.25)
        imgui.TextColored(imgui.ImVec4(0.30, 0.65, 1.00, 1.00), "Arizona Prices V2.0")
        imgui.TextWrapped("Спасибо, что пользуешься скриптом! Заходи в наши соцсети: там актуальные цены, новости и обновления. Нашёл ошибку или есть идея - пиши разработчику в личные сообщения.")
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()
        for i, l in ipairs(about_links) do
            local c = l.color
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(c[1] * 0.55, c[2] * 0.55, c[3] * 0.55, 1.00))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(c[1] * 0.80, c[2] * 0.80, c[3] * 0.80, 1.00))
            imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(c[1], c[2], c[3], 1.00))
            if imgui.Button("##about_" .. i, imgui.ImVec2(-1, 56)) then
                if l.url then
                    open_url(l.url)
                elseif l.copy then
                    imgui.SetClipboardText(l.copy)
                    notify("Ник скопирован: " .. l.copy, "ok")
                end
            end
            local rmin, rmax = imgui.GetItemRectMin(), imgui.GetItemRectMax()
            local dl = imgui.GetWindowDrawList()
            local cy = (rmin.y + rmax.y) / 2
            local ts = imgui.CalcTextSize(l.title)
            dl:AddText(imgui.ImVec2((rmin.x + rmax.x) / 2 - ts.x / 2, cy - ts.y / 2), 0xFFFFFFFF, l.title)
            local icon = ic(l.icon, "")
            local isz = imgui.CalcTextSize(icon)
            dl:AddText(imgui.ImVec2(rmin.x + 18, cy - isz.y / 2), 0xFFFFFFFF, icon)
            imgui.PopStyleColor(3)
        end
        imgui.SetWindowFontScale(1.0)
    end
    imgui.EndChild()
end

-- ===================== Время стран =====================
local function days_from_civil(y, m, d)
    if m <= 2 then y = y - 1 end
    local era = math.floor(y / 400)
    local yoe = y - era * 400
    local mp = (m + 9) % 12
    local doy = math.floor((153 * mp + 2) / 5) + d - 1
    local doe = yoe * 365 + math.floor(yoe / 4) - math.floor(yoe / 100) + doy
    return era * 146097 + doe - 719468
end

local function utc_epoch(y, m, d, h)
    return days_from_civil(y, m, d) * 86400 + h * 3600
end

local function weekday_of(y, m, d) -- 0 = воскресенье
    return (days_from_civil(y, m, d) + 4) % 7
end

local function nth_sunday(y, m, n)
    local first = 1 + (7 - weekday_of(y, m, 1)) % 7
    return first + (n - 1) * 7
end

local function last_sunday(y, m)
    local dim = ({31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31})[m]
    return dim - weekday_of(y, m, dim)
end

local function is_dst(rule, std_offset, now)
    local y = tonumber(os.date("!%Y", now))
    if rule == "eu" then
        local s = utc_epoch(y, 3, last_sunday(y, 3), 1)
        local e = utc_epoch(y, 10, last_sunday(y, 10), 1)
        return now >= s and now < e
    elseif rule == "us" then
        local s = utc_epoch(y, 3, nth_sunday(y, 3, 2), 2) - std_offset * 3600
        local e = utc_epoch(y, 11, nth_sunday(y, 11, 1), 2) - (std_offset + 1) * 3600
        return now >= s and now < e
    end
    return false
end

local function local_pc_offset()
    local now = os.time()
    local l = os.date("*t", now)
    local u = os.date("!*t", now)
    u.isdst = l.isdst
    return os.difftime(os.time(l), os.time(u)) / 3600
end

local countries = {
    { name = "Азербайджан", off = 4 },
    { name = "Армения", off = 4 },
    { name = "Беларусь", off = 3 },
    { name = "Великобритания", off = 0, dst = "eu" },
    { name = "Германия", off = 1, dst = "eu" },
    { name = "Грузия", off = 4 },
    { name = "Индия", off = 5.5 },
    { name = "Казахстан", off = 5 },
    { name = "Китай", off = 8 },
    { name = "Кыргызстан", off = 6 },
    { name = "Москва (время Аризоны)", off = 3 },
    { name = "ОАЭ", off = 4 },
    { name = "Польша", off = 1, dst = "eu" },
    { name = "Россия, Владивосток", off = 10 },
    { name = "Россия, Екатеринбург", off = 5 },
    { name = "Россия, Новосибирск", off = 7 },
    { name = "США, Лос-Анджелес", off = -8, dst = "us" },
    { name = "США, Нью-Йорк", off = -5, dst = "us" },
    { name = "Таджикистан", off = 5 },
    { name = "Таиланд", off = 7 },
    { name = "Турция", off = 3 },
    { name = "Узбекистан", off = 5 },
    { name = "Украина", off = 2, dst = "eu" },
    { name = "Япония", off = 9 },
}

local selected_country = 1
for i, c in ipairs(countries) do
    if c.name == "Узбекистан" then selected_country = i end
end

local function country_time(c)
    local now = os.time()
    local off
    if c.pc then
        off = local_pc_offset()
    else
        off = c.off
        if c.dst and is_dst(c.dst, c.off, now) then off = off + 1 end
    end
    local shifted = now + off * 3600
    return os.date("!%H:%M:%S", shifted), os.date("!%d.%m.%Y", shifted)
end

local function shadow_text(color, text)
    local p = imgui.GetCursorScreenPos()
    imgui.GetWindowDrawList():AddText(imgui.ImVec2(p.x + 1, p.y + 1), 0xFF000000, text)
    imgui.TextColored(color, text)
end

local clock_edit = false
local clock_pos = { x = settings.clock.x, y = settings.clock.y }
local pending_clock_open = false
local pending_clock_index = nil
local CLOCK_MODAL_ID = "Время на экране###clock_modal"

local function find_country(name)
    for _, c in ipairs(countries) do
        if c.name == name then return c end
    end
    return countries[1]
end

local function draw_time_tab()
    section_header(ic("GLOBE", ""), "Время стран")
    if imgui.BeginChild("##time_child", imgui.ImVec2(-1, LAYOUT.h - 79), true) then
        local sel = countries[selected_country]
        local tm, dt = country_time(sel)
        local width = imgui.GetWindowWidth()

        imgui.SetWindowFontScale(2.4)
        local ts = imgui.CalcTextSize(tm)
        imgui.SetCursorPosX(math.max(5, (width - ts.x) / 2))
        imgui.TextColored(imgui.ImVec4(1.00, 0.85, 0.30, 1.00), tm)
        imgui.SetWindowFontScale(1.0)

        local label = sel.name .. "  |  " .. dt
        local ls = imgui.CalcTextSize(label)
        imgui.SetCursorPosX(math.max(5, (width - ls.x) / 2))
        imgui.Text(label)
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()

        if settings.clock.enabled then
            imgui.AlignTextToFramePadding()
            imgui.Text("На экране: " .. settings.clock.country)
            imgui.SameLine()
            if not clock_edit then
                if imgui.Button("Передвинуть##clock_move") then clock_edit = true end
            else
                if imgui.Button(FA.FLOPPY_DISK .. " Сохранить положение##clock_save") then
                    settings.clock.x = clock_pos.x
                    settings.clock.y = clock_pos.y
                    save_settings()
                    clock_edit = false
                end
            end
            imgui.SameLine()
            if imgui.Button("Убрать с экрана##clock_hide") then
                settings.clock.enabled = false
                clock_edit = false
                save_settings()
            end
            if clock_edit then
                imgui.TextColored(imgui.ImVec4(0.45, 1.00, 0.55, 1.00), "Перетащи надпись мышкой, затем нажми «Сохранить положение».")
            end
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()
        end

        if imgui.BeginChild("##time_list", imgui.ImVec2(-1, -1), false) then
            local bw = math.floor((imgui.GetContentRegionAvail().x - 10 - 16) / 3)
            for i, c in ipairs(countries) do
                if (i - 1) % 3 ~= 0 then imgui.SameLine() end
                local ctm = country_time(c)
                local active = (i == selected_country)
                if active then
                    imgui.PushStyleColor(imgui.Col.Button, accent_vec(1.0))
                end
                if imgui.Button(c.name .. "\n" .. ctm .. "###country_" .. i, imgui.ImVec2(bw, 44)) then
                    selected_country = i
                    pending_clock_index = i
                    pending_clock_open = true
                    local ntm, ndt = country_time(c)
                    local chat_msg = u8:decode("{33AAFF}[Arizona Prices] {FFFFFF}Время (" .. c.name .. "): {33AAFF}" .. ntm .. " {FFFFFF}(" .. ndt .. ")")
                    defer(function() sampAddChatMessage(chat_msg, -1) end)
                end
                if active then imgui.PopStyleColor(1) end
            end
        end
        imgui.EndChild()

        if pending_clock_open then
            imgui.OpenPopup(CLOCK_MODAL_ID)
            pending_clock_open = false
        end
        local sw, sh = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(400, 135), imgui.Cond.Always)
        if imgui.BeginPopupModal(CLOCK_MODAL_ID, nil, bit.bor(imgui.WindowFlags.NoCollapse, imgui.WindowFlags.NoResize)) then
            local pc = countries[pending_clock_index or selected_country]
            imgui.TextColored(imgui.ImVec4(1.00, 0.85, 0.30, 1.00), pc.name)
            imgui.TextWrapped("Показывать время этой страны на экране?")
            imgui.Spacing()
            local half = (imgui.GetContentRegionAvail().x - 5) / 2
            if imgui.Button(ic("CIRCLE_CHECK", "") .. " Да##clock_yes", imgui.ImVec2(half, 34)) then
                settings.clock.enabled = true
                settings.clock.country = pc.name
                save_settings()
                imgui.CloseCurrentPopup()
            end
            imgui.SameLine()
            if imgui.Button(FA.CIRCLE_XMARK .. " Нет##clock_no", imgui.ImVec2(half, 34)) then
                imgui.CloseCurrentPopup()
            end
            imgui.EndPopup()
        end
    end
    imgui.EndChild()
end

local clock_frame
clock_frame = imgui.OnFrame(
    function()
        clock_frame.HideCursor = not clock_edit
        return settings.clock.enabled
    end,
    guard_frame("clock", function()
        if clock_edit and not main_window[0] then clock_edit = false end
        local flags = bit.bor(imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.AlwaysAutoResize, imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoSavedSettings)
        if not clock_edit then
            flags = bit.bor(flags, imgui.WindowFlags.NoMove, imgui.WindowFlags.NoInputs, imgui.WindowFlags.NoBackground)
            imgui.SetNextWindowPos(imgui.ImVec2(clock_pos.x, clock_pos.y), imgui.Cond.Always)
        end
        imgui.SetNextWindowBgAlpha(0.45)
        imgui.Begin("##clock_overlay", nil, flags)
        imgui.SetWindowFontScale(UI_CFG.overlay_scale)
        local c = find_country(settings.clock.country)
        shadow_text(imgui.ImVec4(0.55, 0.85, 1.00, 1.00), c.name .. ": " .. country_time(c))
        if clock_edit then
            local pos = imgui.GetWindowPos()
            clock_pos.x, clock_pos.y = pos.x, pos.y
        end
        imgui.End()
    end, function() settings.clock.enabled = false end)
)

-- ===================== Автообновление (скрипт и цены) =====================
local SCRIPT_VERSION = "3.2"
local UPDATE_BASE = "https://raw.githubusercontent.com/hydracrmpdesign-commits/arizona-prices/main/"
local CHECK_EVERY = 1800 -- проверять обновления раз в 30 минут
local cfg_dir = getWorkingDirectory() .. "\\config\\"
local state_path = cfg_dir .. "arizona_prices_state.json"
local state = { prices_sig = "", auto_prices = true }
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
    if not loadstring(c) or not c:find("SCRIPT_VERSION", 1, true) then
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

    -- горячие клавиши внутри открытого меню: цифры 1-8 переключают вкладки, Ctrl+F - поиск по таблице
    if main_window[0] and UIFX.alpha > 0.5 and not hk.typing then
        local okc, busy = pcall(function() return sampIsChatInputActive() or sampIsDialogActive() end)
        if not (okc and busy) then
            if wparam >= 0x31 and wparam <= 0x38 then
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
        imgui.TextDisabled("Esc - отмена, Backspace - убрать клавишу. Команда /prices работает всегда.")

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

local function draw_notes_tab()
    section_header(ic("NOTE_STICKY", ""), "Заметки")
    if imgui.BeginChild("##notes_child", imgui.ImVec2(-1, LAYOUT.h - 79), true) then
        imgui.TextDisabled("Записывай сюда всё важное: цены, договорённости, ники. Сохраняется само.")
        imgui.Spacing()
        imgui.SetWindowFontScale(1.15)
        local h = imgui.GetContentRegionAvail().y - 48
        if imgui.InputTextMultiline("##notes_text", UIFX.notes, ffi.sizeof(UIFX.notes), imgui.ImVec2(-1, math.max(80, h))) then
            settings.notes = ffi.string(UIFX.notes)
            mark_ui_dirty()
        end
        imgui.SetWindowFontScale(1.0)
        local used = math.floor(#settings.notes / 81.91)
        imgui.AlignTextToFramePadding()
        imgui.TextDisabled("Заполнено: " .. used .. "%")
        imgui.SameLine()
        if imgui.Button(ic("TRASH_CAN", "") .. " Очистить##notes_clear", imgui.ImVec2(130, 28)) then
            imgui.StrCopy(UIFX.notes, "")
            settings.notes = ""
            mark_ui_dirty()
        end
    end
    imgui.EndChild()
end

local function draw_extra_tab(id)
    if id == 3 then
        draw_payday_tab()
    elseif id == 4 then
        draw_phrases_tab()
    elseif id == 5 then
        draw_about_tab()
    elseif id == 6 then
        draw_time_tab()
    elseif id == 7 then
        draw_settings_tab()
    elseif id == 8 then
        draw_notes_tab()
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
    LAYOUT.tab_h = clamp(math.floor((LAYOUT.h - 161) / 8) - 5, 26, 42)
    LAYOUT.block_y = 5 + 8 * (LAYOUT.tab_h + 5) + 6
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
                sidebar_tab(ic("COMMENT_DOTS", "") .. " Фразы", 4, "Быстрые фразы в чат (клавиша 4)")
                sidebar_tab(ic("NOTE_STICKY", "") .. " Заметки", 8, "Ваши заметки (клавиша 5)")
                sidebar_tab(ic("GLOBE", "") .. " Время стран", 6, "Время в других странах (клавиша 6)")
                sidebar_tab(ic("CIRCLE_INFO", "") .. " О скрипте", 5, "Соцсети и разработчик (клавиша 7)")
                sidebar_tab(ic("GEAR", "") .. " Настройки", 7, "Тема, шрифт, прозрачность (клавиша 8)")
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
                
                local sort_items = {"По умолчанию", "Сначала дорогие", "Сначала дешёвые", "По алфавиту"}
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

                    for i, v in ipairs(items_list) do 
                        local item_name = lower_cp1251(v.item or "") 
                        if search_query == "" or item_name:find(search_query, 1, true) then 
                            table.insert(display_indices, i) 
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

    sampAddChatMessage(u8:decode("{33AAFF}[Arizona Prices V2.0] {FFFFFF}Скрипт успешно загружен! Для активации - {33AAFF}/prices{FFFFFF}. ТГК - {33AAFF}@arizona_prices"), -1)

    sampRegisterChatCommand('prices', toggle_menu)
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
