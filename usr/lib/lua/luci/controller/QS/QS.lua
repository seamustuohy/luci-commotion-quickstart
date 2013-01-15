module("luci.controller.QS.QS", package.seeall)

require "luci.model.uci"

function index()
   local uci = luci.model.uci.cursor()
   if uci:get('quickstart', 'options', 'complete') ~= 'true' then
	  entry({"QuickStart"}, call("main"), "Quick Start").dependent=false
   end
end

 function main()
   -- FIRST if return values get them and pass them to return value parser
   if luci.http.formvalue then
	  errorMsg = checkPage()
   end
   --1) call uci parser, returning dict of pages
   local uci = luci.model.uci.cursor()
   local pageNo = uci:get('quickstart', 'options', 'pageNo')
   local lastPg = uci:get('quickstart', 'options', 'lastPg')
   --Create/clear a space for pageValues and populate with page
   local pageValues = {modules = {}, buttons ={}, page = {['pageNo'] = pageNo, ['lastPg'] = lastPg}}
   local pageContext = uci:get_all('quickstart', pageNo)
   -- iterate through the list of page content from the UCI file and run corresponding functions, populating a dictionary with the values required by each module
   for i,x in pairs(pageContext) do
	  if i == 'modules' then
		 for y,z in ipairs(x) do
			pageValues.modules[z]=luci.controller.QS.QS[z .. "Renderer"]()
		 end
	  elseif i == 'buttons' then
		 for y,z in ipairs(x) do
			--2) run button function returning values and adding them to the variable page
			pageValues.buttons[z]=true
		 end
	  else
		 pageValues[i]=x
	  end
   end
   
   if errorMsg then
	  pageValues['errorMsg'] = errorMsg
   end
   --3) pass dictionary to the main page loader luci.http.loadtemplate("quickstart")
   luci.template.render("QS/main/Quickstart", {pv=pageValues})
end

function logoRenderer()
   return 'true'
end

function checkPage()
   local returns = luci.http.formvalue()
   errors = parseSubmit(returns)
   --1) TODO check for return values
   -- 2) TODO send values to parser for each module
   --3) TODO if values good set them in custom config, iterate pageNo, set lastPg number to current page, and call main()
   --4) TODO if values bad, send main(errorMsg) and DO NOT ITERATE pageNo, so that page is reloaded with errrors, if redirected to a error page, etc lastPg needs to be modified to save state.
   return errors
end

function parseSubmit(returns)
	  --check for submission value
      local uci = luci.model.uci.cursor()
	  local submit = returns.submit
	  returns.submit = nil
	  if submit == 'next' then
		 local errors = {}
		 local modules = {}
		 for type,val in pairs(returns) do
			if type == 'moduleName' then
			   if modules[val] ~= true then
				  modules[val] = true
				  --log(returns)
				  errors[val] = luci.controller.QS.QS[val .. "Parser"](returns)
			   end
			end
		 end
		 if next(errors) == nil then
			page = uci:get('quickstart', 'options', 'pageNo')
			uci:get('quickstart', 'options', 'lastPg')
			uci:set('quickstart', 'options', 'pageNo', page)
			uci:set('quickstart', 'options', 'pageNo', page+1)
			uci:save('quickstart')
			uci:commit('quickstart')
		 else
			return(errors)
		 end
	  elseif submit == 'back' then
		 return nil
	  else
		 return luci.controller.QS.QS[submit .. "Button"]()
	  end
end


function welcomeRenderer()
   return 'true'
end

function welcomeParser()
   return nil
end

function basicInfoRenderer()
   --check current node_name and return it as nodename
   local uci = luci.model.uci.cursor()
   local nodeName = assert(uci:get('nodeConf', 'confInfo', 'name'), 'No nodeConf File Found.')
   if nodeName then
	  return {['name'] = nodeName}
   else
	  return nil
   end
end

function basicInfoParser(val)
   local errors = {}
   local uci = luci.model.uci.cursor()
   if val.basicInfo_nodeName == '' then
	  errors['node_name'] = "Please enter a node name"
   else
	  uci:set('nodeConf', 'confInfo', 'name', val.basicInfo_nodeName)
	  uci:save('nodeConf')
	  uci:commit('nodeConf')
   end
   local p1 = val.basicInfo_pwd1
   local p2 = val.basicInfo_pwd2 
   if p1 or p2 then
	  if p1 == p2 then
		 if p1 == '' then
			errors['pw'] = "Please enter a password"
		 else   
			luci.sys.user.setpasswd("root", p1)
		 end
	  else
		 errors['pw'] = "Given password confirmation did not match, password not changed!"
	  end
   end
   if next(errors) == nil then
	  return nil
   else
	  return errors
   end
end

function nearbyMeshRenderer()

end

function nearbyMeshParser()
   local networks = commotionDaemon('nearbyNetworks')
   return networks
end


function uploadConfButton()
end

function preBuiltButton()
end

function commotionDaemon(request)
--TODO have this function make Ubus calls to the commotion daemon instead of pass back dummy variables
--This if statement FAKES grabbing nearby mesh networks from the commotion daemon
   if request == 'nearbyNetworks' then
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
	  return networks
   end
end



function error(errorType)
--TODO add submitButton error
end





















function log(msg)
   if (type(msg) == "table") then
	  for key, val in pairs(msg) do
		 if type(key) == 'boolean' then
			log('{')
			log(tostring(key))
			log(':')
			log(val)
			log('}')
		 elseif type(val) == 'boolean' then
			log('{')
			log(key)
			log(':')
			log(tostring(val))
			log('}')
		 else
			log('{')
			log(key)
			log(':')
			log(val)
			log('}')
		 end
	  end
   else
	  luci.sys.exec("logger -t luci " .. msg)
   end
end