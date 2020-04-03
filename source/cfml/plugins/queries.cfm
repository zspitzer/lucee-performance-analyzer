<Cfset local.debugLogs = {}>
<cfparam name="req.maxrows" default ="1000">

<cfadmin action="getLoggedDebugData"
	type="#request.adminType#"
	password="#session["password"&request.adminType]#"
	returnVariable="local.debugLogs.data">

<cfscript>
	if (not structKeyExists(local.debugLogs, "data"))
		local.debugLogs.data = []; // getLoggedDebugData may return null
	var q = QueryNew("name,time,sql,src,line,	count,datasource,usage,cacheType");
	request.subtitle = "Slowest Queries";
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
	<Cfset local.queries=local.log.queries>
	<cfscript>
		//dump(local.log); abort;
		loop query="#local.queries#" {
			queryAddRow(q, queryRowData(local.queries, local.queries.currentrow));
		}
	</cfscript>
</cfloop>
<!--- Qoq doesn't like count --->
<cfquery name="local.q" dbtype="query">
	select  name,time,sql,src,line,	count as total,datasource,cacheType
	from    q
</cfquery>

<cfquery name="local.q" dbtype="query">
	select  name, sum(time) as totalTime, min(time) as minTime, max(time) as maxTime, avg(time) as avgTime,
			src,line,	sum(total) as total ,datasource,cacheType, count(*) as executions
	from    q
	group by name,src,line,datasource,cacheType
	order by totalTime desc
</cfquery>
<Cfset local.src_rows = local.q.recordcount>

<cfoutput>
	<p>This report is based on all the debugging logs currently in memory (#local.debugLogs.data.len()#), click column headers to sort</p>
</cfoutput>
<table class="maintbl checkboxtbl sort-table">
<thead>
<tr>
	<th data-type="text">Template</th>
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
<cfoutput query="local.q" maxrows=#req.maxrows#>
	<tr>
		<td>#local.q.src#</td>
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
<tfoot>
	<tr>
		<td colspan="9" align="center">
			<br>
		<cfif local.debugLogs.data.len() eq 0>
			No query logs found? Is debugging enabled?
		<cfelseif local.q.recordcount eq 0>
			No Queries found
		</cfif>
		</td>
	</tr>
	<cfif src_rows gt req.maxrows>
		<cfoutput>
		<tr>
			<td colspan="9"><br>Showing the top #req.maxrows# queries by total execution time (from #src_rows#)
		</tr>
		</cfoutput>
	</cfif>
</tfoot>
</table>
<cfoutput>
	#renderUtils.includeLang()#	
	#renderUtils.includeJavascript("perf")#
</cfoutput>

