<Cfset local.debugLogs = {}>
<cfparam name="req.maxrows" default ="1000">

<cfadmin action="getLoggedDebugData"
	type="#request.adminType#"
	password="#session["password"&request.adminType]#"
	returnVariable="local.debugLogs.data">

<cfscript>
	if (not structKeyExists(local.debugLogs, "data"))
		local.debugLogs.data = []; // getLoggedDebugData may return null
	var q = QueryNew("template,line,scope,count,name");
	request.subtitle = "Varscoping Problems";
	var local.r =0;
	cfinclude(template="toolbar.cfm");
</cfscript>

<cfloop from="#local.debugLogs.data.len()#" to="1" step=-1 index="local.i">
	<cfscript>
		local.log = local.debugLogs.data[local.i];
		if (StructKeyExists(req, "since")){
			if (dateCompare(log.starttime, req.since ) neq 1)
				continue;
		}
	</cfscript>
	<Cfset local.implicitAccess=local.log.implicitAccess>
	<cfscript>
		loop query="#local.implicitAccess#" {
			queryAddRow(q, queryRowData(local.implicitAccess, local.implicitAccess.currentrow));
		}
	</cfscript>
</cfloop>
<!--- Qoq doesn't like count --->
<cfquery name="local.q" dbtype="query">
	select  template, line, scope as resolvedScope, count as total ,name
	from    q
</cfquery>

<cfquery name="local.q_implicit" dbtype="query">
	select  template, line, resolvedScope, sum(total) total ,name
	from    q
	group by template, line, resolvedScope, name
	order by total desc
</cfquery>
<Cfset local.src_rows = local.q.recordcount>

<cfoutput>
	<p>This report is based on all the debugging logs currently in memory (#local.debugLogs.data.len()#), click column headers to sort</p>
</cfoutput>
<table class="maintbl checkboxtbl sort-table">
<thead>
<tr>
	<th data-sort-type="text">Template</th>
	<th>Line</th>
	<th data-sort-type="text">Variable</th>
	<th data-sort-type="text">Resolved Scope</th>
	<th>Total</th>
</tr>
</thead>
<tbody>
<cfoutput query="local.q_implicit" maxrows="#req.maxrows#">
	<tr>
		<td>#local.q_implicit.template#</td>
		<td>#NumberFormat(local.q_implicit.line)#</td>
		<td>#local.q_implicit.name#</td>
		<td>#local.q_implicit.resolvedScope#</td>
		<td align="right">#NumberFormat(local.q_implicit.total)#</td>
	</tr>
</cfoutput>
</tbody>
<tfoot>
	<tr>
		<td colspan="9" align="center"><br>
		<cfif local.debugLogs.data.len() eq 0>
			No debug logs found? Is debugging enabled?
		<cfelseif local.q_implicit.recordcount eq 0>
			Great! No Implicit access found
		<cfelse>
		</cfif>
		</td>
	</tr>
	<cfif src_rows gt req.maxrows>
		<cfoutput>
		<tr>
			<td colspan="9" align="center"><br>Showing the top #req.maxrows# scope problems by count (from #src_rows#)
		</tr>
	</cfoutput>
	</cfif>
</tfoot>
</table>
<cfoutput>
	#renderUtils.includeLang()#
	#renderUtils.includeJavascript("perf")#
</cfoutput>
