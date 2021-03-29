<cfscript>
	param name="arguments.req.template" default ="";
	param name="arguments.req.maxrows" default ="100";
	setTitle("Slowest Templates");
	local.pages = variables.Perf.getLogs(arguments.req, "pages");
	local.q = local.pages.q;
</cfscript>

<cfscript>
	local.templates = [=]; // ordered struct
	if ( len( arguments.req.template ) && ! variables.exactTemplatePath ){
		timer label='DirectoryList(path=#arguments.req.template#, recurse=true, listInfo="path")' {
			local.files = DirectoryList( path=arguments.req.template, recurse=true, listInfo="path",
				filter = function( path ){
					local.e = listLast( arguments.path, "\/." );
					return ( Find( "cf", local.e ) eq 1 );
				}
			);
		}
		//dump(var=local.files, top=10);
		loop array = local.files index="local.file"{
			templates[ local.file ] = {
				uses: 0 // count usage
				, file: local.file
			};
		}
		//dump(var=local.templates, top=10);
	}
</cfscript>

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
</table>

<cfscript>
	// loop again, because cfoutput has a maxrows
	loop query="local.q" {
		if ( StructKeyExists( local.templates, local.q.template ) ){
			local.templates[ local.q.template ].uses ++;
		}
	}
</cfscript>

<cftimer label="templates-usage">
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
				<cfset local.usage = 0>
				<cfloop collection="#local.templates#" key="local.t" value="local.c">
					<tr class=<cfif local.c.uses eq 0>"unused-template"</cfif>>
						#renderTemplateLink( arguments.req, local.t )#
						<cfset local.fi = getFileInfo(local.c.file)>
						<td align="right">#NumberFormat( local.c.uses )#</td>
						<td align="right">#NumberFormat( fi.size)#</td>
						<td class="no-wrap">#LSDateTimeFormat( fi.lastModified )#</td>
					</tr>
					<cfset local.usage ++>
					<cfif local.usage gt arguments.req.maxrows>
						<cfbreak>
					</cfif>
				</cfloop>
			</tbody>
		</cfoutput>
		</table>
	</cfif>
</cftimer>