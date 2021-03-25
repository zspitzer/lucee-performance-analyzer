<cfset local.debugLogs = {}>
<cfparam name="arguments.req.maxrows" default="1000">

<cfadmin action="getLoggedDebugData"
	type="#request.adminType#"
	password="#session["password"&request.adminType]#"
	returnVariable="local.debugLogs.data">

<cfscript>
	if (!StructKeyExists( local.debugLogs, "data" ) )
		local.debugLogs.data = []; // getLoggedDebugData may return null
	var q = QueryNew( "label,time,executions,template" );
	setTitle( "Timers" );
	var local.r = 0;

	function prettyTime( n ){
		if ( arguments.n == 0 )
			return "";
		 var s = arguments.n / ( 1000 * 1000 );
		 if ( int( s ) eq 0 )
		 	return "";
		return NumberFormat( s );
	}

	function prettyNum( n ){
		if ( arguments.n == 0 )
			return "";

		 if ( int( arguments.n )  eq 0 )
		 	return "";
		return NumberFormat( arguments.n );
	}
</cfscript>

<cfloop from="#local.debugLogs.data.len()#" to="1" step=-1 index="local.i">
	<cfscript>
		local.log = local.debugLogs.data[local.i];
		if ( StructKeyExists( arguments.req, "since" ) ){
			if ( DateCompare( log.starttime, arguments.req.since ) neq 1)
				continue;
		}
		// if timers isn't enabled in debug settings, there won't be data
		if ( structKeyExists( local.log, "timers") ){
			local.timers = local.log.timers;
			loop query="#local.timers#" {
				queryAddRow( q, queryRowData( local.timers, local.timers.currentrow) );
			}
		}
	</cfscript>
</cfloop>

<cfquery name="local.q" dbtype="query">
	select  label, sum(time) as totalTime, count(*) as executions, template
	from    q
	<cfif len(arguments.req.template)>
		where template like <cfqueryparam value="#arguments.req.template#%" sqltype="varchar">
	</cfif>
	group by label, template
	order by totalTime desc
</cfquery>
<cfscript>
	local.src_rows = local.debugLogs.data.len();T
	local.rows = local.q.recordcount;
	local._total_time = 0;
	local._total_executions = 0;
</cfscript>

<cfsavecontent variable="local.body">
	<tbody>
	<cfoutput query="local.q" maxrows=#arguments.req.maxrows#>
		<tr class="#altRow( local.q.currentRow )#">
			<td>#local.q.label#</td>
			#renderTemplateLink( arguments.req, local.q.template )#
			<td align="right">#prettyTime (local.q.totalTime * 1000 * 1000 )#</td>
			<td align="right">#NumberFormat( local.q.executions )#</td>
		</tr>
		<cfscript>
			local._total_time += local.q.totalTime;
			local._total_executions += local.q.executions;
		</cfscript>
	</cfoutput>
	</tbody>
</cfsavecontent>
<cfsavecontent variable="local.totals">
	<tr class="log-totals">
		<td colspan="#hasTemplates()+1#" align="right">Totals</td>
		<cfoutput>
			<td align="right">#prettyTime( local._total_time * 1000 * 1000 )#</td>
			<td align="right">#prettyNum( local._total_executions )#</td>
		</cfoutput>
	</tr>
</cfsavecontent>
<table class="maintbl checkboxtbl sort-table">
<thead>
<tr>
	<th data-type="text">Label</th>
	<cfoutput>
		#renderTemplateHead()#
	</cfoutput>
	<th>Total time</th>
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
		<cfif local.debugLogs.data.len() eq 0>
			No debug logs found? Is debugging enabled?
		<cfelseif local.q.recordcount eq 0>
			No Timer entries found
		</cfif>
		</td>
	</tr>
	<cfif src_rows gt arguments.req.maxrows>
		<cfoutput>
		<tr>
			<td colspan="9"><br>Showing the top #arguments.req.maxrows# entries by total execution time (from #src_rows#)
		</tr>
		</cfoutput>
	</cfif>
</tfoot>
</table>
<cfoutput>
	#variables.renderUtils.includeLang()#
	#variables.renderUtils.includeJavascript( "perf" )#
</cfoutput>
