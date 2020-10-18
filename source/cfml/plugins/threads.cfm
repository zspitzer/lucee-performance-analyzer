<!--- needed for toolbar.cfm --->
<cfscript>
	local.debugLogs = {};
	local.debugLogs.data = []
	admin action="getLoggedDebugData"
		type="#request.adminType#"
		password="#session["password"&request.adminType]#"
		returnVariable="local.debugLogs.data";
	request.subtitle = "Java Threads";
	cfinclude(template="toolbar.cfm");
</cfscript>
<cfadmin action="getLoggedDebugData"
	type="#request.adminType#"
	password="#session["password"&request.adminType]#"
	returnVariable="local.debugLogs.data">
<br>
<table class="maintbl checkboxtbl sort-table">
<thead>
<tr>
	<th data-type="text">Thread</th>
	<th data-type="text">Status</th>
	<th data-type="text">Stack</th>
</tr>
</thead>
<tbody>
<cfscript>
	Thread=createObject("java","java.lang.Thread");
	it=Thread.getAllStackTraces().keySet().iterator();
	// loop threads

	loop collection=it item="t" {
		//dump(t); abort;
		st=t.getStackTrace();
		str="";
		// loop stacktraces
		loop array=st item="ste" {
			str&=ste;
			str&="<br>";
		}
		//if(!find("PageContextImpl",str)) continue;
		echo("<tr><td>#t.name#</td>");// PageContextImpl
		echo("<td>#t.getState()#</td>");// PageContextImpl
		echo("<td><pre>#trim(str)#</pre></td></tr>");
	}
</cfscript>
<cfoutput>
	#renderUtils.includeLang()#
	#renderUtils.includeJavascript("perf")#
</cfoutput>
</tbody>
</table>