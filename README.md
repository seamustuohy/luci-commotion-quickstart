## commotion-quick-start

The quickstart is a "on first boot" interface that walks a user through customizing a node. This is intended to make
the initial setup of a node trivial for a new user. 


###Using The Quickstart

Upon starting a new node a link to the quickstart will be created in the "password needed" text block. When a user clicks on this the QuickStart begins. 

###Understanding the Quickstart

The quickstart is controlled by the /etc/config/quickstart file. (see below for customization.) The quickstart file controls the QS.lua buttons.lua and modules.lua files in the QS controller folder in the luci directory. 

The movement of data is as such.

1. The user requests the page http://IPADDRESS/cgi-bin/luci/QuickStart

2. QS.lua asks module renderers for any data the page needs

3. module.lua requests the PAGErenderer function and passes the QS.lua

4. QS.lua renders the page, passing it any data the modules sent to it

5. Quickstart.htm loads and pulls in the module htm files to create the custom page

6. The user clicks a submit button

7. QS.lua checks to see if the button pressed has any special functions and passes those buttons a list of the modules on the page
  * If the button pressed has no predefined function and just points to the next page then QS.lua's pages function will process that here
  * If a button has a special function it will run that function and chooses the page it will continue to next 

8. button.lua calls any defined buttons which pass back the names of modules that they want to process data passed through the submit call

9. modules.lua runs the PAGEparser function to process any data passed to it from a module on the page

10. QS.lua checks for any possible uploaded data to the node and processes it

11. GOTO #2


###Creating Your Own Quickstart Walkthrough

The whole quickstart configuration can be found in /etc/config/quickstart. This contains one "quickstart" section titled
"options" and multiple "page" sections. "options" holds the current and last pages as well as a variable that controls weather the Quickstart page is accessible. We disable it after completion because it allows non-admin users to manipulate root level controls. A "page" contains title that is either a number (this is how the controller iterates through the quickstart) or a title that represents a side page.

Each page has set of title information for its display. The page also contains a "buttonText" item that specifies the text to be placed on any button that links to it in the quickstart. A "page" can contain up to two lists. The first list is modules. This list pulls content to populate the main section. In our quickstart I have separated most pages to include only one content section. There is nothing to stop someone from customizing a page that holds multiple content items. Modules call a <modulename>Renderer function in the controller when the page is initially rendered, and a <modulename>Parser function when data from a page is submitted. This means that if you want your own module you simple add it to a page and create a renderer and a parser function. Renderer's send initial variables to the page and parsers process user input and send back errors that possible occur in the page.They stack quite well. Lastly a "page" can contain a button list. Buttons call <buttonname>Button functions when pressed that load up side pages. The noBack button removes the auto-generated back button to allow for specialized pages.




