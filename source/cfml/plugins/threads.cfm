<!--- needed for toolbar.cfm --->
<cfscript>
	local.debugLogs = {};
	local.debugLogs.data = []
	admin action="getLoggedDebugData"
		type="#request.adminType#"
		password="#session["password"&request.adminType]#"
		returnVariable="local.debugLogs.data";
	request.subtitle = "Java Threads";
	cfinclude(template="toolbar.cfm");
</cfscript>
<cfadmin action="getLoggedDebugData"
	type="#request.adminType#"
	password="#session["password"&request.adminType]#"
	returnVariable="local.debugLogs.data">
<br>
<cfscript>
	javaManagementFactory = createObject( "java", "java.lang.management.ManagementFactory" );
	threadMXBean = javaManagementFactory.getThreadMXBean();

	allThreadIDs = threadMXBean.getAllThreadIds();
	//allThreads = threadMXBean.getThreadInfo( allThreadIDs, javaCast( "int", 3 ) );

	//dump(allThreads);

	Thread=createObject("java","java.lang.Thread");
	it=Thread.getAllStackTraces().keySet().iterator();
	// loop threads

	q_threads = queryNew("name,threadState,stack,cpuTime","varchar,varchar,varchar,numeric");

	loop collection=it item="t" {
		//dump(t); abort;
		st=t.getStackTrace();
		str="";
		// loop stacktraces
		loop array=st item="ste" {
			str&=ste;
			str&="<br>";
		}
		r = queryAddRow(q_threads);
		//if(!find("PageContextImpl",str)) continue;
		QuerySetCell(q_threads, "name", t.name, r);
		QuerySetCell(q_threads, "threadState", t.getState().toString(), r);
		QuerySetCell(q_threads, "stack",trim(str), r);
		QuerySetCell(q_threads, "cpuTime", threadMXBean.getThreadCpuTime(t.getId())/1000/1000, r);
	}

	q_threads = q_threads.sort("cputime","desc");
	//dump(q_threads); 	abort;
</cfscript>

<cfquery name="q_summary" dbtype="query">
	select threadState, count(threadState) as threads, sum(cpuTime) as cpuTotal
	from  q_threads
	group by threadState
	order by cpuTime desc
</cfquery>

<b>Summary:</b>
<cfoutput query="q_summary">
	#q_summary.threadState# (#q_summary.threads#) #DecimalFormat(q_summary.cpuTotal)#s,
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
		<tr>
			<td>#q_threads.name#</td>
			<td>#q_threads.threadState#</td>
			<td><pre>#q_threads.stack#</pre></td>
			<td align="right">#DecimalFormat(q_threads.cpuTime)#</td>
		</tr>
	</cfoutput>
</tbody>
</table>

<cfoutput>
	#renderUtils.includeLang()#
	#renderUtils.includeJavascript("perf")#
</cfoutput>
