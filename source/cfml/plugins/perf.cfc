component {
	this.debugLogs = [];
	this.debugLogsIndex = {};
	this.filtered = false;
	variables.cfquery ="";

	public void function init (){
		admin action="getLoggedDebugData"
			type="#request.adminType#"
			password="#session["password"&request.adminType]#"
			returnVariable="this.debugLogs";
		timer label="prepare Logs" {
			loop from="#this.debugLogs.len()#" to="1" step=-1 index="local.i" {
				if ( !StructKeyExists( this.debugLogs[i], "scope" ) )
					this.debugLogs[ i ]["scope"].scope.cgi = local.log.cgi; // pre 5.3++
				if ( !StructKeyExists( this.debugLogs[i], "size" ) )
					this.debugLogs[ i ]["size"] = SizeOf( this.debugLogs[i] ); // expensive, do it once (cheeky, debug logs are writeable)
				this.debugLogsIndex[ this.debugLogs[i].id ] = i;
			}
		}
		if (IsNull(this.debugLogs))
			this.debugLogs = [];
	}

	public void function purgeLogs(){
		try {
			admin action="purgeDebugPool"
				type="#request.adminType#"
				password="#session["password"&request.adminType]#";
			this.debugLogs = [];
		} catch ( e ){
			```
				<cfoutput>
					<b>Sorry, Purge logs failed, it was added in Lucee 5.3.8.80 (this is #server.lucee.version#)</b>
				</cfoutput>
				<cfdump var="#cfcatch#" expand="false" label='cfadmin action="purgeDebugPool" failed'>
				<cfabort>
			```
		}
	}

	public struct function splitUrl( requestUrl ){
		var frags = [=]; // ordered
		var offset = 0;
		var str = "";
		var doubleSlash = find( "//", arguments.requestUrl );
		var singleSlash = find( "/", arguments.requestUrl, doubleSlash + 2 );
		var qs = find( "?", arguments.requestUrl);
		if (singleSlash eq 0 ){
			frags[ arguments.requestUrl ] = arguments.requestUrl;
		} else {
			var f = Mid( arguments.requestUrl, 1, singleSlash );
			frags[f] = f;
			offset = singleSlash + 1;
			if ( len( arguments.requestUrl ) gt offset){
				if (qs gt 0){
					str = Mid( arguments.requestUrl, offset, qs - offset );
				} else {
					str = Mid( arguments.requestUrl, offset );
				}

				if ( Len(str) gt 0 ){
					loop list="#str#" item="folder" delimiters="/" {
						f = f & folder;
						frags[ f ] = folder;
					}
				}
			}

		}
		if ( qs gt 0 ){
			frags[ arguments.requestUrl ] = Mid( arguments.requestUrl, qs );
		}
		/*
		dump(local);
		dump(arguments);
		abort;
		*/
		return frags;

	};

	public string function getHost( string requestUrl ){
		local.doubleSlash = Find( "//", arguments.requestUrl );
		if ( doubleSlash gte 0 ){
			local.singleSlash = Find( "/", arguments.requestUrl, doubleSlash + 2 );
			if ( singleSlash gt 0 )
				return Mid( arguments.requestUrl, 1, singleSlash );
		}
		return arguments.requestUrl;
	}

	public struct function getLog( string logId ){
		if ( StructKeyExists( this.debugLogsIndex, arguments.logId )
				&& ArrayIndexExists( this.debugLogs, this.debugLogsIndex[ arguments.logId ]))
			return this.debugLogs[ this.debugLogsIndex[ arguments.logId ] ];
		else
			return {};

	}

	public struct function getLogs(struct req={}, string logType=""){
		var reqUrl = arguments.req?.url?: "";
		var reqTemplate = arguments.req?.template?: "";
		var reqLog = arguments.req?.log?: "";
		if ( IsNull( reqUrl ) && logType == ""){
			return local.debugLogs;
		} else {
			if ( len( reqLog ) gt 0 ){
				local.logs = this.debugLogs.filter(function(row){
					return arguments.row.id eq reqLog;
				});
			} else if ( len( reqUrl ) gt 0 ){
				timer label="logs filter reqUrl(#reqUrl#)" {
					local.logs = this.debugLogs.filter(function(row){
						return arguments.row.scope.cgi.REQUEST_URL contains variables.reqUrl;
					});
				}
			} else {
				local.logs = this.debugLogs;
			}
			request.hiddenPerfAnalyzerOwnLogs = 0;
			// hide performance analyzer
			if ( application.applicationName eq "lucee-performance-analzyer" ){
				var perfUrl = ListFirst( cgi.REQUEST_URL, "?" );
				local.logs = local.logs.filter( function( row ){
					var notPerfAnalyzer = arguments.row.scope.cgi.REQUEST_URL does not contain variables.perfUrl;
					if (notPerfAnalyzer){
						return true;
					} else {
						request.hiddenPerfAnalyzerOwnLogs++;
						return false;
					}

				});
			}

			return getFilteredLogs( logs, reqTemplate, arguments.logType );
		}
	}

	public numeric function getRawLogCount(){
		return ArrayLen( this.debugLogs );
	}

	public string function getDebugMemUsage(){
		local.s = 0;
		loop from="#this.debugLogs.len()#" to="1" step=-1 index="local.i" {
			local.s += this.debugLogs[ local.i ].size;
		}
		return DecimalFormat( local.s / 1024 / 1024 ) & " Mb";
	}

	public struct function getFilteredLogs( logs, reqTemplate, logType ){
		local.q = false;
		timer label="getFilteredLogs:#arguments.logType#" {
			switch (arguments.logType){
				case "timers":
					local.result = getTimers( arguments.logs );
					break;
				case "pages":
					local.result = getPages( arguments.logs );
					break;
				case "parts":
					local.result = getParts( arguments.logs );
					break;
				case "exceptions":
					local.result = getExceptions( arguments.logs );
					break;
				case "scopes":
					local.result = getScopes( arguments.logs );
					break;
				case "queries":
					local.result = getQueries( arguments.logs );
					break;
				case "logs":
					local.result = getDebugLogs( arguments.logs );
					break;
				case "dumps":
					local.result = getDumps( arguments.logs );
					break;
				case "aborts":
					local.result = getAborts( arguments.logs );
					break;
				case "traces":
					local.result = getTraces( arguments.logs );
					break;
				default:
					throw "write code zac! [#arguments.logType#]";
			}
		}
		result.sourceRows = local.result.q.recordcount;

		if ( len( arguments.reqTemplate ) gt 0 ){
			this.reqTemplate = arguments.reqTemplate;
			timer label="query.filter reqTemplate(#arguments.reqTemplate#)"{
				local.result.q = local.result.q.filter( function( row ){
					return arguments.row.template contains this.reqTemplate;
				});
			}
		}

		return local.result;
	}

	// TODO since

	public struct function getTimers( required array logs ){
		var q_timers = QueryNew( "label,time,executions,template,line,requestUrl" );
		loop from="#arguments.logs.len()#" to="1" step=-1 index="local.i" {
			local.log = arguments.logs[local.i];
			if ( structKeyExists( local.log, "timers") ){
				local.timers = local.log.timers;
				loop query="#local.timers#" {
					local.r = queryAddRow( q_timers, queryRowData( local.timers, local.timers.currentrow ) );
					QuerySetCell( q_timers, "requestUrl", local.log.scope.cgi.REQUEST_URL, local.r );
				}
			}
		}
		```
		<cfquery name="local.q_timers" dbtype="query">
			select  label, sum(time) as totalTime, count(*) as executions, template, line,
					min(time) as minTime, max(time) as maxTime, avg(time) as avgTime
			from    q_timers
			group by label, template, line
			order by totalTime desc
		</cfquery>
		```
		return {
			q: q_timers
		};
	}

	public struct function getPages( required array logs ){
		var q = QueryNew('id,count,min,max,avg,app,load,query,total,src,template,requestUrl');
		loop from="#arguments.logs.len()#" to="1" step=-1 index="local.i" {
			local.log = arguments.logs[local.i];
			if ( StructKeyExists( local.log, "pages" )){
				local.pages=local.log.pages;
				loop query="#local.pages#" {
					local.r = queryAddRow( q, queryRowData( local.pages, local.pages.currentrow ) );
					QuerySetCell( q, "requestUrl", local.log.scope.cgi.REQUEST_URL, local.r );
					QuerySetCell( q, "template", local.q.src[r], local.r );
				}
			}
		}
		<!--- Qoq doesn't like count --->
		```
		<cfquery name="local.q_pages" dbtype="query">
			select 	id,	count as _count, min as _min, max as _max, avg as _avg, app, load, query,	total,	src, '' as template,  '' as _function
			from    q
		</cfquery>
		<cfscript>
			loop query="q_pages" {
				local.tmp = ListToArray( local.q_pages.src, "$" );
				if ( ArrayLen( local.tmp ) eq 2 ){
					QuerySetCell( q_pages, "_function", local.tmp[2], q_pages.currentrow );
				}
				QuerySetCell( q_pages, "template", local.tmp[1], q_pages.currentrow );
			}
		</cfscript>

		<cfquery name="local.q_pages" dbtype="query">
			select  template, _function, min(_min) as minTime, max(_max) as maxTime, avg(_avg) as avgTime,
					avg(query) as avgQuery, avg(load) as avgLoad, sum(total) as totalTime, sum(_count) as totalCount,
					sum(total) as total, count(*) as executions
			from	q_pages
			group by template, _function
			order by totalTime desc
		</cfquery>
		```

		return {
			q: q_pages
		};
	}

	public struct function getParts( required array logs ){
		var q = QueryNew('id,count,min,max,avg,total,path,start,end,startLine,endLine,snippet,template,requestUrl,lines');
		loop from="#arguments.logs.len()#" to="1" step=-1 index="local.i" {
			local.log = arguments.logs[local.i];

			if ( StructKeyExists( local.log, "pageParts" )){
				local.parts=local.log.pageParts;
				loop query="#local.parts#" {
					local.r = queryAddRow( q, queryRowData( local.parts, local.parts.currentrow ) );
					QuerySetCell( q, "requestUrl", local.log.scope.cgi.REQUEST_URL, local.r );
					QuerySetCell( q, "template", local.q.path[r], local.r );
					QuerySetCell( q, "lines", "#local.q.startline[r]# - #local.q.endline[r]#", local.r );
				}
			}
		}
		// QoQ doesn't like count
		```
		<cfquery name="local.q_parts" dbtype="query">

			select 	id,	count as _count, min as _min, max as _max, avg as _avg,
					total, path, start, end as _end, startLine, endLine, snippet, template, requestUrl, lines
			from    q
		</cfquery>

		<cfquery name="local.q_parts" dbtype="query">
			select  template, lines, min(_min) as minTime, max(_max) as maxTime, avg(_avg) as avgTime,
					sum(total) as totalTime, sum(_count) as totalCount,
					sum(total) as total, count(*) as executions, snippet, start, _end
			from	q_parts
			group by template, lines, snippet, start, _end
			order by totalTime desc
		</cfquery>
		```
		return {
			q: q_parts
		};
	}

	public struct function getScopes( required array logs ){
		var q_scopes = QueryNew( "template,line,scope,count,name,requestUrl" );
		loop from="#arguments.logs.len()#" to="1" step=-1 index="local.i" {
			local.log = arguments.logs[local.i];
			// if implicitAccess isn't enabled in debug settings, there won't be data
			if (structKeyExists( local.log, "implicitAccess" )){
				local.implicitAccess = local.log.implicitAccess;
				loop query="#local.implicitAccess#" {
					QueryAddRow( q_scopes, QueryRowData( local.implicitAccess, local.implicitAccess.currentrow ) );
				}
			}
		}
		<!--- Qoq doesn't like count --->
		```
		<cfquery name="local.q_scopes" dbtype="query">
			select  template, line, scope as resolvedScope, count as total ,name
			from    q_scopes
		</cfquery>

		<cfquery name="local.q_scopes" dbtype="query">
			select  template, line, resolvedScope, sum(total) total ,name
			from    q_scopes
			group 	by template, line, resolvedScope, name
			order 	by total desc
		</cfquery>
		```

		return {
			q: q_scopes
		};
	}

	public struct function getExceptions( required array logs ){
		var q = QueryNew( "_type,message,detail,template,line,requestUrl" );

		loop from="#arguments.logs.len()#" to="1" step=-1 index="local.i" {
			local.log = arguments.logs[local.i];
			// if exceptions isn't enabled in debug settings, there won't be data
			if ( StructKeyExists( local.log, "exceptions" ) ){
				local.exceptions = local.log.exceptions;
				loop array="#local.exceptions#" item="local.exp"{
					local.r = QueryAddRow( q );
					QuerySetCell( local.q, "_type", exp.type, r );
					QuerySetCell( local.q, "message", exp.message, r );
					QuerySetCell( local.q, "detail", exp.detail, r );
					if ( arrayLen(exp.TagContext) ) {
						QuerySetCell( local.q, "line", exp.TagContext[1].line, r );
						QuerySetCell( local.q, "template", exp.TagContext[1].template, r );
					}
					QuerySetCell( local.q, "requestUrl", local.log.scope.cgi.REQUEST_URL, local.r );
				}
			}
		}
		```
		<cfquery name="local.q_exceptions" dbtype="query">
			select  _type, template, message, detail, line, count(*) as executions
			from    q
			group by _type, template, message, detail, line
			order by executions desc
		</cfquery>
		```
		return {
			q: local.q_exceptions
		};
	}

	public struct function getDumps( required array logs ){
		var q = QueryNew( "output,template,line,requestUrl" );

		loop from="#arguments.logs.len()#" to="1" step=-1 index="local.i" {
			local.log = arguments.logs[local.i];
			// if exceptions isn't enabled in debug settings, there won't be data
			if ( StructKeyExists( local.log, "dumps" ) ){
				local.dumps = local.log.dumps;
				loop query="#local.dumps#"{
					local.r = QueryAddRow( q, QueryRowData( local.dumps, local.dumps.currentrow ) );
					QuerySetCell( q, "requestUrl", local.log.scope.cgi.REQUEST_URL, local.r );
				}
			}
		}
		```
		<cfquery name="local.q_dumps" dbtype="query">
			select  output, template, line, requestUrl, count(*) as executions
			from    q
			group by output, template, line, requestUrl
			order by executions desc
		</cfquery>
		```
		return {
			q: q_dumps
		};
	}
	//KeyConstants._type, KeyConstants._category, KeyConstants._text, KeyConstants._template, KeyConstants._line,
			//KeyConstants._action, KeyConstants._varname, KeyConstants._varvalue, KeyConstants._time

	public struct function getTraces( required array logs ){
		var q = QueryNew( "type,category,text,template,line,action,var,varValue,time,requestUrl" );

		loop from="#arguments.logs.len()#" to="1" step=-1 index="local.i" {
			local.log = arguments.logs[local.i];
			// if exceptions isn't enabled in debug settings, there won't be data
			if ( StructKeyExists( local.log, "traces" ) ){
				local.traces = local.log.traces;
				loop query="#local.traces#"{
					local.r = QueryAddRow( q, queryRowData(local.traces, local.traces.currentrow ) );
					QuerySetCell( q, "requestUrl", local.log.scope.cgi.REQUEST_URL, local.r );
				}
			}
		}
		```
		<cfquery name="local.q_traces" dbtype="query">
			select  type, category, text, template, line, action, var, varValue, time, requestUrl, count(*) as executions
			from    q
			group by type, category, text, template, line, action, var, varValue, time, requestUrl
			order by executions desc
		</cfquery>
		```
		return {
			q: q_traces
		};
	}

	public struct function getAborts( required array logs ){
		var q = QueryNew( "template,line,requestUrl" );

		loop from="#arguments.logs.len()#" to="1" step=-1 index="local.i" {
			local.log = arguments.logs[local.i];
			// if exceptions isn't enabled in debug settings, there won't be data
			if ( StructKeyExists( local.log, "abort" ) ){
				local.abort = local.log.abort;
				local.r = QueryAddRow( q );
				QuerySetCell( q, "template", local.abort.template, r );
				QuerySetCell( q, "line", local.abort.line, r );
				QuerySetCell( q, "requestUrl", local.log.scope.cgi.REQUEST_URL, local.r );
			}
		}
		```
		<cfquery name="local.q_aborts" dbtype="query">
			select  template, line, requestUrl, count(*) as executions
			from    q
			group by template, line, requestUrl
			order by executions desc
		</cfquery>
		```
		return {
			q: q_aborts
		};
	}

	public struct function getQueries( required array logs ){
		var q = QueryNew( "name,time,sql,src,line,count,datasource,usage,cacheType,requestUrl,template" );

		loop from="#arguments.logs.len()#" to="1" step=-1 index="local.i" {
			local.log = arguments.logs[local.i];
			// if queries isn't enabled in debug settings, there won't be data
			if ( StructKeyExists( local.log, "queries" ) ){
				local.queries=local.log.queries;
				loop query="#local.queries#" {
					local.r = QueryAddRow( q, QueryRowData(local.queries, local.queries.currentrow) );
					QuerySetCell( q, "template", local.q.src[r], r );
					QuerySetCell( q, "requestUrl", local.log.scope.cgi.REQUEST_URL, local.r );
				}
			}
		}
		// QoQ doesn't like count
		```
		<cfquery name="local.q_queries" dbtype="query">
			select  name, time, sql, src as template, line,	count as total, datasource, cacheType
			from    q
		</cfquery>

		<cfquery name="local.q_queries" dbtype="query">
			select  name, sum(time) as totalTime, min(time) as minTime, max(time) as maxTime, avg(time) as avgTime,
					template,line,	sum(total) as total, datasource, cacheType, count(*) as executions
			from    local.q_queries
			group by name, template, line, datasource, cacheType
			order by totalTime desc
		</cfquery>
		```

		return {
			q: q_queries
		};
	}

	public struct function getDebugLogs( required array logs ){
		var q = QueryNew( "template,requestUrl,path,total,query,load,app,scope,exceptions,starttime,id,size,isThread,threadName,statusCode,ContentType,ContentLength" );
		local.totals = {
			app = 0,
			query: 0,
			total: 0,
			load: 0,
			size: 0,
			scope: 0,
			exceptions: 0
		};
		local.log = {};
		local.rows = 0;
		loop from="#arguments.logs.len()#" to="1" step="-1" index="local.i" {
			local.log = arguments.logs[local.i];
			local.rows ++;
			//dump(local.log);
			local.cgi  = local.log.scope.cgi;
			var path = local.cgi.REQUEST_URL

			if (local.cgi.REQUEST_METHOD eq "POST")
				path = "POST #PATH#";

			var _scope = "0";
			if ( StructKeyExists( local.log, "implicitAccess" ) and local.log.implicitAccess.recordcount ){
				_scope = QueryReduce( local.log.implicitAccess,
					function( problems=0, row, rowNumber, recordset ){
						return arguments.problems + arguments.row.count;
					}
				);
			}
			var _total=0;
			var _query=0;
			var _app=0;
			var _load=0;
			var _exp=0
			if ( StructKeyExists( local.log, "pages" ) ){
				loop query="local.log.pages"{
					_total += local.log.pages.total;
					_query+= local.log.pages.query;
					_app += local.log.pages.app;
					_load += local.log.pages.load;
				}
			}

			if (StructKeyExists( local.log, "exceptions" ) )
				_exp += ArrayLen( local.log.exceptions );


			local.r = QueryAddRow( q );
			QuerySetCell( local.q, "size", log.size, local.r );
			QuerySetCell( local.q, "id", log.id, local.r );
			QuerySetCell( local.q, "starttime", log.starttime, local.r );
			QuerySetCell( local.q, "template", local.cgi.script_name, local.r );
			QuerySetCell( local.q, "path", path, local.r );
			QuerySetCell( local.q, "total", _total, local.r );
			QuerySetCell( local.q, "query", _query, local.r );
			QuerySetCell( local.q, "load", _load, local.r );
			QuerySetCell( local.q, "app", _app, local.r );
			QuerySetCell( local.q, "scope", _scope, local.r );
			QuerySetCell( local.q, "exceptions", _exp, local.r );
			QuerySetCell( local.q, "requestUrl", local.log.scope.cgi.REQUEST_URL, local.r );
			QuerySetCell( local.q, "isThread", ( Len( local.log.scope.cgi.HTTP_USER_AGENT ) eq 0 ), local.r );
			QuerySetCell( local.q, "threadName", local.log.threadName ?: "", local.r );

			if ( StructKeyExists( log, "statusCode" ) )
				QuerySetCell( local.q, "statusCode", log.statusCode, local.r );
			if ( StructKeyExists( log, "ContentType" ) )
				QuerySetCell( local.q, "ContentType", log.ContentType, local.r );
			if ( StructKeyExists( log, "ContentLength" ) )
				QuerySetCell( local.q, "ContentLength", log.ContentLength, local.r );

			local.totals.size +=  + local.log.size / 1000;
			local.totals.app += _app;
			local.totals.query += _query;
			local.totals.total += _total;
			local.totals.load += _load;
			local.totals.scope += _scope;
			local.totals.exceptions += _exp;
		}
		return {
			totals: local.totals,
			q: local.q
		};
	}
}