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

module("luci.controller.QS.QS", package.seeall)


function index()
	--each page gets an entry that either calls a template or a function
	--any function call needs a template call at the end of the function

	entry({"QS", "welcome"}, template("QS/QS_welcome_main"), "Quick Start").dependent=false
	entry({"QS", "basicinfo"}, template("QS/QS_basicInfo_main"), "Quick Start").dependent=false
	entry({"QS", "nearbyMesh"}, call("find_nearby")).dependent=false
	entry({"QS", "sharingPrefs"}, call("sharing_options")).dependent=false
	entry({"QS", "chosenMeshDefault"}, call("mesh_defaults")).dependent=false
	entry({"QS", "error"}, call("error")).dependent=false
	entry({"QS", "connectedNodes"}, call("connected_nodes")).dependent=false
	entry({"QS", "wait4Reset"}, call("wait_4_reset")).dependent=false
	entry({"QS", "uploadConfig"}, call("upload_file")).dependent=false
	entry({"QS", "bugReport"}, call("bug_report")).dependent=false
end

function load_main()
		 luci.template.render("QS/QS_error_main", {errorType=header, errorMsg=errorMsg,})
end

function find_nearby()
		 --this would eventually call the daemon. For now we just send some falsified data over.

		 local networks = {
		 	   { name="Commotion", config="true"},
		 	   { name="RedHooks", config="true"},
		 	   { name="Ninux", config="false"},
		 	   { name="Byzantium", config="true"},
		 	   { name="Funkfeuer", config="false"},
		 	   { name="FreiFunk", config="false"},
		 	   { name="Big Bobs Mesh Network", config="false"},
		 	   { name="Viva la' Revolution", config="true"},
		}
		
		luci.template.render("QS/QS_nearbyMesh_main", {networks=networks})
end

function sharing_options()
		 --the place where sharing options are parsed from

		 local share_service = {
		 	   { name="access point", help_name="Public Access Point:", help_text="These access points have no password and allow any wifi enabled user to use your node to access the network", description="This is a description of stuff"},
			   }
			   
		luci.template.render("QS/QS_sharingPrefs_main", {share_service=share_service})
end


function switch(t,x,y)
	t.case = function (self,x,y)
      local f=self[x] or self.default
	  if f then
	  	 if type(f)=="function" then
		 	f(x,self,y)
		 else
		     error("case "..tostring(x).." not a function")
		 end
	  end
	end
	return t
end

function mesh_defaults()
		 --Later this will parse text from each config file and then use that data against a set of values here to create a "network defaults" info page.
		 
		 local security_counter = 0
		 local list_items = {}

		 -- parse config of network/ call daemon for network values
		 -- values below are temporary fakes
		 network = "Commotion"
		 local defaults = {
		 OLSR_secure = true,
		 WPA_None = true,
		 ServalD = true,
		 DTN = true,
		 network_key = "lkj84rfl234lfd2feds2f3fd23f2",
		 gateway_sharing = true,
		 app_sharing = true,
		 }
		 --end of fakes
		 

		 
		 --Create switch to parse through for values (still need full list)
		 default_switch = switch {
		 OLSR_secure = function (x,y,value) if value == true then results={"sec",1} return results end end,
		 WPA_None = function (x,y,value)  if value == true then results={"sec",1}  return results end end,
		 ServalD = function (x,y,value)  if value == true then results = {"sec",1} return results end end,
		 DTN = function (x,y,value)  if value == true then results = {"sec",1} return results end end,
		 network_key = function (x,y,value) if value then results = {"network_key",value} return results end end,
		 gateway_sharing = function (x,y,value) if value then results = {"gateway_sharing",value} return results end end,
		 app_sharing = function (x,y,value) if value then results = {"app_sharing",value} return results end end,
		 }
		 
		 for i, value in pairs(defaults) do
		 	 default_switch:case(i, value)
			 --print(results[1])
			 --print(results[2])
			 if results[1] == "sec" then
  	   		 	security_counter = security_counter + results[2]
			 else
				table.insert(list_items,{results[1],results[2]})
			 end
			 results = {}
		end
		table.insert(list_items,{"security_counter",security_counter})

		--send list of items to the template for parsing
		luci.template.render("QS/QS_chosenMeshDefault_main", {list_items=list_items, network=network})
		
end

function upload_file()
   local sys = require "luci.sys"
   local fs = require "luci.fs"
   local tmp_file = "/tmp/"
   local access = nixio.fs.access("/tmp/")
   -- causes media files to be uploaded to their namesake in the /tmp/ dir.
   local fp
   luci.http.setfilehandler(
	  function(meta, chunk, eof)
		 if not fp then
			if meta and meta.name == "file" then
			   fp = io.open(tmp_file .. meta.file, "w")
			end
		 end
		 if chunk then
			fp:write(chunk)
		 end
		 if eof then
			fp:close()
		 end
	end)

   luci.template.render("QS/QS_uploadConfig_main", {access=access})
end
