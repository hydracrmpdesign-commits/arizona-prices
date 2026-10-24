local imgui = require('mimgui') 
local fa = require('fAwesome6') 
local ffi = require('ffi') 
local encoding = require('encoding') 
encoding.default = 'CP1251' 
local u8 = encoding.UTF8

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
local MODAL_ID_ADD = fa.CIRCLE_PLUS .. " Добавить предмет###item_modal"
local MODAL_ID_EDIT = fa.PEN_LINE .. " Редактировать предмет###item_modal"

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
local is_blinking = false 
local blink_start_time = 0

local empty_item_field = false 
local empty_buy_field = false 
local empty_sell_field = false 
local items_list = {} 
local datadir = getWorkingDirectory() .. "\\config\\item_prices.json"

local function load_data()
    if doesFileExist(datadir) then 
        local f = io.open(datadir, "r") 
        if f then 
            local content = f:read("*a") 
            f:close() 
            local success, data = pcall(decodeJson, content) 
            if success and type(data) == "table" then 
                items_list = data 
            end 
        end 
    else 
        items_list = {} 
    end
end

local function save_data() 
    local dir = getWorkingDirectory() .. "\\config" 
    if not doesDirectoryExist(dir) then 
        createDirectory(dir) 
    end 
    local f = io.open(datadir, "w") 
    if f then 
        f:write(encodeJson(items_list)) 
        f:close() 
    end 
end

local function format_price(amount) 
    local num = tonumber(amount) 
    if not num then return tostring(amount) end
    local formatted = tostring(num):reverse():gsub("(%d%d%d)", "%1."):reverse() 
    if formatted:sub(1, 1) == "." then formatted = formatted:sub(2) end 
    return formatted
end

local function lower_cp1251(str) 
    str = u8:decode(tostring(str or "")) 
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

function apply_theme() 
    local style = imgui.GetStyle() 
    local clr = style.Colors
    style.WindowPadding = imgui.ImVec2(5, 5) 
    style.FramePadding = imgui.ImVec2(5, 5) 
    style.ItemSpacing = imgui.ImVec2(5, 5) 
    style.ItemInnerSpacing = imgui.ImVec2(2, 2)
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5) 
    style.ScrollbarSize = 10 
    style.WindowBorderSize = 0 
    style.PopupBorderSize = 0 
    style.WindowRounding = 0 
    style.ScrollbarRounding = 0

    clr[imgui.Col.WindowBg] = imgui.ImVec4(0.07, 0.07, 0.08, 1.00) 
    clr[imgui.Col.PopupBg] = imgui.ImVec4(0.09, 0.09, 0.10, 1.00) 
    clr[imgui.Col.Border] = imgui.ImVec4(1.00, 1.00, 1.00, 0.10)
    clr[imgui.Col.TitleBg] = imgui.ImVec4(0.07, 0.07, 0.08, 1.00) 
    clr[imgui.Col.TitleBgActive] = imgui.ImVec4(0.07, 0.07, 0.08, 1.00) 
    clr[imgui.Col.TitleBgCollapsed] = imgui.ImVec4(0.07, 0.07, 0.08, 1.00)
    clr[imgui.Col.FrameBg] = imgui.ImVec4(0.12, 0.12, 0.13, 1.00) 
    clr[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.15, 0.15, 0.16, 1.00) 
    clr[imgui.Col.FrameBgActive] = imgui.ImVec4(0.18, 0.18, 0.19, 1.00)
    clr[imgui.Col.Button] = imgui.ImVec4(0.12, 0.12, 0.13, 1.00) 
    clr[imgui.Col.ButtonHovered] = imgui.ImVec4(0.15, 0.15, 0.16, 1.00) 
    clr[imgui.Col.ButtonActive] = imgui.ImVec4(0.18, 0.18, 0.19, 1.00)
    clr[imgui.Col.Header] = imgui.ImVec4(0.15, 0.15, 0.16, 1.00) 
    clr[imgui.Col.HeaderHovered] = imgui.ImVec4(0.18, 0.18, 0.19, 1.00) 
    clr[imgui.Col.HeaderActive] = imgui.ImVec4(0.21, 0.21, 0.22, 1.00)
    clr[imgui.Col.ScrollbarBg] = imgui.ImVec4(0.00, 0.00, 0.00, 0.00) 
    clr[imgui.Col.ScrollbarGrab] = imgui.ImVec4(0.12, 0.12, 0.13, 1.00) 
    clr[imgui.Col.ScrollbarGrabHovered] = imgui.ImVec4(0.15, 0.15, 0.16, 1.00) 
    clr[imgui.Col.ScrollbarGrabActive] = imgui.ImVec4(0.18, 0.18, 0.19, 1.00)
    clr[imgui.Col.Separator] = imgui.ImVec4(1.00, 1.00, 1.00, 0.10) 
    clr[imgui.Col.ModalWindowDimBg] = imgui.ImVec4(0.00, 0.00, 0.00, 0.65)
end

-- ===================== Левая панель и калькулятор =====================
local SIDEBAR_W = 200
local current_tab = 1 -- 1 = Arizona Prices, 2 = Калькулятор, 3 = Отчет до PayDay, 4 = Фразы, 5 = О скрипте, 6 = Время стран

local calc_expr = ""
local calc_prev = ""
local calc_error = nil
local calc_fresh = false

local function ic(name, fallback)
    return fa[name] or fallback
end

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
    calc_prev = calc_format_expr(calc_expr) .. " ="
    calc_expr = calc_raw_number(res)
    calc_fresh = true
end
-- CALC_LOGIC_END

local function sidebar_tab(label, id)
    local active = (current_tab == id)
    if active then
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.21, 0.21, 0.22, 1.00))
    end
    imgui.SetWindowFontScale(1.15)
    if imgui.Button(label .. "##tab" .. id, imgui.ImVec2(SIDEBAR_W - 10, 46)) then
        current_tab = id
    end
    imgui.SetWindowFontScale(1.0)
    if active then
        imgui.PopStyleColor(1)
        local rmin, rmax = imgui.GetItemRectMin(), imgui.GetItemRectMax()
        imgui.GetWindowDrawList():AddRectFilled(rmin, imgui.ImVec2(rmin.x + 3, rmax.y), imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.18, 0.45, 0.85, 1.00)))
    end
end

local function draw_calculator()
    -- Шапка
    imgui.AlignTextToFramePadding()
    imgui.SetCursorPosX(9)
    imgui.Text(ic("CALCULATOR", "") .. " Калькулятор")
    imgui.SameLine(606)
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0, 0, 0, 0))
    if imgui.Button(fa.CIRCLE_XMARK .. "##close_calc", imgui.ImVec2(24, 24)) then
        main_window[0] = false
    end
    imgui.PopStyleColor(1)
    imgui.Spacing()

    local calc_w, btn_w, btn_h = 355, 85, 54
    local x0 = (635 - calc_w) / 2

    -- Экран калькулятора
    imgui.SetCursorPosX(x0)
    if imgui.BeginChild("##calc_display", imgui.ImVec2(calc_w, 92), true) then
        local avail = imgui.GetContentRegionAvail().x

        local prev_text = calc_prev ~= "" and calc_prev or " "
        local pw = imgui.CalcTextSize(prev_text).x
        imgui.SetCursorPosX(math.max(5, 5 + avail - pw))
        imgui.TextColored(imgui.ImVec4(0.60, 0.60, 0.65, 1.00), prev_text)

        local shown, color
        if calc_error then
            shown = calc_error
            color = imgui.ImVec4(1.00, 0.35, 0.35, 1.00)
        else
            shown = (calc_expr == "") and "0" or calc_format_expr(calc_expr)
            color = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
        end

        local scale = 1.7
        imgui.SetWindowFontScale(scale)
        while scale > 0.8 and imgui.CalcTextSize(shown).x > avail do
            scale = scale - 0.1
            imgui.SetWindowFontScale(scale)
        end
        local tw = imgui.CalcTextSize(shown).x
        imgui.SetCursorPosX(math.max(5, 5 + avail - tw))
        imgui.TextColored(color, shown)
        imgui.SetWindowFontScale(1.0)
    end
    imgui.EndChild()

    -- Кнопки
    local rows = {
        { {"C", calc_clear, 3}, {ic("DELETE_LEFT", "<"), calc_back, 1}, {ic("PERCENT", "%"), calc_percent, 1}, {ic("DIVIDE", "/"), function() calc_op("/") end, 1} },
        { {"7", function() calc_digit("7") end, 0}, {"8", function() calc_digit("8") end, 0}, {"9", function() calc_digit("9") end, 0}, {ic("XMARK", "x"), function() calc_op("*") end, 1} },
        { {"4", function() calc_digit("4") end, 0}, {"5", function() calc_digit("5") end, 0}, {"6", function() calc_digit("6") end, 0}, {ic("MINUS", "-"), function() calc_op("-") end, 1} },
        { {"1", function() calc_digit("1") end, 0}, {"2", function() calc_digit("2") end, 0}, {"3", function() calc_digit("3") end, 0}, {ic("PLUS", "+"), function() calc_op("+") end, 1} },
        { {"0", function() calc_digit("0") end, 0}, {"000", function() calc_digit("000") end, 0}, {",", calc_dot, 0}, {ic("EQUALS", "="), calc_equals, 2} },
    }

    imgui.SetWindowFontScale(1.25)
    for r, row in ipairs(rows) do
        imgui.SetCursorPosX(x0)
        for c, b in ipairs(row) do
            if c > 1 then imgui.SameLine() end
            local style = b[3]
            local pushed = false
            if style == 1 then
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.17, 0.17, 0.19, 1.00))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.21, 0.21, 0.23, 1.00))
                imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.25, 0.25, 0.27, 1.00))
                pushed = true
            elseif style == 2 then
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.18, 0.45, 0.85, 1.00))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.22, 0.52, 0.92, 1.00))
                imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.15, 0.38, 0.75, 1.00))
                pushed = true
            elseif style == 3 then
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.55, 0.18, 0.18, 1.00))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.65, 0.22, 0.22, 1.00))
                imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.45, 0.15, 0.15, 1.00))
                pushed = true
            end
            if imgui.Button(b[1] .. "##cb" .. r .. "_" .. c, imgui.ImVec2(btn_w, btn_h)) then
                b[2]()
            end
            if pushed then imgui.PopStyleColor(3) end
        end
    end
    imgui.SetWindowFontScale(1.0)
end

-- ===================== Новые разделы: PayDay, фразы, о скрипте =====================
local settings_path = getWorkingDirectory() .. "\\config\\arizona_prices_settings.json"
local settings = { payday = { enabled = false, x = 20, y = 300 }, phrases = {}, clock = { enabled = false, country = "Узбекистан", x = 20, y = 340 } }

local function load_settings()
    if doesFileExist(settings_path) then
        local f = io.open(settings_path, "r")
        if f then
            local content = f:read("*a")
            f:close()
            local ok, data = pcall(decodeJson, content)
            if ok and type(data) == "table" then
                if type(data.payday) == "table" then
                    settings.payday.enabled = (data.payday.enabled == true)
                    settings.payday.x = tonumber(data.payday.x) or 20
                    settings.payday.y = tonumber(data.payday.y) or 300
                end
                if type(data.phrases) == "table" then
                    settings.phrases = data.phrases
                end
                if type(data.clock) == "table" then
                    settings.clock.enabled = (data.clock.enabled == true)
                    if type(data.clock.country) == "string" then settings.clock.country = data.clock.country end
                    settings.clock.x = tonumber(data.clock.x) or 20
                    settings.clock.y = tonumber(data.clock.y) or 340
                end
            end
        end
    end
end

local function save_settings()
    local dir = getWorkingDirectory() .. "\\config"
    if not doesDirectoryExist(dir) then
        createDirectory(dir)
    end
    local f = io.open(settings_path, "w")
    if f then
        f:write(encodeJson(settings))
        f:close()
    end
end

load_settings()

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
    imgui.SameLine(606)
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0, 0, 0, 0))
    if imgui.Button(fa.CIRCLE_XMARK .. "##close_section", imgui.ImVec2(24, 24)) then
        main_window[0] = false
    end
    imgui.PopStyleColor(1)
    imgui.Spacing()
end

local function draw_payday_tab()
    section_header(ic("CLOCK", ""), "Отчет до PayDay")
    if imgui.BeginChild("##payday_child", imgui.ImVec2(-1, 421), true) then
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
            if imgui.Button(ic("UP_DOWN_LEFT_RIGHT", "") .. " Передвинуть надпись", imgui.ImVec2(260, 38)) then
                payday_edit = true
                payday_on[0] = true
            end
        else
            imgui.TextColored(imgui.ImVec4(0.45, 1.00, 0.55, 1.00), "Перетащи надпись мышкой, затем нажми «Сохранить».")
            if imgui.Button(fa.FLOPPY_DISK .. " Сохранить положение", imgui.ImVec2(260, 38)) then
                settings.payday.x = payday_pos.x
                settings.payday.y = payday_pos.y
                settings.payday.enabled = payday_on[0]
                save_settings()
                payday_edit = false
                sampAddChatMessage(u8:decode("{33AAFF}[Arizona Prices] {FFFFFF}Положение надписи сохранено."), -1)
            end
        end
        imgui.Spacing()
        imgui.TextDisabled("Сейчас: " .. payday_text())
    end
    imgui.EndChild()
end

local function draw_phrases_tab()
    section_header(ic("COMMENT_DOTS", ""), "Фразы для автоотправки")
    imgui.SetNextItemWidth(imgui.GetContentRegionAvail().x - 125)
    local enter = imgui.InputTextWithHint("##phrase_input", "Введи фразу или команду (например /time)", phrase_buf, ffi.sizeof(phrase_buf), imgui.InputTextFlags.EnterReturnsTrue)
    imgui.SameLine()
    local add_clicked = imgui.Button(fa.CIRCLE_PLUS .. " Добавить##add_phrase", imgui.ImVec2(120, 0))
    if enter or add_clicked then
        local text = ffi.string(phrase_buf)
        if text:gsub("%s", "") ~= "" then
            table.insert(settings.phrases, text)
            save_settings()
            imgui.StrCopy(phrase_buf, "")
        end
    end
    imgui.Spacing()
    if imgui.BeginChild("##phrases_list", imgui.ImVec2(-1, -1), true) then
        if #settings.phrases == 0 then
            imgui.TextDisabled("Пока нет фраз. Добавь первую выше.")
        end
        local to_remove = nil
        for i, phrase in ipairs(settings.phrases) do
            if imgui.Button(fa.PAPER_PLANE .. "##send_phrase_" .. i, imgui.ImVec2(36, 28)) then
                sampSendChat(u8:decode(phrase))
            end
            if imgui.IsItemHovered() then imgui.SetTooltip("Отправить в чат") end
            imgui.SameLine()
            if imgui.Button(fa.TRASH_CAN .. "##del_phrase_" .. i, imgui.ImVec2(36, 28)) then
                to_remove = i
            end
            if imgui.IsItemHovered() then imgui.SetTooltip("Удалить фразу") end
            imgui.SameLine()
            imgui.AlignTextToFramePadding()
            imgui.Text(phrase)
        end
        if to_remove then
            table.remove(settings.phrases, to_remove)
            save_settings()
        end
    end
    imgui.EndChild()
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
    if imgui.BeginChild("##about_child", imgui.ImVec2(-1, 421), true) then
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
            if imgui.Button("##about_" .. i, imgui.ImVec2(-1, 46)) then
                if l.url then
                    open_url(l.url)
                elseif l.copy then
                    imgui.SetClipboardText(l.copy)
                    sampAddChatMessage(u8:decode("{33AAFF}[Arizona Prices] {FFFFFF}Ник скопирован: {33AAFF}" .. l.copy), -1)
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
    if imgui.BeginChild("##time_child", imgui.ImVec2(-1, 421), true) then
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
                if imgui.Button(fa.FLOPPY_DISK .. " Сохранить положение##clock_save") then
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
                    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.18, 0.45, 0.85, 1.00))
                end
                if imgui.Button(c.name .. "\n" .. ctm .. "###country_" .. i, imgui.ImVec2(bw, 44)) then
                    selected_country = i
                    pending_clock_index = i
                    pending_clock_open = true
                    local ntm, ndt = country_time(c)
                    sampAddChatMessage(u8:decode("{33AAFF}[Arizona Prices] {FFFFFF}Время (" .. c.name .. "): {33AAFF}" .. ntm .. " {FFFFFF}(" .. ndt .. ")"), -1)
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
            if imgui.Button(fa.CIRCLE_XMARK .. " Нет##clock_no", imgui.ImVec2(half, 34)) then
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
    function()
        if clock_edit and not main_window[0] then clock_edit = false end
        local flags = bit.bor(imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.AlwaysAutoResize, imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoSavedSettings)
        if not clock_edit then
            flags = bit.bor(flags, imgui.WindowFlags.NoMove, imgui.WindowFlags.NoInputs, imgui.WindowFlags.NoBackground)
            imgui.SetNextWindowPos(imgui.ImVec2(clock_pos.x, clock_pos.y), imgui.Cond.Always)
        end
        imgui.SetNextWindowBgAlpha(0.45)
        imgui.Begin("##clock_overlay", nil, flags)
        local c = find_country(settings.clock.country)
        shadow_text(imgui.ImVec4(0.55, 0.85, 1.00, 1.00), c.name .. ": " .. country_time(c))
        if clock_edit then
            local pos = imgui.GetWindowPos()
            clock_pos.x, clock_pos.y = pos.x, pos.y
        end
        imgui.End()
    end
)

-- ===================== Автообновление (скрипт и цены) =====================
local SCRIPT_VERSION = "1.1"
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
    write_file(state_path, encodeJson(state))
end

load_state()

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
            sampAddChatMessage(u8:decode("{33AAFF}[Arizona Prices] {FFFFFF}Вышла новая версия {33AAFF}" .. v .. "{FFFFFF}! Откройте /prices и нажмите «Обновить»."), -1)
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
    if sig == state.prices_sig then return end
    local ok, remote = pcall(decodeJson, c)
    if not ok or type(remote) ~= "table" then return end
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
                items_list[#items_list + 1] = { item = r.item, buy = buy, sell = sell }
                index[r.item] = #items_list
                added = added + 1
            end
        end
    end
    state.prices_sig = sig
    save_state()
    if added + changed > 0 then
        save_data()
        sampAddChatMessage(u8:decode("{33AAFF}[Arizona Prices] {FFFFFF}Цены обновлены: новых " .. added .. ", изменено " .. changed .. "."), -1)
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

local function draw_update_block()
    imgui.SetCursorPos(imgui.ImVec2(5, 340))
    imgui.TextDisabled("Версия " .. SCRIPT_VERSION)
    imgui.SetCursorPosX(5)
    if update_info.available then
        imgui.TextColored(imgui.ImVec4(0.45, 1.00, 0.55, 1.00), "Вышла версия " .. update_info.version)
        imgui.SetCursorPosX(5)
        if update_info.busy then
            imgui.TextDisabled("Скачивание...")
        elseif imgui.Button(ic("DOWNLOAD", "") .. " Обновить##do_update", imgui.ImVec2(SIDEBAR_W - 10, 32)) then
            start_update()
        end
    else
        if imgui.Button(ic("ARROWS_ROTATE", "") .. " Проверить##check_update", imgui.ImVec2(SIDEBAR_W - 10, 28)) then
            manual_check = true
            update_info.status = "Проверка..."
            start_checks()
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
        if state.auto_prices then start_checks() end
    end
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
    end
end

local payday_frame
payday_frame = imgui.OnFrame(
    function()
        payday_frame.HideCursor = not payday_edit
        return payday_on[0]
    end,
    function()
        if payday_edit and not main_window[0] then payday_edit = false end
        local flags = bit.bor(imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.AlwaysAutoResize, imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoSavedSettings)
        if not payday_edit then
            flags = bit.bor(flags, imgui.WindowFlags.NoMove, imgui.WindowFlags.NoInputs, imgui.WindowFlags.NoBackground)
            imgui.SetNextWindowPos(imgui.ImVec2(payday_pos.x, payday_pos.y), imgui.Cond.Always)
        end
        imgui.SetNextWindowBgAlpha(0.45)
        imgui.Begin("##payday_overlay", nil, flags)
        shadow_text(imgui.ImVec4(1.00, 0.85, 0.30, 1.00), payday_text())
        if payday_edit then
            local pos = imgui.GetWindowPos()
            payday_pos.x, payday_pos.y = pos.x, pos.y
        end
        imgui.End()
    end
)

imgui.OnInitialize(function() 
    fa.Init() 
    apply_theme() 
    load_data() 
end)

imgui.OnFrame(function() return main_window[0] or modal_window[0] end,
    function(player)
        if main_window[0] then 
            local sw, sh = getScreenResolution()
            imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5)) 
            imgui.SetNextWindowSize(imgui.ImVec2(SIDEBAR_W + 635, 500), imgui.Cond.Always)
            if imgui.Begin(u8("Arizona Prices##main_window"), main_window, bit.bor(imgui.WindowFlags.NoCollapse, imgui.WindowFlags.NoResize, imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoScrollWithMouse)) then
                local wpos = imgui.GetWindowPos()
                local win_cx, win_cy = wpos.x + (SIDEBAR_W + 635) / 2, wpos.y + 500 / 2

                -- Левая панель с вкладками
                imgui.GetWindowDrawList():AddRectFilled(wpos, imgui.ImVec2(wpos.x + SIDEBAR_W - 1, wpos.y + 500), imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.10, 0.10, 0.115, 1.00)))
                imgui.GetWindowDrawList():AddLine(imgui.ImVec2(wpos.x + SIDEBAR_W - 1, wpos.y), imgui.ImVec2(wpos.x + SIDEBAR_W - 1, wpos.y + 500), imgui.GetColorU32(imgui.Col.Separator), 1.0)
                imgui.SetCursorPos(imgui.ImVec2(5, 5))
                sidebar_tab(fa.CIRCLE_DOLLAR .. u8(" Arizona Prices"), 1)
                sidebar_tab(ic("CALCULATOR", "") .. " Калькулятор", 2)
                sidebar_tab(ic("CLOCK", "") .. " Отчет до PayDay", 3)
                sidebar_tab(ic("COMMENT_DOTS", "") .. " Фразы", 4)
                sidebar_tab(ic("GLOBE", "") .. " Время стран", 6)
                sidebar_tab(ic("CIRCLE_INFO", "") .. " О скрипте", 5)
                draw_update_block()

                -- Правая часть (содержимое выбранной вкладки)
                imgui.SetCursorPos(imgui.ImVec2(SIDEBAR_W, 0))
                local content_flags = bit.bor(imgui.WindowFlags.AlwaysUseWindowPadding or 0, imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoScrollWithMouse)
                local content_visible = imgui.BeginChild("##content", imgui.ImVec2(635, 500), false, content_flags)
                if content_visible then
                if current_tab == 1 then
                imgui.AlignTextToFramePadding() 
                imgui.SetCursorPosX(9) 
                imgui.Text(fa.CIRCLE_DOLLAR .. u8(' Arizona Prices'))
                imgui.SameLine(140) 
                imgui.SetNextItemWidth(306) 
                imgui.InputTextWithHint("##search", fa.MAGNIFYING_GLASS .. " Поиск", buf_search, ffi.sizeof(buf_search))
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
                
                imgui.SameLine(606) 
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0, 0, 0, 0)) 
                if imgui.Button(fa.CIRCLE_XMARK .. "##close", imgui.ImVec2(24, 24)) then 
                    main_window[0] = false 
                end 
                imgui.PopStyleColor(1) 
                imgui.Spacing()

                if imgui.BeginChild("##table_child", imgui.ImVec2(-1, 421), true) then 
                    local table_style = imgui.GetStyle() 
                    local table_start_x = imgui.GetCursorScreenPos().x
                    local table_top_y = imgui.GetCursorScreenPos().y - table_style.WindowPadding.y 
                    local separator_spacing = table_style.ItemSpacing.y 
                    local col_w0, col_w1, col_w2, col_w3 = 295, 120, 120, 80
                    
                    imgui.Columns(4, "item_table", false) 
                    imgui.SetColumnWidth(0, col_w0) 
                    imgui.SetColumnWidth(1, col_w1) 
                    imgui.SetColumnWidth(2, col_w2) 
                    imgui.SetColumnWidth(3, col_w3)

                    do 
                        local sz = imgui.CalcTextSize("Предмет")
                        imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w0 - sz.x) * 0.5)) 
                        imgui.Text("Предмет")
                    end 
                    imgui.NextColumn()

                    do 
                        local sz = imgui.CalcTextSize("Цена")
                        imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w1 - sz.x) * 0.5)) 
                        imgui.Text("Цена")
                    end 
                    imgui.NextColumn()

                    do 
                        local sz = imgui.CalcTextSize("Продажа")
                        imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w2 - sz.x) * 0.5)) 
                        imgui.Text("Продажа")
                    end 
                    imgui.NextColumn()

                    do 
                        local sz = imgui.CalcTextSize("Действия")
                        imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w3 - sz.x) * 0.5)) 
                        imgui.Text("Действия")
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

                    for _, idx in ipairs(display_indices) do 
                        local item = items_list[idx]
                        if item then 
                            local row_y = imgui.GetCursorPosY() 
                            local item_text = item.item or "" 
                            local sz = imgui.CalcTextSize(item_text)
                            imgui.SetCursorPosY(row_y + math.max(0, (24 - sz.y) * 0.5)) 
                            local icon_w = imgui.CalcTextSize(fa.CIRCLE_QUESTION).x 
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
                                if imgui.IsItemHovered() then imgui.SetTooltip(item_text) end 
                                imgui.SameLine(col_w0 - icon_w - 6) 
                                imgui.Text(fa.CIRCLE_QUESTION) 
                                if imgui.IsItemHovered() then imgui.SetTooltip(item_text) end
                            else 
                                imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w0 - sz.x) * 0.5)) 
                                imgui.Text(item_text)
                            end

                            imgui.NextColumn()
                            do 
                                local sz = imgui.CalcTextSize(format_price(item.buy))
                                imgui.SetCursorPosY(row_y + math.max(0, (24 - sz.y) * 0.5)) 
                                imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w1 - sz.x) * 0.5)) 
                                imgui.Text(format_price(item.buy))
                            end

                            imgui.NextColumn()
                            do 
                                local sale_value = tonumber(item.sell) or 0 
                                local sale_text = format_price(item.sell) 
                                local sz = imgui.CalcTextSize(sale_text)
                                imgui.SetCursorPosY(row_y + math.max(0, (24 - sz.y) * 0.5)) 
                                imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w2 - sz.x - 20) * 0.5)) 
                                imgui.Text(sale_text)
                                local icon_w = imgui.CalcTextSize(fa.BADGE_PERCENT).x 
                                imgui.SameLine(col_w2 - icon_w - 6) 
                                imgui.Text(fa.BADGE_PERCENT)
                                if imgui.IsItemHovered() then 
                                    imgui.SetTooltip("1%% - " .. format_price(math.floor(sale_value * 0.99 + 0.5)) .. "\n" .. "3%% - " .. format_price(math.floor(sale_value * 0.97 + 0.5)) .. "\n" .. "4%% - " .. format_price(math.floor(sale_value * 0.96 + 0.5)) .. "\n" .. "5%% - " .. format_price(math.floor(sale_value * 0.95 + 0.5))) 
                                end
                            end

                            imgui.NextColumn()
                            local buttons_total_width = 28 + 5 + 28 
                            imgui.SetCursorPosY(row_y) 
                            imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w3 - buttons_total_width) * 0.5))
                            
                            if imgui.Button(fa.PEN_LINE .. "##edit_" .. idx, imgui.ImVec2(28, 24)) then 
                                open_edit_modal(idx) 
                            end 
                            imgui.SameLine()
                            
                            if imgui.Button(fa.TRASH_CAN .. "##del_" .. idx, imgui.ImVec2(28, 24)) then 
                                pending_delete_index = idx 
                                pending_delete_open = true 
                            end

                            imgui.NextColumn() 
                            imgui.Separator() 
                            table_bottom_y = imgui.GetCursorScreenPos().y - separator_spacing - 1.0
                        end
                    end
                    imgui.Columns(1)

                    if table_bottom_y > table_top_y then 
                        local draw_list = imgui.GetWindowDrawList() 
                        local border_col = imgui.GetColorU32(imgui.Col.Separator) 
                        local x = table_start_x 
                        local column_widths = {col_w0, col_w1, col_w2}
                        for i = 1, 3 do 
                            x = x + column_widths[i] 
                            draw_list:AddLine(imgui.ImVec2(x, table_top_y), imgui.ImVec2(x, table_bottom_y), border_col, 1.0) 
                        end
                    end
                    imgui.EndChild()
                end

                local add_w = imgui.GetContentRegionAvail().x - 70
                if imgui.Button(fa.CIRCLE_PLUS .. " Добавить предмет", imgui.ImVec2(add_w, 30)) then
                    open_add_modal() 
                end

                imgui.SameLine()
                if imgui.Button(fa.TRIANGLE_EXCLAMATION .. "##report_prices", imgui.ImVec2(30, 30)) then
                    open_url("https://t.me/xi_vivide")
                end
                if imgui.IsItemHovered() then imgui.SetTooltip("Сообщить об устаревших ценах") end

                imgui.SameLine()
                if imgui.Button(fa.BUG .. "##report_bug", imgui.ImVec2(30, 30)) then
                    open_url("https://t.me/obrezik")
                end
                if imgui.IsItemHovered() then imgui.SetTooltip("Сообщить о баге") end

                if pending_modal_open then 
                    imgui.OpenPopup(is_editing and MODAL_ID_EDIT or MODAL_ID_ADD) 
                    pending_modal_open = false 
                end

                if modal_window[0] then 
                    local popup_title = is_editing and MODAL_ID_EDIT or MODAL_ID_ADD
                    imgui.SetNextWindowPos(imgui.ImVec2(win_cx, win_cy), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5)) 
                    imgui.SetNextWindowSize(imgui.ImVec2(300, 171), imgui.Cond.Always)
                    if imgui.BeginPopupModal(popup_title, modal_window, bit.bor(imgui.WindowFlags.NoCollapse, imgui.WindowFlags.NoResize)) then
                        local hint_item = fa.LAYER_GROUP .. " Предмет"
                        local hint_buy = fa.HANDS_HOLDING_DOLLAR .. " Цена"
                        local hint_sell = fa.HAND_HOLDING_DOLLAR .. " Продажа"
                        
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
                            if imgui.Button(fa.FLOPPY_DISK .. " Сохранить", imgui.ImVec2(142, 30)) then
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
                                        items_list[edit_index] = {item = name, buy = buy, sell = sell} 
                                        save_data() 
                                        close_modal() 
                                    end
                                end
                            end
                            imgui.SameLine()
                            if imgui.Button(fa.CIRCLE_XMARK .. " Отменить", imgui.ImVec2(142, 30)) then
                                close_modal() 
                            end
                        else
                            if imgui.Button(fa.CIRCLE_PLUS .. " Добавить", imgui.ImVec2(-1, 30)) then
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
                    imgui.OpenPopup(fa.TRASH_CAN .. ' Подтверждение удаления##delete_modal')
                    pending_delete_open = false 
                end

                imgui.SetNextWindowPos(imgui.ImVec2(win_cx, win_cy), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5)) 
                imgui.SetNextWindowSize(imgui.ImVec2(415, 88), imgui.Cond.Always)
                if imgui.BeginPopupModal(fa.TRASH_CAN .. ' Подтверждение удаления##delete_modal', nil, bit.bor(imgui.WindowFlags.NoCollapse, imgui.WindowFlags.NoResize)) then
                    imgui.TextWrapped(fa.CIRCLE_QUESTION .. ' Вы действительно хотите удалить этот предмет из справочника?')
                    imgui.Spacing()
                    if imgui.Button(fa.TRASH_CAN .. ' Да, удалить', imgui.ImVec2(200, 30)) then
                        if pending_delete_index and items_list[pending_delete_index] then 
                            table.remove(items_list, pending_delete_index) 
                            save_data() 
                        end 
                        pending_delete_index = nil 
                        imgui.CloseCurrentPopup()
                    end
                    imgui.SameLine()
                    if imgui.Button(fa.CIRCLE_XMARK .. ' Отменить', imgui.ImVec2(200, 30)) then
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
                imgui.EndChild()

                imgui.End()
            end
        end
    end
)

-- ===================== Большое окно «старая версия» =====================
imgui.OnFrame(function() return outdated_popup[0] end, function()
    local sw, sh = getScreenResolution()
    imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(580, 290), imgui.Cond.Always)
    imgui.SetNextWindowFocus()
    local flags = bit.bor(imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.NoResize, imgui.WindowFlags.NoMove,
        imgui.WindowFlags.NoCollapse, imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoSavedSettings)
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
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.18, 0.45, 0.85, 1.00))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.22, 0.52, 0.92, 1.00))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.15, 0.38, 0.75, 1.00))
    if update_info.busy then
        imgui.Button("Скачивание...##outdated_busy", imgui.ImVec2(half, 44))
    elseif imgui.Button(ic("DOWNLOAD", "") .. " Обновить##outdated_update", imgui.ImVec2(half, 44)) then
        start_update()
    end
    imgui.PopStyleColor(3)
    imgui.SameLine()
    if imgui.Button(fa.CIRCLE_XMARK .. " Закрыть##outdated_close", imgui.ImVec2(half, 44)) then
        outdated_popup[0] = false
    end
    imgui.End()
end)

function main() 
    while not isSampAvailable() do wait(0) end 
    load_data() 
    
    sampAddChatMessage(u8:decode("{33AAFF}[Arizona Prices V2.0] {FFFFFF}Скрипт успешно загружен! Для активации - {33AAFF}/prices{FFFFFF}. ТГК - {33AAFF}@arizona_prices"), -1)
    
    sampRegisterChatCommand('prices', function()
        main_window[0] = not main_window[0]
        if main_window[0] and update_info.available then
            outdated_popup[0] = true
        end
    end)
    
    local next_check = os.time() + 5
    while true do
        wait(100)
        if pending_url then
            local url = pending_url
            pending_url = nil
            pcall(function() shell32.ShellExecuteA(nil, "open", url, nil, nil, 1) end)
        end
        process_updates()
        if os.time() >= next_check then
            next_check = os.time() + CHECK_EVERY
            pcall(start_checks)
        end
        if need_reload then
            need_reload = false
            wait(700)
            thisScript():reload()
        end
    end
end
