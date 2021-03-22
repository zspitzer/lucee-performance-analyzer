<cfset local.debugLogs = {}>
<cfparam name="arguments.req.maxrows" default ="1000">
<cfparam name="arguments.req.template" default ="">

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
		if (StructKeyExists(arguments.req, "since")){
			if (dateCompare(log.starttime, arguments.req.since ) neq 1)
				continue;
		}
		// if implicitAccess isn't enabled in debug settings, there won't be data
		if (structKeyExists(local.log, "implicitAccess")){
			local.implicitAccess=local.log.implicitAccess;	
			loop query="#local.implicitAccess#" {
				queryAddRow(q, queryRowData(local.implicitAccess, local.implicitAccess.currentrow));
			}
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
	<cfif len(arguments.req.template)>
		where template like <cfqueryparam value="#arguments.req.template#%" sqltype="varchar">
	</cfif>
	group by template, line, resolvedScope, name
	order by total desc
</cfquery>
<Cfset local.src_rows = local.q.recordcount>

<cfoutput>
	<p>This report is based on all the debugging logs currently in memory (#local.debugLogs.data.len()#), click column headers to sort</p>
	<cfif len(arguments.req.template)>
		<p><b>Filtering by Template:</b>  #encodeForHtml(arguments.req.template)# 
			&nbsp; <a href="?action=#arguments.req.action#&plugin=#arguments.req.plugin#&pluginAction=#arguments.req.pluginAction#" class="toolbar-filter">Remove Filter</a>
		</p>
	</cfif>
</cfoutput>
<table class="maintbl checkboxtbl sort-table">
<thead>
<tr>
	<th data-type="text">Template</th>
	<th>Line</th>
	<th data-type="text">Variable</th>
	<th data-type="text">Resolved Scope</th>
	<th>Total</th>
</tr>
</thead>
<tbody>
<cfoutput query="local.q_implicit" maxrows="#arguments.req.maxrows#">
	<tr>
		<td><a href="?action=#arguments.req.action#&plugin=#arguments.req.plugin#&pluginAction=#arguments.req.pluginAction#&template=#urlEncodedFormat(local.q_implicit.template)#" 
			title="show only problems from this template" class="toolbar-filter">#local.q_implicit.template#</a></td>
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
	<cfif src_rows gt arguments.req.maxrows and len(arguments.req.template) eq 0>
		<cfoutput>
		<tr>
			<td colspan="9" align="center"><br>Showing the top #req.maxrows# scope problems by count (from #src_rows#)
		</tr>
	</cfoutput>
	</cfif>
</tfoot>
</table>
<cfoutput>
	#variables.renderUtils.includeLang()#
	#variables.renderUtils.includeJavascript("perf")#
</cfoutput>
