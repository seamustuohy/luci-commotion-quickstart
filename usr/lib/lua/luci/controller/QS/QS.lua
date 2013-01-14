module("luci.controller.QS.QS", package.seeall)

require "luci.model.uci"

function index()
   local uci = luci.model.uci.cursor()
   if uci:get('quickstart', 'options', 'complete') ~= 'true' then
	  entry({"QuickStart"}, call("main"), "Quick Start").dependent=false
   end
end

 function main(errorMsg)
   -- FIRST if return values get them and pass them to return value parser
   if luci.http.formvalue then
	  checkPage()
   end
   --1) call uci parser, returning dict of pages
   local uci = luci.model.uci.cursor()
   local pageNo = uci:get('quickstart', 'options', 'pageNo')
   local lastPg = uci:get('quickstart', 'options', 'lastPg')
   --Create/clear a space for pageValues and populate with page
   local pageValues = {modules = {}, page = {['pageNo'] = pageNo, ['lastPg'] = lastPg}}
   local pageContext = uci:get_all('quickstart', pageNo)
   -- iterate through the list of page content from the UCI file and run corresponding functions, populating a dictionary with the values required by each module
   for i,x in pairs(pageContext) do
	  if i == 'modules' then
		 for y,z in ipairs(x) do
			pageValues.modules[z]=luci.controller.QS.QS[z]()
		 end
	  elseif i == 'buttons' then
		 for y,z in ipairs(x) do
			--2) run button function returning values and adding them to the variable page
			pageValues.modules[z]=button(z)
		 end
	  else
		 pageValues[i]=x
	  end
   end
   
   if errorMsg then
	  pageValues[errorMsg] = errorMsg
   end
   --3) pass dictionary to the main page loader luci.http.loadtemplate("quickstart")
   luci.template.render("QS/Quickstart", {pv=pageValues})
end

function logo()
   return 'true'
end

function checkPage(returns)
   for i,x in returns do
	  table[x] = assert(luci.http.formvaluetable(x, nil))
   --1) TODO check for return values
   -- 2) TODO send values to parser for each module
   --3) TODO if values good set them in custom config, iterate pageNo, set lastPg number to current page, and call main()
   --4) TODO if values bad, send main(errorMsg) and DO NOT ITERATE pageNo, so that page is reloaded with errrors, if redirected to a error page, etc lastPg needs to be modified to save state.
end

function basicInfo()
   --check current node_name and return it as nodename
   local uci = luci.model.uci.cursor()
   local nodeName = assert(uci:get('nodeConf', 'confInfo', 'name'))
   if nodeName then
	  return nodeName
   else
	  return nil
   end
end

function button()
   --TODO take simple button types from uci files and create button values to send to the  page
   --TODO {text = BUTTON_TEXT, icon = ICON_NAME, name=SUBMIT_VALUE}
end






























function log(msg)
   if (type(msg) == "table") then
	  for key, val in pairs(msg) do
		 log('{')
		 log(tostring(key))
		 log(':')
		 log(tostring(val))
		 log('}')
	  end
   else
	  luci.sys.exec("logger -t luci " .. msg)
   end
end