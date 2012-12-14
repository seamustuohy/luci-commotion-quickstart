--[[

Commotion QuickStart - LuCI based Application Front end.
Copyright (C) <2012>  <Seamus Tuohy>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]--

module("luci.controller.commotion.QS.QS_button", package.seeall)


function index()
	--each page gets an entry that either calls a template or a function
	--any function call needs a template call at the end of the function
	
	--buttony takes a value passed to it from a button and calls that entry
	entry({"QS", "button"}, call("buttony", name))

	entry({"QS", "welcome"}, template("QS/QS_welcome_main"), "Quick Start").dependent=false
	entry({"QS", "basicinfo"}, template("QS/QS_basicInfo_main"), "Quick Start").dependent=false

end


function buttony()
	page = name
	luci.dispatcher.node("QS", page)
end


function load_main()
luci.template.render("QS/QS_error_main", {errorType=header, errorMsg=errorMsg,})
end		 