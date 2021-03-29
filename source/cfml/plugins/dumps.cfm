<cfscript>
	param name="arguments.req.maxrows" default="1000";
	local._total_dumps = 0;
	local.dumps = variables.Perf.getLogs(arguments.req, "dumps");
	local.q = local.dumps.q
	setTitle( "Dumps" );
</cfscript>

<cfsavecontent variable="local.body">
	<tbody>
	<cfoutput query="local.q" maxrows=#arguments.req.maxrows#>
		<tr>
			<td>#local.q.output#</td>
			#renderTemplateLink( arguments.req, local.q.template )#
			<td>#local.q.line#</td>
			<td align="right">#NumberFormat( local.q.dumps )#</td>
		</tr>
		<cfscript>
			local._total_dumps += local.q.dumps;
		</cfscript>
	</cfoutput>
	</tbody>
</cfsavecontent>

<cfsavecontent variable="local.totals">
	<tr class="log-totals">
		<cfoutput>
			<td colspan="#hasTemplates()+4#" align="right">Totals</td>
			<td align="right">#numberFormat( local._total_dumps )#</td>
		</cfoutput>
	</tr>
</cfsavecontent>

<table class="maintbl checkboxtbl sort-table">
<thead>
	<tr>
		<th data-type="text">Output</th>
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