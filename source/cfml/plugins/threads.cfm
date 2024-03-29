<!--- needed for toolbar.cfm --->
<cfscript>
	local.debugLogs = {};
	local.debugLogs.data = this.perf.getRawDebugLogs();

	setTitle( "Java Threads" );
</cfscript>
<br>
<cfscript>
	local.javaManagementFactory = createObject( "java", "java.lang.management.ManagementFactory" );
	local.threadMXBean = javaManagementFactory.getThreadMXBean();

	local.allThreadIDs = threadMXBean.getAllThreadIds();
	//allThreads = threadMXBean.getThreadInfo( allThreadIDs, javaCast( "int", 3 ) );

	//dump(allThreads);

	local.Thread = createObject( "java", "java.lang.Thread" );
	local.it = Thread.getAllStackTraces().keySet().iterator();
	// loop threads

	local.q_threads = queryNew( "name,threadState,stack,cpuTime,cfmlStack","varchar,varchar,varchar,numeric,object" );

	loop collection=it item="local.t" {
		//dump(t); abort;
		local.st = t.getStackTrace();
		local.str = "";
		// loop stacktraces
		loop array=st item="local.ste" {
			str &= ste;
			str &= "<br>";
		}
		local.servlet = find( "lucee.loader.servlet.CFMLServlet.service", str );
		if ( local.servlet gt 1 )
			str = mid( str , 1, local.servlet-1 ) & "...";

		local.r = queryAddRow(q_threads);
		//if(!find("PageContextImpl",str)) continue;
		QuerySetCell( q_threads, "name", t.name, r  );
		QuerySetCell( q_threads, "threadState", t.getState().toString(), r );
		QuerySetCell( q_threads, "stack",trim(str), r );
		QuerySetCell( q_threads, "cpuTime", threadMXBean.getThreadCpuTime(t.getId())/1000/1000, r );
		QuerySetCell( q_threads, "cfmlstack", extractCfmlStack(str), r );

	}

	q_threads = q_threads.sort("cputime","desc");
	//dump(q_threads); 	abort;

	function extractCfmlStack(string str){
		var cfStack = REMatch("(\([\/a-zA-Z\_\-\.\$]*[\.cfc|\.cfm|\.lucee)]\:\d+\))", arguments.str);
		for (var cf = 1; cf <= cfStack.len(); cf++){
			// strip out the wrapping braces
			cfStack[cf] = ListFirst(cfStack[cf],"()");
		}
		// https://regex101.com/r/Fd8qCi/1/
		var logStack = REMatch("(\[[\:\/\\a-zA-Z\_\-\.\$]*\])", arguments.str);
		if (logStack.len() gt 0){
			// de dup
			var ls = StructNew('linked');
			for (var s in logstack)
				ls[listFirst(s,"[]")]="";
			logStack = StructKeyList(ls);
			ArrayAppend(cfStack, logStack, true);
		}
		return cFstack;
	}
</cfscript>

<cfquery name="local.q_summary" dbtype="query">
	select threadState, count(threadState) as threads, sum(cpuTime) as cpuTotal
	from  q_threads
	group by threadState
		union
	select 'All threads' as threadstate, count(*) as threads, sum(cpuTime) as cpuTotal
	from  q_threads
	order by cpuTotal desc
</cfquery>

<b>Thread States:</b>
<span class="thread-state-filter">
	<cfoutput query="q_summary">
		<a class="filter #(q_summary.threadState eq "all threads" ? "filterSelected" : "")#"
			data-filter="#q_summary.threadState#" title="click to filter">#q_summary.threadState#</a>
		( #q_summary.threads# ) #NumberFormat(q_summary.cpuTotal)#s,
	</cfoutput>
</span>
<br>
<br>
<b>Thread Types:</b>
<span class="thread-type-filter">
	<cfloop list="all,cfml,java" item="filter">
		<cfoutput><a class="filter #(filter eq "all" ? "filterSelected" : "")#"
			data-filter="#filter#" title="click to filter">#filter#</a></cfoutput>
	</cfloop>
</span>
<br>

<table class="maintbl checkboxtbl sort-table thread-table" >
	<thead>
	<tr>
		<th data-type="text">Thread</th>
		<th data-type="text">Status</th>
		<th data-type="text">Stack</th>
		<th data-type="numeric">CPU Time (seconds)</th>
	</tr>
	</thead>
<tbody>
	<cfoutput query="q_threads">
		<tr class="#altRow(local.q_threads.currentRow)# stack" data-stack="#isEmpty(q_threads.cfmlStack)? "java" : "cfml"#" data-state="#q_threads.threadState#">
			<td>#q_threads.name#</td>
			<td>#q_threads.threadState#</td>
			<td>
				<cfif ArrayLen(q_threads.cfmlStack)>
					<div class="cfmlStack">
						<cfdump var=#q_threads.cfmlStack#>
					</div>
				</cfif>
				<pre class="javaStack">#q_threads.stack#</pre></td>
			<td>#DecimalFormat(q_threads.cpuTime)#</td>
		</tr>
	</cfoutput>
</tbody>
</table>