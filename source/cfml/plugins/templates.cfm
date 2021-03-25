<cfset local.debugLogs = {}>
<cfparam name="arguments.req.maxrows" default ="100">
<cfparam name="arguments.req.template" default ="">

<cfadmin action="getLoggedDebugData"
	type="#request.adminType#"
	password="#session["password"&request.adminType]#"
	returnVariable="local.debugLogs.data">

<cfscript>
	if (not structKeyExists(local.debugLogs, "data"))
		local.debugLogs.data = []; // getLoggedDebugData may return null
	var q = QueryNew('id,count,min,max,avg,app,load,query,total,src');
	setTitle("Slowest Templates");
	var local.r =0;
</cfscript>

<cfloop from="#local.debugLogs.data.len()#" to="1" step=-1 index="local.i">
	<cfscript>
		local.log = local.debugLogs.data[ local.i ];
		if ( StructKeyExists(arguments.req, "since" ) ){
			if ( dateCompare( log.starttime, arguments.req.since ) neq 1)
				continue;
		}
		// if queries isn't enabled in debug settings, there won't be data
		if ( StructKeyExists( local.log, "pages" )){
			if ( q.recordcount eq 0 ){
				q = duplicate(local.log.pages); // use existing query
			} else {
				local.pages=local.log.pages;
				loop query="#local.pages#" {
					queryAddRow( q, queryRowData( local.pages, local.pages.currentrow ) );
				}
			}
		}
	</cfscript>
</cfloop>
<!--- Qoq doesn't like count --->
<cfquery name="local.q" dbtype="query">
	select 	id,	count as _count, min as _min, max as _max, avg as _avg, app, load, query,	total,	src, '' as template,  '' as _function
	from    q
</cfquery>
<cfscript>
	loop query="q"{
		local.tmp = ListToArray( local.q.src, "$" );
		if ( ArrayLen( local.tmp ) eq 2 ){
			QuerySetCell( q, "_function", local.tmp[2], q.currentrow );
		}
		QuerySetCell( q, "template", local.tmp[1], q.currentrow );
	}
</cfscript>

<cfquery name="local.q" dbtype="query">
	select  template, _function, min(_min) as minTime, max(_max) as maxTime, avg(_avg) as avgTime,
			avg(query) as avgQuery, avg(load) as avgLoad, sum(total) as totalTime, sum(_count) as totalCount,
			sum(total) as total, count(*) as executions
	from	q
	<cfif len( arguments.req.template )>
		where template like <cfqueryparam value="#arguments.req.template#%" sqltype="varchar">
	</cfif>
	group by template, _function
	order by totalTime desc
</cfquery>

<cfscript>
	local.templates = [=]; // ordered struct
	if ( len( arguments.req.template ) && ! variables.exactTemplatePath ){
		local.files = DirectoryList( path=arguments.req.template, recurse=true, listInfo="query",
			filter = function( path ){
				local.e = listLast( arguments.path, "\/." );
				return ( Find( "cf", local.e ) eq 1 );
			}
		);
		//dump(var=local.files, top=10);
		loop query = local.files {
			templates[ local.files.directory & server.separator.file & local.files.name ] = {
				uses: 0 // count usage
				, file: QueryRowData( local.files, local.files.currentrow )
			};
		}
		//dump(var=local.templates, top=10);
	}
</cfscript>
<Cfset local.src_rows = local.q.recordcount>

<table class="maintbl checkboxtbl sort-table">
<thead>
<tr>
	<cfoutput>
		#renderTemplateHead()#
	</cfoutput>
	<th data-type="text">Function</th>
	<th>Total time</th>
	<th>Count</th>
	<th>Min</th>
	<th>Max</th>
	<th>Avg</th>
	<!---<th>Query</th>--->
	<th>Requests</th>
</tr>
</thead>
<tbody>
<cfoutput query="local.q" maxrows=#arguments.req.maxrows#>
	<tr class="#altRow(local.q.currentRow)#">
		#renderTemplateLink( arguments.req, local.q.template )#
		<td>#local.q._function#<cfif Len( local.q._function )>()</cfif></td>
		<td align="right">#NumberFormat( local.q.totalTime / ( 1000 * 1000 ) )#</td>
		<td align="right">#NumberFormat( local.q.totalCount)#</td>
		<td align="right">#NumberFormat( local.q.minTime / ( 1000 * 1000 ) )#</td>
		<td align="right">#NumberFormat( local.q.maxTime / ( 1000 * 1000 ) )#</td>
		<td align="right">#NumberFormat( local.q.avgTime / ( 1000 * 1000 ) )#</td>
		<!---<td align="right">#NumberFormat(local.q.avgQuery / ( 1000 * 1000 ) )#</td>--->
		<td align="right">#NumberFormat( local.q.executions )#</td>
	</tr>
</cfoutput>
</tbody>
<tfoot>
	<tr>
		<td colspan="9" align="center">
			<br>
		<cfif local.debugLogs.data.len() eq 0>
			No Templates logs found? Is debugging enabled?
		<cfelseif local.q.recordcount eq 0>
			No Templates found
		</cfif>
		</td>
	</tr>
	<cfif src_rows gt arguments.req.maxrows>
		<cfoutput>
		<tr>
			<td colspan="9"><br>Showing the top #arguments.req.maxrows# Templates by total execution time (from #src_rows#)
		</tr>
		</cfoutput>
	</cfif>
</tfoot>
</table>

<cfscript>
	// loop again, because cfoutput has a maxrows
	loop query="local.q" {
		if ( StructKeyExists( local.templates, local.q.template ) ){
			local.templates[ local.q.template ].uses ++;
		}
	}
</cfscript>


<cfif StructCount( local.templates ) gt 0>
	<h3>Template Usage (via current debug logs)</h3>
	<table class="maintbl checkboxtbl sort-table">
	<thead>
		<tr>
			<th data-type="text">Template</th>
			<th>Uses</th>
			<th>Size</th>
			<th>Last Modified</th>
		</tr>
	</thead>
	<cfoutput>
		<tbody>
			<cfloop collection="#local.templates#" key="local.t" value="local.c">
				<tr class=<cfif local.c.uses eq 0>"unused-template"</cfif>>
					#renderTemplateLink( arguments.req, local.t )#
					<td align="right">#NumberFormat( local.c.uses )#</td>
					<td align="right">#NumberFormat( local.c.file.size )#</td>
					<td class="no-wrap">#LSDateTimeFormat( local.c.file.dateLastModified )#</td>
				</tr>
			</cfloop>
		</tbody>
	</cfoutput>
	</table>
</cfif>
<cfoutput>
	#variables.renderUtils.includeLang()#
	#variables.renderUtils.includeJavascript( "perf" )#
</cfoutput>
