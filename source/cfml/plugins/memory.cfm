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

	local.rows = 1;
	local.app_size = sizeOf(serverScope);
	local.app_keys = structCount(serverScope);
	local.session_size  = 0;
	local.session_count  = 0;
</cfscript>

<cfadmin action="getLoggedDebugData"
	type="#request.adminType#"
	password="#session["password"&request.adminType]#"
	returnVariable="local.debugLogs.data">


<cfsavecontent variable="body">
	<cfoutput>
		<tr>
			<td>Server Scope</td>
			<td></td>
			<td align="right">#prettyNum(sizeOf(serverScope))#</td>
			<td align="right">#prettyNum(structCount(serverScope), false)#</td>
			<td></td>
			<td></td>
		</tr>
		<cfloop collection="#webContexts#" item="configName">
			<cfscript>
				config = webContexts[configName];
				context = config.getFactory().getScopeContext();
				apps = context.getAllApplicationScopes();
				sessions = context.getAllCFSessionScopes();

				local.rows++;

				//local.app_size += sizeOf(apps[app]);
				local.app_keys += structCount(apps[app]);
			</cfscript>
			<cfloop collection="#apps#" item="app">
				<tr>
					<td>#config.getRootDirectory()#</td>
					<td>#app#</td>
					<td align="right">#prettyNum(sizeOf(apps[app]))#</td>
					<td align="right">#prettyNum(structCount(apps[app]), false)#</td>
					<cfif structKeyExists(sessions, app)>
						<cfscript>
							local.session_count += structCount(sessions[app]);
							local.session_size += sizeOf(sessions[app]);
						</cfscript>
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
</cfsavecontent>
<cfsavecontent variable="totals">
	<tr class="log-totals">
		<td colspan="2" align="center">Totals</td>
		<cfoutput>
			<td></td>
			<td></td>
			<td></td>
			<td align="right">#prettyTime(local.app_size)#</td>
			<td align="right">#prettyNum(local.app_keys)#</td>
			<td align="right">#prettyNum(local.session_count)#</td>
			<td align="right">#prettyNum(local.session_size)#</td>
		</cfoutput>
	</tr>
</cfsavecontent>

<cfoutput>
	<p>Size of the Server, Application and Session scopes currently in memory, click column headers to sort</p>
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
<cfif local.rows gt 0>
	<cfoutput>#totals#</cfoutput>
</cfif>
</thead>
<tbody>
	<cfoutput>#body#</cfoutput>
</tbody>
<tfoot>
	<cfif local.rows gt 10>
		<cfoutput>#totals#</cfoutput>
	</cfif>
</tfoot>
</table>
<cfoutput>
	#renderUtils.includeLang()#
	#renderUtils.includeJavascript("perf")#
</cfoutput>
