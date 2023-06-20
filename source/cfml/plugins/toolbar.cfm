<cfscript>
	param name="arguments.req.template" default ="";
	param name="arguments.req.url" default ="";
	param name="arguments.req.log" default ="";
	variables.template = arguments.req.template;
	variables.req = arguments.req;

	local.reports = ["Requests", "Templates", "Scopes", "Queries", "Timers", "Exceptions", "Dumps", "Aborts", "Traces", "Parts", "Memory", "Threads", "Settings"];
	//if ( Len( arguments.req.template ) || Len( arguments.req.url ) || Len( arguments.req.log ) )
		ArrayPrepend(local.reports, "Analysis");
	local.path_reports = ["Requests", "Templates", "Scopes", "Queries", "Timers", "Exceptions", "Dumps", "Aborts", "Traces", "Parts"];
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

	void function renderRequestLink ( required struct req, required string linkTemplate, required string logId, string extra="" ){
		var temp = arguments.linkTemplate;
		if (len( arguments.req.url ) gt 0 and find( arguments.req.url, arguments.linkTemplate, 1 ) eq 1)
			temp = mid( arguments.linkTemplate, len( arguments.req.url ) + 1 );
		if ( Len(temp) eq 0)
			temp = arguments.linkTemplate;
		echo('<a href="?action=#arguments.req.action#&plugin=#arguments.req.plugin#&pluginAction=Analysis'
			& '&log=#urlEncodedFormat(arguments.logId)#"'
			& 'title="show only problems from this request" class="toolbar-filter">#htmleditformat( temp )#');
		if ( Len( arguments.extra ) )
			echo( ' ' & arguments.extra );
		echo(' </a> ');

	}

	void function renderTemplateLink ( required struct req, reqPath ){
		var temp = arguments.reqPath;
		if (len( arguments.req.template ) gt 0 and find( arguments.req.template, arguments.reqPath, 1 ) eq 1)
			temp = mid( arguments.reqPath, len( arguments.req.template ) + 2 );
		if ( Len(temp) eq 0)
			temp = arguments.reqPath;
		if ( !variables.exactTemplatePath ){
			echo("<td>");
			echo('<a href="?action=#arguments.req.action#&plugin=#arguments.req.plugin#&pluginAction=#arguments.req.pluginAction#'
				& '&template=#urlEncodedFormat(arguments.reqPath)#"'
				& 'title="show only problems from this template" class="toolbar-filter">#htmleditformat( temp )#</a>');
			//  TODO if (len(singleLog.scope.cgi.http_user_agent) eq 0>Empty, probably a Lucee thread)
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

	void function setTitle( string title ){
		var t = ListFirst( ListLast( GetCurrentTemplatePath(), "\/" ), "." );
		if ( variables.req.pluginAction eq t )
			echo( "<h3>#arguments.title#</h3>" );
		request.subtitle = arguments.title;
	}

	string function altRow( numeric currentrow ){
		if ( arguments.currentRow mod 2 eq 1 )
			return "alt-row";
		return "zzz";
	}

	string function prettyTime( numeric n ){
		if ( arguments.n == 0 )
			return "";
		 var s = arguments.n / ( 1000 * 1000 );
		 if ( int( s ) eq 0 )
		 	return "";
		return NumberFormat( s );
	}

	string function prettyNum( numeric n=0, boolean large=false ){
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
		<cfset local.singleLog = this.perf.getLog(arguments.req.log )>
		<cfif StructCount(singleLog)>
			<table>
			<tr>
				<td>Url</td>
				<td><a href="#singleLog.scope.cgi.request_url#" target="blank" rel="noopener">#encodeForHtml( singleLog.scope.cgi.request_url )#</a></td>
			</tr>
			<cfif len(singleLog.scope.cgi.http_referer)>
				<tr>
					<td>Http Referer</td>
					<td><a href="#singleLog.scope.cgi.http_referer#" target="blank" rel="noopener">#encodeForHtml( singleLog.scope.cgi.http_referer )#</a></td>
				</tr>
			</cfif>
			<tr>
				<td>User-Agent</td>
				<td><cfif len(singleLog.scope.cgi.http_user_agent) eq 0>Empty, probably a Lucee thread<cfelse>#encodeForHtml(singleLog.scope.cgi.http_user_agent)#</cfif></td>
			</tr>
			<cfif structKeyExists(singleLog, "StatusCode")>
				<tr>
					<td>Status-Code</td>
					<td><span class="statusCode-#Left(singleLog.statusCode,1)#">#listFirst(singleLog.statusCode," ")#</span></td>
				</tr>
			</cfif>
			<cfif structKeyExists(singleLog, "contentType")>
				<tr>
					<td>Content-Type</td>
					<td>#singleLog.contentType#</td>
				</tr>
			</cfif>
			<cfif structKeyExists(singleLog, "contentLength") and len(singleLog.contentLength) gt 0>
				<tr>
					<td>Content-Length</td>
					<td>#singleLog.contentLength#</td>
				</tr>
			</cfif>
			<cfif structKeyExists(singleLog, "applicationName") and len(singleLog.applicationName) gt 0>
				<tr>
					<td>Application Name</td>
					<td>#singleLog.applicationName#</td>
				</tr>
			</cfif>
			<cfif structKeyExists(singleLog, "threadName") and len(singleLog.threadName) gt 0>
				<tr>
					<td>Thread</td>
					<td>#singleLog.threadName#</td>
				</tr>
			</cfif>

			</table>
		<cfelse>
			Log not found?<br>
		</cfif>
		<br>
		</span>
		<cfdump label="raw debug log" var=#local.singleLog# expand=false>
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
					delim = server.separator.file;
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