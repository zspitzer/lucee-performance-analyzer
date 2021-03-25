<!--- needed for toolbar.cfm --->
<cfscript>
	local.debugLogs = {};
	local.debugLogs.data = []
	admin action="getLoggedDebugData"
		type="#request.adminType#"
		password="#session["password"&request.adminType]#"
		returnVariable="local.debugLogs.data";
	local.serverScope = getPageContext().scope( createObject( "java", "lucee.runtime.type.scope.Scope" ).SCOPE_SERVER )
	local.configServer= getPageContext().getConfig().getConfigServer( session[ "password" & request.adminType ] );
	local.webContexts = configServer.getConfigWebs();
	setTitle( "Memory Scopes" );

	function prettyNum( n=0, large=true ){
		if ( arguments.n == 0 )
			return "";

		if ( int( arguments.n ) eq 0 )
			 return "";
		if ( arguments.large )
			return NumberFormat( arguments.n / 1024 );
		else
			return NumberFormat( arguments.n );
	}

	local.rows = 1;
	local.total_app_size = sizeOf( serverScope );
	local.total_app_keys = structCount( serverScope );
	local.total_session_size  = 0;
	local.total_session_count  = 0;
</cfscript>

<cfadmin action="getLoggedDebugData"
	type="#request.adminType#"
	password="#session["password"&request.adminType]#"
	returnVariable="local.debugLogs.data">


<cfsavecontent variable="local.body">
	<cfoutput>
		<tr>
			<td>Server Scope</td>
			<td></td>
			<td align="right">#prettyNum( sizeOf( serverScope ) )#</td>
			<td align="right">#prettyNum( structCount( serverScope ), false)#</td>
			<td></td>
			<td></td>
		</tr>
		<cfloop collection="#webContexts#" item="local.configName">
			<cfscript>
				local.config = webContexts[ configName ];
				local.context = config.getFactory().getScopeContext();
				local.apps = context.getAllApplicationScopes();
				local.sessions = context.getAllCFSessionScopes();

				local.rows++;
			</cfscript>
			<cfloop collection="#apps#" item="local.app">
				<cfscript>
					local.app_size = sizeOf( duplicate( apps[ app ] ) );
					local.total_app_size += local.app_size;
					local.total_app_keys += structCount( apps[ app ] );
				</cfscript>
				<tr>
					<td>#config.getRootDirectory()#</td>
					<td>#app#</td>
					<td align="right">#prettyNum( local.app_size )#</td>
					<td align="right">#prettyNum( structCount( apps[ app ] ), false)#</td>
					<cfif structKeyExists( sessions, app )>
						<cfscript>
							local.session_size = sizeOf( duplicate( local.sessions[ app ] ) );
							local.total_session_size += local.session_size;
							local.total_session_count += structCount( sessions[ app ] );
						</cfscript>
						<td align="right">#prettyNum( structCount( sessions[ app ]), false )#</td>
						<td align="right">#prettyNum( local.session_size )#</td>
					<cfelse>
						<td></td>
						<td></td>
					</cfif>
				</tr>
			</cfloop>
		</cfloop>
	</cfoutput>
</cfsavecontent>
<cfsavecontent variable="local.totals">
	<tr class="log-totals">
		<td colspan="2" align="center">Totals</td>
		<cfoutput>
			<td align="right">#prettyNum( local.total_app_size )#</td>
			<td align="right">#prettyNum( local.total_app_keys, false )#</td>
			<td align="right">#prettyNum( local.total_session_count, false )#</td>
			<td align="right">#prettyNum( local.total_session_size )#</td>
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
	#variables.renderUtils.includeLang()#
	#variables.renderUtils.includeJavascript("perf")#
</cfoutput>
