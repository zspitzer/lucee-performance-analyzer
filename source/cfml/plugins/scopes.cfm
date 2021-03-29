<cfscript>
	param name="arguments.req.maxrows" default ="100";
	local.scopes = variables.Perf.getLogs(arguments.req, "scopes");
	local.q = local.scopes.q;
	local.src_rows = local.q.recordcount
	setTitle( "Variable Scoping Problems");
</cfscript>

<table class="maintbl checkboxtbl sort-table">
<thead>
<tr>
	<cfoutput>
		#renderTemplateHead()#
	</cfoutput>
	<th>Line</th>
	<th data-type="text">Variable</th>
	<th data-type="text">Resolved Scope</th>
	<th>Total</th>
</tr>
</thead>
<tbody>
<cfoutput query="local.q" maxrows="#arguments.req.maxrows#">
	<tr class="#altRow( local.q.currentRow )#">
		#renderTemplateLink( arguments.req, local.q.template )#
		<td>#NumberFormat( local.q.line )#</td>
		<td>#local.q.name#</td>
		<td>#local.q.resolvedScope#</td>
		<td align="right">#NumberFormat( local.q.total )#</td>
	</tr>
</cfoutput>
</tbody>
</table>