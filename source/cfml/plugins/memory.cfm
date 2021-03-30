<!--- needed for toolbar.cfm --->
<cfscript>

	local.serverScope = getPageContext().scope( createObject( "java", "lucee.runtime.type.scope.Scope" ).SCOPE_SERVER )
	local.configServer= getPageContext().getConfig().getConfigServer( session[ "password" & request.adminType ] );
	local.webContexts = configServer.getConfigWebs();
	setTitle( "Memory Scopes" );
	local.r = 0;
	local.rows = 1;
	local.total_app_size = sizeOf( serverScope );
	local.total_app_keys = structCount( serverScope );
	local.total_session_size  = 0;
	local.total_session_count  = 0;
</cfscript>

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
				<tr class="#altRow( local.r )#">
					<td>#config.getRootDirectory()#</td>
					<td>#app#</td>
					<td align="right">#prettyNum( local.app_size, true )#</td>
					<td align="right">#prettyNum( structCount( apps[ app ] ), false)#</td>
					<cfif structKeyExists( sessions, app )>
						<cfscript>
							local.session_size = sizeOf( duplicate( local.sessions[ app ] ) );
							local.total_session_size += local.session_size;
							local.total_session_count += structCount( sessions[ app ] );
						</cfscript>
						<td align="right">#prettyNum( structCount( sessions[ app ]), false )#</td>
						<td align="right">#prettyNum( local.session_size, true)#</td>
					<cfelse>
						<td></td>
						<td></td>
					</cfif>
				</tr>
				<cfset local.r++>
			</cfloop>
		</cfloop>
	</cfoutput>
</cfsavecontent>
<cfsavecontent variable="local.totals">
	<tr class="log-totals">
		<td colspan="2" align="center">Totals</td>
		<cfoutput>
			<td align="right">#prettyNum( local.total_app_size, true )#</td>
			<td align="right">#prettyNum( local.total_app_keys, false )#</td>
			<td align="right">#prettyNum( local.total_session_count, false )#</td>
			<td align="right">#prettyNum( local.total_session_size, true )#</td>
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
	<th>Scope Mb</th>
	<th>Keys</th>
	<th>Session Count</th>
	<th>Size Mb</th>
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