local M = {}


---@type table<string, string[]>
M.alternative_language_names = {
    ["English"]    = {"en"},
    ["Español"]    = {"Spanish",    "es"},
    ["Português"]  = {"Portuguese", "pt"},
    ["Русский"]    = {"Russian",    "ru"},
    ["Polski"]     = {"Polish",     "pl"},
    ["Română"]     = {"Romanian",   "ro"},
    ["Esperanto"]  = {"Esperanto",  "eo"},
    ["Français"]   = {"French",     "fr"},
    ["Deutsch"]    = {"German",     "de"},
    ["Italiano"]   = {"Italian",    "it"},
    ["Nederlands"] = {"Dutch",      "nl"},
    ["Kiswahili"]  = {"Swahili",    "sw"},
    ["한국어"]      = {"Korean",     "ko"},
    ["日本語"]      = {"Japanese",   "ja"},
    ["हिन्दी"]        = {"Hindi",      "hi"},
    ["বাংলা"]       = {"Bengali",     "bn"},
    ["Bahasa Indonesia"] = {"Indonesian", "id"},
}

-- Some translations from https://babylscript.plom.dev/translations.html
---@type Crino
---@return table<string, table>
M.get_syntaxes = function(Crino)
    local __crinoTypes = Crino.__types

    --- keys are local language names and specific syntaxes of languages
    local syntaxes = {
        ["lua"] = {
            predefined_elements = {
                ["("]  = {type = __crinoTypes.left_round_bracket, is_bracket = true},
                [")"]  = {type = __crinoTypes.right_round_bracket, is_bracket = true},
                ["{"]  = {type = __crinoTypes.left_curly_bracket, is_bracket = true},
                ["}"]  = {type = __crinoTypes.right_curly_bracket, is_bracket = true},
                ["["]  = {type = __crinoTypes.left_square_bracket, is_bracket = true},
                ["]"]  = {type = __crinoTypes.right_square_bracket, is_bracket = true},
                ["#"]  = {type = __crinoTypes.length_operator},
                ["="]  = {type = __crinoTypes.assignment},
                [","]  = {type = __crinoTypes.comma},
                ["."]  = {type = __crinoTypes.dot},
                [".."]  = {type = __crinoTypes.concatenation},
                ["=="] = {type = __crinoTypes.basic_operator, value = "=="},
                [">="] = {type = __crinoTypes.basic_operator, value = ">="},
                ["<="] = {type = __crinoTypes.basic_operator, value = "<="},
                ["~="] = {type = __crinoTypes.basic_operator, value = "~="},
                [">"]  = {type = __crinoTypes.basic_operator, value = ">"},
                ["<"]  = {type = __crinoTypes.basic_operator, value = "<"},
                ["+"]  = {type = __crinoTypes.basic_operator, value = "+"},
                ["-"]  = {type = __crinoTypes.basic_operator, value = "-"},
                ["/"]  = {type = __crinoTypes.basic_operator, value = "/"},
                ["*"]  = {type = __crinoTypes.basic_operator, value = "*"},
                ["^"]  = {type = __crinoTypes.basic_operator, value = "^"},
                ["%"]  = {type = __crinoTypes.basic_operator, value = "%"},
                ["and"] = {type = __crinoTypes.basic_operator, value = " and"},
                ["or"]  = {type = __crinoTypes.basic_operator, value = " or"},
                ["not"] = {type = __crinoTypes.basic_operator, value = " not"},
                ["nil"]   = {type = __crinoTypes["nil"]},
                ["true"]  = {type = __crinoTypes.boolean, value = "true"},
                ["false"] = {type = __crinoTypes.boolean, value = "false"},
                ["end"]      = {type = __crinoTypes["end"]},
                ["if"]       = {type = __crinoTypes["if"]},
                ["then"]     = {type = __crinoTypes["then"]},
                ["else"]     = {type = __crinoTypes["else"]},
                ["for"]      = {type = __crinoTypes["for"]},
                ["while"]    = {type = __crinoTypes["while"]},
                ["repeat"]   = {type = __crinoTypes["repeat"]},
                ["until"]    = {type = __crinoTypes["until"]},
                ["break"]    = {type = __crinoTypes["break"]},
                ["continue"] = {type = __crinoTypes["continue"]},
                ["do"]       = {type = __crinoTypes["do"]},
                ["in"]       = {type = __crinoTypes["in"]},
            },
            allowed_functions = {
                pairs    = {func_name = "pairs"},
                ipairs   = {func_name = "ipairs"},
                next     = {func_name = "next"},
                tostring = {func_name = "tostring"},
                tonumber = {func_name = "tonumber"},
                random   = {func_name = "random"},
                select   = {func_name = "select"},
                type     = {func_name = "type"},
                pack     = {func_name = "pack"},
                unpack   = {func_name = "unpack"}
            },
            custom_funcs = {},
            global_variables = {},
        },
        ["lua-extended"] = {
            predefined_elements = {
                ["elseif"]   = {type = __crinoTypes["elseif"]},
                ["elsif"]    = {type = __crinoTypes["elseif"]},
                ["elif"]     = {type = __crinoTypes["elseif"]},
                ["+="]  = {type = __crinoTypes.complex_assignment, value = "+"},
                ["-="]  = {type = __crinoTypes.complex_assignment, value = "-"},
                ["*="]  = {type = __crinoTypes.complex_assignment, value = "*"},
                ["^="]  = {type = __crinoTypes.complex_assignment, value = "^"},
                ["/="]  = {type = __crinoTypes.complex_assignment, value = "/"},
                ["%="]  = {type = __crinoTypes.complex_assignment, value = "%"},
                ["..="] = {type = __crinoTypes.complex_assignment, value = ".."},
                ["++"] = {type = __crinoTypes.short_operators, value = "++"},
                ["--"] = {type = __crinoTypes.short_operators, value = "--"},
            },
            allowed_functions = {},
            custom_funcs = {},
            global_variables = {},
        },
        ["c-like"] = {
            predefined_elements = {
                ["&&"]  = {type = __crinoTypes.basic_operator, value = " and"},
                ["||"]  = {type = __crinoTypes.basic_operator, value = " or"},
                ["!"]   = {type = __crinoTypes.basic_operator, value = " not"},
                ["&&="] = {type = __crinoTypes.complex_assignment, value = " and"},
                ["||="] = {type = __crinoTypes.complex_assignment, value = " or"},
                ["!="] = {type = __crinoTypes.basic_operator, value = "~="},
            },
            allowed_functions = {},
            custom_funcs = {},
            global_variables = {},
        },
        ["additional-support"] = {
            predefined_elements = {
                ["、"]  = {type = __crinoTypes.comma},
                ["。"]  = {type = __crinoTypes.dot},
            },
            allowed_functions = {},
            custom_funcs = {},
            global_variables = {},
        },
        ["English"] = {
            predefined_elements = {
                ["and"] = {type = __crinoTypes.basic_operator, value = " and"},
                ["or"]  = {type = __crinoTypes.basic_operator, value = " or"},
                ["not"] = {type = __crinoTypes.basic_operator, value = " not"},
                ["is"]  = {type = __crinoTypes.basic_operator, value = "=="},
                ["nil"]   = {type = __crinoTypes["nil"]},
                ["null"]  = {type = __crinoTypes["nil"]},
                ["true"]  = {type = __crinoTypes.boolean, value = "true"},
                ["false"] = {type = __crinoTypes.boolean, value = "false"},
                ["end"]      = {type = __crinoTypes["end"]},
                ["if"]       = {type = __crinoTypes["if"]},
                ["then"]     = {type = __crinoTypes["then"]},
                ["elseif"]   = {type = __crinoTypes["elseif"]},
                ["elsif"]    = {type = __crinoTypes["elseif"]},
                ["elif"]     = {type = __crinoTypes["elseif"]},
                ["else"]     = {type = __crinoTypes["else"]},
                ["for"]      = {type = __crinoTypes["for"]},
                ["loop"]     = {type = __crinoTypes["for"]},
                ["LOOP"]     = {type = __crinoTypes["for"]},
                ["while"]    = {type = __crinoTypes["while"]},
                ["repeat"]   = {type = __crinoTypes["repeat"]},
                ["until"]    = {type = __crinoTypes["until"]},
                ["break"]    = {type = __crinoTypes["break"]},
                ["continue"] = {type = __crinoTypes["continue"]},
                ["do"]       = {type = __crinoTypes["do"]},
                ["in"]       = {type = __crinoTypes["in"]},
            },
            allowed_functions = {},
            custom_funcs = {},
            global_variables = {},
            goto_name = "goto",
        },
        ["Español"] = {
            predefined_elements = {
                ["y"] = {type = __crinoTypes.basic_operator, value = " and"},
                ["o"] = {type = __crinoTypes.basic_operator, value = " or"},
                ["nulo"]      = {type = __crinoTypes["nil"]},
                ["nada"]      = {type = __crinoTypes["nil"]},
                ["verdadero"] = {type = __crinoTypes.boolean, value = "true"},
                ["falso"]     = {type = __crinoTypes.boolean, value = "false"},
                ["fin"]       = {type = __crinoTypes["end"]},
                ["si"]        = {type = __crinoTypes["if"]},
                ["entonces"]  = {type = __crinoTypes["then"]},
                ["osi"]       = {type = __crinoTypes["elseif"]},
                ["sino"]      = {type = __crinoTypes["else"]},
                ["desde"]     = {type = __crinoTypes["for"]},
                ["para"]      = {type = __crinoTypes["while"]},
                ["repetir"]   = {type = __crinoTypes["repeat"]},
                ["hasta"]     = {type = __crinoTypes["until"]},
                ["romper"]    = {type = __crinoTypes["break"]},
                ["continuar"] = {type = __crinoTypes["continue"]},
                ["hacer"]     = {type = __crinoTypes["do"]},
                ["en"]        = {type = __crinoTypes["in"]},
            },
            allowed_functions = {
                ["escribir"] = {func_name = "print"},
                ["alogico"]  = {func_name = "type"}
            },
            custom_funcs = {},
            global_variables = {},
            goto_name = "ira",
        },
        ["Português"] = {
            predefined_elements = {
                ["e"]  = {type = __crinoTypes.basic_operator, value = " and"},
                ["ou"] = {type = __crinoTypes.basic_operator, value = " or"},
                ["nulo"]       = {type = __crinoTypes["nil"]},
                ["nada"]       = {type = __crinoTypes["nil"]},
                ["verdadeiro"] = {type = __crinoTypes.boolean, value = "true"},
                ["falso"]      = {type = __crinoTypes.boolean, value = "false"},
                ["fim"]        = {type = __crinoTypes["end"]},
                ["se"]         = {type = __crinoTypes["if"]},
                ["senão"]      = {type = __crinoTypes["else"]},
                ["por"]        = {type = __crinoTypes["for"]},
                ["enquanto"]   = {type = __crinoTypes["while"]},
                ["quebra"]     = {type = __crinoTypes["break"]},
                ["continuar"]  = {type = __crinoTypes["continue"]},
                ["fazer"]      = {type = __crinoTypes["do"]},
                ["em"]         = {type = __crinoTypes["in"]},
            },
            allowed_functions = {
                ["tipode"] = {func_name = "type"}
            },
            custom_funcs = {},
            global_variables = {},
            goto_name = "irpara",
        },
        ["Русский"] = {
            predefined_elements = {
                ["и"]   = {type = __crinoTypes.basic_operator, value = " and"},
                ["или"] = {type = __crinoTypes.basic_operator, value = " or"},
                ["ничего"]   = {type = __crinoTypes["nil"]},
                ["ничему"]   = {type = __crinoTypes["nil"]},
                ["пустота"]  = {type = __crinoTypes["nil"]},
                ["пустоте"]  = {type = __crinoTypes["nil"]},
                ["пусто"]    = {type = __crinoTypes["nil"]},
                ["истина"]   = {type = __crinoTypes.boolean, value = "true"},
                ["истине"]   = {type = __crinoTypes.boolean, value = "true"},
                ["ложь"]     = {type = __crinoTypes.boolean, value = "false"},
                ["конец"]    = {type = __crinoTypes["end"]},
                ["все"]      = {type = __crinoTypes["end"]},
                ["если"]     = {type = __crinoTypes["if"]},
                ["то"]       = {type = __crinoTypes["then"]},
                ["тогда"]    = {type = __crinoTypes["then"]},
                ["иначесли"] = {type = __crinoTypes["elseif"]},
                ["иначе"]    = {type = __crinoTypes["else"]},
                ["цикл"]     = {type = __crinoTypes["for"]},
                ["для"]      = {type = __crinoTypes["for"]},
                ["пока"]     = {type = __crinoTypes["while"]},
                ["повтори"]  = {type = __crinoTypes["repeat"]},
                ["повторяй"] = {type = __crinoTypes["repeat"]},
                ["до"]       = {type = __crinoTypes["until"]},
                ["прервать"] = {type = __crinoTypes["break"]},
                ["сделай"]   = {type = __crinoTypes["do"]},
                ["соверши"]  = {type = __crinoTypes["do"]},
                ["в"]        = {type = __crinoTypes["in"]},
                ["продолжи"] = {type = __crinoTypes["continue"]},
                ["продолжить"] = {type = __crinoTypes["continue"]},
            },
            allowed_functions = {
                ["тип"]     = {func_name = "type"},
                ["встроку"] = {func_name = "tostring"},
                ["вчисло"]  = {func_name = "tonumber"},
                ["запаковать"]  = {func_name = "pack"},
                ["распаковать"] = {func_name = "unpack"}
            },
            custom_funcs = {},
            global_variables = {},
            goto_name = "перейти",
        },
        ["Polski"] = {
            predefined_elements = {
                ["oraz"] = {type = __crinoTypes.basic_operator, value = " and"},
                ["lub"]  = {type = __crinoTypes.basic_operator, value = " or"},
                ["prawda"]   = {type = __crinoTypes.boolean, value = "true"},
                ["fałsz"]    = {type = __crinoTypes.boolean, value = "false"},
                ["null"]     = {type = __crinoTypes["nil"]},
                ["w"]        = {type = __crinoTypes["in"]},
                ["jeśli"]    = {type = __crinoTypes["if"]},
                ["inaczej"]  = {type = __crinoTypes["else"]},
                ["dla"]      = {type = __crinoTypes["for"]},
                ["póki"]     = {type = __crinoTypes["while"]},
                ["powtórz"]  = {type = __crinoTypes["do"]},
                ["koniec"]   = {type = __crinoTypes["end"]},
                ["przerwij"] = {type = __crinoTypes["break"]},
                ["dalej"]    = {type = __crinoTypes["continue"]},
            },
            allowed_functions = {
                ["typ"]       = {func_name = "type"},
                ["typdla"]    = {func_name = "type"},
                ["napis"]     = {func_name = "print"},
                ["naŁańcuch"] = {func_name = "tostring"},
            },
            custom_funcs = {},
            global_variables = {},
            goto_name = "idz",
        },
        ["Română"] = {
            predefined_elements = {
                ["adevărat"] = {type = __crinoTypes.boolean, value = "true"},
                ["fals"]     = {type = __crinoTypes.boolean, value = "false"},
                ["nul"]      = {type = __crinoTypes["nil"]},
                ["în"]       = {type = __crinoTypes["in"]},
                ["dacă"]     = {type = __crinoTypes["if"]},
                ["altfel"]   = {type = __crinoTypes["else"]},
                ["pentru"]   = {type = __crinoTypes["for"]},
                ["câttimp"]  = {type = __crinoTypes["while"]},
                ["execută"]  = {type = __crinoTypes["do"]},
                ["ieșire"]   = {type = __crinoTypes["break"]},
                ["continuă"] = {type = __crinoTypes["continue"]},
            },
            allowed_functions = {
                ["cătreȘirCaractere"] = {func_name = "tostring"},
                ["tip"] = {func_name = "type"},
            },
            custom_funcs = {},
            global_variables = {},
            goto_name = "mergila",
        },
        ["বাংলা"] = {
            predefined_elements = {
                ["সত্য"]   = {type = __crinoTypes.boolean, value = "true"},
                ["অসত্য"] = {type = __crinoTypes.boolean, value = "false"},
                ["নাল"]   = {type = __crinoTypes["nil"]},
                ["মধ্যে"]   = {type = __crinoTypes["in"]},
                ["যদ্যপি"]  = {type = __crinoTypes["if"]},
                ["নয়ত"]   = {type = __crinoTypes["else"]},
                ["জন্যে"]   = {type = __crinoTypes["for"]},
                ["যেহেতু"]  = {type = __crinoTypes["while"]},
                ["করো"]  = {type = __crinoTypes["do"]},
                ["ভাঙ্গন"]  = {type = __crinoTypes["break"]},
                ["অগ্রসর"] = {type = __crinoTypes["continue"]},
            },
            allowed_functions = {
                ["এই_ধরনের"] = {func_name = "type"},
                ["পংক্তিতে"]  = {func_name = "tostring"},
            },
            custom_funcs = {},
            global_variables = {},
            goto_name = "যাও_তাতে",
        },
        ["Esperanto"] = {
            predefined_elements = {
                ["kaj"] = {type = __crinoTypes.basic_operator, value = " and"},
                ["aŭ"]  = {type = __crinoTypes.basic_operator, value = " or"},
                ["vera"]  = {type = __crinoTypes.boolean, value = "true"},
                ["falsa"] = {type = __crinoTypes.boolean, value = "false"},
                ["nulo"]  = {type = __crinoTypes["nil"]},
                ["en"]    = {type = __crinoTypes["in"]},
                ["se"]    = {type = __crinoTypes["if"]},
                ["alie"]  = {type = __crinoTypes["else"]},
                ["por"]   = {type = __crinoTypes["for"]},
                ["dum"]   = {type = __crinoTypes["while"]},
                ["fare"]  = {type = __crinoTypes["do"]},
                ["eksterŝalte"] = {type = __crinoTypes["break"]},
                ["sekvŝalte"]   = {type = __crinoTypes["continue"]},
            },
            allowed_functions = {
                ["tipkongruas"] = {func_name = "type"},
                ["ĉenigu"]      = {func_name = "tostring"},
            },
            custom_funcs = {},
            global_variables = {},
            goto_name = "alŝalte",
        },
        ["Français"] = {
            predefined_elements = {
                ["et"] = {type = __crinoTypes.basic_operator, value = " and"},
                ["ou"] = {type = __crinoTypes.basic_operator, value = " or"},
                ["vrai"]  = {type = __crinoTypes.boolean, value = "true"},
                ["faux"]  = {type = __crinoTypes.boolean, value = "false"},
                ["nul"]   = {type = __crinoTypes["nil"]},
                ["dans"]  = {type = __crinoTypes["in"]},
                ["si"]    = {type = __crinoTypes["if"]},
                ["sinon"] = {type = __crinoTypes["else"]},
                ["pour"]  = {type = __crinoTypes["for"]},
                ["faire"] = {type = __crinoTypes["do"]},
                ["répéter"] = {type = __crinoTypes["repeat"]},
                ["Jusqu’à"] = {type = __crinoTypes["until"]},
                ["casser"]    = {type = __crinoTypes["break"]},
                ["tantque"]   = {type = __crinoTypes["while"]},
                ["continuer"] = {type = __crinoTypes["continue"]},
            },
            allowed_functions = {
                ["typede"]   = {func_name = "type"},
                ["enChaîne"] = {func_name = "tostring"},
            },
            custom_funcs = {
                ["terminer"] = Crino.custom_funcs.stop
            },
            global_variables = {},
        },
        ["Deutsch"] = {
            predefined_elements = {
                ["und"]    = {type = __crinoTypes.basic_operator, value = " and"},
                ["oder"]   = {type = __crinoTypes.basic_operator, value = " or"},
                ["null"]   = {type = __crinoTypes["nil"]},
                ["wahr"]   = {type = __crinoTypes.boolean, value = "true"},
                ["falsch"] = {type = __crinoTypes.boolean, value = "false"},
                ["wenn"]   = {type = __crinoTypes["if"]},
                ["sonst"]  = {type = __crinoTypes["else"]},
                ["für"]    = {type = __crinoTypes["for"]},
                ["in"]     = {type = __crinoTypes["in"]},
                ["ausführen"]  = {type = __crinoTypes["do"]},
                ["solange"]    = {type = __crinoTypes["while"]},
                ["abbrechen"]  = {type = __crinoTypes["break"]},
                ["fortfahren"] = {type = __crinoTypes["continue"]},

                -- Contributed by hubert/Stefan#5336 in Discord
                ["dann"] = {type = __crinoTypes["then"]},
                ["bis"]  = {type = __crinoTypes["until"]},
                ["wiederholen"] = {type = __crinoTypes["repeat"]},
                ["blockende"]   = {type = __crinoTypes["end"]},
                ["sonst_wenn"]  = {type = __crinoTypes["elseif"]},
            },
            allowed_functions = {
                ["artvon"]         = {func_name = "type"},
                ["zuZeichenkette"] = {func_name = "tostring"}
            },
            custom_funcs = {},
            global_variables = {},
            goto_name = "springen",
        },
        ["한국어"] = {
            predefined_elements = {
                ["그리고"]  = {type = __crinoTypes.basic_operator, value = " and"},
                ["또는"]   = {type = __crinoTypes.basic_operator, value = " or"},
                ["참"]     = {type = __crinoTypes.boolean, value = "true"},
                ["거짓"]   = {type = __crinoTypes.boolean, value = "false"},
                ["널"]     = {type = __crinoTypes["nil"]},
                ["만약"]   = {type = __crinoTypes["if"]},
                ["아니면"] = {type = __crinoTypes["else"]},
                ["반복"]   = {type = __crinoTypes["for"]},
                ["동안"]   = {type = __crinoTypes["while"]},
                ["정지"]   = {type = __crinoTypes["break"]},
                ["실행"]   = {type = __crinoTypes["do"]},
                ["가운데"] = {type = __crinoTypes["in"]},
                ["계속"]   = {type = __crinoTypes["continue"]},
            },
            allowed_functions = {
                ["문자열화"] = {func_name = "tostring"},
                ["의형"]    = {func_name = "type"}
            },
            custom_funcs = {},
            global_variables = {},
            goto_name = "이행",
        },
        ["Kiswahili"] = {
            predefined_elements = {
                ["batili"]  = {type = __crinoTypes["nil"]},
                ["kweli"]   = {type = __crinoTypes.boolean, value = "true"},
                ["sikweli"] = {type = __crinoTypes.boolean, value = "false"},
                ["ikiwa"]   = {type = __crinoTypes["if"]},
                ["lasivyo"] = {type = __crinoTypes["else"]},
                ["kwa"]     = {type = __crinoTypes["for"]},
                ["wakati"]  = {type = __crinoTypes["while"]},
                ["vunja"]   = {type = __crinoTypes["break"]},
                ["tenda"]   = {type = __crinoTypes["do"]},
                ["ndaniYa"] = {type = __crinoTypes["in"]},
                ["endelea"] = {type = __crinoTypes["continue"]},
            },
            allowed_functions = {
                ["ainaya"]     = {func_name = "type"},
                ["kuwaMtungo"] = {func_name = "tostring"},
            },
            custom_funcs = {},
            global_variables = {},
            goto_name = "nenda",
        },
        ["हिन्दी"] = {
            predefined_elements = {
                ["रिक्त"]   = {type = __crinoTypes["nil"]},
                ["सही"]    = {type = __crinoTypes.boolean, value = "true"},
                ["ग़लत"]   = {type = __crinoTypes.boolean, value = "false"},
                ["अगर"]   = {type = __crinoTypes["if"]},
                ["अन्यथा"]  = {type = __crinoTypes["else"]},
                ["के_लिए"]  = {type = __crinoTypes["for"]},
                ["जब_तक"] = {type = __crinoTypes["while"]},
                ["अवरोध"]  = {type = __crinoTypes["break"]},
                ["कर"]    = {type = __crinoTypes["do"]},
                ["में"]     = {type = __crinoTypes["in"]},
                ["जारी"]   = {type = __crinoTypes["continue"]},
            },
            allowed_functions = {
                ["का_प्रकार"] = {func_name = "type"},
                ["वर्णमाला_में"] = {func_name = "tostring"},
            },
            custom_funcs = {},
            global_variables = {},
            goto_name = "जाओ",
        },
        ["Malaysian"] = {
            predefined_elements = {
                ["kosong"]  = {type = __crinoTypes["nil"]},
                ["benar"]   = {type = __crinoTypes.boolean, value = "true"},
                ["salah"]   = {type = __crinoTypes.boolean, value = "false"},
                ["jika"]    = {type = __crinoTypes["if"]},
                ["lainnya"] = {type = __crinoTypes["else"]},
                ["untuk"]   = {type = __crinoTypes["for"]},
                ["selagi"]  = {type = __crinoTypes["while"]},
                ["putus"]   = {type = __crinoTypes["break"]},
                ["lakukan"] = {type = __crinoTypes["do"]},
                ["pada"]    = {type = __crinoTypes["in"]},
                ["lanjut"]  = {type = __crinoTypes["continue"]},
            },
            allowed_functions = {
                ["tipedari"]     = {func_name = "type"},
                ["keSerentetan"] = {func_name = "tostring"},
            },
            custom_funcs = {},
            global_variables = {},
            goto_name = "menuju",
        },
        ["Bahasa Indonesia"] = {
            predefined_elements = {
                ["atau"]    = {type = __crinoTypes.basic_operator, value = " or"},
                ["kosong"]  = {type = __crinoTypes["nil"]},
                ["benar"]   = {type = __crinoTypes.boolean, value = "true"},
                ["salah"]   = {type = __crinoTypes.boolean, value = "false"},
                ["jika"]    = {type = __crinoTypes["if"]},
                ["lainnya"] = {type = __crinoTypes["else"]},
                ["untuk"]   = {type = __crinoTypes["for"]},
                ["selagi"]  = {type = __crinoTypes["while"]},
                ["putus"]   = {type = __crinoTypes["break"]},
                ["lakukan"] = {type = __crinoTypes["do"]},
                ["pada"]    = {type = __crinoTypes["in"]},
                ["lanjut"]  = {type = __crinoTypes["continue"]},
            },
            allowed_functions = {
                ["tipedari"]     = {func_name = "type"},
                ["keSerentetan"] = {func_name = "tostring"},
            },
            custom_funcs = {},
            global_variables = {},
            goto_name = "menuju",
        },
        ["Chinese simplified"] = {
            predefined_elements = {
                ["并且"] = {type = __crinoTypes.basic_operator, value = " and"},
                ["或者"] = {type = __crinoTypes.basic_operator, value = " or"},
                ["空"]   = {type = __crinoTypes["nil"]},
                ["真"]   = {type = __crinoTypes.boolean, value = "true"},
                ["假"]   = {type = __crinoTypes.boolean, value = "false"},
                ["如果"] = {type = __crinoTypes["if"]},
                ["否则"] = {type = __crinoTypes["else"]},
                ["取"]   = {type = __crinoTypes["for"]},
                ["当"]   = {type = __crinoTypes["while"]},
                ["跳出"] = {type = __crinoTypes["break"]},
                ["做"]   = {type = __crinoTypes["do"]},
                ["在"]   = {type = __crinoTypes["in"]},
                ["继续"] = {type = __crinoTypes["continue"]},
            },
            allowed_functions = {
                ["类型为"]  = {func_name = "type"},
                ["转字符串"] = {func_name = "tostring"},
            },
            custom_funcs = {},
            global_variables = {},
            goto_name = "跳转到",
        },
        ["Italiano"] = {
            predefined_elements = {
                ["nullo"]    = {type = __crinoTypes["nil"]},
                ["vero"]     = {type = __crinoTypes.boolean, value = "true"},
                ["falso"]    = {type = __crinoTypes.boolean, value = "false"},
                ["se"]       = {type = __crinoTypes["if"]},
                ["oppure"]   = {type = __crinoTypes["else"]},
                ["per"]      = {type = __crinoTypes["for"]},
                ["mentre"]   = {type = __crinoTypes["while"]},
                ["eseguire"] = {type = __crinoTypes["do"]},
                ["in"]       = {type = __crinoTypes["in"]},
                ["continuare"]   = {type = __crinoTypes["continue"]},
                ["interrompere"] = {type = __crinoTypes["break"]},
            },
            allowed_functions = {
                ["instringa" ] = {func_name = "tostring"},
                ["tipodi"]     = {func_name = "type"},
            },
            custom_funcs = {},
            global_variables = {},
            goto_name = "vaia",
        },
        ["Nederlands"] = {
            predefined_elements = {
                ["en"] = {type = __crinoTypes.basic_operator, value = " and"},
                ["of"] = {type = __crinoTypes.basic_operator, value = " or"},
                ["nul"]    = {type = __crinoTypes["nil"]},
                ["waar"]   = {type = __crinoTypes.boolean, value = "true"},
                ["onwaar"] = {type = __crinoTypes.boolean, value = "false"},
                ["als"]    = {type = __crinoTypes["if"]},
                ["anders"] = {type = __crinoTypes["else"]},
                ["voor"]   = {type = __crinoTypes["for"]},
                ["zolang"] = {type = __crinoTypes["while"]},
                ["doe"]    = {type = __crinoTypes["do"]},
                ["eind"]   = {type = __crinoTypes["end"]},
                ["herhaal"]    = {type = __crinoTypes["continue"]},
                ["onderbreek"] = {type = __crinoTypes["break"]},
            },
            allowed_functions = {
                ["typevan"]        = {func_name = "type"},
                ["naarTekenreeks"] = {func_name = "tostring"},
            },
            custom_funcs = {},
            global_variables = {},
            goto_name = "ganaar"
        },
        ["日本語"] = {
            predefined_elements = {
                ["ヌル"]   = {type = __crinoTypes["nil"]},
                ["真"]     = {type = __crinoTypes.boolean, value = "true"},
                ["偽"]     = {type = __crinoTypes.boolean, value = "false"},
                ["もし"]   = {type = __crinoTypes["if"]},
                ["なら"]   = {type = __crinoTypes["for"]},
                ["ながら"] = {type = __crinoTypes["while"]},
                ["中断"]   = {type = __crinoTypes["break"]},
                ["する"]   = {type = __crinoTypes["do"]},
                ["が"]     = {type = __crinoTypes["in"]},
                ["続け"]   = {type = __crinoTypes["continue"]},
                ["それ以外"] = {type = __crinoTypes["else"]},
            },
            allowed_functions = {
                ["属性"]    = {func_name = "type"},
                ["文字例化"] = {func_name = "tostring"},
            },
            custom_funcs = {},
            global_variables = {},
            goto_name = "行け",
        },
    }

    -- Add some stuff in some syntaxes
    do
        local _, _, version = string.find(_VERSION, ".+(%d.%d)")
        if tonumber(version) >= 5.3 then
            for _, v in ipairs({"//", "&", "|", "~", ">>", "<<"}) do
                syntaxes.lua.predefined_elements[v]      = {type = __crinoTypes.basic_operator,     value = v}
                syntaxes.lua.predefined_elements[v.."="] = {type = __crinoTypes.complex_assignment, value = v}
            end
        end
    end
    if math then
        Crino.hidden_variables.math = {}
        for k, v in pairs(math) do
            Crino.hidden_variables.math[k] = v
        end
        syntaxes.lua.global_variables.math = {name="HV.math"}
        Crino.hidden_variables.math.randomseed = nil
    end
    if string then
        Crino.hidden_variables.string = {}
        for k, v in pairs(string) do
            Crino.hidden_variables.string[k] = v
        end
        syntaxes.lua.global_variables.string = {name="HV.string"}
        Crino.hidden_variables.string.dump = nil
        -- TODO: change rep
    end
    if table then
        Crino.hidden_variables.table = {}
        for k, v in pairs(table) do
            Crino.hidden_variables.table[k] = v
        end
        syntaxes.lua.global_variables.table = {name="HV.table"}
        Crino.hidden_variables.table.remove = nil
        Crino.hidden_variables.table.insert = nil
        Crino.hidden_variables.table.sort   = nil
    end
    if bit then
        syntaxes.lua.global_variables.bit = {name="bit"}
    end
    if bits then
        syntaxes.lua.global_variables.bits = {name="bits"}
    end

    if print then
        syntaxes.lua.allowed_functions.print = {func_name = "print"}
    end

    --#region if you want to use some stuff as Crino functions
    -- if math then
    -- 	for k in pairs(math) do
    -- 		syntaxes.lua.allowed_function[k] = {func_name = "math." .. k}
    -- 	end
    -- end
    -- if string then
    -- 	for k in pairs(string) do
    -- 		syntaxes.lua.allowed_function[k] = {func_name = "string." .. k}
    -- 	end
    -- end
    -- if table then
    -- 	for k in pairs(table) do
    -- 		syntaxes.lua.allowed_function[k] = {func_name = "table." .. k}
    -- 	end
    -- end
    -- if bit or bits then
    -- 	local prefix = (bit and "bit") or "bits"
    -- 	for k in pairs(bit or bits) do
    -- 		syntaxes.lua.allowed_function[k] = {func_name = prefix .. k}
    -- 	end
    -- end
    --#endregion

    return syntaxes
end


return M
