var classType = "iecert";
var pageNum = 1;

function internetExplorer() {
    if (document.getElementById('certWrapper').className == "hidden") {
        document.getElementById("certWrapper").className = "certWrapper";
    }
    classType = "iecert";
    pageNum = 1;
    document.getElementById("certTut").className="sprite " + classType + pageNum;
};

function firefoxFunc() {
    if (document.getElementById('certWrapper').className == "hidden") {
        document.getElementById("certWrapper").className = "certWrapper";
    }
    classType = "ffcert";
    pageNum = 1;
    document.getElementById("certTut").className="sprite " + classType + pageNum;
};

function chromeFunc() {
    if (document.getElementById('certWrapper').className == "hidden") {
        document.getElementById("certWrapper").className = "certWrapper";
    }
    classType = "chcert";
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
