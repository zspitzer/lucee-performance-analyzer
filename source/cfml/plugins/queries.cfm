<cfscript>
	param name="arguments.req.maxrows" default ="1000";
	local.queries = variables.Perf.getLogs(arguments.req, "queries");
	local.q = queries.q
	setTitle("Slowest Queries");
</cfscript>

<table class="maintbl checkboxtbl sort-table">
<thead>
<tr>
	<cfoutput>
		#renderTemplateHead()#
	</cfoutput>
	<th>Line</th>
	<th data-type="text">Name</th>
	<th data-type="text">Datasource</th>
	<th>Total time</th>
	<th>Min</th>
	<th>Max</th>
	<th>Avg</th>
	<th>Executions</th>
</tr>
</thead>
<tbody>
<cfoutput query="local.q" maxrows=#arguments.req.maxrows#>
	<tr class="#altRow(local.q.currentRow)#">
		#renderTemplateLink(arguments.req, local.q.template)#
		<td>#NumberFormat(local.q.line)#</td>
		<td>#local.q.name#</td>
		<td>#local.q.datasource#</td>
		<td align="right">#DecimalFormat(local.q.totalTime/(1000*1000))#</td>
		<td align="right">#DecimalFormat(local.q.minTime/(1000*1000))#</td>
		<td align="right">#DecimalFormat(local.q.maxTime/(1000*1000))#</td>
		<td align="right">#DecimalFormat(local.q.avgTime/(1000*1000))#</td>
		<td align="right">#NumberFormat(local.q.executions)#</td>
	</tr>
</cfoutput>
</tbody>
</table>
