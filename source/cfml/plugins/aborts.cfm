<cfscript>
	param name="arguments.req.maxrows" default="1000";
	local._total_aborts = 0;
	local.aborts = variables.Perf.getLogs(arguments.req, "aborts");
	local.q = local.aborts.q
	setTitle( "Aborts" );
</cfscript>

<cfsavecontent variable="local.body">
	<tbody>
	<cfoutput query="local.q" maxrows=#arguments.req.maxrows#>
		<tr class="#altRow( local.q.currentRow )#">
			#renderTemplateLink( arguments.req, local.q.template )#
			<td>#local.q.line#</td>
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
		<th>Line</th>
		<th>Count</th>
	</tr>
	<cfif local.q.recordcount gt 10>
		<cfoutput>#totals#</cfoutput>
	</cfif>
</thead>
<cfoutput>#body#</cfoutput>
</table>