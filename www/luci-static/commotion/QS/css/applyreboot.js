var classType = "iecert";
var pageNum = 1;
document.getElementById('internetexplorerButton').onclick = function() {
    if (document.getElementById('certWrapper').className === "hidden") {
        document.getElementById("certWrapper").className = "certWrapper";
    }
    classType = "iecert";
    pageNum = 1;
    document.getElementById("certTut").className="sprite " + classType + pageNum;
};
document.getElementById('chromeButton').onclick = function() {
    if (document.getElementById('certWrapper').className == "hidden") {
        document.getElementById("certWrapper").className="certWrapper";
    }
    classType = "chcert";
    pageNum = 1;
    document.getElementById("certTut").className="sprite " + classType + pageNum;
};
document.getElementById('firefoxButton').onclick = function() {
    if (document.getElementById('certWrapper').className == "hidden") {
        document.getElementById("certWrapper").className="certWrapper";
    }
    classType = "ffcert";
    pageNum = 1;
    document.getElementById("certTut").className="sprite " + classType + pageNum;
};
function next() {
    if (classType == 'ffcert' || classType == 'iecert') {
        if (pageNum <= 3) {
            pageNum += 1;
		}
		else {
		    pageNum = 1;
		}
    }
	else if (classType == 'chcert') {
        if (pageNum <= 2) {
            pageNum += 1;
		}
		else {
		    pageNum = 1;
		}
    }
	document.getElementById("certTut").className="sprite " + classType + pageNum;
};

function toggleVisibility(x)
{
	if (document.getElementById(x).className === "hidden") {
        document.getElementById(x).className = "visible";
    }
	else {document.getElementById(x).className = "hidden";}
}

//<![CDATA[
var interval = window.setInterval(function() {
	var img = new Image();
	var interval2 = window.setInterval(function() {
		window.clearInterval(interval);
		window.clearInterval(interval2);
		location.href = "<%=redirect_location%>";
	}, 30000);
	img.onload = function() {
		window.clearInterval(interval);
		location.href = "<%=redirect_location%>";
	};
	img.src = 'http://<%=addr or luci.http.getenv("SERVER_NAME")%><%=resource%>/icons/loading.gif?' + Math.random();
}, 30000);
//]]>
