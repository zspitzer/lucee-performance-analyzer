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
	request.subtitle = "Debugging Logs";
	var local.r =0;
	cfinclude(template="toolbar.cfm");
	function prettyTime(n){
		if (n == 0)
			return "";
		 var s = n/(1000*1000);
		 if (int(s)  eq 0)
		 	return "";
		return NumberFormat(s);
	}

	function prettyNum(n){
		if (n == 0)
			return "";
		 
		 if (int(n)  eq 0)
		 	return "";
		return NumberFormat(n);
	}
	local.midnight = createDate(year(now()), month(now()), day(now()) ); // hide todays date
</cfscript>

<cfloop from="#local.debugLogs.data.len()#" to="1" step=-1 index="local.i">
	<cfscript>
		local.log = local.debugLogs.data[local.i];		
		if (StructKeyExists(req, "since")){
			if (dateCompare(log.starttime, req.since ) neq 1)
				continue;
		}
	</cfscript>
</cfloop>
<Cfset local.src_rows = local.debugLogs.data.len()>

<cfoutput>
	<p>This report is based on all the debugging logs currently in memory (#local.debugLogs.data.len()#), click column headers to sort</p>
</cfoutput>
<table class="maintbl checkboxtbl sort-table">
<thead>
<tr>
	<th data-type="text">Url</th>
	<th>Timestamp</th>
	<th>Total time</th>	
	<th>App time</th>
	<th>Query time</th>
	<th>Scope Problems</th>
	<th>Exceptions</th>	
</tr>
</thead>
<tbody>
<cfloop from="#local.debugLogs.data.len()#" to="1" step=-1 index="local.i">
	<cfscript>
		local.log = local.debugLogs.data[local.i];		
		if (StructKeyExists(req, "since")){
			if (dateCompare(log.starttime, req.since ) neq 1)
				continue;
		}
		if (local.i gt req.maxrows)
			break;
		//dump(local.log); 
		if (not structKeyExists(local.log, "scope"))
			local.cgi = local.log.cgi;
		else
			local.cgi  = local.log.scope.cgi; // 5.3++
		var path = local.cgi.SCRIPT_NAME;

		if (len(local.cgi.QUERY_STRING))
			path = path & "?" & left(local.cgi.QUERY_STRING, 50);
		if (len(local.cgi.QUERY_STRING) gt 50)
			path = path & "....";
		

		var _scope = "0";	
		if (local.log.implicitAccess.recordcount){
			_scope = QueryReduce( local.log.implicitAccess,
				function(problems=0, row, rowNumber, recordset ){
				return problems + row.count;
			});
		}
		var _total=0;
		var _query=0;
		var _app=0;
		
		loop query="local.log.pages"{
			_total += local.log.pages.total;
			_query+= local.log.pages.query;
			_app += local.log.pages.app;
		}
	</cfscript>
	<cfoutput>
	<tr>
		<td><a href="?action=debugging.logs&action2=detail&id=#hash(local.log.id&":"&local.log.startTime)#">#path#</td>
		<td data-value=#DateDiff('s', "2000-1-1", local.log.starttime)#>
		<cfif DateCompare(local.log.starttime, local.midnight) eq -1>
			#DateTimeFormat(local.log.starttime)#
		<cfelse>
			#TimeFormat(local.log.starttime)#
		</cfif>
		</td>
		<td align="right">#prettyTime(_total)#</td>
		<td align="right">#prettyTime(_app)#</td>
		<td align="right">#prettyTime(_query)#</td>
		<td align="right">#prettyNum(_scope)#</td>
		<td align="right">#prettyNum(arrayLen(local.log.exceptions))#</td>
	</tr>
	</cfoutput>
</cfloop>
</tbody>
<tfoot>
	<tr>
		<td colspan="9" align="center">
			<br>
		<cfif local.debugLogs.data.len() eq 0>
			No logs found? Is debugging enabled?
		</cfif>
		</td>
	</tr>
	<cfif src_rows gt req.maxrows>
		<cfoutput>
		<tr>
			<td colspan="9"><br>Showing the top #req.maxrows# logs(from #src_rows#)
		</tr>
		</cfoutput>
	</cfif>
</tfoot>
</table>
<cfoutput>
    #renderUtils.includeLang()#    
	#renderUtils.includeJavascript("perf")#
</cfoutput>

