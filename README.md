**[About](#about)** |
Some differences from Lua |
**[Status](#status)** |
**[Plans](#plans)** |
**[Notes](#notes)** |
**[Issues](#issues)** |
**[Localization](#localization)** |
**[Support](#support)** |
**[License](#license)**

---

# Please, read [Status](#status) section

# About

Crino is an open-source multilingual Domain Specific Language and library in pure Lua.\
Crino limits access to variables, functions and separating code into different instructions.\
Crino executes 1 instruction from all codes each tick by default.

* Lua compatibility - Library works under any Lua versions and in most environments. Crino doesn't try to be close to Lua syntax. But has some similarities with it;
* Minimal overhead on runtime - Compiled instructions almost efficient as hand-written Lua;
* Embeddable - Crino is a one-file library;
* Localizable - People are able to write code in their own native languages and not just English.
* Adaptable - Library provides interface for different cases, languages as "Crino rules". Each code can have different rules. Any keyword is overwritable in Crino via its Library.
* Safer - Crino prevents most abuse of application-layer DoS attacks from its users. However, better protection from data flood **isn't ready yet**.

# Some differences from Lua

Crino has more "loose" syntax rules.

* `then`, `do` are optional;
* There are operators like `++`, `+=`, `||`, `&&`, `..=` etc. by default;
* There are no difference between `elseif`, `else if` etc. in Crino;
* `;` does nothing in Crino;
* `continue`, `goto` works under any Lua version;
* `goto` and its labels can be used anywhere, but all labels must have unique names;
* Tables and variables can have any name;
* "Multi-actions" aren't allowed in one line (but restrictions on functions are determined by rules in the library);
* All variables are global;
* Crino string delimiters: `''`, `""`, `「」`, `﹁﹂`, `《》`, `«»`, `『』`, `„”`, `‚‘`;
* Crino doesn't support multi-line strings and multi-line comments;
* It's not possible to create new functions and metatable, metamethods stuff in Crino;
* Crino limits use of "unique" functions by Crino rules;
* It's not possible to affect functions via Crino code;
* Crino doesn't support some multi-actions in 1 line. For instance: you can't use `if` and `else` in the same line.

Short example:
```lua
local Crino = require("Crino")
local environment = Crino.create_environment()
Crino.compile(environment, [[
	print("S")
	num = 0
	repeat
		num++
		print(num)
	until num >= 3
	t = {9,8,7}
	for k, v in pairs(t) do
		print(k, v)
	end
	print()
	for k, v in t do
		print(k, v)
	end
	print()
	for k, v in ipairs(t) do
		print(k, v)
	end
	print()
	if true then
		num++
		print(num)
	else
		print("WHAT!")
	end
	for i=1, 3, -1 do
		print(i)
	end
	while true
		print("F")
		break
	end
]])
Crino.activate_environment(environment)
for _ = 1, 100 do
	Crino.step()
end
```

# Status

* Crino is under development and not fully ready yet;
* Crino isn't fully tested, there are important bugs;
* Documentation isn't ready;
* Expect changes to Crino;
* Library isn't fully ready yet;
* There are no examples yet, please read [plans](#plans).

# Plans

I'll provide examples in [Factorio](https://factorio.com/)/[minetest](https://www.minetest.net/) as a mod and library as soon as Crino is ready for use. After that, I'll provide more details about plans.

* Better protection from data flood. (HIGHLY IMPORTANT, manage it as you consider by yourself right now);
* New restrictions on string.rep;
* Remove additional instructions before `else` and `elseif`;
* Fix `i--`;
* Improve check of numbers;
* Converter between languages;
* Merged instructions in some cases.

# Notes

* It can take quite a lot of time to compile some code, so make sure it won't affect devices much, otherwise you should implement protection from spam attacks;
* If you are a Lua developer, then I highly recommend you to read http://lua-users.org/wiki/SandBoxes;
* I decided to publish it sooner, than later because of my current situation (I'd rather publish in a more stable state with more explanation and features);
* Crino doesn't create new Lua environments at the moment.

# Issues

Please, read [Status](#status) section.

* `goto` doesn't support comments;
* There's no localization for errors;
* There's no any protection against data flood **yet**;
* Empty blocks within loops and ifs etc. have quirky behaviors (it'll be fixed at some point);
* Complex expression after a comma in `for` causes errors (it'll be fixed at some point);
* Determination of data within tables should be improved (it's important).

# Localization

Some content were taken from https://babylscript.plom.dev/translations.html, some localization was provided by ZwerOxotnik and by hubert/Stefan#5336 in [Discord](https://discord.com/)

Did you notice any problems with the current translations? Would you like to add support for a new language? Please help!

# Support

If you need support or would like to post issues or feature requests, please use the GitHub issue list at https://github.com/ZwerOxotnik/Crino/issues or send an email to the author.

# License

Copyright (c) 2023 ZwerOxotnik (<zweroxotnik@gmail.com>)

Licensed under the MIT licence.

```txt
The MIT License (MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
