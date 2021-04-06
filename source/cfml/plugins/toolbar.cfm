<cfscript>
	param name="arguments.req.template" default ="";
	param name="arguments.req.url" default ="";
	param name="arguments.req.log" default ="";
	variables.template = arguments.req.template;
	variables.req = arguments.req;

	local.reports = ["Requests", "Templates", "Scopes", "Queries", "Timers", "Exceptions", "Dumps", "Aborts", "Traces", "Memory", "Threads", "Settings"];
	if ( Len( arguments.req.template ) || Len( arguments.req.url ) || Len( arguments.req.log ) )
		ArrayPrepend(local.reports, "Analysis");
	local.path_reports = ["Requests", "Templates", "Scopes", "Queries", "Timers", "Exceptions", "Dumps", "Aborts", "Traces"];
	local.lastLogDate = now();
	local.urlExtra = "";
	if ( StructKeyExists(arguments.req, "since") and arguments.req.since and isDate(arguments.req.since))
		urlExtra = "&since=#arguments.req.since#";
	if ( Len( arguments.req.template ) )
		urlExtra = urlExtra & "&template=" & urlEncodedFormat( arguments.req.template );
	if ( Len( arguments.req.url ) )
		urlExtra = urlExtra & "&url=" & urlEncodedFormat( arguments.req.url );
	if ( Len( arguments.req.log ) )
		urlExtra = urlExtra & "&log=" & urlEncodedFormat( arguments.req.log );

	local.cfquery = ""; // hide from scopes
	request.title = "Performance Analyzer";
	local.path = "";
	variables.exactTemplatePath = len( arguments.req.template ) eq 0 ? false:  FileExists( arguments.req.template );
	if ( variables.exactTemplatePath && DirectoryExists( arguments.req.template ))
		variables.exactTemplatePath = false;

	void function renderRequestLink ( req, linkTemplate, logId ){
		var temp = arguments.linkTemplate;
		if (len( arguments.req.url ) gt 0 and find( arguments.req.url, arguments.linkTemplate, 1 ) eq 1)
			temp = mid( arguments.linkTemplate, len( arguments.req.url ) + 1 );
		echo('<a href="?action=#arguments.req.action#&plugin=#arguments.req.plugin#&pluginAction=Analysis'
			& '&log=#urlEncodedFormat(arguments.logId)#"'
			& 'title="show only problems from this request" class="toolbar-filter">#htmleditformat( temp )#</a>');

	}

	void function renderTemplateLink ( req, reqPath ){
		var temp = arguments.reqPath;
		if (len( arguments.req.template ) gt 0 and find( arguments.req.template, arguments.reqPath, 1 ) eq 1)
			temp = mid( arguments.reqPath, len( arguments.req.template ) + 2 );
		if ( !variables.exactTemplatePath ){
			echo("<td>");
			echo('<a href="?action=#arguments.req.action#&plugin=#arguments.req.plugin#&pluginAction=#arguments.req.pluginAction#'
				& '&template=#urlEncodedFormat(arguments.reqPath)#"'
				& 'title="show only problems from this template" class="toolbar-filter">#htmleditformat( temp )#</a>');
			echo("</td>");
		}
	}

	void function renderTemplateHead(){
		if ( !variables.exactTemplatePath )
			echo( '<th data-type="text">Template</th>' );
	};

	boolean function hasTemplates(){
		return variables.exactTemplatePath ? 0 : 1;
	};

	void function setTitle(title){
		var t = ListFirst( ListLast( GetCurrentTemplatePath(), "\/" ), "." );
		if ( variables.req.pluginAction eq t )
			echo( "<h3>#arguments.title#</h3>" );
		request.subtitle = arguments.title;
	}

	string function altRow(currentrow){
		if ( arguments.currentRow mod 2 eq 1 )
			return "alt-row";
		return "zzz";
	}

	string function prettyTime( n ){
		if ( arguments.n == 0 )
			return "";
		 var s = arguments.n / ( 1000 * 1000 );
		 if ( int( s ) eq 0 )
		 	return "";
		return NumberFormat( s );
	}

	string function prettyNum( n=0, boolean large=false ){
		if ( arguments.n == 0 )
			return "";

		if ( int( arguments.n ) eq 0 )
			 return "";
		if ( arguments.large )
			return NumberFormat( arguments.n / 1024 );
		else
			return NumberFormat( arguments.n );
	}
	local.baseUrl = "?action=#arguments.req.action#&plugin=#arguments.req.plugin#&pluginAction=#arguments.req.pluginAction#";
</cfscript>

<cfif len( arguments.req.log )>
	<cfoutput>
		<span class="toolbar-file-filter">
		<h3>Request Log: #arguments.req.log#
			&nbsp; <a href="#local.baseUrl#" class="toolbar-filter" title="Remove URL Filter">(clear)</a>
		</h3>
		</span>
		<hr>
	</cfoutput>
</cfif>

<cfif len( arguments.req.url )>
	<cfscript>
		local.delim = "";
		local.offset = 0;
		local.pLen = listLen( arguments.req.url, "/" );
		local.p = 0;
		local.urlFragments = this.Perf.splitUrl(arguments.req.url);
		//dump(local.urlFragments);
	</cfscript>
	<cfoutput>
		<span class="toolbar-file-filter">
		<h3> URL:
			<cfloop collection="#local.urlFragments#" key="local.u" value="local.v">
				<a href="#local.baseUrl#&template=#UrlEncodedFormat( path )#&url=#urlEncodedFormat( local.u )#" style="color:black;"
					title="Filter by Request URL: #EncodeForHtml(local.u)#">
					#delim# #encodeForHtml( local.v )#
				</a>
				<cfset delim="/">
			</cfloop>
			&nbsp; <a href="#local.baseUrl#" class="toolbar-filter" title="Remove URL Filter">(clear)</a>
		</h3>
		</span>
		<hr>
	</cfoutput>
</cfif>

<cfif len( arguments.req.template )>
	<cfscript>
		local.delim = "";
		local.offset = 0;
		local.pLen=listLen( arguments.req.template, "\/" );
		local.p = 0;
	</cfscript>
	<cfoutput>
		<span class="toolbar-file-filter">
		<cfif variables.exactTemplatePath>
			<h1><a href="#local.baseUrl#&template=#urlEncodedFormat( arguments.req.template )#&Url=#urlEncodedFormat( arguments.req.url )#"
					title="Filtering exact by Template path: #EncodeForHtml(arguments.req.template)#"
					style="color:black;">
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
						<a href="#local.baseUrl#&template=#urlEncodedFormat( path )#&url=#urlEncodedFormat( arguments.req.url )#" style="color:black;"
							title="Filter by Template path: #EncodeForHtml(path)#">
							#encodeForHtml( folder )#
						</a>
					</cfif>
				<cfscript>
					local.offset += len( local.folder ) +1;
					delim = mid( arguments.req.template, local.offset, 1 );
				</cfscript>
			</cfloop>
			&nbsp; <a href="#local.baseUrl#" class="toolbar-filter" title="Remove Template Path Filter">(clear)</a>
		</h3>
	</span>
		<hr>
	</cfoutput>
</cfif>

<div class="btn-group" role="group">
<cfoutput>
	<cfloop array=#local.reports# item="local.report">
		<a href="?action=#arguments.req.action#&plugin=#arguments.req.plugin#&pluginAction=#report#&#urlExtra#" class="toolbar-filter">
			<cfif arguments.req.pLuginAction eq report><b></cfif>#ucFirst(report)#
			<cfif arguments.req.pLuginAction eq report></b></cfif>
		</a>
	</cfloop>
</cfoutput>
</div>
<hr>
<cfoutput>
<cfif StructKeyExists( arguments.req, "since" )>
	<p>Filter: Only reporting logs since #DateTimeFormat( arguments.req.since )#
		<a href="#local.baseUrl#" class="toolbar-filter">
		 (remove filter)
		</a>
	</p>
</cfif>
<cfif lastLogDate neq "false" or StructKeyExists( arguments.req, "since" )>
	<p>Refresh with only new logs
		<a href="#local.baseUrl#&since=#DateTimeFormat(lastlogDate,"yyyy-mm-dd HH:MM:SS")#" class="toolbar-filter">
			#LSDateTimeFormat( lastLogDate )#
	   </a>
</p>
</cfif>
</cfoutput>