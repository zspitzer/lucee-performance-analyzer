<!--- needed for toolbar.cfm --->
<cfscript>
	local.debugLogs = {};
	local.debugLogs.data = []
	admin action="getLoggedDebugData"
		type="#request.adminType#"
		password="#session["password"&request.adminType]#"
		returnVariable="local.debugLogs.data";
	setTitle( "Java Threads" );
</cfscript>
<cfadmin action="getLoggedDebugData"
	type="#request.adminType#"
	password="#session["password"&request.adminType]#"
	returnVariable="local.debugLogs.data">
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

	local.q_threads = queryNew( "name,threadState,stack,cpuTime","varchar,varchar,varchar,numeric" );

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
	}

	q_threads = q_threads.sort("cputime","desc");
	//dump(q_threads); 	abort;
</cfscript>

<cfquery name="local.q_summary" dbtype="query">
	select threadState, count(threadState) as threads, sum(cpuTime) as cpuTotal
	from  q_threads
	group by threadState
	order by cpuTotal desc
</cfquery>

<b>Summary:</b>
<cfoutput query="q_summary">
	#q_summary.threadState# (#q_summary.threads#) #NumberFormat(q_summary.cpuTotal)#s,
</cfoutput>
<br>
<br>

<table class="maintbl checkboxtbl sort-table">
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
		<tr class="#altRow(local.q_threads.currentRow)#">
			<td>#q_threads.name#</td>
			<td>#q_threads.threadState#</td>
			<td><pre>#q_threads.stack#</pre></td>
			<td>#DecimalFormat(q_threads.cpuTime)#</td>
		</tr>
	</cfoutput>
</tbody>
</table>