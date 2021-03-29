<cfscript>
	param name="arguments.req.maxrows" default="1000";
	local._total_executions = 0;
	local.exceptions = variables.Perf.getLogs(arguments.req, "exceptions");
	local.q = local.exceptions.q
	setTitle( "Exceptions" );
</cfscript>

<cfsavecontent variable="local.body">
	<tbody>
	<cfoutput query="local.q" maxrows=#arguments.req.maxrows#>
		<tr>
			<td>#local.q._type#</td>
			<td>#local.q.message#</td>
			<td>#local.q.detail#</td>
			#renderTemplateLink( arguments.req, local.q.template )#
			<td>#local.q.line#</td>
			<td align="right">#NumberFormat( local.q.executions )#</td>
		</tr>
		<cfscript>
			local._total_executions += local.q.executions;
		</cfscript>
	</cfoutput>
	</tbody>
</cfsavecontent>

<cfsavecontent variable="local.totals">
	<tr class="log-totals">
		<cfoutput>
			<td colspan="#hasTemplates()+4#" align="right">Totals</td>
			<td align="right">#numberFormat( local._total_executions )#</td>
		</cfoutput>
	</tr>
</cfsavecontent>

<table class="maintbl checkboxtbl sort-table">
<thead>
	<tr>
		<th data-type="text">Type</th>
		<th data-type="text">Message</th>
		<th data-type="text">Detail</th>
		<cfoutput>
			#renderTemplateHead()#
		</cfoutput>
		<th>Line</th>
		<th>Count</th>
	</tr>
	<cfif local.q.recordcount gt 10>
		<cfoutput>#totals#</cfoutput>
	</cfif>
</thead>
<cfoutput>#body#</cfoutput>
</table>