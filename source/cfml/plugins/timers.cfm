<cfscript>
	param name="arguments.req.maxrows" default="1000";
	local.timers = variables.Perf.getLogs(arguments.req, "timers");
	local.q = timers.q;
	local._total_time = 0;
	local._total_executions = 0;
	setTitle( "Timers" );
</cfscript>

<cfsavecontent variable="local.body">
	<tbody>
		<cfoutput query="local.q" maxrows=#arguments.req.maxrows#>
			<tr class="#altRow( local.q.currentRow )#">
				<td>#local.q.label#</td>
				#renderTemplateLink( arguments.req, local.q.template )#
				<td>#local.q.line#</td>
				<td align="right">#prettyTime (local.q.totalTime * 1000 * 1000 )#</td>
				<td align="right">#DecimalFormat(local.q.minTime/(1000*1000))#</td>
				<td align="right">#DecimalFormat(local.q.maxTime/(1000*1000))#</td>
				<td align="right">#DecimalFormat(local.q.avgTime/(1000*1000))#</td>
				<td align="right">#NumberFormat( local.q.executions )#</td>
			</tr>
			<cfscript>
				local._total_time += local.q.totalTime;
				local._total_executions += local.q.executions;
			</cfscript>
		</cfoutput>
	</tbody>
</cfsavecontent>

<cfsavecontent variable="local.totals">
	<tr class="log-totals">
		<td colspan="#hasTemplates()+1#" align="right">Totals</td>
		<cfoutput>
			<td align="right">#prettyTime( local._total_time * 1000 * 1000 )#</td>
			<td align="right">#prettyNum( local._total_executions )#</td>
		</cfoutput>
	</tr>
</cfsavecontent>

<table class="maintbl checkboxtbl sort-table">
<thead>
	<tr>
		<th data-type="text">Label</th>
		<cfoutput>
			#renderTemplateHead()#
		</cfoutput>
		<th>Line</th>
		<th>Total time</th>
		<th>Min</th>
		<th>Max</th>
		<th>Avg</th>
		<th>Count</th>
	</tr>
	<cfif local.q.recordcount gt 10>
		<cfoutput>#totals#</cfoutput>
	</cfif>
</thead>
<cfoutput>#body#</cfoutput>
</table>
