module("luci.controller.QS.modules", package.seeall)
  --to have a html page render you must return a value or it wont.

require "commotion_helpers"

function index()
   --This function is required for LuCI
   --we don't need to define any pages in this file
end

function welcomeRenderer()
   return 'true'
end

function adminPasswordRenderer()
   return 'true'
end

function completeRenderer()
   return 'true'
end

function nameRenderer()
   luci.sys.call("echo '' > /etc/commotion/profiles.d/quickstartSettings") 
   return 'true'
end

function nameParser()
   local QS = luci.controller.QS.QS
   QS.log("nameParser running")
   errors = nil
   local val = luci.http.formvalue()
   --QS.log(val)
   if val.nodeName and val.nodeName ~= "" and string.len(val.nodeName) < 20 then
	  if is_hostname(val.nodeName) then
		 nodeID = luci.sys.exec("commotion nodeid")
		 --luci.controller.QS.QS.log(val.nodeName)
		 hostName = tostring(val.nodeName) .. nodeID
		 --QS.log(name)

		 local file = "/etc/commotion/profiles.d/quickstartSettings"
		 local find =  '^hostname=.*'
		 local replacement = "hostname="..hostName
		 replaceLine(file, find, replacement)
		 
		 --QS.log("wrote hostname")
		 if val.secure == 'true' then
			--QS.log("passwords:"..val.pwd1.." & "..val.pwd2)
			pass = checkPass(val.pwd1, val.pwd2)
			if pass == nil then
			   if not luci.fs.isfile("/etc/commotion/profiles.d/quickstartSec") then
				  luci.sys.call('cp /etc/commotion/profiles.d/defaultSec /etc/commotion/profiles.d/quickstartSec') 
			   end
			   local file = "/etc/commotion/profiles.d/quickstartSettings"
			   local find =  '^pwd=.*'
			   local replacement = "pwd="..val.pwd1
			   replaceLine(file, find, replacement)
			   
			   local file = "/etc/commotion/profiles.d/quickstartSettings"
			   local find =  '^SSIDSec=.*'
			   local replacement = "SSIDSec="..val.nodeName
			   replaceLine(file, find, replacement)
			   
			else
			   return pass
			end
		 else
			if not luci.fs.isfile("/etc/commotion/profiles.d/quickstartAP") then
			   luci.sys.call('cp /etc/commotion/profiles.d/defaultAP /etc/commotion/profiles.d/quickstartAP') 
			end
			local file = "/etc/commotion/profiles.d/quickstartSettings"
			local find =  '^SSID=.*'
			local replacement = "SSID="..val.nodeName
			replaceLine(file, find, replacement)
		 end
	  else
		 errors = "Please enter a correctly formatted name."
	  end
   else
	  errors = "Please enter a name that is greater than 0 and less than 20 chars."
   end
   if errors ~= nil then
	  return errors
   end
end

function setAPPassword(pass)
   local QS = luci.controller.QS.QS
   QS.log("setAPPassword started")

   local file = "/etc/commotion/profiles.d/quickstartSec"
   local find =  '^wpakey=.*'
   local replacement = "wpakey="..pass
   replaceLine(file, find, replacement)
   
   --local file = "/etc/commotion/profiles.d/quickstartSec"
   --local find =  '^wpa=.*'
   --local replacement = "wpa=true"
   --replaceLine(file, find, replacement)
end

function setSecAccessPoint(SSID)
   local QS = luci.controller.QS.QS
   QS.log("setSecAccessPoint started")

   local file = "/etc/commotion/profiles.d/quickstartSec"
   local find =  "^ssid=.*"
   local replacement = 'ssid='..SSID
   replaceLine(file, find, replacement)
end


function string.split(str, pat)
	local t = {} 
	if pat == nil then pat=' ' end
	local fpat = "(.-)" .. pat
	local last_end = 1
	local s, e, cap = str:find(fpat, 1)
	while s do
	   if s ~= 1 or cap ~= "" then
	  table.insert(t,cap)
	   end
	   last_end = e+1
	   s, e, cap = str:find(fpat, last_end)	end
	if last_end <= #str then
	   cap = str:sub(last_end)
	   table.insert(t, cap)
	end
	return t
end


function setHostName(hostNamen)
   local QS = luci.controller.QS.QS
   QS.log("setHostName started")
   local uci = luci.model.uci.cursor()
   uci:foreach("system", "system",
			   function(s)
				  if s.hostname then
					 uci:set("system", s['.name'], "hostname", hostNamen)
					 uci:commit("system")
					 uci:save("system")
				  end
			   end)
   hostnameWorks = luci.sys.call("echo " .. hostNamen .. " > /proc/sys/kernel/hostname")
   QS.log("HostName was set correcty:"..tostring(hostnameWorks))
   QS.log("hostname set")
end

function setAccessPoint(SSID)
   local QS = luci.controller.QS.QS
   QS.log("setAccessPoint started")
   local file = "/etc/commotion/profiles.d/quickstartAP"
   local find =  "^ssid=.*"
   local replacement = 'ssid='..SSID
   replaceLine(file, find, replacement)
   QS.log("Access Point Set")
end

function loadingPage()
   local QS = luci.controller.QS.QS
   QS.log("loadingPage started")

   environment = luci.http.getenv("SERVER_NAME")
   if not environment then
	  environment = "thisnode"
   end
   luci.template.render("QS/module/applyreboot", {redirect_location=("http://" .. environment .. "/cgi-bin/luci/admin")})
   luci.http.close()
end

function setValues(setting, value)
   --[=[ This function activates the setting value setting functions for defined values.
	  --]=]
   --TODO how do we deal with functions that take multiple values? Lua allows passing of muiltiple values, may just need to make more ways to submit.
   local QS = luci.controller.QS.QS
   QS.log("setValue started")
   settings = {
	  SSID = setAccessPoint,
	  hostname = setHostName,
	  pwd = setAPPassword,
	  SSIDSec = setSecAccessPoint,
   }
   settings[setting](value)
   return
end

function checkSettings()
   --[=[ Checks the quickstart settings file and returns a table with setting, value pairs.--]=]
   local QS = luci.controller.QS.QS
   QS.log("checkSetttings started")
   for line in io.lines("/etc/commotion/profiles.d/quickstartSettings") do
	  setting = line:split("=")
	  if setting[1] ~= "" and setting[1] ~= nil then
		 setValues(setting[1], setting[2])
	  end
   end
   QS.log("quickstartSettings Completed")
   return true
end

function getCommotionSetting(settingName)
   --[=[ Checks the quickstart settings file and returns a table with setting, value pairs.--]=]
   local QS = luci.controller.QS.QS
   QS.log("commotion settting getter started")
   for line in io.lines("/etc/commotion/profiles.d/quickstartSettings") do
	  setting = line:split("=")
	  if setting[1] == settingName then
		 current = setting[2]
	  end
   end
   return current
end


function completeParser()
   --[=[ This function controls the final settings process--]=]
   local QS = luci.controller.QS.QS
   QS.log("completeParser started")
   local uci = luci.model.uci.cursor()
   loadingPage()
   --This may be where we split the finction into smaller components
   checkSettings()
   files = {{"mesh","quickstartMesh"}, {"secAp","quickstartSec"}, {"ap","quickstartAP"}}
   QS.log("Wireless UCI Controller about to start")
   QS.wirelessController(files)
   QS.log("Quickstart Final Countdown started")
   uci:set('quickstart', 'options', 'complete', 'true')
   uci:save('quickstart')
   uci:commit('quickstart')
   p = luci.sys.reboot()
end



function readProfile(name, obj)
   --[=[ This function takes a profile name and the value desired and returns the result of that value.
   --]=]
   if type(name) == "string" then
	  offset = string.len(tostring(obj))
      for line in io.lines("/etc/commotion/profiles.d/"..name) do
		 b,c = string.find(line,"^"..obj.."=.*")
		 if b then
			value = string.sub(line,b+offset,c)
		 end
	  end
	  return value
   else
	  return nil
   end
end


function replaceLine(fn, find, replacement)
   --[=[ Function for replacing values in non-uci config files
	     replaceLine(File Name, search string, replacement text)
   --]=]
   errorCode = 1
   grepable = luci.sys.call('grep -q '..find..' '..fn) 
   if grepable == 1 then
	  errorCode = luci.sys.call("echo " .. replacement .. " >> ".. fn)
   else
	  errorCode = luci.sys.call('sed -i s/'..find..'/'..replacement..'/g '..fn)
   end
   return errorCode
end

function checkPass(p1, p2)
   --[=[ This function takes two values and compares them. It returns error text for password pages. It needs some serious refactoring, but it works --]=]
   QS = luci.controller.QS.QS
   if p1 and p2 then
	  if p1 == p2 then
		 if p1 == '' then
			return "Please enter a password"
		 elseif string.len(p1) < 8 then
			return "Please enter a password that is more than 8 chars long"
		 elseif not tostring(p1):match("^[%p%w]+$") then
			return "Your password has spaces in it. You can't have spaces."
			
		 end
	  else
		 return "Given password confirmation did not match, password not changed!"
	  end
   end
end


function replaceLine(fn, find, replacement)
   --[=[ Function for replacing values in non-uci config files
	     replaceLine(File Name, search string, replacement text)
   --]=]
   errorCode = 1
   grepable = luci.sys.call('grep -q '..find..' '..fn) 
   if grepable == 1 then
	  errorCode = luci.sys.call("echo " .. replacement .. " >> ".. fn)
   else
	  errorCode = luci.sys.call('sed -i s/'..find..'/'..replacement..'/g '..fn)
   end
   return errorCode
end


function uploadRenderer()
   --creates an uploader based upon the fileType of the page config
   local uci = luci.model.uci.cursor()
   local page = uci:get('quickstart', 'options', 'pageNo')
   local fileType = uci:get('quickstart', page, 'fileType')
   --TODO check uploader module to see if it needs any values
   if fileType == 'config' then
   fileInstructions="and submit a config file from your own computer. You will be able to customize this configuration once it has been applied to the node."
   elseif fileType == 'key' then
	  fileInstructions="and submit a key file from your own computer. This will allow your node to talk to any network with the same key file"
   end   
   return {['fileType']=fileType, ['fileInstructions']=fileInstructions}
end


function uploadParser()
   --Parses uploaded data 
   local uci = luci.model.uci.cursor()
      error = ''
   if luci.http.formvalue("config") ~= '' then
	  file = luci.http.formvalue("config")
   elseif luci.http.formvalue("config") == '' then
	  error = "Please upload a setting file."
   elseif luci.http.formvalue("key") ~= '' then
	  file = luci.http.formvalue("key")
   end
   if file then
	  if luci.http.formvalue("config") then
		 --check that each file is actually the file type that we are looking for!!!
		 if not uci:get('nodeConf', 'confInfo', 'name') then
			error = 'This file is not a configuration file. Please check the file and upload a working config file or go back and choose a pre-built config'
		 end
	  elseif luci.http.formvalue("key") then
		 if luci.sys.call("pwd") == '1' then
			elseif luci.sys.call("servald keyring list") == '1' then
			error = 'The file uploaded is either not a proper keyring or has a pin that is required to access the key within. If you do not think that your keyring has a pin please upload a proper servald keyring for your network key. If your keyring is pin protected, please click continue below.'
		 end
	  end
   end
   if error ~= '' then
	  return error
   end
end
