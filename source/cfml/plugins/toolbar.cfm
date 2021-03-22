<cfscript>
    local.reports = ["Logs","Scopes","Queries","Timers","Exceptions","Memory","Threads"];
	local.lastLogDate = false;
    if (ArrayLen(local.debugLogs.data))
        lastLogDate =  local.debugLogs.data[ArrayLen(local.debugLogs.data)].starttime;
    local.urlExtra = "";
    if ( StructKeyExists(arguments.req, "since") and arguments.req.since)
        urlExtra = "since=#arguments.req.since#";
    local.cfquery = ""; // hide from scopes
    request.title = "Performance Analyzer";
</cfscript>
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
<cfoutput>
<cfif StructKeyExists(arguments.req, "since")>
    <p>Filter: Only reporting logs since #dateTimeFormat(arguments.req.since)#
        <a href="?action=#arguments.req.action#&plugin=#arguments.req.plugin#&pluginAction=#arguments.req.pluginAction#" class="toolbar-filter">
         (remove filter)
        </a>
    </p>
</cfif>
<cfif lastLogDate neq "false" or StructKeyExists(arguments.req, "since")>
    <p>Refresh with only new logs created since
        <a href="?action=#arguments.req.action#&plugin=#arguments.req.plugin#&pluginAction=#arguments.req.pluginAction#&since=#DateTimeFormat(lastlogDate,"yyyy-mm-dd HH:MM:SS")#" class="toolbar-filter">
            #DateTimeFormat(lastLogDate)#
       </a>
</p>
</cfif>
</cfoutput>