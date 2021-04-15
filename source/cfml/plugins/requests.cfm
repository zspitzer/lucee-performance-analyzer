<cfscript>
	param name="arguments.req.maxrows" default ="1000";
	param name="arguments.req.consoleDump" default ="false";
	param name="arguments.req.doPurge" default ="false";

	if (arguments.req.doPurge)
		this.Perf.purgeLogs();

	setTitle( "Debugging Logs" );
	local.midnight = CreateDate( Year( Now() ), Month( Now() ), Day( Now() ) ); // hide todays date
	local.logs = this.Perf.getLogs(arguments.req, "logs");
	local.q = logs.q;
	local.baseUrl = "?action=#arguments.req.action#&plugin=#arguments.req.plugin#&pluginAction=#arguments.req.pluginAction#";
</cfscript>

<cfsavecontent variable="local.body">
	<tbody>
	<cfloop query="local.q" maxrows="#arguments.req.maxrows#">
		<cfoutput>
			<cfif arguments.req.consoleDump>
				<cfscript>
					if (!iSJson( SerializeJson( this.Perf.getLog( q.id ) ) ) )
						throw "json error";
				</cfscript>
				<script>
					console.log( "#JsStringFormat(q.requestUrl)#", #SerializeJson( this.Perf.getLog( q.id ) )# );
				</script>
			</cfif>
			<tr class="#altRow( local.q.currentRow )#">
				<td>#renderRequestLink( arguments.req, local.q.path, local.q.id )# <cfif local.q.isThread>(thread)</cfif></td>
				<td class="statusCode-#Left(local.q.statusCode,1)#">#listFirst(local.q.statusCode," ")#</td>
				<td>
				<a href="#local.baseUrl#&url=#urlEncodedFormat(q.requestUrl)#" title="Filter by Request URL">By Url</a>,&nbsp;
				<cfset local.host = this.Perf.getHost(q.requestUrl)>
				<a href="#local.baseUrl#&url=#urlEncodedFormat(host)#" title="Filter by Host: #encodeForHtml(host)#">By Host<a></td>
				<td data-value=#DateDiff( 's', "2000-1-1", local.q.starttime )#>
				<cfif DateCompare( local.q.starttime, local.midnight ) eq -1>
					#DateTimeFormat( local.q.starttime )#
				<cfelse>
					#TimeFormat( local.q.starttime )#
				</cfif>
				</td>
				<td align="right">#prettyTime( local.q.total )# </td>
				<td align="right">#prettyTime( local.q.app )#</td>
				<td align="right">#prettyTime( local.q.query )#</td>
				<td align="right">#prettyTime( local.q.load )#</td>
				<td align="right">#prettyNum( local.q.scope )#</td>
				<td align="right">#prettyNum( local.q.exceptions )#</td>
				<td align="right" title="Kb">#prettyNum( local.q.size / 1000 )#</td>
			</tr>
		</cfoutput>
	</cfloop>
	</tbody>
</cfsavecontent>

<cfsavecontent variable="local.totals">
	<tr class="log-totals">
		<td colspan="4" align="center">Totals</td>
		<cfoutput>
			<td align="right">#prettyTime( local.logs.totals.total )#</td>
			<td align="right">#prettyTime( local.logs.totals.app )#</td>
			<td align="right">#prettyTime( local.logs.totals.query )#</td>
			<td align="right">#prettyTime( local.logs.totals.load )#</td>
			<td align="right">#prettyNum( local.logs.totals.scope )#</td>
			<td align="right">#prettyNum( local.logs.totals.exceptions )#</td>
			<td align="right" title="Kb">#prettyNum( local.logs.totals.size )#</td>
		</cfoutput>
	</tr>
</cfsavecontent>

<table class="maintbl checkboxtbl sort-table">
<thead>
<tr>
	<th data-type="text">Url</th>
	<th title="http status code">Code</th>
	<th data-type="text">Filter</th>
	<th>Timestamp</th>
	<th>Total</th>
	<th>App</th>
	<th>Query</th>
	<th>Load</th>
	<th>Scope Problems</th>
	<th>Exceptions</th>
	<th>Log Size</th>
</tr>
<cfif local.q.recordcount gt 10>
	<cfoutput>#totals#</cfoutput>
</cfif>
</thead>
<cfoutput>#body#</cfoutput>
</table>
