--[[
	Copyright (c) 2023 ZwerOxotnik <zweroxotnik@gmail.com>
	Licensed under the MIT licence.

	Source: https://github.com/ZwerOxotnik/Crino
	Description: Crino is an open-source multilingual
	Domain Specific Language and library in pure lua.
	Crino limits access to variables, functions and separating
	code into different instructions. Crino executes 1 instruction
	from all codes each tick by default.
]]


--- WARNING: Crino isn't fully ready yet.
--- Please, read README.md first!
local Crino = {
	VERSION = "0.2.0",
	store_functions = true, -- it's problematic to store functions in some environments
	default_rule_group = 0,
	log = print -- change it if you need to
}
--[[
	Reserved global variables:
		_E, _V, _CCF, _HV
]]


--[[
Crino.set_default_goto_name(string)
Crino.create_rule_group(string|integer): crinoRules
Crino.create_environment(): crinoEnvironment
Crino.remove_from_running_environments(crinoEnvironment)
Crino.remove_from_paused_environments(crinoEnvironment)
Crino.remove_from_stopped_environments(crinoEnvironment)
Crino.reset_environment(crinoEnvironment): boolean
Crino.stop_environment(crinoEnvironment): boolean
Crino.pause_environment(crinoEnvironment, pause_ticks:integer = 1): boolean
Crino.delete_environment(crinoEnvironment)
Crino.compile(crinoEnvironment, code:string?): function[]?
Crino.activate_environment(crinoEnvironment): boolean
Crino.step()


# Not fully ready:
Crino.remove_rule_group(string|integer)
Crino.add_custom_function(crinoRules, name:string, table<string, crinoFunction>)
Crino.remove_custom_function(crinoRules, name:string)
Crino.add_function(crinoRules, name:string, table<string, crinoFunction>)
Crino.remove_function(crinoRules, name:string)
Crino.add_global_variable(crinoRules, name:string, data:string)
Crino.remove_global_variable(crinoRules, name:string, data:string)
Crino.add_predefined_element(crinoRules, name:string, crinoElement)
Crino.remove_predefined_element(crinoRules, name:string)


Localization stuff:
Crino.add_spanish_syntax(crinoRules?)
Crino.add_portuguese_syntax(crinoRules?)
Crino.add_russian_syntax(crinoRules?)
Crino.add_polish_syntax(crinoRules?)
Crino.add_romanian_syntax(crinoRules?)
Crino.add_bengali_syntax(crinoRules?)
Crino.add_esperanto_syntax(crinoRules?)
Crino.add_french_syntax(crinoRules?)
Crino.add_german_syntax(crinoRules?)
Crino.add_korean_syntax(crinoRules?)
Crino.add_swahili_syntax(crinoRules?)
Crino.add_hindi_syntax(crinoRules?)
Crino.add_malaysian_syntax(crinoRules?)
Crino.add_indonesian_syntax(crinoRules?)
Crino.add_chinese_simplified_syntax(crinoRules?)
Crino.add_italian_syntax(crinoRules?)
Crino.add_dutch_syntax(crinoRules?)
Crino.add_japanese_syntax(crinoRules?)


# Not ready and, probably, will be changed:
Crino._logHandler(crinoEnvironment, error_message:string)
Crino._crinoErrorHandler()
]]


---@class crino_environment_states
local __crino_environment_states = {
	not_working = 0,
	active      = 1,
	paused      = 2,
	stopped     = 3,
	removed     = 4
}


---@class crinoEnvironment
---@field current_line integer?
---@field pause_ticks integer
---@field is_finished boolean
---@field id integer
---@field state integer
---@field code string
---@field compilation_error_message string?
---@field runtime_error_message string?
---@field error_line integer?
---@field instructions function[]? # Only if Crino.store_functions is true
---@field instructions_to_line integer[]?
---@field labels    table<string, integer>
---@field variables table<integer, any> # but it shoudn't have functions
---@field rules_level string|integer # 0 by default
---@field _ni integer #Next instruction (don't fiddle with that)


---@class crinoFunction
---@field func_name string     -- Original name in Lua
---@field is_custom_func true? -- Has `CCF.` prefix
---@field is_unique true?      -- All unique functions can be called only N times (see crinoRules)


---@class crinoElement
---@field type integer # (value of crinoType)
---@field is_bracket true?
---@field instruction_id integer? # Only for goto
---@field value string?
---@field is_unique boolean?


---@class crinoRules
---@field allowed_functions   table<string, crinoFunction>
---@field custom_funcs        table<string, crinoFunction>
---@field global_variables    table<string, string>
---@field predefined_elements table<string, crinoElement>
---@field max_unique_functions_per_action integer # 1 by default
---@field max_elements_per_action integer # 350 by default
---@field max_variables integer # 256 by default
---@field max_code_lines integer # 1024 by default
---@field max_characters_in_line integer # 400 by default
---@field goto_name string?


--- For functions when they can't be serialized
---@type table<integer, function[]>
Crino.environment_instructions_reference = {}


---@type table<string, table>
Crino.hidden_variables = {}


---@type crinoEnvironment[]
Crino.all_environments = {}
---@type crinoEnvironment[]
Crino.running_environments = {}
local running_environments = Crino.running_environments
---@type crinoEnvironment[]
Crino.paused_environments = {}
local paused_environments = Crino.paused_environments
---@type crinoEnvironment[]
Crino.stopped_environments = {}
local stopped_environments = Crino.stopped_environments


Crino.last_environment_id = 0


local __goto_name = "goto"


---@param name string
Crino.set_default_goto_name = function(name)
	__goto_name = name
end


---@type table<string, function>
Crino.custom_funcs = {
	---@param self crinoEnvironment
	stop = function(self)
		local state = self.state
		if state == __crino_environment_states.stopped then
			return
		end
		if state == __crino_environment_states.not_working then
			return
		end

		self.is_finished = true
		self.state = __crino_environment_states.stopped
	end,
	---@param self crinoEnvironment
	reset = function(self)
		if self.state ~= __crino_environment_states.active then return end
		self._ni = 1
		--#region Reset variables
		local variables = self.variables
		for k in pairs(variables) do
			variables[k] = nil
		end
		--#endregion
	end,
	---@param self crinoEnvironment
	---@param ticks integer?
	pause = function(self, ticks)
		if self.state ~= __crino_environment_states.active then return end
		self.pause_ticks = ticks or 1
		self.state = __crino_environment_states.paused
		table.insert(Crino.paused_environments, self)
		for i = #running_environments, 1, -1 do
			if running_environments[i] == self then
				table.remove(running_environments, i)
				return
			end
		end
	end
}
Crino.custom_funcs.wait = Crino.custom_funcs.pause


---@type table<string, crinoFunction>
Crino.functions_to_original = {
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
}
for k in pairs(Crino.custom_funcs) do
	Crino.functions_to_original[k] = {func_name = "CCF." .. k .. "(S,", is_custom_func = true}
end
if print then
	Crino.functions_to_original.print = {func_name = "print"}
end

--#region if you want to use some stuff as Crino functions
-- if math then
-- 	local functions_to_original = Crino.functions_to_original
-- 	for k in pairs(math) do
-- 		functions_to_original[k] = {func_name = "math." .. k}
-- 	end
-- end
-- if string then
-- 	local functions_to_original = Crino.functions_to_original
-- 	for k in pairs(string) do
-- 		functions_to_original[k] = {func_name = "string." .. k}
-- 	end
-- end
-- if table then
-- 	local functions_to_original = Crino.functions_to_original
-- 	for k in pairs(table) do
-- 		functions_to_original[k] = {func_name = "table." .. k}
-- 	end
-- end
-- if bit or bits then
-- 	local functions_to_original = Crino.functions_to_original
-- 	local prefix = (bit and "bit") or "bits"
-- 	for k in pairs(bit or bits) do
-- 		functions_to_original[k] = {func_name = prefix .. k}
-- 	end
-- end
--#endregion


---@type table<string, table>
Crino.global_variables = {}
if math then
	Crino.hidden_variables.math = {}
	for k, v in pairs(math) do
		Crino.hidden_variables.math[k] = v
	end
	Crino.global_variables.math = {name="HV.math"}
	Crino.hidden_variables.math.randomseed = nil
end
if string then
	Crino.hidden_variables.string = {}
	for k, v in pairs(string) do
		Crino.hidden_variables.string[k] = v
	end
	Crino.global_variables.string = {name="HV.string"}
	Crino.hidden_variables.string.dump = nil
	-- TODO: change rep
end
if table then
	Crino.hidden_variables.table = {}
	for k, v in pairs(table) do
		Crino.hidden_variables.table[k] = v
	end
	Crino.global_variables.table = {name="HV.table"}
	Crino.hidden_variables.table.remove = nil
	Crino.hidden_variables.table.insert = nil
	Crino.hidden_variables.table.sort   = nil
end
if bit then
	Crino.global_variables.bit = {name="bit"}
end
if bits then
	Crino.global_variables.bits = {name="bits"}
end


---@class crinoType
Crino.types = {
	number = 1,
	string = 2,
	boolean = 3,
	["nil"] = 4,
	variable = 5,
	["function"] = 6,
	table = 7,
	basic_operator = 8,
	left_round_bracket = 9,
	right_round_bracket = 10,
	left_curly_bracket = 11,
	right_curly_bracket = 12,
	left_square_bracket = 13,
	right_square_bracket = 14,
	comma = 15,
	assignment = 16,
	concatenation = 17,
	["end"] = 18,
	["if"] = 19,
	["elseif"] = 20,
	["else"] = 21,
	["for"] = 22,
	["while"] = 23,
	["repeat"] = 24,
	["until"] = 25,
	["break"] = 26,
	["continue"] = 27,
	["goto"] = 28,
	complex_assignment = 29,
	dot = 30,
	["then"] = 31,
	["do"] = 32,
	length_operator = 33,
	["in"] = 34,
	short_operators = 35,
	general_data = 36,
	global_variables = 37,
	colon = 38,
	unidentified = 39,
	end_of_action = 40, -- Does nothing in Crino actually
}
local __crinoTypes = Crino.types


local __predefined_elements = {
	["("]  = {type = __crinoTypes.left_round_bracket, is_bracket = true},
	[")"]  = {type = __crinoTypes.right_round_bracket, is_bracket = true},
	["{"]  = {type = __crinoTypes.left_curly_bracket, is_bracket = true},
	["}"]  = {type = __crinoTypes.right_curly_bracket, is_bracket = true},
	["["]  = {type = __crinoTypes.left_square_bracket, is_bracket = true},
	["]"]  = {type = __crinoTypes.right_square_bracket, is_bracket = true},
	["#"]  = {type = __crinoTypes.length_operator},
	["="]  = {type = __crinoTypes.assignment},
	[","]  = {type = __crinoTypes.comma},
	["、"]  = {type = __crinoTypes.comma},
	["."]  = {type = __crinoTypes.dot},
	["。"]  = {type = __crinoTypes.dot},
	[":"]  = {type = __crinoTypes.colon},
	[";"]  = {type = __crinoTypes.end_of_action},
	[".."]  = {type = __crinoTypes.concatenation},
	["and"] = {type = __crinoTypes.basic_operator, value = " and"},
	["&&"]  = {type = __crinoTypes.basic_operator, value = " and"},
	["or"]  = {type = __crinoTypes.basic_operator, value = " or"},
	["||"]  = {type = __crinoTypes.basic_operator, value = " or"},
	["not"] = {type = __crinoTypes.basic_operator, value = " not"},
	["!"]   = {type = __crinoTypes.basic_operator, value = " not"},
	["&&="] = {type = __crinoTypes.complex_assignment, value = " and"},
	["||="] = {type = __crinoTypes.complex_assignment, value = " or"},
	["+="]  = {type = __crinoTypes.complex_assignment, value = "+"},
	["-="]  = {type = __crinoTypes.complex_assignment, value = "-"},
	["*="]  = {type = __crinoTypes.complex_assignment, value = "*"},
	["^="]  = {type = __crinoTypes.complex_assignment, value = "^"},
	["/="]  = {type = __crinoTypes.complex_assignment, value = "/"},
	["%="]  = {type = __crinoTypes.complex_assignment, value = "%"},
	["..="] = {type = __crinoTypes.complex_assignment, value = ".."},
	["++"] = {type = __crinoTypes.short_operators, value = "++"},
	["--"] = {type = __crinoTypes.short_operators, value = "--"},
	["=="] = {type = __crinoTypes.basic_operator, value = "=="},
	["is"] = {type = __crinoTypes.basic_operator, value = "=="},
	[">="] = {type = __crinoTypes.basic_operator, value = ">="},
	["<="] = {type = __crinoTypes.basic_operator, value = "<="},
	["~="] = {type = __crinoTypes.basic_operator, value = "~="},
	["!="] = {type = __crinoTypes.basic_operator, value = "~="},
	[">"]  = {type = __crinoTypes.basic_operator, value = ">"},
	["<"]  = {type = __crinoTypes.basic_operator, value = "<"},
	["+"]  = {type = __crinoTypes.basic_operator, value = "+"},
	["-"]  = {type = __crinoTypes.basic_operator, value = "-"},
	["/"]  = {type = __crinoTypes.basic_operator, value = "/"},
	["*"]  = {type = __crinoTypes.basic_operator, value = "*"},
	["^"]  = {type = __crinoTypes.basic_operator, value = "^"},
	["%"]  = {type = __crinoTypes.basic_operator, value = "%"},
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
}
do
	local _, _, version = string.find(_VERSION, ".+(%d.%d)")
	if tonumber(version) >= 5.3 then
		for _, v in ipairs({"//", "&", "|", "~", ">>", "<<"}) do
			__predefined_elements[v]      = {type = __crinoTypes.basic_operator,     value = v}
			__predefined_elements[v.."="] = {type = __crinoTypes.complex_assignment, value = v}
		end
	end
end
for k, v in pairs(Crino.global_variables) do
	__predefined_elements[k] = {
		type = __crinoTypes.global_variables,
		value = v.name,
		is_unique = v.is_unique
	}
end


---@type table<string|integer, crinoRules>
Crino.rules_groups = {}


---@type table<crinoType, fun(crinoElem: crinoElement?): string>
Crino.converters = {
	[__crinoTypes.number] = function(crinoElem)
		return crinoElem.value
	end,
	[__crinoTypes.string] = function(crinoElem)
		return '"' .. crinoElem.value .. '"'
	end,
	[__crinoTypes.variable] = function(crinoElem)
		return string.format("M[%d]", crinoElem.value)
	end,
	[__crinoTypes["function"]] = function(crinoElem)
		return crinoElem.value.func_name
	end,
	[__crinoTypes.basic_operator] = function(crinoElem)
		return crinoElem.value
	end,
	[__crinoTypes.basic_operator] = function(crinoElem)
		return crinoElem.value
	end,
	[__crinoTypes.general_data] = function(crinoElem)
		return crinoElem.value
	end,
	[__crinoTypes.global_variables] = function(crinoElem)
		return crinoElem.value
	end,
	[__crinoTypes.unidentified] = function(crinoElem)
		return "['" .. crinoElem.value .. "']"
	end,
	[__crinoTypes.left_round_bracket]   = function() return "(" end,
	[__crinoTypes.right_round_bracket]  = function() return ")" end,
	[__crinoTypes.left_curly_bracket]   = function() return "{\n" end,
	[__crinoTypes.right_curly_bracket]  = function() return "\n}" end,
	[__crinoTypes.left_square_bracket]  = function() return "[\n" end,
	[__crinoTypes.right_square_bracket] = function() return "\n]" end,
	[__crinoTypes["nil"]] = function() return "nil" end,
	[__crinoTypes.comma] = function() return "," end,
	[__crinoTypes.dot] = function() return "." end,
	[__crinoTypes.colon] = function() return ":" end,
	[__crinoTypes.concatenation]  = function() return ".." end,
	[__crinoTypes.boolean] = function(crinoElem) return crinoElem.value end,
	[__crinoTypes.assignment] = function() return "=" end,
}
__converters = Crino.converters


---@type table<string, fun(variable_number:integer): string>
local _short_operators = {
	["++"] = function(variable_number)
		return string.format("M[%d] = M[%d] + 1", variable_number, variable_number)
	end,
	["--"] = function(variable_number)
		return string.format("M[%d] = M[%d] - 1", variable_number, variable_number)
	end,
}


---@param name string|integer
---@return crinoRules
Crino.create_rule_group = function(name)
	---@type crinoRules
	local data = {
		allowed_functions = {},
		custom_funcs = {},
		predefined_elements = {},
		global_variables = {},
		max_unique_functions_per_action = 1,
		max_elements_per_action = 350,
		max_variables = 256,
		max_code_lines = 1024,
		max_characters_in_line = 400
	}
	Crino.rules_groups[name] = data

	return data
end
Crino.create_rule_group(0)



---@param name string|integer
Crino.remove_rule_group = function(name)
	Crino.rules_groups[name] = nil
	-- WIP (set default rule group)
end


---@param rules crinoRules
---@param name string
---@param data table<string, crinoFunction>
Crino.add_custom_function = function(rules, name, data)
	local custom_funcs
	if rules then
		custom_funcs = rules.custom_funcs
	else
		custom_funcs = Crino.custom_funcs
	end

	if custom_funcs[name] then
		-- WIP
		-- Crino.log()
	end
	custom_funcs[name] = data
end


---@param rules crinoRules
---@param name string
Crino.remove_custom_function = function(rules, name)
	local custom_funcs
	if rules then
		custom_funcs = rules.custom_funcs
	else
		custom_funcs = Crino.custom_funcs
	end

	if custom_funcs[name] then
		-- WIP
		-- Crino.log()
		custom_funcs[name] = nil
	end
end


---@param rules crinoRules
---@param name string
---@param data table<string, crinoFunction>
Crino.add_function = function(rules, name, data)
	local allowed_functions
	if rules then
		allowed_functions = rules.allowed_functions
	else
		allowed_functions = Crino.functions_to_original
	end

	if allowed_functions[name] then
		-- WIP
		-- Crino.log()
	end
	allowed_functions[name] = data
end


---@param rules crinoRules
---@param name string
Crino.remove_function = function(rules, name)
	local allowed_functions
	if rules then
		allowed_functions = rules.allowed_functions
	else
		allowed_functions = Crino.functions_to_original
	end

	if allowed_functions[name] then
		-- WIP
		-- Crino.log()
		allowed_functions[name] = nil
	end
end


---@param rules crinoRules
---@param name string
---@param data string
Crino.add_global_variable = function(rules, name, data)
	local global_variables
	if rules then
		global_variables = rules.global_variables
	else
		global_variables = Crino.global_variables
	end

	if global_variables[name] then
		-- WIP
		-- Crino.log()
	end
	global_variables[name] = data
end


---@param rules crinoRules
---@param name string
Crino.remove_global_variable = function(rules, name)
	local global_variables
	if rules then
		global_variables = rules.global_variables
	else
		global_variables = Crino.global_variables
	end

	if global_variables[name] then
		-- WIP
		-- Crino.log()
		global_variables[name] = nil
	end
end


---@param rules crinoRules
---@param name string
---@param data crinoElement
Crino.add_predefined_element = function(rules, name, data)
	local predefined_elements
	if rules then
		predefined_elements = rules.predefined_elements
	else
		predefined_elements = __predefined_elements
	end

	if predefined_elements[name] then
		-- WIP
		-- Crino.log()
	end
	predefined_elements[name] = data
end


---@param rules crinoRules
---@param name string
Crino.remove_predefined_element = function(rules, name)
	local predefined_elements
	if rules then
		predefined_elements = rules.predefined_elements
	else
		predefined_elements = __predefined_elements
	end

	if predefined_elements[name] then
		-- WIP
		-- Crino.log()
		predefined_elements[name] = nil
	end
end


--#region Crino.add_*_syntax


-- Inspiration from https://manual.lenguajelatino.org/es/stable
---@param rules crinoRules?
function Crino.add_spanish_syntax(rules)
	local predefined_elements, functions_to_original, custom_funcs, global_variables
	if rules then
		predefined_elements   = rules.predefined_elements
		functions_to_original = rules.allowed_functions
		custom_funcs     = rules.custom_funcs
		global_variables = rules.global_variables
		rules.goto_name = "ira"

	else
		predefined_elements   = __predefined_elements
		functions_to_original = Crino.functions_to_original
		custom_funcs     = Crino.custom_funcs
		global_variables = Crino.global_variables
	end

	functions_to_original.escribir = {func_name = "print"}
	functions_to_original.alogico  = {func_name = "type"}
	predefined_elements["y"] = {type = __crinoTypes.basic_operator, value = " and"}
	predefined_elements["o"] = {type = __crinoTypes.basic_operator, value = " or"}
	predefined_elements["nulo"]      = {type = __crinoTypes["nil"]}
	predefined_elements["nada"]      = {type = __crinoTypes["nil"]}
	predefined_elements["verdadero"] = {type = __crinoTypes.boolean, value = "true"}
	predefined_elements["falso"]     = {type = __crinoTypes.boolean, value = "false"}
	predefined_elements["fin"]       = {type = __crinoTypes["end"]}
	predefined_elements["si"]        = {type = __crinoTypes["if"]}
	predefined_elements["entonces"]  = {type = __crinoTypes["then"]}
	predefined_elements["osi"]       = {type = __crinoTypes["elseif"]}
	predefined_elements["sino"]      = {type = __crinoTypes["else"]}
	predefined_elements["desde"]     = {type = __crinoTypes["for"]}
	predefined_elements["para"]      = {type = __crinoTypes["while"]}
	predefined_elements["repetir"]   = {type = __crinoTypes["repeat"]}
	predefined_elements["hasta"]     = {type = __crinoTypes["until"]}
	predefined_elements["romper"]    = {type = __crinoTypes["break"]}
	predefined_elements["continuar"] = {type = __crinoTypes["continue"]}
	predefined_elements["hacer"]     = {type = __crinoTypes["do"]}
	predefined_elements["en"]        = {type = __crinoTypes["in"]}
end


-- Translation from https://babylscript.plom.dev/translations.html
---@param rules crinoRules?
function Crino.add_portuguese_syntax(rules)
	local predefined_elements, functions_to_original, custom_funcs, global_variables
	if rules then
		predefined_elements   = rules.predefined_elements
		functions_to_original = rules.allowed_functions
		custom_funcs     = rules.custom_funcs
		global_variables = rules.global_variables
		rules.goto_name = "irpara"

	else
		predefined_elements   = __predefined_elements
		functions_to_original = Crino.functions_to_original
		custom_funcs     = Crino.custom_funcs
		global_variables = Crino.global_variables
	end

	functions_to_original.tipode = {func_name = "type"}
	predefined_elements["e"]  = {type = __crinoTypes.basic_operator, value = " and"}
	predefined_elements["ou"] = {type = __crinoTypes.basic_operator, value = " or"}
	predefined_elements["nulo"]       = {type = __crinoTypes["nil"]}
	predefined_elements["nada"]       = {type = __crinoTypes["nil"]}
	predefined_elements["verdadeiro"] = {type = __crinoTypes.boolean, value = "true"}
	predefined_elements["falso"]      = {type = __crinoTypes.boolean, value = "false"}
	predefined_elements["fim"]        = {type = __crinoTypes["end"]}
	predefined_elements["se"]         = {type = __crinoTypes["if"]}
	predefined_elements["senão"]      = {type = __crinoTypes["else"]}
	predefined_elements["por"]        = {type = __crinoTypes["for"]}
	predefined_elements["enquanto"]   = {type = __crinoTypes["while"]}
	predefined_elements["quebra"]     = {type = __crinoTypes["break"]}
	predefined_elements["continuar"]  = {type = __crinoTypes["continue"]}
	predefined_elements["fazer"]      = {type = __crinoTypes["do"]}
	predefined_elements["em"]         = {type = __crinoTypes["in"]}
end


---@param rules crinoRules?
function Crino.add_russian_syntax(rules)
	local predefined_elements, functions_to_original, custom_funcs, global_variables
	if rules then
		predefined_elements   = rules.predefined_elements
		functions_to_original = rules.allowed_functions
		custom_funcs     = rules.custom_funcs
		global_variables = rules.global_variables
		rules.goto_name = "перейти"

	else
		predefined_elements   = __predefined_elements
		functions_to_original = Crino.functions_to_original
		custom_funcs     = Crino.custom_funcs
		global_variables = Crino.global_variables
	end

	functions_to_original["тип"]     = {func_name = "type"}
	functions_to_original["встроку"] = {func_name = "tostring"}
	functions_to_original["вчисло"]  = {func_name = "tonumber"}
	functions_to_original["запаковать"]  = {func_name = "pack"}
	functions_to_original["распаковать"] = {func_name = "unpack"}
	predefined_elements["и"]   = {type = __crinoTypes.basic_operator, value = " and"}
	predefined_elements["или"] = {type = __crinoTypes.basic_operator, value = " or"}
	predefined_elements["ничего"]   = {type = __crinoTypes["nil"]}
	predefined_elements["ничему"]   = {type = __crinoTypes["nil"]}
	predefined_elements["пустота"]  = {type = __crinoTypes["nil"]}
	predefined_elements["пустоте"]  = {type = __crinoTypes["nil"]}
	predefined_elements["пусто"]    = {type = __crinoTypes["nil"]}
	predefined_elements["истина"]   = {type = __crinoTypes.boolean, value = "true"}
	predefined_elements["истине"]   = {type = __crinoTypes.boolean, value = "true"}
	predefined_elements["ложь"]     = {type = __crinoTypes.boolean, value = "false"}
	predefined_elements["конец"]    = {type = __crinoTypes["end"]}
	predefined_elements["все"]      = {type = __crinoTypes["end"]}
	predefined_elements["если"]     = {type = __crinoTypes["if"]}
	predefined_elements["то"]       = {type = __crinoTypes["then"]}
	predefined_elements["тогда"]    = {type = __crinoTypes["then"]}
	predefined_elements["иначесли"] = {type = __crinoTypes["elseif"]}
	predefined_elements["иначе"]    = {type = __crinoTypes["else"]}
	predefined_elements["цикл"]     = {type = __crinoTypes["for"]}
	predefined_elements["для"]      = {type = __crinoTypes["for"]}
	predefined_elements["пока"]     = {type = __crinoTypes["while"]}
	predefined_elements["повтори"]  = {type = __crinoTypes["repeat"]}
	predefined_elements["повторяй"] = {type = __crinoTypes["repeat"]}
	predefined_elements["до"]       = {type = __crinoTypes["until"]}
	predefined_elements["прервать"] = {type = __crinoTypes["break"]}
	predefined_elements["сделай"]   = {type = __crinoTypes["do"]}
	predefined_elements["соверши"]  = {type = __crinoTypes["do"]}
	predefined_elements["в"]        = {type = __crinoTypes["in"]}
	predefined_elements["продолжи"] = {type = __crinoTypes["continue"]}
	predefined_elements["продолжить"] = {type = __crinoTypes["continue"]}
end


-- Translation from https://babylscript.plom.dev/translations.html
---@param rules crinoRules?
function Crino.add_polish_syntax(rules)
	local predefined_elements, functions_to_original, custom_funcs, global_variables
	if rules then
		predefined_elements   = rules.predefined_elements
		functions_to_original = rules.allowed_functions
		custom_funcs     = rules.custom_funcs
		global_variables = rules.global_variables
		rules.goto_name = "idz"
	else
		predefined_elements   = __predefined_elements
		functions_to_original = Crino.functions_to_original
		custom_funcs     = Crino.custom_funcs
		global_variables = Crino.global_variables
	end

	predefined_elements["oraz"] = {type = __crinoTypes.basic_operator, value = " and"}
	predefined_elements["lub"]  = {type = __crinoTypes.basic_operator, value = " or"}
	functions_to_original["typ"]       = {func_name = "type"}
	functions_to_original["typdla"]    = {func_name = "type"}
	functions_to_original["napis"]     = {func_name = "print"}
	functions_to_original["naŁańcuch"] = {func_name = "tostring"}
	predefined_elements["prawda"]   = {type = __crinoTypes.boolean, value = "true"}
	predefined_elements["fałsz"]    = {type = __crinoTypes.boolean, value = "false"}
	predefined_elements["null"]     = {type = __crinoTypes["nil"]}
	predefined_elements["w"]        = {type = __crinoTypes["in"]}
	predefined_elements["jeśli"]    = {type = __crinoTypes["if"]}
	predefined_elements["inaczej"]  = {type = __crinoTypes["else"]}
	predefined_elements["dla"]      = {type = __crinoTypes["for"]}
	predefined_elements["póki"]     = {type = __crinoTypes["while"]}
	predefined_elements["powtórz"]  = {type = __crinoTypes["do"]}
	predefined_elements["koniec"]   = {type = __crinoTypes["end"]}
	predefined_elements["przerwij"] = {type = __crinoTypes["break"]}
	predefined_elements["dalej"]    = {type = __crinoTypes["continue"]}
end

-- Translation from https://babylscript.plom.dev/translations.html
---@param rules crinoRules?
function Crino.add_romanian_syntax(rules)
	local predefined_elements, functions_to_original, custom_funcs, global_variables
	if rules then
		predefined_elements   = rules.predefined_elements
		functions_to_original = rules.allowed_functions
		custom_funcs     = rules.custom_funcs
		global_variables = rules.global_variables
		rules.goto_name = "mergila"
	else
		predefined_elements   = __predefined_elements
		functions_to_original = Crino.functions_to_original
		custom_funcs     = Crino.custom_funcs
		global_variables = Crino.global_variables
	end

	functions_to_original["tip"] = {func_name = "type"}
	functions_to_original["cătreȘirCaractere"] = {func_name = "tostring"}
	predefined_elements["adevărat"] = {type = __crinoTypes.boolean, value = "true"}
	predefined_elements["fals"]     = {type = __crinoTypes.boolean, value = "false"}
	predefined_elements["nul"]      = {type = __crinoTypes["nil"]}
	predefined_elements["în"]       = {type = __crinoTypes["in"]}
	predefined_elements["dacă"]     = {type = __crinoTypes["if"]}
	predefined_elements["altfel"]   = {type = __crinoTypes["else"]}
	predefined_elements["pentru"]   = {type = __crinoTypes["for"]}
	predefined_elements["câttimp"]  = {type = __crinoTypes["while"]}
	predefined_elements["execută"]  = {type = __crinoTypes["do"]}
	predefined_elements["ieșire"]   = {type = __crinoTypes["break"]}
	predefined_elements["continuă"] = {type = __crinoTypes["continue"]}
end


-- Translation from https://babylscript.plom.dev/translations.html
---@param rules crinoRules?
function Crino.add_bengali_syntax(rules)
	local predefined_elements, functions_to_original, custom_funcs, global_variables
	if rules then
		predefined_elements   = rules.predefined_elements
		functions_to_original = rules.allowed_functions
		custom_funcs     = rules.custom_funcs
		global_variables = rules.global_variables
		rules.goto_name = "যাও_তাতে"
	else
		predefined_elements   = __predefined_elements
		functions_to_original = Crino.functions_to_original
		custom_funcs     = Crino.custom_funcs
		global_variables = Crino.global_variables
	end

	functions_to_original["এই_ধরনের"] = {func_name = "type"}
	functions_to_original["পংক্তিতে"]  = {func_name = "tostring"}
	predefined_elements["সত্য"]   = {type = __crinoTypes.boolean, value = "true"}
	predefined_elements["অসত্য"] = {type = __crinoTypes.boolean, value = "false"}
	predefined_elements["নাল"]   = {type = __crinoTypes["nil"]}
	predefined_elements["মধ্যে"]   = {type = __crinoTypes["in"]}
	predefined_elements["যদ্যপি"]  = {type = __crinoTypes["if"]}
	predefined_elements["নয়ত"]   = {type = __crinoTypes["else"]}
	predefined_elements["জন্যে"]   = {type = __crinoTypes["for"]}
	predefined_elements["যেহেতু"]  = {type = __crinoTypes["while"]}
	predefined_elements["করো"]  = {type = __crinoTypes["do"]}
	predefined_elements["ভাঙ্গন"]  = {type = __crinoTypes["break"]}
	predefined_elements["অগ্রসর"] = {type = __crinoTypes["continue"]}
end


-- Translation from https://babylscript.plom.dev/translations.html
---@param rules crinoRules?
function Crino.add_esperanto_syntax(rules)
	local predefined_elements, functions_to_original, custom_funcs, global_variables
	if rules then
		predefined_elements   = rules.predefined_elements
		functions_to_original = rules.allowed_functions
		custom_funcs     = rules.custom_funcs
		global_variables = rules.global_variables
		rules.goto_name = "alŝalte"
	else
		predefined_elements   = __predefined_elements
		functions_to_original = Crino.functions_to_original
		custom_funcs     = Crino.custom_funcs
		global_variables = Crino.global_variables
	end

	functions_to_original["tipkongruas"] = {func_name = "type"}
	functions_to_original["ĉenigu"]      = {func_name = "tostring"}
	predefined_elements["kaj"] = {type = __crinoTypes.basic_operator, value = " and"}
	predefined_elements["aŭ"]  = {type = __crinoTypes.basic_operator, value = " or"}
	predefined_elements["vera"]  = {type = __crinoTypes.boolean, value = "true"}
	predefined_elements["falsa"] = {type = __crinoTypes.boolean, value = "false"}
	predefined_elements["nulo"]  = {type = __crinoTypes["nil"]}
	predefined_elements["en"]    = {type = __crinoTypes["in"]}
	predefined_elements["se"]    = {type = __crinoTypes["if"]}
	predefined_elements["alie"]  = {type = __crinoTypes["else"]}
	predefined_elements["por"]   = {type = __crinoTypes["for"]}
	predefined_elements["dum"]   = {type = __crinoTypes["while"]}
	predefined_elements["fare"]  = {type = __crinoTypes["do"]}
	predefined_elements["eksterŝalte"] = {type = __crinoTypes["break"]}
	predefined_elements["sekvŝalte"]   = {type = __crinoTypes["continue"]}
end


-- Translation from https://babylscript.plom.dev/translations.html
---@param rules crinoRules?
function Crino.add_french_syntax(rules)
	local predefined_elements, functions_to_original, custom_funcs, global_variables
	if rules then
		predefined_elements   = rules.predefined_elements
		functions_to_original = rules.allowed_functions
		custom_funcs     = rules.custom_funcs
		global_variables = rules.global_variables
		rules.goto_name = "allerà"
	else
		predefined_elements   = __predefined_elements
		functions_to_original = Crino.functions_to_original
		custom_funcs     = Crino.custom_funcs
		global_variables = Crino.global_variables
	end

	custom_funcs["terminer"] = Crino.custom_funcs.stop
	predefined_elements["et"] = {type = __crinoTypes.basic_operator, value = " and"}
	predefined_elements["ou"] = {type = __crinoTypes.basic_operator, value = " or"}
	functions_to_original["typede"]   = {func_name = "type"}
	functions_to_original["enChaîne"] = {func_name = "tostring"}
	predefined_elements["vrai"]  = {type = __crinoTypes.boolean, value = "true"}
	predefined_elements["faux"]  = {type = __crinoTypes.boolean, value = "false"}
	predefined_elements["nul"]   = {type = __crinoTypes["nil"]}
	predefined_elements["dans"]  = {type = __crinoTypes["in"]}
	predefined_elements["si"]    = {type = __crinoTypes["if"]}
	predefined_elements["sinon"] = {type = __crinoTypes["else"]}
	predefined_elements["pour"]  = {type = __crinoTypes["for"]}
	predefined_elements["faire"] = {type = __crinoTypes["do"]}
	predefined_elements["répéter"] = {type = __crinoTypes["repeat"]}
	predefined_elements["Jusqu’à"] = {type = __crinoTypes["until"]}
	predefined_elements["casser"]    = {type = __crinoTypes["break"]}
	predefined_elements["tantque"]   = {type = __crinoTypes["while"]}
	predefined_elements["continuer"] = {type = __crinoTypes["continue"]}
end


---@param rules crinoRules?
function Crino.add_german_syntax(rules)
	local predefined_elements, functions_to_original, custom_funcs, global_variables
	if rules then
		predefined_elements   = rules.predefined_elements
		functions_to_original = rules.allowed_functions
		custom_funcs     = rules.custom_funcs
		global_variables = rules.global_variables
		rules.goto_name = "springen"
	else
		predefined_elements   = __predefined_elements
		functions_to_original = Crino.functions_to_original
		custom_funcs     = Crino.custom_funcs
		global_variables = Crino.global_variables
	end

	-- Translation from https://babylscript.plom.dev/translations.html
	functions_to_original["artvon"]         = {func_name = "type"}
	functions_to_original["zuZeichenkette"] = {func_name = "tostring"}
	predefined_elements["und"]    = {type = __crinoTypes.basic_operator, value = " and"}
	predefined_elements["oder"]   = {type = __crinoTypes.basic_operator, value = " or"}
	predefined_elements["null"]   = {type = __crinoTypes["nil"]}
	predefined_elements["wahr"]   = {type = __crinoTypes.boolean, value = "true"}
	predefined_elements["falsch"] = {type = __crinoTypes.boolean, value = "false"}
	predefined_elements["wenn"]   = {type = __crinoTypes["if"]}
	predefined_elements["sonst"]  = {type = __crinoTypes["else"]}
	predefined_elements["für"]    = {type = __crinoTypes["for"]}
	predefined_elements["in"]     = {type = __crinoTypes["in"]}
	predefined_elements["ausführen"]  = {type = __crinoTypes["do"]}
	predefined_elements["solange"]    = {type = __crinoTypes["while"]}
	predefined_elements["abbrechen"]  = {type = __crinoTypes["break"]}
	predefined_elements["fortfahren"] = {type = __crinoTypes["continue"]}

	-- Contributed by hubert/Stefan#5336 in Discord
	predefined_elements["dann"] = {type = __crinoTypes["then"]}
	predefined_elements["bis"]  = {type = __crinoTypes["until"]}
	predefined_elements["wiederholen"] = {type = __crinoTypes["repeat"]}
	predefined_elements["fortfahren"]  = {type = __crinoTypes["continue"]}
	predefined_elements["blockende"]   = {type = __crinoTypes["end"]}
	predefined_elements["sonst_wenn"]  = {type = __crinoTypes["elseif"]}
end


-- Translation from https://babylscript.plom.dev/translations.html
---@param rules crinoRules?
function Crino.add_korean_syntax(rules)
	local predefined_elements, functions_to_original, custom_funcs, global_variables
	if rules then
		predefined_elements   = rules.predefined_elements
		functions_to_original = rules.allowed_functions
		custom_funcs     = rules.custom_funcs
		global_variables = rules.global_variables
		rules.goto_name = "이행"
	else
		predefined_elements   = __predefined_elements
		functions_to_original = Crino.functions_to_original
		custom_funcs     = Crino.custom_funcs
		global_variables = Crino.global_variables
	end

	functions_to_original["문자열화"] = {func_name = "tostring"}
	functions_to_original["의형"]    = {func_name = "type"}
	predefined_elements["그리고"]  = {type = __crinoTypes.basic_operator, value = " and"}
	predefined_elements["또는"]   = {type = __crinoTypes.basic_operator, value = " or"}
	predefined_elements["참"]     = {type = __crinoTypes.boolean, value = "true"}
	predefined_elements["거짓"]   = {type = __crinoTypes.boolean, value = "false"}
	predefined_elements["널"]     = {type = __crinoTypes["nil"]}
	predefined_elements["만약"]   = {type = __crinoTypes["if"]}
	predefined_elements["아니면"] = {type = __crinoTypes["else"]}
	predefined_elements["반복"]   = {type = __crinoTypes["for"]}
	predefined_elements["동안"]   = {type = __crinoTypes["while"]}
	predefined_elements["정지"]   = {type = __crinoTypes["break"]}
	predefined_elements["실행"]   = {type = __crinoTypes["do"]}
	predefined_elements["가운데"] = {type = __crinoTypes["in"]}
	predefined_elements["계속"]   = {type = __crinoTypes["continue"]}
end


-- Translation from https://babylscript.plom.dev/translations.html
---@param rules crinoRules?
function Crino.add_swahili_syntax(rules)
	local predefined_elements, functions_to_original, custom_funcs, global_variables
	if rules then
		predefined_elements   = rules.predefined_elements
		functions_to_original = rules.allowed_functions
		custom_funcs     = rules.custom_funcs
		global_variables = rules.global_variables
		rules.goto_name = "nenda"
	else
		predefined_elements   = __predefined_elements
		functions_to_original = Crino.functions_to_original
		custom_funcs     = Crino.custom_funcs
		global_variables = Crino.global_variables
	end

	functions_to_original["ainaya"]     = {func_name = "type"}
	functions_to_original["kuwaMtungo"] = {func_name = "tostring"}
	predefined_elements["batili"]  = {type = __crinoTypes["nil"]}
	predefined_elements["kweli"]   = {type = __crinoTypes.boolean, value = "true"}
	predefined_elements["sikweli"] = {type = __crinoTypes.boolean, value = "false"}
	predefined_elements["ikiwa"]   = {type = __crinoTypes["if"]}
	predefined_elements["lasivyo"] = {type = __crinoTypes["else"]}
	predefined_elements["kwa"]     = {type = __crinoTypes["for"]}
	predefined_elements["wakati"]  = {type = __crinoTypes["while"]}
	predefined_elements["vunja"]   = {type = __crinoTypes["break"]}
	predefined_elements["tenda"]   = {type = __crinoTypes["do"]}
	predefined_elements["ndaniYa"] = {type = __crinoTypes["in"]}
	predefined_elements["endelea"] = {type = __crinoTypes["continue"]}
end


-- Translation from https://babylscript.plom.dev/translations.html
---@param rules crinoRules?
function Crino.add_hindi_syntax(rules)
	local predefined_elements, functions_to_original, custom_funcs, global_variables
	if rules then
		predefined_elements   = rules.predefined_elements
		functions_to_original = rules.allowed_functions
		custom_funcs     = rules.custom_funcs
		global_variables = rules.global_variables
		rules.goto_name = "जाओ"
	else
		predefined_elements   = __predefined_elements
		functions_to_original = Crino.functions_to_original
		custom_funcs     = Crino.custom_funcs
		global_variables = Crino.global_variables
	end

	functions_to_original["का_प्रकार"] = {func_name = "type"}
	functions_to_original["वर्णमाला_में"] = {func_name = "tostring"}
	predefined_elements["रिक्त"]   = {type = __crinoTypes["nil"]}
	predefined_elements["सही"]    = {type = __crinoTypes.boolean, value = "true"}
	predefined_elements["ग़लत"]   = {type = __crinoTypes.boolean, value = "false"}
	predefined_elements["अगर"]   = {type = __crinoTypes["if"]}
	predefined_elements["अन्यथा"]  = {type = __crinoTypes["else"]}
	predefined_elements["के_लिए"]  = {type = __crinoTypes["for"]}
	predefined_elements["जब_तक"] = {type = __crinoTypes["while"]}
	predefined_elements["अवरोध"]  = {type = __crinoTypes["break"]}
	predefined_elements["कर"]    = {type = __crinoTypes["do"]}
	predefined_elements["में"]     = {type = __crinoTypes["in"]}
	predefined_elements["जारी"]   = {type = __crinoTypes["continue"]}
end


-- Translation from https://babylscript.plom.dev/translations.html
---@param rules crinoRules?
function Crino.add_malaysian_syntax(rules)
	local predefined_elements, functions_to_original, custom_funcs, global_variables
	if rules then
		predefined_elements   = rules.predefined_elements
		functions_to_original = rules.allowed_functions
		custom_funcs     = rules.custom_funcs
		global_variables = rules.global_variables
		rules.goto_name = "menuju"
	else
		predefined_elements   = __predefined_elements
		functions_to_original = Crino.functions_to_original
		custom_funcs     = Crino.custom_funcs
		global_variables = Crino.global_variables
	end

	functions_to_original["tipedari"]     = {func_name = "type"}
	functions_to_original["keSerentetan"] = {func_name = "tostring"}
	predefined_elements["kosong"]  = {type = __crinoTypes["nil"]}
	predefined_elements["benar"]   = {type = __crinoTypes.boolean, value = "true"}
	predefined_elements["salah"]   = {type = __crinoTypes.boolean, value = "false"}
	predefined_elements["jika"]    = {type = __crinoTypes["if"]}
	predefined_elements["lainnya"] = {type = __crinoTypes["else"]}
	predefined_elements["untuk"]   = {type = __crinoTypes["for"]}
	predefined_elements["selagi"]  = {type = __crinoTypes["while"]}
	predefined_elements["putus"]   = {type = __crinoTypes["break"]}
	predefined_elements["lakukan"] = {type = __crinoTypes["do"]}
	predefined_elements["pada"]    = {type = __crinoTypes["in"]}
	predefined_elements["lanjut"]  = {type = __crinoTypes["continue"]}
end


-- Translation from https://babylscript.plom.dev/translations.html
---@param rules crinoRules?
function Crino.add_indonesian_syntax(rules)
	local predefined_elements, functions_to_original, custom_funcs, global_variables
	if rules then
		predefined_elements   = rules.predefined_elements
		functions_to_original = rules.allowed_functions
		custom_funcs     = rules.custom_funcs
		global_variables = rules.global_variables
		rules.goto_name = "menuju"
	else
		predefined_elements   = __predefined_elements
		functions_to_original = Crino.functions_to_original
		custom_funcs     = Crino.custom_funcs
		global_variables = Crino.global_variables
	end

	functions_to_original["tipedari"]     = {func_name = "type"}
	functions_to_original["keSerentetan"] = {func_name = "tostring"}
	predefined_elements["atau"]    = {type = __crinoTypes.basic_operator, value = " or"}
	predefined_elements["kosong"]  = {type = __crinoTypes["nil"]}
	predefined_elements["benar"]   = {type = __crinoTypes.boolean, value = "true"}
	predefined_elements["salah"]   = {type = __crinoTypes.boolean, value = "false"}
	predefined_elements["jika"]    = {type = __crinoTypes["if"]}
	predefined_elements["lainnya"] = {type = __crinoTypes["else"]}
	predefined_elements["untuk"]   = {type = __crinoTypes["for"]}
	predefined_elements["selagi"]  = {type = __crinoTypes["while"]}
	predefined_elements["putus"]   = {type = __crinoTypes["break"]}
	predefined_elements["lakukan"] = {type = __crinoTypes["do"]}
	predefined_elements["pada"]    = {type = __crinoTypes["in"]}
	predefined_elements["lanjut"]  = {type = __crinoTypes["continue"]}
end


-- Translation from https://babylscript.plom.dev/translations.html
---@param rules crinoRules?
function Crino.add_chinese_simplified_syntax(rules)
	local predefined_elements, functions_to_original, custom_funcs, global_variables
	if rules then
		predefined_elements   = rules.predefined_elements
		functions_to_original = rules.allowed_functions
		custom_funcs     = rules.custom_funcs
		global_variables = rules.global_variables
		rules.goto_name = "跳转到"
	else
		predefined_elements   = __predefined_elements
		functions_to_original = Crino.functions_to_original
		custom_funcs     = Crino.custom_funcs
		global_variables = Crino.global_variables
	end

	functions_to_original["类型为"]  = {func_name = "type"}
	functions_to_original["转字符串"] = {func_name = "tostring"}
	predefined_elements["并且"] = {type = __crinoTypes.basic_operator, value = " and"}
	predefined_elements["或者"] = {type = __crinoTypes.basic_operator, value = " or"}
	predefined_elements["空"]   = {type = __crinoTypes["nil"]}
	predefined_elements["真"]   = {type = __crinoTypes.boolean, value = "true"}
	predefined_elements["假"]   = {type = __crinoTypes.boolean, value = "false"}
	predefined_elements["如果"] = {type = __crinoTypes["if"]}
	predefined_elements["否则"] = {type = __crinoTypes["else"]}
	predefined_elements["取"]   = {type = __crinoTypes["for"]}
	predefined_elements["当"]   = {type = __crinoTypes["while"]}
	predefined_elements["跳出"] = {type = __crinoTypes["break"]}
	predefined_elements["做"]   = {type = __crinoTypes["do"]}
	predefined_elements["在"]   = {type = __crinoTypes["in"]}
	predefined_elements["继续"] = {type = __crinoTypes["continue"]}
end


-- Translation from https://babylscript.plom.dev/translations.html
---@param rules crinoRules?
function Crino.add_italian_syntax(rules)
	local predefined_elements, functions_to_original, custom_funcs, global_variables
	if rules then
		predefined_elements   = rules.predefined_elements
		functions_to_original = rules.allowed_functions
		custom_funcs     = rules.custom_funcs
		global_variables = rules.global_variables
		rules.goto_name = "vaia"
	else
		predefined_elements   = __predefined_elements
		functions_to_original = Crino.functions_to_original
		custom_funcs     = Crino.custom_funcs
		global_variables = Crino.global_variables
	end

	functions_to_original["instringa" ] = {func_name = "tostring"}
	functions_to_original["tipodi"]     = {func_name = "type"}
	predefined_elements["nullo"]    = {type = __crinoTypes["nil"]}
	predefined_elements["vero"]     = {type = __crinoTypes.boolean, value = "true"}
	predefined_elements["falso"]    = {type = __crinoTypes.boolean, value = "false"}
	predefined_elements["se"]       = {type = __crinoTypes["if"]}
	predefined_elements["oppure"]   = {type = __crinoTypes["else"]}
	predefined_elements["per"]      = {type = __crinoTypes["for"]}
	predefined_elements["mentre"]   = {type = __crinoTypes["while"]}
	predefined_elements["eseguire"] = {type = __crinoTypes["do"]}
	predefined_elements["in"]       = {type = __crinoTypes["in"]}
	predefined_elements["continuare"]   = {type = __crinoTypes["continue"]}
	predefined_elements["interrompere"] = {type = __crinoTypes["break"]}
end


-- Translation from https://babylscript.plom.dev/translations.html
---@param rules crinoRules?
function Crino.add_dutch_syntax(rules)
	local predefined_elements, functions_to_original, custom_funcs, global_variables
	if rules then
		predefined_elements   = rules.predefined_elements
		functions_to_original = rules.allowed_functions
		custom_funcs     = rules.custom_funcs
		global_variables = rules.global_variables
		rules.goto_name = "ganaar"
	else
		predefined_elements   = __predefined_elements
		functions_to_original = Crino.functions_to_original
		custom_funcs     = Crino.custom_funcs
		global_variables = Crino.global_variables
	end

	functions_to_original["typevan"]        = {func_name = "type"}
	functions_to_original["naarTekenreeks"] = {func_name = "tostring"}
	predefined_elements["en"] = {type = __crinoTypes.basic_operator, value = " and"}
	predefined_elements["of"] = {type = __crinoTypes.basic_operator, value = " or"}
	predefined_elements["nul"]    = {type = __crinoTypes["nil"]}
	predefined_elements["waar"]   = {type = __crinoTypes.boolean, value = "true"}
	predefined_elements["onwaar"] = {type = __crinoTypes.boolean, value = "false"}
	predefined_elements["als"]    = {type = __crinoTypes["if"]}
	predefined_elements["anders"] = {type = __crinoTypes["else"]}
	predefined_elements["voor"]   = {type = __crinoTypes["for"]}
	predefined_elements["zolang"] = {type = __crinoTypes["while"]}
	predefined_elements["doe"]    = {type = __crinoTypes["do"]}
	predefined_elements["eind"]   = {type = __crinoTypes["end"]}
	predefined_elements["herhaal"]    = {type = __crinoTypes["continue"]}
	predefined_elements["onderbreek"] = {type = __crinoTypes["break"]}
end


-- Translation from https://babylscript.plom.dev/translations.html
---@param rules crinoRules?
function Crino.add_japanese_syntax(rules)
	local predefined_elements, functions_to_original, custom_funcs, global_variables
	if rules then
		predefined_elements   = rules.predefined_elements
		functions_to_original = rules.allowed_functions
		custom_funcs     = rules.custom_funcs
		global_variables = rules.global_variables
		rules.goto_name = "行け"
	else
		predefined_elements   = __predefined_elements
		functions_to_original = Crino.functions_to_original
		custom_funcs     = Crino.custom_funcs
		global_variables = Crino.global_variables
	end

	functions_to_original["属性"]    = {func_name = "type"}
	functions_to_original["文字例化"] = {func_name = "tostring"}
	predefined_elements["ヌル"]   = {type = __crinoTypes["nil"]}
	predefined_elements["真"]     = {type = __crinoTypes.boolean, value = "true"}
	predefined_elements["偽"]     = {type = __crinoTypes.boolean, value = "false"}
	predefined_elements["もし"]   = {type = __crinoTypes["if"]}
	predefined_elements["なら"]   = {type = __crinoTypes["for"]}
	predefined_elements["ながら"] = {type = __crinoTypes["while"]}
	predefined_elements["中断"]   = {type = __crinoTypes["break"]}
	predefined_elements["する"]   = {type = __crinoTypes["do"]}
	predefined_elements["が"]     = {type = __crinoTypes["in"]}
	predefined_elements["続け"]   = {type = __crinoTypes["continue"]}
	predefined_elements["それ以外"] = {type = __crinoTypes["else"]}
end


--#endregion


---@return crinoEnvironment
function Crino.create_environment()
	local id = Crino.last_environment_id + 1
	Crino.last_environment_id = id

	---@type crinoEnvironment
	local new_environment = {
		_ni = 1, --next instruction
		current_line = nil,
		is_finished = true,
		instructions_to_line = {},
		runtime_error_message = nil,
		compilation_error_message = nil,
		error_line = nil,
		instructions = {},
		variables = {},
		labels = {},
		pause_ticks = 0,
		rules_level = 0,
		state = __crino_environment_states.not_working,
		id = id
	}

	return new_environment
end


---@param target_environment crinoEnvironment
Crino.remove_from_running_environments = function(target_environment)
	if target_environment.state ~= __crino_environment_states.active then return end
	for i = #running_environments, 1, -1 do
		if running_environments[i] == target_environment then
			table.remove(running_environments, i)
			break
		end
	end
end


---@param target_environment crinoEnvironment
Crino.remove_from_paused_environments = function(target_environment)
	if target_environment.state ~= __crino_environment_states.paused then return end
	for i = #paused_environments, 1, -1 do
		if paused_environments[i] == target_environment then
			table.remove(paused_environments, i)
			break
		end
	end
end


---@param target_environment crinoEnvironment
Crino.remove_from_stopped_environments = function(target_environment)
	if target_environment.state ~= __crino_environment_states.stopped then return end
	for i = #stopped_environments, 1, -1 do
		if stopped_environments[i] == target_environment then
			table.remove(stopped_environments, i)
			break
		end
	end
end


---@param environment crinoEnvironment
---@return boolean
Crino.reset_environment = function(environment)
	local state = environment.state
	if state == __crino_environment_states.paused then
		Crino.remove_from_running_environments(environment)
	elseif state == __crino_environment_states.stopped then
		Crino.remove_from_stopped_environments(environment)
	elseif environment.compilation_error_message or environment.runtime_error_message then
		return false
	end

	environment.state = __crino_environment_states.active
	environment._ni = 1
	--#region Reset variables
	local variables = environment.variables
	for k in pairs(variables) do
		variables[k] = nil
	end
	--#endregion
	return true
end


---@param environment crinoEnvironment
---@return boolean
Crino.stop_environment = function(environment)
	local state = environment.state
	if state == __crino_environment_states.active then
		Crino.remove_from_running_environments(environment)
	elseif state == __crino_environment_states.paused then
		Crino.remove_from_paused_environments(environment)
	elseif state == __crino_environment_states.stopped then
		return true
	else
		return false
	end

	environment.state = __crino_environment_states.stopped
	stopped_environments[#stopped_environments+1] = environment
	return true
end


---@param environment crinoEnvironment
---@param pause_ticks integer # 1 by default
---@return boolean
Crino.pause_environment = function(environment, pause_ticks)
	if environment.compilation_error_message or environment.runtime_error_message then
		return false
	end

	pause_ticks = pause_ticks or 1
	local state = environment.state
	if state == __crino_environment_states.active then
		Crino.remove_from_running_environments(environment)
		environment.pause_ticks = pause_ticks
		paused_environments[#paused_environments+1] = environment
		environment.state = __crino_environment_states.paused
	elseif state == __crino_environment_states.stopped or state == __crino_environment_states.paused then
		environment.pause_ticks = pause_ticks
	else
		return false
	end

	return true
end


---@param environment crinoEnvironment
Crino.delete_environment = function(environment)
	local state = environment.state
	if state == __crino_environment_states.active then
		Crino.remove_from_running_environments(environment)
	elseif state == __crino_environment_states.stopped then
		Crino.remove_from_stopped_environments(environment)
	elseif state == __crino_environment_states.paused then
		Crino.remove_from_paused_environments(environment)
	end
	environment.state = __crino_environment_states.removed
	Crino.environment_instructions_reference[environment.id] = nil
end
Crino.remove_environment = Crino.delete_environment


---@param line string
---@param character string
---@param start_index integer
---@return boolean, string?, integer? #is valid, character, last index
local function __find_string_2nd_part(line, character, start_index)
	local _, last_i, backlashes = string.find(line, '(\\*)' .. character, start_index)
	if not last_i then
		return false
	end

	if backlashes and #backlashes % 2 ~= 0 then
		return __find_string_2nd_part(line, character, last_i+1)
	end

	return true, character, last_i
end


-- Perpaps, it should be in different place...
local __string_delimeters = {
	["'"]   = "'",
	["\""]  = "\""
}
local __spec_string_delimeters = {
	["「"]  = "」", -- for Chinese Simplified language
	["﹁"]  = "﹂", -- for Chinese Simplified language
	["《"]  = "》", -- for Chinese Simplified language
	["«"]   = "»", -- for German language
	["『"]  = "』", -- for Japanese language
	["„"]   = "”", -- for several language
	["‚"]   = "‘", -- for several language
}
local __string_delimeter_expr = "(["
for k in pairs(__string_delimeters) do
	__string_delimeter_expr = __string_delimeter_expr .. k
end
for k in pairs(__spec_string_delimeters) do
	__string_delimeter_expr = __string_delimeter_expr .. k
end
__string_delimeter_expr = __string_delimeter_expr .. "])"
---@param line string
---@param start_index integer?
---@return boolean, integer?, integer?, integer?, integer? #is valid, first delimeter index, last delimeter index, first string index, last string index
local function __find_string_1st_part(line, start_index)
	local first_i, last_i, string_delimeter1 = string.find(line, __string_delimeter_expr, start_index)
	if first_i == nil then
		return true
	end

	local string_delimeter2 = __string_delimeters[string_delimeter1]
	if string_delimeter2 == nil then
		for k, v in pairs(__spec_string_delimeters) do
			local temp_first_i = string.find(line, k, first_i)
			if temp_first_i == first_i then
				string_delimeter1 = k
				string_delimeter2 = v
				break
			end
		end
	end

	local is_valid, _, end_i = __find_string_2nd_part(line, string_delimeter2, first_i+1)
	return is_valid, last_i, end_i, last_i + #string_delimeter1, end_i - #string_delimeter2
end


---@param rules crinoRules
---@param word string
---@return crinoElement
local function __check_word(rules, word)
	local predefined_element = __predefined_elements[word] or rules.predefined_elements[word]
	if predefined_element then
		return predefined_element
	end

	if tonumber(word) then
		return {
			type = __crinoTypes.number,
			value = word
		}
	end

	local func_data = rules.allowed_functions[word]
	if func_data then
		return {
			type = __crinoTypes["function"],
			value = func_data
		}
	end

	local func_data2 = Crino.functions_to_original[word]
	if func_data2 then
		return {
			type = __crinoTypes["function"],
			value = func_data2
		}
	end

	return {
		type = __crinoTypes.unidentified,
		value = word
	}
end


---@param rules crinoRules
---@param line string
---@return crinoElement[], string? #error message
local function __parse_words(rules, line)
	local elements
	for word in line:gmatch("%S+") do
		local first_character = string.sub(word, 1, 2)
		if first_character == "--" then -- if a comment
			break
		end

		elements = elements or {nil}
		if tonumber(word) then
			elements[#elements+1] = {
				type = __crinoTypes.number,
				value = word
			}
		else
			local predef_elem = __predefined_elements[word]
			if predef_elem then
				elements[#elements+1] = predef_elem
			elseif #word == 1 then
				elements[#elements+1] = {
					type = __crinoTypes.unidentified,
					value = word
				}
			else
				local last_usual_chacacter_index = 0
				while true do
					local start_spec_character_i, end_special_character_i, special_characters = string.find(word, "([(){}%[%]*+%-,、/%%&^$@\\|/!@~=><《》‚‘«»„”﹁﹂「」『』%.。:;]+)", last_usual_chacacter_index)
					if special_characters == nil then
						if last_usual_chacacter_index <= #word then
							local last_type = elements[#elements]
							last_type = last_type and last_type.type
							if last_type and (last_type == __crinoTypes.dot or last_type == __crinoTypes.colon)
								and not tonumber(string.sub(word, last_usual_chacacter_index, last_usual_chacacter_index))
							then
								local prefix = (last_type == __crinoTypes.dot and ".") or ":"
								elements[#elements] = {
									type = __crinoTypes.general_data,
									value = prefix .. string.sub(word, last_usual_chacacter_index, #word)
								}
							else
								local elem = __check_word(rules, string.sub(word, last_usual_chacacter_index, #word))
								elements[#elements+1] = elem
								last_usual_chacacter_index = #word
							end
						end
						break
					else
						-- Find usual characters before special_characters
						local end_usual_character_i = start_spec_character_i - 1
						if end_usual_character_i ~= 0 and last_usual_chacacter_index <= end_usual_character_i then
							local last_type = elements[#elements]
							last_type = last_type and last_type.type
							if last_type and (last_type == __crinoTypes.dot or last_type == __crinoTypes.colon)
								and not tonumber(string.sub(word, last_usual_chacacter_index, last_usual_chacacter_index))
							then
								local prefix = (last_type == __crinoTypes.dot and ".") or ":"
								local next_spec_character_i = string.find(word, "([(){}%[%]*+%-,、/%%&^$@\\|/!@~=><《》‚‘«»„”﹁﹂「」『』%.。:;]+)", last_usual_chacacter_index)
								next_spec_character_i = (next_spec_character_i and (next_spec_character_i - 1))
								elements[#elements] = {
									type = __crinoTypes.general_data,
									value = prefix .. string.sub(word, last_usual_chacacter_index, next_spec_character_i or #word)
								}
							else
								local usual_characters = string.sub(word, last_usual_chacacter_index, start_spec_character_i - 1)
								local elem = __check_word(rules, usual_characters)
								elements[#elements+1] = elem
							end
						end
						last_usual_chacacter_index = end_special_character_i + 1

						predef_elem = __predefined_elements[special_characters]
						if predef_elem then
							elements[#elements+1] = predef_elem
						elseif #special_characters == 1 then
							return elements, string.format("Unidentified character \"%s\"", special_characters)
						else
							local last_special_chacacter_index = 0
							-- Probably, I should change it
							if #special_characters >= 3 then
								local complex_characters = string.sub(special_characters, 1, 3)
								predef_elem = __predefined_elements[complex_characters]
								if predef_elem then
									elements[#elements+1] = predef_elem
									last_special_chacacter_index = 4
								end
							end

							while true do
								local start_special_character2_i, end_special_character2_i, special_character = string.find(special_characters, "([(){}%[%]*+%-,、/%%&^$@\\|/!@~=><《》‚‘«»„”﹁﹂「」『』%.。:;]+)", last_special_chacacter_index)
								if start_special_character2_i == nil then
									break
								else
									predef_elem = __predefined_elements[special_character]
									if predef_elem then
										elements[#elements+1] = predef_elem
										local end_sub_special_character_index = #special_characters
										if end_sub_special_character_index ~= end_special_character2_i then
											end_sub_special_character_index = end_special_character2_i - 1
										end
										if start_special_character2_i > end_sub_special_character_index then
											local _characters = string.sub(special_characters, start_special_character2_i, end_sub_special_character_index)
											_predef_elem = __predefined_elements[_characters]
											if _predef_elem then
												elements[#elements+1] = _predef_elem
											else
												return elements, string.format("Unidentified characters \"%s\"", _characters)
											end
										end
									else
										-- Perhaps, I should change it because of complex_assignment
										local character_i = 0
										repeat
											character_i = character_i + 1
											predef_elem = __predefined_elements[string.sub(special_character, character_i, character_i+1)]
											if predef_elem then
												character_i = character_i + 1
												elements[#elements+1] = predef_elem
											else
												local _characters = string.sub(special_character, character_i, character_i)
												predef_elem = __predefined_elements[_characters]
												if predef_elem then
													elements[#elements+1] = predef_elem
												else
													return elements, string.format("Unidentified characters \"%s\"", _characters)
												end
											end
										until (character_i >= #special_character)
									end
									last_special_chacacter_index = end_special_character2_i + 1
								end
							end
						end
					end
				end
			end
		end
	end

	return elements
end


local __action_types = {
	unknown = 1,
	assignment = 2,
	call = 3,
	special = 4,
	["while"] = 5,
	["end"] = 6,
	["for"] = 7,
	["if"] = 8,
	["elseif"] = 9,
	["else"] = 10,
	["repeat"] = 11,
}
local __assignment_data = {
	is_assigned = false,
	has_value = false
}
local __for_data = {
	is_assigned = false,
	expr_id = 0
}
---@param environment crinoEnvironment
---@return function[]?, string? #instructions for crinoEnvironment, error message
local function __to_lua(environment, all_elements)
	---#region for generated functions
	_E = environment
	_V = environment.variables
	_CCF = Crino.custom_funcs
	_HV = Crino.hidden_variables
	---#endregion
	local loadstring = loadstring or load
	local all_levels = {nil}
	environment.instructions_to_line = {nil}
	local instructions_to_line = environment.instructions_to_line
	local environment_instructions = {}
	local instruction = ""
	local levels = {nil}
	local breaks = {}
	local continues = {}
	local gotos = {}
	local if_levels = {nil, nil, nil}
	local action_type = __action_types.unknown
	local open_square_brackets = 0
	local open_curly_brackets = 0
	local open_round_brackets = 0
	local variables_count = 0
	local last_element_type = 0
	local is_end_action = true
	local init_line_number = nil
	local skip_left_round_bracket = false
	local is_table = false
	local check_brackets_for_table_function = false
	local rules = Crino.rules_groups[environment.rules_level]
	local left_unique_funcs = rules.max_unique_functions_per_action
	local left_elements_per_action = rules.max_elements_per_action

	local last_variable_id = 0
	---@type table<string, crinoElement>
	local variable_map = {}
	---@param element crinoElement
	---@return element crinoElement
	local function convert_to_variable(element)
		local name = element.value
		local data = variable_map[name]
		if data == nil then
			last_variable_id = last_variable_id + 1
			data = {
				type = __crinoTypes.variable,
				value = last_variable_id
			}
			variable_map[name] = data
		end
		return data
	end

	for i = 1, #all_elements do
		local line_elements = all_elements[i]
		local first_element = line_elements[1]
		local first_type = first_element.type
		if is_end_action and #line_elements == 2 and first_type == __crinoTypes.unidentified then
			first_element = convert_to_variable(first_element)
			line_elements[1] = first_element
			local second_element = line_elements[2]
			if second_element.type ~= __crinoTypes.short_operators then
				environment.error_line = line_elements.line_number
				return nil, "Incorrect use of short operators at line " .. line_elements.line_number
			end
			instruction = _short_operators[second_element.value](first_element.value)
			local instruction_id = #environment_instructions+1
			instruction = string.format("local S,M,CCF,HV=_E,_V,_CCF,_HV\nreturn function()\n%s\nS._ni=%d\nend", instruction, instruction_id+1)
			environment_instructions[instruction_id] = loadstring(instruction)()
			instructions_to_line[instruction_id] = init_line_number
			instruction = ""
		else
			if is_end_action then
				if check_brackets_for_table_function then
					environment.error_line = init_line_number
					return nil, "Expected \"(\" after function"
				elseif left_elements_per_action < 0 then
					environment.error_line = init_line_number
					return nil, string.format("Max elements per action is %d", rules.max_elements_per_action)
				end
				left_elements_per_action = rules.max_elements_per_action

				init_line_number = line_elements.line_number
				if first_type == __crinoTypes["elseif"] then
					action_type = __action_types["elseif"]
					local last_if_level = if_levels[#if_levels]
					if last_if_level == nil then
						environment.error_line = line_elements.line_number
						return nil, "Missing \"if\" for \"elseif\" at line " .. line_elements.line_number
					end
					local elseifs = last_if_level.elseifs
					local instruction_id = #environment_instructions+1
					environment_instructions[instruction_id] = true
					instructions_to_line[instruction_id] = true
					instruction_id = instruction_id+1
					environment_instructions[instruction_id] = true
					instructions_to_line[instruction_id] = init_line_number
					elseifs[#elseifs+1] = {start=#environment_instructions, instruction=nil}
				elseif first_type == __crinoTypes["if"] then
					local instruction_id = #environment_instructions+1
					environment_instructions[instruction_id] = true
					instructions_to_line[instruction_id] = init_line_number
					action_type = __action_types["if"]
					local if_level = {
						start = #environment_instructions, --["end"] = nil,
						level = levels[#levels],
						elseifs = {},
						instruction = nil,
						else_id = nil
					}
					if_levels[#if_levels+1] = if_level
				elseif first_type == __crinoTypes["else"] then
					local last_if_level = if_levels[#if_levels]
					if last_if_level == nil then
						environment.error_line = line_elements.line_number
						return nil, "Missing \"if\" for \"elseif\" at line " .. line_elements.line_number
					end
					if #line_elements > 1 then
						local next_element = line_elements[2]
						if next_element.type == __crinoTypes["if"] then
							action_type = __action_types["elseif"]
							local elseifs = last_if_level.elseifs
							local instruction_id = #environment_instructions+1
							environment_instructions[instruction_id] = true
							instructions_to_line[instruction_id] = true
							instruction_id = instruction_id+1
							environment_instructions[instruction_id] = true
							instructions_to_line[instruction_id] = init_line_number
							elseifs[#elseifs+1] = {start=#environment_instructions, instruction=nil}
						else
							environment.error_line = line_elements.line_number
							return nil, "Excessive expression after \"else\" at line " .. line_elements.line_number
						end
					else
						action_type = __action_types["else"]

						local instruction_id = #environment_instructions+1
						environment_instructions[instruction_id] = true
					end
				elseif first_type == __crinoTypes["while"] then
					action_type = __action_types["while"]
					local level = {type = __action_types["while"], start = #environment_instructions+1, ["end"] = nil, instruction = nil}
					all_levels[#all_levels+1] = level
					levels[#levels+1] = level
				elseif first_type == __crinoTypes["repeat"] then
					action_type = __action_types["repeat"]
					local level = {type = __action_types["repeat"], start = #environment_instructions+1}
					all_levels[#all_levels+1] = level
					levels[#levels+1] = level
					if #line_elements > 1 then
						environment.error_line = line_elements.line_number
						return nil, "\"repeat\" doesn't support any additional actions, error at line " .. line_elements.line_number
					end
				elseif first_type == __crinoTypes["until"] then
					action_type = __action_types["repeat"]
					if #line_elements == 1 then
						environment.error_line = line_elements.line_number
						return nil, "Expected expression after \"until\" at line " .. line_elements.line_number
					end
				elseif first_type == __crinoTypes["end"] then
					local last_level = levels[#levels]
					local last_if_level = if_levels[#if_levels]
					if last_if_level and last_level == last_if_level.level then
						-- TODO: recheck
					elseif last_if_level == nil and last_level == nil then
						environment.error_line = line_elements.line_number
						return nil, "\"end\" does nothing at line " .. line_elements.line_number
					elseif #line_elements > 1 then
						environment.error_line = line_elements.line_number
						return nil, "\"end\" doesn't support any additional actions, error at line " .. line_elements.line_number
					else
						last_level["end"] = #environment_instructions + 1
					end
					action_type = __action_types.special
				elseif first_type == __crinoTypes["break"] then
					action_type = __action_types.special
					if #line_elements > 1 then
						environment.error_line = line_elements.line_number
						return nil, "\"break\" doesn't support any additional actions, error at line " .. line_elements.line_number
					end
				elseif first_type == __crinoTypes["continue"] then
					action_type = __action_types.special
					-- TODO: improve, accept `;`
					if #line_elements > 1 then
						environment.error_line = line_elements.line_number
						return nil, "\"continue\" doesn't support any additional actions, error at line " .. line_elements.line_number
					end
				elseif first_type == __crinoTypes.unidentified then
					action_type = __action_types.assignment
				elseif first_type == __crinoTypes["function"] then
					action_type = __action_types.call
				elseif first_type == __crinoTypes["for"] then
					action_type = __action_types["for"]
					local level = {
						type = __action_types["for"],
						start = #environment_instructions+2, -- Complex instruction with one more instruction
						["end"] = nil,
						mem1 = nil, mem2 = nil, mem3 = nil,
						has_in = false, func_name = nil, is_func_assigned = false,
						expr1 = nil, expr2 = nil, expr3 = nil, instruction_id = nil
					}
					all_levels[#all_levels+1] = level
					levels[#levels+1] = level
				end
				is_table = false
			end

			for j = 1, #line_elements do
				left_elements_per_action = left_elements_per_action - #line_elements
				local element = line_elements[j]
				local element_type = element.type
				if skip_left_round_bracket then
					if element_type ~= __crinoTypes.left_round_bracket then
						environment.error_line = line_elements.line_number
						return nil, "There's no \"(\" after function at line " .. line_elements.line_number -- TODO: improve
					end
					last_element_type = element_type
					skip_left_round_bracket = false
					local next_element = line_elements[j+1]
					if next_element == nil then
						local next_line_elements = line_elements[j+1]
						if next_line_elements then
							next_element = next_line_elements[1]
						end
					elseif next_element.type == __crinoTypes.right_round_bracket then
						--TODO: optimize
						instruction = string.sub(instruction, 1, #instruction-1)
					end
				else
					if element.is_bracket then
						if action_type == __action_types.unknown then
							environment.error_line = line_elements.line_number
							return nil, "Undetermined use of brackets at line " .. line_elements.line_number
						end

						if check_brackets_for_table_function then
							if not (element_type == __crinoTypes.left_curly_bracket or
								element_type == __crinoTypes.left_round_bracket)
							then
								return nil, "\"(\" is necessary after function at line" .. line_elements.line_number -- TOOD: improve
							end
							check_brackets_for_table_function = false
						end

						if element_type == __crinoTypes.left_curly_bracket then
							open_curly_brackets = open_curly_brackets + 1
							is_table = true
							if action_type == __action_types.assignment then
								if __assignment_data.is_assigned == false then
									return nil, "Assignment operator is necessary at line " .. line_elements.line_number
								end
								__assignment_data.has_value = true
							end
						elseif element_type == __crinoTypes.right_curly_bracket then
							open_curly_brackets = open_curly_brackets - 1
							if open_curly_brackets < 0 then
								environment.error_line = line_elements.line_number
								local __error_message = "Incrorrent amount of \"}\""
								if line_elements.line_number == init_line_number then
									return nil, __error_message .. " at line " .. init_line_number
								else
									return nil, __error_message .. " from line " .. init_line_number .. " to " .. line_elements.line_number
								end
							elseif open_curly_brackets == 0 then
								is_table = false
							end
						elseif element_type == __crinoTypes.left_round_bracket then
							open_round_brackets = open_round_brackets + 1
							if action_type == __action_types["for"] then
								local last_level = levels[#levels]
								if last_level.func_name then
									if open_curly_brackets > 1 then
										environment.error_line = line_elements.line_number
										local __error_message = "Incrorrent amount of \"(\""
										if line_elements.line_number == init_line_number then
											return nil, __error_message .. " at line " .. init_line_number
										else
											return nil, __error_message .. " from line " .. init_line_number .. " to " .. line_elements.line_number
										end
									end
								end
							end
						elseif element_type == __crinoTypes.right_round_bracket then
							open_round_brackets = open_round_brackets - 1
							if action_type == __action_types["for"] then
								local last_level = levels[#levels]
								if not last_level.is_func_assigned and last_level.func_name then
									if open_curly_brackets == 0 then
										if not last_level.mem3 then
											environment.error_line = line_elements.line_number
											return nil, "Requires a variable at line " .. line_elements.line_number -- TODO: improve
										end
										last_level.expr1 = instruction .. string.format(")(M[%d],M[%d])", last_level.mem3, last_level.mem1)
										last_level.is_func_assigned = true
										element = nil
									end
								end
							elseif open_round_brackets < 0 then
								environment.error_line = line_elements.line_number
								local __error_message = "Incrorrent amount of \")\""
								if line_elements.line_number == init_line_number then
									return nil, __error_message .. " at line " .. init_line_number
								else
									return nil, __error_message .. " from line " .. init_line_number .. " to " .. line_elements.line_number
								end
							end
						elseif element_type == __crinoTypes.left_square_bracket then
							if last_element_type == __crinoTypes.left_square_bracket then
								environment.error_line = line_elements.line_number
								return nil, "Incrorrent expression \"[[\" at line " .. line_elements.line_number
							end
							open_square_brackets = open_square_brackets + 1
						elseif element_type == __crinoTypes.right_square_bracket then
							if last_element_type == __crinoTypes.left_square_bracket then
								environment.error_line = line_elements.line_number
								return nil, "Expected expression within \"[]\" at line " .. line_elements.line_number
							end
							open_square_brackets = open_square_brackets - 1
							if open_square_brackets < 0 then
								environment.error_line = line_elements.line_number
								local __error_message = "Incrorrent amount of \"]\""
								if line_elements.line_number == init_line_number then
									return nil, __error_message .. " at line " .. init_line_number
								else
									return nil, __error_message .. " from line " .. init_line_number .. " to " .. line_elements.line_number
								end
							end
						end
					elseif check_brackets_for_table_function then
						if element_type ~= __crinoTypes.general_data then
							environment.error_line = line_elements.line_number
							return nil, "Invalid data at line " .. line_elements.line_number -- TODO: improve
						end
					else
						-- TODO: optimize
						if element_type == __crinoTypes.unidentified then
							if not is_table then
								element = convert_to_variable(element)
								element_type = element.type
							else
								local prev_element = line_elements[j-1]
								if prev_element.type == __crinoTypes.assignment then
									element = convert_to_variable(element)
									element_type = element.type
								end
							end
						end

						if element_type == __crinoTypes.global_variables then
							check_brackets_for_table_function = true
							if __assignment_data.is_assigned then
								__assignment_data.has_value = true
							end
							if element.is_unique then
								left_unique_funcs = left_unique_funcs - 1
								-- TODO: perhaps, I should refactor it
								if left_unique_funcs < 0 then
									environment.error_line = line_elements.line_number
									return nil, "Too many unique functions at line " .. line_elements.line_number
								end
							end
						elseif element_type == __crinoTypes.assignment then
							if is_table then
								if action_type == __action_types.unknown then
									environment.error_line = line_elements.line_number
									return nil, "Incorrect use of assignment at line " .. line_elements.line_number
								end
							else
								if action_type == __action_types.assignment then
									if __assignment_data.is_assigned then
										-- TODO: recheck, perhaps it could refer to a wrong line.
										environment.error_line = line_elements.line_number
										return nil, "There's no assignment at line " .. line_elements.line_number
									end
									__assignment_data.is_assigned = true
								elseif action_type == __action_types["for"] then
									local last_level = levels[#levels]
									if last_element_type ~= __crinoTypes.variable then
										environment.error_line = line_elements.line_number
										return nil, "Incorrect expression at line " .. line_elements.line_number -- TODO: improve
									elseif __for_data.is_assigned then
										-- TODO: Recheck, perhaps, it could cause problems
										environment.error_line = line_elements.line_number
										return nil, "Only one assignment is allowed at line " .. line_elements.line_number
									elseif last_level.mem1 == nil then
										environment.error_line = line_elements.line_number
										return nil, "Missing a variable in \"for\" at line " .. line_elements.line_number
									end
									__for_data.is_assigned = true
								else
									environment.error_line = line_elements.line_number
									return nil, "Unexpected action type at line " .. line_elements.line_number
								end
							end
						elseif element_type == __crinoTypes.variable then
							variables_count = variables_count + 1
							if __assignment_data.is_assigned then
								__assignment_data.has_value = true
							elseif action_type == __action_types["for"] then
								local last_level = levels[#levels]
								if last_element_type == __crinoTypes["for"] then
									last_level.mem1 = element.value
								elseif last_level.mem1 and not last_level.has_in then
									if last_level.mem2 then
										-- TODO: allow this, refactor!
										environment.error_line = line_elements.line_number
										return nil, "Complex expression after a comma in \"for\" isn't allowed yet, error at line " .. line_elements.line_number
									end
									last_level.mem2 = element.value
								elseif last_level.has_in and not last_level.mem3 then
									last_level.mem3 = element.value
								end
							end
						elseif element_type == __crinoTypes["function"] then
							local next_element = line_elements[j+1]
							local is_new_element = false
							if next_element and next_element.type == __crinoTypes.assignment then
								if is_table then
									element = {
										type = __crinoTypes.unidentified,
										value = element.value.func_name
									}
									is_new_element = true
								else
									-- TODO: recheck and improve description
									environment.error_line = line_elements.line_number
									return nil, "Unexpected case for functions at line " .. line_elements.line_number
								end
							end

							if is_new_element == false then
								if next_element == nil then
									environment.error_line = line_elements.line_number
									return nil, "Expected expression after a function at line " .. line_elements.line_number
								elseif next_element.type ~= __crinoTypes.left_round_bracket then
									environment.error_line = line_elements.line_number
									return nil, "Expected \"(\" after a function at line " .. line_elements.line_number
								end

								if __assignment_data.is_assigned then
									__assignment_data.has_value = true
								elseif action_type == __action_types["for"] then
									local last_level = levels[#levels]
									if not last_level.has_in then
										environment.error_line = line_elements.line_number
										return nil, "Expected \"in\" at line " .. line_elements.line_number
									elseif not last_level.func_name then
										local func_data = element.value
										if not func_data.is_custom_func then
											local func_name = func_data.func_name
											if func_name ~= "pairs" then -- WARNING: probably, it's wrong
												last_level.func_name = func_name
												if func_name == "ipairs" then -- WARNING: probably, it's wrong
													last_level.is_ipairs = true
												end
											end
										end
									end
								end

								local func_data = element.value
								if func_data.is_unique then
									left_unique_funcs = left_unique_funcs - 1
									-- TODO: perhaps, I should refactor it
									if left_unique_funcs < 0 then
										environment.error_line = line_elements.line_number
										return nil, "Too many unique functions at line " .. line_elements.line_number
									end
								end
								if func_data.is_custom_func then
									open_round_brackets = open_round_brackets + 1
									skip_left_round_bracket = true
								end
							end
						elseif element_type == __crinoTypes.number then
							if __assignment_data.is_assigned then
								__assignment_data.has_value = true
							end
						elseif element_type == __crinoTypes.string then
							if __assignment_data.is_assigned then
								__assignment_data.has_value = true
							end
						elseif element_type == __crinoTypes.boolean then
							if __assignment_data.is_assigned then
								__assignment_data.has_value = true
							end
						elseif element_type == __crinoTypes["nil"] then
							if __assignment_data.is_assigned then
								__assignment_data.has_value = true
							end
						elseif element_type == __crinoTypes.end_of_action then
							if not is_end_action then
								environment.error_line = line_elements.line_number
								return nil, "Previous expression wasn't finished before \";\", error at line" .. line_elements.line_number
							end
							local next_element = line_elements[j+1]
							if next_element and
								not (next_element.type ~= __crinoTypes["then"] or next_element.type ~= __crinoTypes["do"])
							then
								environment.error_line = line_elements.line_number
								return nil, "Invalid next element after \";\" at line " .. line_elements.line_number
							end
						elseif element_type == __crinoTypes.comma then
							if action_type == __action_types["for"] then
								if not is_end_action then
									environment.error_line = line_elements.line_number
									return nil, "Wrong use of comma at line " .. line_elements.line_number -- TODO: improve
								end

								local last_level = levels[#levels]
								local expr_id = __for_data.expr_id
								if expr_id == 0 then
									if not __for_data.is_assigned then
										-- TODO: reheck, perhaps pointless
										if last_element_type ~= __crinoTypes.variable then
											environment.error_line = line_elements.line_number
											return nil, "Last element isn't a variable at line " .. line_elements.line_number -- TODO: improve
										end
									elseif not last_level.mem1 then
										environment.error_line = line_elements.line_number
										return nil, "Missing first variable at line " .. line_elements.line_number -- TODO: improve
									else
										last_level.expr1 = instruction
										__for_data.expr_id = 1
										instruction = ""
									end
								elseif expr_id == 1 then
									last_level.expr2 = instruction
									__for_data.expr_id = 2
									instruction = ""
								else
									environment.error_line = line_elements.line_number
									return nil, "Wrong expression at line " .. line_elements.line_number -- TODO: improve
								end
								last_element_type = element_type
								element = nil
							end
						elseif element_type ==  __crinoTypes["for"] then
							if action_type ~= __action_types["for"] or last_element_type ~= 0 then
								environment.error_line = line_elements.line_number
								return nil, "Loop keywords must be as a first element of line, error at line " .. line_elements.line_number
							end
						elseif element_type == __crinoTypes["goto"] then
							local instruction_id = #environment_instructions+1
							environment_instructions[instruction_id] = true
							instructions_to_line[instruction_id] = init_line_number
							element.instruction_id = instruction_id
							gotos[#gotos+1] = element
						elseif element_type == __crinoTypes.complex_assignment then
							if action_type ~= __action_types.assignment then
								environment.error_line = line_elements.line_number
								return nil, "Expected assignment action at line " .. line_elements.line_number
							elseif j ~= 2 then
								environment.error_line = line_elements.line_number
								return nil, "Expected complex assignment as 2nd element at line " .. line_elements.line_number
							end
							__assignment_data.is_assigned = true
							instruction = instruction .. "=" .. instruction .. element.value
							element = nil
						elseif element_type == __crinoTypes["in"] then
							local last_level = levels[#levels]
							if action_type ~= __action_types["for"] then
								environment.error_line = line_elements.line_number
								return nil, string.format("\"in\" at line %d is allowed only in loops", line_elements.line_number)
							elseif last_level.mem1 == nil then
								environment.error_line = line_elements.line_number
								return nil, "Key isn't a variable at line " .. line_elements.line_number
							elseif last_level.expr2 then
								environment.error_line = line_elements.line_number
								return nil, "Not full expression at line " .. line_elements.line_number
							elseif last_level.has_in then
								environment.error_line = line_elements.line_number
								return nil, "There's no \"in\" at line " .. line_elements.line_number
							elseif last_element_type ~= __crinoTypes.variable then
								environment.error_line = line_elements.line_number
								return nil, "Missing variable at line " .. line_elements.line_number -- TODO: improve
							end
							last_level.has_in = true
							instruction = ""
						end
					end

					if element then
						local converter = __converters[element_type]
						if converter then
							instruction = instruction .. __converters[element_type](element)
						end

						-- Perhaps, it should be in another place
						if open_curly_brackets == 0 and open_round_brackets == 0 and open_square_brackets == 0 then
							is_end_action = true
						else
							is_end_action = false
						end

						last_element_type = element.type
					end
				end
			end

			if last_element_type == __crinoTypes.basic_operator then
				is_end_action = false
			end

			if is_end_action then
				if last_element_type == __crinoTypes.concatenation then
					is_end_action = false
				else
					local full_instruction = "local S,M,CCF,HV=_E,_V,_CCF,_HV\nreturn function()\n"
					if action_type == __action_types["while"] then
						local last_level = levels[#levels]
						local instruction_id = #environment_instructions + 1
						environment_instructions[instruction_id] = true
						instructions_to_line[instruction_id] = init_line_number
						last_level.instruction = instruction
						last_level.instruction_id = #environment_instructions
					elseif action_type == __action_types.special then
						if last_element_type == __crinoTypes["end"] then
							local last_if_level = if_levels[#if_levels]
							local last_level = levels[#levels]
							if last_if_level and last_if_level.level == last_level then
								local loop_id
								if last_level then
									-- Optimize?
									if #if_levels > 1 then
										local is_loop_end = true
										local if_level_id = #if_levels
										local line_id = i+1
										while if_level_id > 0 do
											if last_if_level.level ~= if_levels[if_level_id].level then
												break
											end
											local next_element2 = all_elements[line_id]
											next_element2 = next_element2 and next_element2[1]
											if next_element2 == nil or (next_element2.type ~= __crinoTypes["end"]) then
												is_loop_end = false
												break
											end
											if_level_id = if_level_id - 1
											line_id = line_id + 1
										end
										if is_loop_end then
											loop_id = levels[#levels].start
										end
									else
										local next_element2 = all_elements[i+1]
										next_element2 = next_element2 and next_element2[1]
										if next_element2 and (next_element2.type == __crinoTypes["end"]) then
											loop_id = levels[#levels].start
										end
									end
								end

								local elseifs = last_if_level.elseifs
								local false_instruction_id
								local else_id = last_if_level.else_id
								if #elseifs > 0 then
									false_instruction_id = elseifs[1].start
								elseif else_id then
									false_instruction_id = else_id
								else
									false_instruction_id = loop_id or #environment_instructions+1
								end
								local _instruction = string.format(
									"local S,M,CCF,HV=_E,_V,_CCF,_HV\nreturn function()\nif %s then\nS._ni=%d\nelse\nS._ni=%d\nend\nend",
									last_if_level.instruction, last_if_level.start+1, false_instruction_id
								)
								local f, error_message = loadstring(_instruction)
								if f then environment_instructions[last_if_level.start] = f()
								else
									environment.error_line = init_line_number
									return nil, error_message
								end

								if #elseifs > 0 then
									local prev_elseif
									local end_id = loop_id or (#environment_instructions+1)
									for i2 = 1, #elseifs do
										local _elseif = elseifs[i2]
										if prev_elseif then
											local _instruction = string.format(
												"local S,M,CCF,HV=_E,_V,_CCF,_HV\nreturn function()\nS._ni=%d\nend",
												end_id
											)
											local instruction_id = prev_elseif.start-1
											environment_instructions[instruction_id] = loadstring(_instruction)()
											instructions_to_line[instruction_id] = init_line_number

											_instruction = string.format(
												"local S,M,CCF,HV=_E,_V,_CCF,_HV\nreturn function()\nif %s then\nS._ni=%d\nelse\nS._ni=%d\nend\nend",
												prev_elseif.instruction, prev_elseif.start+1, end_id
											)
											local f, error_message = loadstring(_instruction)
											if f then environment_instructions[prev_elseif.start] = f()
											else
												environment.error_line = init_line_number
												return nil, error_message
											end
										end

										prev_elseif = _elseif
									end

									end_id = else_id or loop_id or (#environment_instructions+1)
									prev_elseif = prev_elseif or elseifs[1]
									local _instruction = string.format(
										"local S,M,CCF,HV=_E,_V,_CCF,_HV\nreturn function()\nS._ni=%d\nend",
										end_id
									)
									local instruction_id = prev_elseif.start-1
									environment_instructions[instruction_id] = loadstring(_instruction)()
									instructions_to_line[instruction_id] = init_line_number

									_instruction = string.format(
										"local S,M,CCF,HV=_E,_V,_CCF,_HV\nreturn function()\nif %s then\nS._ni=%d\nelse\nS._ni=%d\nend\nend",
										prev_elseif.instruction, prev_elseif.start+1, end_id
									)
									local f, error_message = loadstring(_instruction)
									if f then environment_instructions[prev_elseif.start] = f()
									else
										environment.error_line = init_line_number
										return nil, error_message
									end

									local else_id = last_if_level.else_id
									if else_id then
										false_instruction_id = else_id
										local _instruction = string.format("local S,M,CCF,HV=_E,_V,_CCF,_HV\nreturn function()\nS._ni=%d\nend", #environment_instructions+1)
											environment_instructions[else_id-1] = loadstring(_instruction)()
											instructions_to_line[else_id-1] = init_line_number
									end
								else
									local false_instruction_id
									local else_id = last_if_level.else_id
									if else_id then
										false_instruction_id = else_id
										local _instruction = string.format("local S,M,CCF,HV=_E,_V,_CCF,_HV\nreturn function()\nS._ni=%d\nend", #environment_instructions+1)
											environment_instructions[else_id-1] = loadstring(_instruction)()
											instructions_to_line[else_id-1] = init_line_number
									elseif last_level then
										local loop_id
										if #if_levels > 1 then
											local is_loop_end = true
											local if_level_id = #if_levels
											local line_id = i+1
											while if_level_id > 0 do
												if last_if_level.level ~= if_levels[if_level_id].level then
													break
												end
												local next_element2 = all_elements[line_id]
												next_element2 = next_element2 and next_element2[1]
												if next_element2 == nil or (next_element2.type ~= __crinoTypes["end"]) then
													is_loop_end = false
													break
												end
												if_level_id = if_level_id - 1
												line_id = line_id + 1
											end
											if is_loop_end then
												loop_id = levels[#levels].start
											end
										else
											local next_element2 = all_elements[i+1]
											next_element2 = next_element2 and next_element2[1]
											if next_element2 and (next_element2.type == __crinoTypes["end"]) then
												loop_id = levels[#levels].start
											end
										end
										false_instruction_id = loop_id or #environment_instructions+1
									else
										false_instruction_id = #environment_instructions+1
									end
									full_instruction = full_instruction ..
										string.format(
											"if %s then\nS._ni=%d\nelse\nS._ni=%d\nend\nend",
											last_if_level.instruction, last_if_level.start+1, false_instruction_id
										)
									local f, error_message = loadstring(full_instruction)
									if f then environment_instructions[last_if_level.start] = f()
									else
										environment.error_line = init_line_number
										return nil, error_message
									end
								end
								if_levels[#if_levels] = nil
							else
								local last_type = last_level.type
								if last_type == __action_types["while"] then
									full_instruction = full_instruction .. "\nif " .. last_level.instruction .. " then\n" ..
										string.format("S._ni=%d\n", last_level.start+1) ..
										"else\n" .. string.format("S._ni=%d", last_level["end"]) .. "\nend\nend"
								elseif last_type == __action_types["for"] then
									if last_level.has_in then
										if last_level.is_ipairs then
											-- TODO: optimize
											local key_string = string.format("M[%d]", last_level.mem1)
											local instruction_id = last_level.instruction_id - 1
											local init_instruction = string.format("local S,M,CCF,HV=_E,_V,_CCF,_HV\nreturn function()\nM[%d]=1", last_level.mem1, instruction_id+1) ..
												"\nlocal v=" .. string.format("M[%d][1]", last_level.mem3) ..
												string.format("\nM[%d]=v", last_level.mem2) ..
												string.format("\nif v~=nil then\nS._ni=%d\nelse\nS._ni=%d\nend\nend" , last_level.start+1, last_level["end"])
											environment_instructions[instruction_id] = loadstring(init_instruction)()
											instructions_to_line[instruction_id] = init_line_number
											local f, error_message = loadstring(init_instruction)
											if f then environment_instructions[instruction_id] = loadstring(init_instruction)()
											else
												environment.error_line = init_line_number
												return nil, error_message
											end
											full_instruction = full_instruction .. "local k=" .. key_string .. "+1\n" ..
												"local v=" .. string.format("M[%d][k]", last_level.mem3) ..
												"\n" .. key_string .. "=k" ..
												string.format("\nM[%d]=v", last_level.mem2) ..
												string.format("\nif v~=nil then\nS._ni=%d\nelse\nS._ni=%d\nend\nend" , last_level.start+1, last_level["end"])
										else
											-- TODO: optimize
											local instruction_id = last_level.instruction_id - 1
											local init_instruction = full_instruction .. string.format("M[%d]=nil", last_level.mem1, instruction_id+1) ..
												"\nlocal k,v=" .. last_level.expr1 ..
												string.format("\nM[%d],M[%d]=k,v", last_level.mem1, last_level.mem2) ..
												string.format("\nif v~=nil then\nS._ni=%d\nelse\nS._ni=%d\nend\nend" , last_level.start+1, last_level["end"])
											local f, error_message = loadstring(init_instruction)
											if f then environment_instructions[instruction_id] = loadstring(init_instruction)()
											else
												environment.error_line = init_line_number
												return nil, error_message
											end
											instructions_to_line[instruction_id] = init_line_number
											full_instruction = full_instruction .. "local k,v=" .. last_level.expr1 ..
												string.format("\nM[%d],M[%d]=k,v", last_level.mem1, last_level.mem2) ..
												string.format("\nif v~=nil then\nS._ni=%d\nelse\nS._ni=%d\nend\nend" , last_level.start+1, last_level["end"])
										end
									elseif last_level.expr1 == nil or last_level.expr2 == nil then
										environment.error_line = init_line_number
										return nil, "Not full expression at line " .. init_line_number -- TODO: improve
									else
										local part1 = string.format("%s then\nS._ni=%d\nelse\nS._ni=%d\nend", last_level.expr2, last_level.start+1, last_level["end"])
										local init_instruction = "local S,M,CCF,HV=_E,_V,_CCF,_HV\nreturn function()\n" .. last_level.expr1 ..
											string.format("\nlocal _step=%s", last_level.expr3 or "1") ..
											"\nif _step < 0 then" ..
											string.format("\nif M[%d] >= %s", last_level.mem1, part1) ..
											"\nelse" .. string.format("if M[%d] <= %s", last_level.mem1, part1) .. "\nend"
										local f, error_message = loadstring(init_instruction)
										if f then
											local instruction_id = last_level.instruction_id - 1
											environment_instructions[instruction_id] = f()
											instructions_to_line[instruction_id] = init_line_number
										else
											environment.error_line = init_line_number
											return nil, error_message
										end

										full_instruction = full_instruction ..
											string.format("\nlocal _step=%s", last_level.expr3 or "1") ..
											string.format("\nM[%d]=M[%d]+_step", last_level.mem1, last_level.mem1) ..
											"\nif _step < 0 then" ..
											string.format("\nif M[%d] >= %s", last_level.mem1, part1) ..
											"\nelse" .. string.format("if M[%d] <= %s", last_level.mem1, part1) .. "\nend"
									end
								else
									environment.error_line = line_elements.line_number
									return nil, "Unknown action type at line " .. line_elements.line_number -- TODO: change, probably wrong description
								end
								levels[#levels] = nil
								local f, error_message = loadstring(full_instruction)
								if f then environment_instructions[last_level.instruction_id] = loadstring(full_instruction)()
								else
									environment.error_line = line_elements.line_number
									return nil, error_message
								end
							end
						elseif last_element_type == __crinoTypes["break"] then
							local instruction_id = #environment_instructions + 1
							environment_instructions[instruction_id] = true
							instructions_to_line[instruction_id] = init_line_number
							breaks[#breaks+1] = {
								instruction_id = #environment_instructions,
								level = levels[#levels]
							}
						elseif last_element_type == __crinoTypes["continue"] then
							local instruction_id = #environment_instructions+1
							environment_instructions[instruction_id] = true
							instructions_to_line[instruction_id] = init_line_number
							continues[#continues+1] = {
								instruction_id = instruction_id,
								level = levels[#levels]
							}
						end
					elseif action_type == __action_types["elseif"] then
						local last_if_level = if_levels[#if_levels]
						if last_if_level == nil then
							 -- TODO: recheck, perhaps, useless check
							environment.error_line = line_elements.line_number
							return nil, "Missing \"if\" for \"elseif\" at line " .. line_elements.line_number
						end
						if #instruction > 0 then
							local elseifs = last_if_level.elseifs
							elseifs[#elseifs].instruction = instruction
						end
					elseif action_type == __action_types["if"] then
						if #instruction > 0 then
							local last_if_level = if_levels[#if_levels]
							last_if_level.instruction = instruction
						end
					elseif action_type == __action_types["else"] then
						local last_if_level = if_levels[#if_levels]
						if last_if_level == nil then
							-- TODO: recheck, probably, useless check
							environment.error_line = init_line_number
							return nil, "Missing \"if\" for \"else\" at line " .. init_line_number
						end
						last_if_level.else_id = #environment_instructions+1
					elseif action_type == __action_types["for"] then
						local last_level = levels[#levels]
						if last_level.has_in then
							if not last_level.is_func_assigned then
								if last_level.mem3 == nil then
									environment.error_line = init_line_number
									return nil, "Missing variable at line " .. init_line_number -- TOOD: improve
								end
								last_level.expr1 = string.format("next(M[%d],M[%d])", last_level.mem3, last_level.mem1)
							end
							local instruction_id = #environment_instructions+1
							environment_instructions[instruction_id] = true
							instructions_to_line[instruction_id] = init_line_number
						else
							if __for_data.expr_id == 2 then
								if #instruction == 0 then
									environment.error_line = init_line_number
									return nil, "There's no expression for loop at line " .. init_line_number
								end
								last_level.expr3 = instruction
							elseif #instruction > 0 then
								if __for_data.expr_id == 1 then
									last_level.expr2 = instruction
								else
									environment.error_line = init_line_number
									return nil, "Invalid expression at line " .. init_line_number
								end
								last_level.expr3 = "1"
							end
							local instruction_id = #environment_instructions+1
							environment_instructions[instruction_id] = true
							instructions_to_line[instruction_id] = init_line_number
						end
						local instruction_id = #environment_instructions+1
						environment_instructions[instruction_id] = true
						instructions_to_line[instruction_id] = init_line_number
						last_level.instruction_id = #environment_instructions
						__for_data.is_assigned = false
						__for_data.expr_id = 0
					elseif action_type == __action_types["repeat"] then
						local last_level = levels[#levels]
						if first_type == __crinoTypes["until"] then
							if last_level.type ~= __action_types["repeat"] then
								environment.error_line = line_elements.line_number
								return nil, string.format("\"until\" at line %d should be used for \"repeat\"", line_elements.line_number)
							end
							local instruction_id = #environment_instructions+1
							local init_instruction = "local S,M,CCF,HV=_E,_V,_CCF,_HV\nreturn function()\n" ..
								string.format("if %s then\nS._ni=%d\nelse\nS._ni=%d", instruction, instruction_id+1, last_level.start)
								.. "\nend\nend"
							local f, error_message = loadstring(init_instruction)
							if f then
								local instruction_id = #environment_instructions+1
								environment_instructions[instruction_id] = f()
								instructions_to_line[instruction_id] = init_line_number
							else
								environment.error_line = init_line_number
								return nil, error_message
							end
							levels[#levels] = nil
						end
					else
						local last_level = levels[#levels]
						local last_if_level = if_levels[#if_levels]
						if action_type == __action_types.assignment then
							if __assignment_data.is_assigned == false then
								environment.error_line = init_line_number
								return nil, "There's no assignment at line " .. init_line_number
							elseif __assignment_data.has_value == false then
								environment.error_line = init_line_number
								return nil, "There's no value for assignment at line " .. init_line_number
							end
							__assignment_data.is_assigned = false
							__assignment_data.has_value = false
						end

						local next_element = all_elements[i+1]
						next_element = next_element and next_element[1]
						local next_instruction_id
						if next_element and next_element.type == __crinoTypes["end"] then
							if last_if_level and last_level == last_if_level.level then
								if last_level then
									local next_element2 = all_elements[i+1]
									next_element2 = next_element2 and next_element2[1]
									if next_element2 and (next_element2.type == __crinoTypes["end"]) then
										next_instruction_id = last_level.start
									else
										next_instruction_id = #environment_instructions+2
									end
								else
									next_instruction_id = #environment_instructions+2
								end
							elseif last_level then
								next_instruction_id = last_level.start
							elseif last_level == nil then
								next_instruction_id = #environment_instructions+2
							end
						else
							next_instruction_id = #environment_instructions+2
						end
						full_instruction = full_instruction .. instruction .. string.format("\nS._ni=%d\nend", next_instruction_id)
						local f, error_message = loadstring(full_instruction)
						if f then
							local instruction_id = #environment_instructions + 1
							environment_instructions[instruction_id] = f()
							instructions_to_line[instruction_id] = init_line_number
						else
							environment.error_line = init_line_number
							return nil, error_message
						end
					end
					left_unique_funcs = rules.max_unique_functions_per_action
					instruction = ""
					action_type = __action_types.unknown
					variables_count = 0
					last_element_type = 0
				end
			end
		end
	end

	if last_variable_id > rules.max_variables then
		return nil, "Too many variables, max amount is " .. rules.max_variables
	end

	if not is_end_action then
		environment.error_line = init_line_number
		return nil, "Expression expected at line " .. init_line_number
	end

	for i = 1, #breaks do
		local _break = breaks[i]
		if _break.level == nil then
			return nil, "\"break\" outside of loops at line " .. instructions_to_line[_break.instruction_id]
		end
		instruction = "local S,M,CCF,HV=_E,_V,_CCF,_HV\nreturn function()\n" .. string.format("S._ni=%d\n", _break.level["end"]) .. "end"
		environment_instructions[_break.instruction_id] = loadstring(instruction)()
	end

	for i = 1, #continues do
		local _continue = continues[i]
		if _continue.level == nil then
			return nil, "\"continue\" outside of loops at line " .. instructions_to_line[_continue.instruction_id]
		end
		instruction = "local S,M,CCF,HV=_E,_V,_CCF,_HV\nreturn function()\n" .. string.format("S._ni=%d\n", _continue.level.start) .. "end"
		environment_instructions[_continue.instruction_id] = loadstring(instruction)()
	end

	if #levels > 0 then
		environment.error_line = init_line_number
		return nil, "There are missing ending for loops"
	elseif #if_levels > 0 then
		environment.error_line = init_line_number
		return nil, "There are missing ending for ifs etc."
	end

	local labels = environment.labels
	for i=1, #gotos do
		local goto_data = gotos[i]
		local instruction_id = labels[goto_data.value]
		if instruction_id == nil then
			environment.error_line = init_line_number
			return nil, string.format("\"%s\" label doesn't exist", goto_data.value)
		end
		instruction = string.format("local S,M,CCF,HV=_E,_V,_CCF,_HV\nreturn function() S._ni=%d end", instruction_id)
		local f = loadstring(instruction)
		environment_instructions[goto_data.instruction_id] = f()
	end

	if #environment_instructions > 0 then
		local last_instruction_id = #environment_instructions
		local new_instruction_id = last_instruction_id+1
		instructions_to_line[new_instruction_id] = instructions_to_line[last_instruction_id]
		environment_instructions[new_instruction_id] = function()
			environment.is_finished = true
		end
	end

	return environment_instructions
end


---@param environment crinoEnvironment
---@param code string
---@return table<crinoElement[]>?, string? #elements, error_message
local function __indenity_elements(environment, code)
	local line_number = 0
	---@type table<crinoElement[]>
	local all_elements = {}
	local rules = Crino.rules_groups[environment.rules_level]
	local goto_expr = "^[^%S]*" .. (rules.goto_name or __goto_name) .. "[^%S]*"
	for line in code:gmatch("[^\r\n]+") do
		---@type crinoElement[]
		local line_elements
		line_number = line_number + 1
		if line_number > rules.max_code_lines then
			environment.error_line = line_number
			return nil, "Max lines is " .. rules.max_code_lines
		end

		local last_target_character_index = #line
		if last_target_character_index > rules.max_characters_in_line then
			environment.error_line = line_number
			return nil, "Max characters per line is " .. rules.max_code_lines
		end
		local end_parse_i
		local comment_index = string.find(line, '%-%-')
		if comment_index then
			comment_index = comment_index - 1
		end
		if comment_index == nil or comment_index ~= 1 then -- if not a comment
			local _, _, label = line:find("^[^%S]*::[^%S](%a+.*)[^%S]::[^%S]*$")
			if label then
				local labels = environment.labels
				if labels[label] == nil then
					labels[label] = line_number
				else
					environment.error_line = line_number
					return nil, "Label with name \"" .. label .. "\" already exists"
				end
			else
				line_elements = {nil}
				-- TODO: FIX comments
				local _, end_goto_i = line:find(goto_expr)
				if end_goto_i then
					if end_goto_i == #line then
						environment.error_line = line_number
						return nil, "Expected text after \"goto\" at line " .. line_number
					end
					line_elements[1] = {
						type = __crinoTypes["goto"],
						value = string.sub(line, end_goto_i+1, #line)
					}
				else
					repeat
						start_index = end_parse_i and (end_parse_i + 1) or 0
						local is_valid, first_delimiter_i, end_delimiter_i, first_string_i, end_string_i = __find_string_1st_part(line, start_index)
						if is_valid == false then
							environment.error_line = line_number
							return nil, string.format("Incorrent string at line %d", line_number)
						else
							local parse_line_end = comment_index or first_delimiter_i and (first_delimiter_i - 1) or last_target_character_index
							end_parse_i = comment_index or end_delimiter_i or last_target_character_index
							if first_delimiter_i and comment_index then
								if comment_index < first_delimiter_i then
									last_target_character_index = comment_index - 1
									--- WIP
									local elements, error_message = __parse_words(rules, string.sub(line, start_index, parse_line_end))
									if error_message then
										environment.error_line = line_number
										return nil, error_message .. " at line " .. line_number
									elseif elements then
										for i = 1, #elements do
											line_elements[#line_elements+1] = elements[i]
										end
									end
								end
								if comment_index >= first_delimiter_i and comment_index <= end_delimiter_i then
									comment_index = string.find(line, '#', end_delimiter_i+1)
									last_target_character_index = comment_index or last_target_character_index
								end
								local elements, error_message = __parse_words(rules, string.sub(line, start_index, parse_line_end))
								if error_message then
									environment.error_line = line_number
									return nil, error_message .. " at line " .. line_number
								elseif elements then
									for i = 1, #elements do
										line_elements[#line_elements+1] = elements[i]
									end
								end
								line_elements[#line_elements+1] = {
									type = __crinoTypes.string,
									value = string.sub(line, first_string_i, end_string_i)
								}
							elseif first_delimiter_i then
								local elements, error_message = __parse_words(rules, string.sub(line, start_index, parse_line_end))
								if error_message then
									environment.error_line = line_number
									return nil, error_message .. " at line " .. line_number
								elseif elements then
									for i = 1, #elements do
										line_elements[#line_elements+1] = elements[i]
									end
								end
								line_elements[#line_elements+1] = {
									type = __crinoTypes.string,
									value = string.sub(line, first_string_i, end_string_i)
								}
							else
								if comment_index then
									last_target_character_index = comment_index
								end
								local elements, error_message = __parse_words(rules, string.sub(line, start_index, end_parse_i))
								if error_message then
									environment.error_line = line_number
									return nil, error_message .. " at line " .. line_number
								elseif elements then
									for i = 1, #elements do
										line_elements[#line_elements+1] = elements[i]
									end
								end
							end
						end
					until (last_target_character_index == end_parse_i)
				end
				if #line_elements > 0 then
					line_elements.line_number = line_number
					all_elements[#all_elements+1] = line_elements
				end
			end
		end
	end

	return all_elements
end


---@param environment crinoEnvironment
---@param code string
---@return function[]?, string? #instructions for crinoEnvironment if there are no errors (see environment.compilation_error_message for error)
local function __compile(environment, code)
	local is_ok, all_elements, compilation_error_message = pcall(__indenity_elements, environment, code)
	if is_ok == false then
		---@cast all_elements string
		environment.compilation_error_message = all_elements
		return nil, all_elements
	elseif compilation_error_message then
		environment.compilation_error_message = compilation_error_message
		return nil, compilation_error_message
	end

	local is_ok, environment_instructions, compilation_error_message = pcall(__to_lua, environment, all_elements)
	--#region Reset local data
	__assignment_data.is_assigned = false
	__assignment_data.has_value = false
	__for_data.is_assigned = false
	__for_data.expr_id = 0
	--#endregion
	if is_ok == false then
		---@cast environment_instructions string
		environment.compilation_error_message = environment_instructions
		return nil, environment_instructions
	elseif compilation_error_message then
		environment.compilation_error_message = compilation_error_message
		return nil, compilation_error_message
	end

	if #environment_instructions == 0 then
		return nil, "There are no instructions"
	end

	if Crino.store_functions then
		environment.instructions = environment_instructions
	end

	return environment_instructions
end


---@param environment crinoEnvironment
---@param code string?
---@return function[]?
Crino.compile = function(environment, code)
	code = code or environment.code or ""
	environment.code = code

	environment._ni = 1
	environment.pause_ticks = 0
	environment.compilation_error_message = nil
	environment.runtime_error_message = nil
	environment.instructions = nil
	environment.instructions_to_line = nil
	--#region Reset variables
	local variables = environment.variables
	for k in pairs(variables) do
		variables[k] = nil
	end
	--#endregion
	local is_ok, environment_instructions, error_message = pcall(__compile, environment, code)
	if error_message then
		environment.compilation_error_message = error_message
		return
	end

	if is_ok then
		return environment_instructions
	end

	---@cast environment_instructions string
	environment.compilation_error_message = environment_instructions
end


---@param environment crinoEnvironment
---@return boolean
function Crino.activate_environment(environment)
	if environment.compilation_error_message then
		return false
	end

	local state = environment.state
	environment.is_finished = false
	if state ~= __crino_environment_states.active then
		if state == __crino_environment_states.paused then
			environment.pause_ticks = 0
			Crino.remove_from_paused_environments(environment)
		elseif state == __crino_environment_states.stopped then
			Crino.remove_from_stopped_environments(environment)
		else
			environment._ni = 1
		end
		running_environments[#running_environments+1] = environment
		environment.state = __crino_environment_states.active
	end
	return true
end


---@param environment crinoEnvironment
---@param error_message string
Crino._logHandler = function(environment, error_message)
end

Crino._crinoErrorHandler = function()
	print(debug.traceback())
end


local __environment, __p_i
local function step_running_environments()
	if Crino.store_functions then
		__p_i = #running_environments
		while running_environments[__p_i] do
			__environment = running_environments[__p_i]

			__environment.instructions[__environment._ni]()
			if __environment.is_finished then
				table.remove(running_environments, __p_i)
				--#region Reset variables
				local variables = __environment.variables
				for k in pairs(variables) do
					variables[k] = nil
				end
				--#endregion
			end
			__p_i = __p_i - 1
		end
	else
		local instructions_reference = Crino.environment_instructions_reference
		__p_i = #running_environments
		while running_environments[__p_i] do
			__environment = running_environments[__p_i]
			local instructions = instructions_reference[__environment.id]
			instructions[__environment._ni]()
			if __environment.is_finished then
				table.remove(running_environments, __p_i)
				--#region Reset variables
				local variables = __environment.variables
				for k in pairs(variables) do
					variables[k] = nil
				end
				--#endregion
			end
			__p_i = __p_i - 1
		end
	end
end


function Crino.step()
	__environment = nil
	__p_i = nil
	local is_ok, error_message = xpcall(step_running_environments, Crino._crinoErrorHandler)
	if is_ok == false then
		---@cast error_message string
		---@cast __environment crinoEnvironment
		__environment.runtime_error_message = error_message
		__environment.is_finished = true
		__environment.error_line = __environment.instructions_to_line[__environment._ni]
		Crino._logHandler(__environment, error_message)
		table.remove(running_environments, __p_i)
		stopped_environments[#stopped_environments+1] = __environment
		--#region Reset variables
		local variables = __environment.variables
		for k in pairs(variables) do
			variables[k] = nil
		end
		--#endregion
	end
	__environment = nil
	__p_i = nil

	for i = #paused_environments, 1, -1 do
		local environment = paused_environments[i]
		local pause_ticks = environment.pause_ticks - 1
		environment.pause_ticks = pause_ticks
		if pause_ticks <= 0 then
			table.remove(paused_environments, i)
			running_environments[#running_environments+1] = environment
		end
	end
end


return Crino
