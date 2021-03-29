<cfscript>
	param name="arguments.req.maxrows" default="1000";
	local._total_aborts = 0;
	local.traces = variables.Perf.getLogs(arguments.req, "traces");
	local.q = local.traces.q
	setTitle( "Traces" );
</cfscript>

<cfsavecontent variable="local.body">
	<tbody>
		<cfoutput query="local.q" maxrows=#arguments.req.maxrows#>
			<tr>

				#renderTemplateLink( arguments.req, local.q.template )#
				<td>#local.q.line#</td>
				<td>#local.q.text#</td>
				<td>#local.q.type#</td>
				<td>#local.q.action#</td>
				<td>#local.q.category#</td>
				<td align="right">#prettyTime (local.q.time * 1000 * 1000 )#</td>
				<td>
					<cfif len(local.q.var)>#local.q.var#
					<ciff len(local.q.varValue)>=#local.q.varValue#</ciff>
					</cfif>
				</td>
				<td align="right">#NumberFormat( local.q.executions )#</td>
			</tr>
			<cfscript>
				local._total_aborts += local.q.executions;
			</cfscript>
		</cfoutput>
	</tbody>
</cfsavecontent>

<cfsavecontent variable="local.totals">
	<tr class="log-totals">
		<cfoutput>
			<td colspan="#hasTemplates()+1#" align="right">Totals</td>
			<td align="right">#numberFormat( local._total_aborts )#</td>
		</cfoutput>
	</tr>
</cfsavecontent>

<table class="maintbl checkboxtbl sort-table">
<thead>
	<tr>
		<cfoutput>
			#renderTemplateHead()#
		</cfoutput>
		<th>Text</th>
		<th>Type</th>
		<th>Line</th>
		<th>Action</th>
		<th>Category</th>
		<th>Time</th>
		<th>Var</th>
		<th>Count</th>
	</tr>
	<cfif local.q.recordcount gt 10>
		<cfoutput>#totals#</cfoutput>
	</cfif>
</thead>
<cfoutput>#body#</cfoutput>
</table>