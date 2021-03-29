<Cfset local.debugLogs = {}>
<cfparam name="arguments.req.maxrows" default ="1000">
<cfparam name="arguments.req.doPurge" default ="false">
<cfparam name="arguments.req.consoleDump" default ="false">
<cfif arguments.req.doPurge>
	<cftry>
		<cfadmin action="purgeDebugPool"
			type="#request.adminType#"
			password="#session["password"&request.adminType]#">
		<cfcatch>
			<cfoutput>
				<b>Sorry, Purge logs failed, it was added in Lucee 5.3.8.80 (this is #server.lucee.version#)</b>
			</cfoutput>
			<cfdump var=#cfcatch# expand=false label='cfadmin action="purgeDebugPool2" failed'>
		</cfcatch>
	</cftry>
</cfif>

<cfadmin action="getLoggedDebugData"
	type="#request.adminType#"
	password="#session["password"&request.adminType]#"
	returnVariable="local.debugLogs.data">

<cfscript>
	if (!StructKeyExists( local.debugLogs, "data" ) )
		local.debugLogs.data = []; // getLoggedDebugData may return null
	var q = QueryNew( "name,time,sql,src,line,count,datasource,usage,cacheType" );
	setTitle( "Debugging Logs" );
	var local.r = 0;

	function prettyTime( n ){
		if ( arguments.n == 0 )
			return "";
		 var s = arguments.n / ( 1000 * 1000 );
		 if ( Int(s) eq 0 )
		 	return "";
		return NumberFormat( s );
	}

	function prettyNum( n ){
		if ( arguments.n == 0 )
			return "";

		 if ( Int(arguments.n)  eq 0 )
		 	return "";
		return NumberFormat( arguments.n );
	}
	local.midnight = CreateDate( Year( Now() ), Month( Now() ), Day( Now() ) ); // hide todays date

	function hasJavaMethod( obj, name ) {
		loop array=arguments.obj.getClass().getMethods() item="local.m" {
			if( m.getName() == arguments.name ) return true;
		}
		return false;
	}
</cfscript>

<cfloop from="#local.debugLogs.data.len()#" to="1" step=-1 index="local.i">
	<cfscript>
		local.log = local.debugLogs.data[local.i];
		if ( StructKeyExists( arguments.req, "since" ) ){
			if ( DateCompare( log.starttime, arguments.req.since ) neq 1)
				continue;
		}
	</cfscript>
</cfloop>
<cfscript>
	local.src_rows = local.debugLogs.data.len();
	local.total_app = 0;
	local.total_query = 0;
	local.total_total = 0;
	local.total_load = 0;
	local.total_size = 0;
	local.total_scope = 0;
	local.total_exp = 0;
	local.log = {};
	local.rows = 0;
</cfscript>

<cfsavecontent variable="local.body">
	<tbody>
	<cfloop from="#local.debugLogs.data.len()#" to="1" step=-1 index="local.i">
		<cfscript>
			local.log = local.debugLogs.data[local.i];
			if ( StructKeyExists(arguments.req, "since") ){
				if ( DateCompare( log.starttime, arguments.req.since ) neq 1)
					continue;
			}
			if ( local.i gt arguments.req.maxrows )
				break;
			local.rows++;
			//dump(local.log);
			if ( !StructKeyExists(local.log, "scope") )
				local.cgi = local.log.cgi;
			else
				local.cgi  = local.log.scope.cgi; // 5.3++
			var path = local.cgi.REQUEST_URL

			if (local.cgi.REQUEST_METHOD eq "POST")
				path = "POST #PATH#";

			var _scope = "0";
			if ( StructKeyExists( local.log, "implicitAccess" ) and local.log.implicitAccess.recordcount ){
				_scope = QueryReduce( local.log.implicitAccess,
					function( problems=0, row, rowNumber, recordset ){
					return arguments.problems + arguments.row.count;
				});
			}
			var _total=0;
			var _query=0;
			var _app=0;
			var _load=0
			if ( StructKeyExists( local.log, "pages" ) ){
				loop query="local.log.pages"{
					_total += local.log.pages.total;
					_query+= local.log.pages.query;
					_app += local.log.pages.app;
					_load += local.log.pages.load;
				}
			}
			local.total_size +=  + SizeOf( local.log ) / 1000;
			local.total_app += _app;
			local.total_query += _query;
			local.total_total += _total;
			local.total_load += _load;
			local.total_scope += _scope;
		</cfscript>
		<cfoutput>
			<cfif arguments.req.consoleDump>
				<script>
					console.log( "#local.log.scope.cgi.request_url#", #SerializeJson( local.log.scope.cgi )# );
				</script>
			</cfif>
		<tr class="#altRow( local.i )#">
			<td><a href="?action=debugging.logs&action2=detail&id=#hash(local.log.id&":"&local.log.startTime)#">#path#</td>
			<td data-value=#DateDiff( 's', "2000-1-1", local.log.starttime )#>
			<cfif DateCompare( local.log.starttime, local.midnight ) eq -1>
				#DateTimeFormat( local.log.starttime )#
			<cfelse>
				#TimeFormat( local.log.starttime )#
			</cfif>
			</td>
			<td align="right">#prettyTime( _total )# </td>
			<td align="right">#prettyTime( _app )#</td>
			<td align="right">#prettyTime( _query )#</td>
			<td align="right">#prettyTime( _load )#</td>
			<td align="right">#prettyNum( _scope )#</td>
			<cfif StructKeyExists( local.log, "exceptions" )>
				<cfset local.total_exp += ArrayLen( local.log.exceptions )>
				<td align="right">#prettyNum( ArrayLen( local.log.exceptions ) )#</td>
			<cfelse>
				<td></td>
			</cfif>
			<td align="right">#prettyNum( SizeOf( local.log ) / 1000 )#</td>
		</tr>
		</cfoutput>
	</cfloop>
	</tbody>
</cfsavecontent>
<cfsavecontent variable="local.totals">
	<tr class="log-totals">
		<td colspan="2" align="center">Totals</td>
		<cfoutput>
			<td align="right">#prettyTime( local.total_total )#</td>
			<td align="right">#prettyTime( local.total_app )#</td>
			<td align="right">#prettyTime( local.total_query )#</td>
			<td align="right">#prettyTime( local.total_load )#</td>
			<td align="right">#prettyNum( local.total_scope )#</td>
			<td align="right">#prettyNum( local.total_exp )#</td>
			<td align="right">#prettyNum( local.total_size )#</td>
		</cfoutput>
	</tr>
</cfsavecontent>

<cfoutput>
	<p>This report is based on all the debugging logs currently in memory (#local.debugLogs.data.len()#), click column headers to sort</p>
	<cfif hasJavaMethod(getPageContext().getConfig().getDebuggerPool(), "purge" )>
		<input type="button" class="bm button submit" name="mainAction" value="Purge Logs"
			onclick='document.location="?action=#arguments.req.action#&plugin=#arguments.req.plugin#&pluginAction=#arguments.req.pluginAction#&doPurge=true"'>
	</cfif>
</cfoutput>

<table class="maintbl checkboxtbl sort-table">
<thead>
<tr>
	<th data-type="text">Url</th>
	<th>Timestamp</th>
	<th>Total</th>
	<th>App</th>
	<th>Query</th>
	<th>Load</th>
	<th>Scope Problems</th>
	<th>Exceptions</th>
	<th>Size (Kb)</th>
</tr>
<cfif local.rows gt 0>
	<cfoutput>#totals#</cfoutput>
</cfif>
</thead>
<cfoutput>#body#</cfoutput>
<tfoot>
	<cfif local.rows gt 10>
		<cfoutput>#totals#</cfoutput>
	</cfif>
	<tr>
		<td colspan="9" align="center">
			<br>
		<cfif local.debugLogs.data.len() eq 0>
			No logs found? Is debugging enabled?
		</cfif>
		</td>
	</tr>
	<cfif src_rows gt arguments.req.maxrows>
		<cfoutput>
		<tr>
			<td colspan="9"><br>Showing the top #arguments.req.maxrows# logs(from #src_rows#)
		</tr>
		</cfoutput>
	</cfif>
</tfoot>
</table>
<cfoutput>
    #variables.renderUtils.includeLang()#
	#variables.renderUtils.includeJavascript( "perf" )#
</cfoutput>
