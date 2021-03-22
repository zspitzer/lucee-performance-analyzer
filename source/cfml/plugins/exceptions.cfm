<cfset local.debugLogs = {}>
<cfparam name="arguments.req.maxrows" default ="1000">

<cfadmin action="getLoggedDebugData"
	type="#request.adminType#"
	password="#session["password"&request.adminType]#"
	returnVariable="local.debugLogs.data">

<cfscript>
	if (not structKeyExists(local.debugLogs, "data"))
		local.debugLogs.data = []; // getLoggedDebugData may return null
	var q = QueryNew("_type,message,detail,template,line");

	request.subtitle = "Exceptions";
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
		// if exceptions isn't enabled in debug settings, there won't be data
		if (structKeyExists(local.log, "exceptions")){
			local.exceptions = local.log.exceptions;
			loop array="#local.exceptions#" item="local.exp"{
				local.r = queryAddRow(q);
				QuerySetCell (local.q, "_type", exp.type, r );
				QuerySetCell (local.q, "message", exp.message, r );
				QuerySetCell (local.q, "detail", exp.detail, r );
				QuerySetCell( local.q, "line", exp.TagContext[1].line, r );
				QuerySetCell( local.q, "template", exp.TagContext[1].template, r );
			}
		}
	</cfscript>
</cfloop>

<cfquery name="local.q" dbtype="query">
	select  _type, template, message, detail, line, count(*) as executions
	from    q
	group by _type, template, message, detail, line
	order by executions desc
</cfquery>
<cfscript>
	local.src_rows = local.debugLogs.data.len();T
	local.rows = local.q.recordcount;
	local._total_executions = 0;
</cfscript>

<cfsavecontent variable="local.body">
	<tbody>
	<cfoutput query="local.q" maxrows=#arguments.req.maxrows#>
		<tr>
			<td>#local.q._type#</td>
			<td>#local.q.message#</td>
			<td>#local.q.detail#</td>
			<td>#local.q.template#</td>
			<td>#local.q.line#</td>
			<td align="right">#NumberFormat(local.q.executions)#</td>
		</tr>
		<cfscript>
			local._total_executions += local.q.executions;
		</cfscript>
	</cfoutput>
	</tbody>
</cfsavecontent>
<cfsavecontent variable="local.totals">
	<tr class="log-totals">
		<td colspan="5" align="right">Totals</td>
		<cfoutput>
			<td align="right">#numberFormat(local._total_executions)#</td>
		</cfoutput>
	</tr>
</cfsavecontent>
<cfoutput>
	<p>This report is based on all the debugging logs currently in memory (#local.debugLogs.data.len()#), click column headers to sort</p>
</cfoutput>
<table class="maintbl checkboxtbl sort-table">
<thead>
<tr>
	<th data-type="text">Type</th>
	<th data-type="text">Message</th>
	<th data-type="text">Detail</th>
	<th data-type="text">Template</th>
	<th>Line</th>
	<th>Count</th>
</tr>
</thead>
<cfif local.rows gt 10>
	<cfoutput>#totals#</cfoutput>
</cfif>
</thead>
<cfoutput>#body#</cfoutput>
<tfoot>
	<cfif local.rows gt 0>
		<cfoutput>#totals#</cfoutput>
	</cfif>
	<tr>
		<td colspan="9" align="center">
			<br>
		<cfif local.debugLogs.data.len() eq 0>
			No debug logs found? Is debugging enabled?
		<cfelseif local.q.recordcount eq 0>
			No Exception entries found
		</cfif>
		</td>
	</tr>
	<cfif src_rows gt arguments.req.maxrows>
		<cfoutput>
		<tr>
			<td colspan="9"><br>Showing the top #arguments.req.maxrows# Exception entries by total execution time (from #src_rows#)
		</tr>
		</cfoutput>
	</cfif>
</tfoot>
</table>
<cfoutput>
	#variables.renderUtils.includeLang()#
	#variables.renderUtils.includeJavascript("perf")#
</cfoutput>

