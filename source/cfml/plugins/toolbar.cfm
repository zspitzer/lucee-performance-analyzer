<cfscript>
	param name="arguments.req.template" default ="";
	variables.template = arguments.req.template;
	variables.req = arguments.req;
	local.reports = ["Logs","Templates", "Scopes","Queries","Timers","Exceptions","Memory","Threads"];
	local.path_reports = ["Templates","Scopes","Queries","Timers","Exceptions"];
	local.lastLogDate = now();
	local.urlExtra = "";
	if ( StructKeyExists(arguments.req, "since") and arguments.req.since and isDate(arguments.req.since))
		urlExtra = "since=#arguments.req.since#";
	if (len(arguments.req.template))
		urlExtra = urlExtra & "template=" & urlEncodedFormat(arguments.req.template);

	local.cfquery = ""; // hide from scopes
	request.title = "Performance Analyzer";
	local.path = "";
	variables.exactTemplatePath = len( arguments.req.template ) eq 0 ? false:  FileExists( arguments.req.template );
	if (variables.exactTemplatePath && DirectoryExists( arguments.req.template ))
		variables.exactTemplatePath = false;

	function renderTemplateLink ( req, linkTemplate ){
		var temp = arguments.linkTemplate;
		if (len( arguments.req.template ) gt 0 and find( arguments.req.template, arguments.linkTemplate, 1 ) eq 1)
			temp = mid( arguments.linkTemplate, len(arguments.req.template)+2 );
		if (!variables.exactTemplatePath ){
			echo("<td>");
			echo('<a href="?action=#arguments.req.action#&plugin=#arguments.req.plugin#&pluginAction=#arguments.req.pluginAction#'
				& '&template=#urlEncodedFormat(arguments.linkTemplate)#"'
				& 'title="show only problems from this template" class="toolbar-filter">#htmleditformat(temp)#</a>')
			echo("</td>");
		}
	}

	function renderTemplateHead(){
		if (!variables.exactTemplatePath)
			echo('<th data-type="text">Template</th>');
	};

	function hasTemplates(){
		return variables.exactTemplatePath ? 0 : 1;
	};

	function setTitle(title){
		var t = listFirst(ListLast(getCurrentTemplatePath(),"\/"), ".");
		if (variables.req.pluginAction eq t)
			echo("<h3>#arguments.title#</h3>");
		request.subtitle = arguments.title;
	}

	function altRow(currentrow){
		if ( arguments.currentRow mod 2 eq 0 )
			return "alt-row";
		return "zzz";
	}

</cfscript>
<cfif len(arguments.req.template)>
	<cfscript>
		local.delim = "";
		local.offset=0;
		local.pLen=listLen( arguments.req.template, "\/" );
		local.p=0;
	</cfscript>
	<cfoutput>
		<cfif variables.exactTemplatePath>
			<h1><a href="?action=#arguments.req.action#&plugin=#arguments.req.plugin#&pluginAction=#arguments.req.pluginAction#&template=#urlEncodedFormat( arguments.req.template )#" style="color:black;">
				#ListLast( arguments.req.template, "\/" )#
				</a>
			</h1>
			<cfset plen-->
		</cfif>
		<h3>
			<cfloop list="#arguments.req.template#" item="local.folder" delimiters="/\">
				<cfset p++>
				<cfset path = path & delim  & folder>

					<cfif p lte pLen>
						#delim#
						<a href="?action=#arguments.req.action#&plugin=#arguments.req.plugin#&pluginAction=#arguments.req.pluginAction#&template=#urlEncodedFormat( path )#" style="color:black;">
							#encodeForHtml( folder )#
						</a>
					</cfif>
				<cfscript>
					local.offset += len( local.folder ) +1;
					delim = mid( arguments.req.template, local.offset, 1 );
				</cfscript>
			</cfloop>
			&nbsp; <a href="?action=#arguments.req.action#&plugin=#arguments.req.plugin#&pluginAction=#arguments.req.pluginAction#" class="toolbar-filter">(clear)</a>
		</h3>
	</p>
	<hr>
</cfoutput>
</cfif>

<div class="btn-group" role="group">
<cfoutput>
	<cfloop array=#local.reports# item="local.report">
		<a href="?action=#arguments.req.action#&plugin=#arguments.req.plugin#&pluginAction=#report#&#urlExtra#" class="toolbar-filter">
			<cfif arguments.req.pLuginAction eq report><b></cfif>#ucase(report)#
			<cfif arguments.req.pLuginAction eq report></b></cfif>
		</a>
	</cfloop>
</cfoutput>
</div>
<hr>
<cfoutput>
<cfif StructKeyExists(arguments.req, "since")>
	<p>Filter: Only reporting logs since #dateTimeFormat(arguments.req.since)#
		<a href="?action=#arguments.req.action#&plugin=#arguments.req.plugin#&pluginAction=#arguments.req.pluginAction#" class="toolbar-filter">
		 (remove filter)
		</a>
	</p>
</cfif>
<cfif lastLogDate neq "false" or StructKeyExists(arguments.req, "since")>
	<p>Refresh with only new logs
		<a href="?action=#arguments.req.action#&plugin=#arguments.req.plugin#&pluginAction=#arguments.req.pluginAction#&since=#DateTimeFormat(lastlogDate,"yyyy-mm-dd HH:MM:SS")#" class="toolbar-filter">
			#DateTimeFormat(lastLogDate)#
	   </a>
</p>
</cfif>
</cfoutput>