<cfscript>
	param name="arguments.req.template" default ="";
	param name="arguments.req.maxrows" default ="100";
	setTitle("Page Parts");
	local.parts = this.Perf.getLogs(arguments.req, "parts");
	local.q = local.parts.q;
</cfscript>


<table class="maintbl checkboxtbl sort-table">
<thead>
	<tr>
		<cfoutput>
			#renderTemplateHead()#
		</cfoutput>
		<th>Lines</th>
		<th>Total time</th>
		<th>Count</th>
		<th>Min</th>
		<th>Max</th>
		<th>Avg</th>
		<!---<th>Query</th>--->
		<th>Requests</th>
	</tr>
</thead>
<tbody>
	<cfoutput query="local.q" maxrows=#arguments.req.maxrows#>
		<tr class="#altRow(local.q.currentRow)#">
			#renderTemplateLink( arguments.req, local.q.template )#
			<td align="right">#local.q.lines#</td>
			<td align="right">#NumberFormat( local.q.totalTime / ( 1000 * 1000 ) )#</td>
			<td align="right">#NumberFormat( local.q.totalCount)#</td>
			<td align="right">#NumberFormat( local.q.minTime / ( 1000 * 1000 ) )#</td>
			<td align="right">#NumberFormat( local.q.maxTime / ( 1000 * 1000 ) )#</td>
			<td align="right">#NumberFormat( local.q.avgTime / ( 1000 * 1000 ) )#</td>
			<!---<td align="right">#NumberFormat(local.q.avgQuery / ( 1000 * 1000 ) )#</td>--->
			<td align="right">#NumberFormat( local.q.executions )#</td>
		</tr>
	</cfoutput>
</tbody>
</table>
