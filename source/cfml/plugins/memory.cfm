<!--- needed for toolbar.cfm --->
<cfscript>
	local.debugLogs = {};
	local.debugLogs.data = []
	admin action="getLoggedDebugData"
		type="#request.adminType#"
		password="#session["password"&request.adminType]#"
		returnVariable="local.debugLogs.data";
	serverScope = getPageContext().scope(createObject("java", "lucee.runtime.type.scope.Scope").SCOPE_SERVER)
	configServer= getPageContext().getConfig().getConfigServer(session["password"&request.adminType]);
	webContexts = configServer.getConfigWebs();
	request.subtitle = "Memory Scopes";
	cfinclude(template="toolbar.cfm");

	function prettyNum(n=0, large=true){
		if (n == 0)
			return "";

		 if (int(n)  eq 0)
			 return "";
		if (arguments.large)
			return NumberFormat(n/1024);
		else
			return NumberFormat(n);
	}
</cfscript>

<cfadmin action="getLoggedDebugData"
	type="#request.adminType#"
	password="#session["password"&request.adminType]#"
	returnVariable="local.debugLogs.data">

<cfoutput>
	<p>This report is based on all the scopes server, application, session currently in memory, click column headers to sort</p>
</cfoutput>
<table class="maintbl checkboxtbl sort-table">
<thead>
<tr>
	<th data-type="text">WebRoot</th>
	<th data-type="text">Application</th>
	<th>Scope Kb</th>
	<th>Keys</th>
	<th>Session Count</th>
	<th>Size Kb</th>
</tr>
</thead>
<tbody>
<cfoutput>
	<cfloop collection="#webContexts#" item="configName">
		<cfscript>
			config = webContexts[configName];
			context = config.getFactory().getScopeContext();
			apps = context.getAllApplicationScopes();
			sessions = context.getAllCFSessionScopes();
		</cfscript>
		<tr>
			<td>Server Scope</td>
			<td></td>
			<td align="right">#prettyNum(sizeOf(serverScope))#</td>
			<td align="right">#prettyNum(structCount(serverScope), false)#</td>
			<td></td>
			<td></td>
		</tr>
		<cfloop collection="#apps#" item="app">
			<tr>
				<td>#config.getRootDirectory()#</td>
				<td>#app#</td>
				<td align="right">#prettyNum(sizeOf(apps[app]))#</td>
				<td align="right">#prettyNum(structCount(apps[app]), false)#</td>
				<cfif structKeyExists(sessions, app)>
					<td align="right">#prettyNum(structCount(sessions[app]), false)#</td>
					<td align="right">#prettyNum(sizeOf(sessions[app]))#</td>
				<cfelse>
					<td></td>
					<td></td>
				</cfif>
			</tr>
		</cfloop>
	</cfloop>
</cfoutput>
</tbody>
<tfoot>
	<tr>
		<td colspan="9" align="center">
		</td>
	</tr>
	<cfif false>
		<cfoutput>
		<tr>
			<td colspan="9" align="center"><br>Showing the top #req.maxrows# scope problems by count (from #src_rows#)
		</tr>
	</cfoutput>
	</cfif>
</tfoot>
</table>
<cfoutput>
	#renderUtils.includeLang()#
	#renderUtils.includeJavascript("perf")#
</cfoutput>
