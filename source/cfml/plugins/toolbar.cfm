<cfscript>
    local.reports = ["Scopes","Queries","Logs"];
    lastLogDate = false;
    if (ArrayLen(local.debugLogs.data))
        lastLogDate =  local.debugLogs.data[ArrayLen(local.debugLogs.data)].starttime;
    urlExtra = "";
    if ( StructKeyExists(req, "since") and req.since)
        urlExtra = "since=#req.since#";
</cfscript>
<div class="btn-group" role="group">
<cfoutput>
    <cfloop array=#local.reports# item="report">
        <a href="?action=#req.action#&plugin=#req.plugin#&pluginAction=#report#&#urlExtra#" class="toolbar-filter">
            <cfif req.pLuginAction eq report><b></cfif>#ucase(report)#
            <cfif req.pLuginAction eq report></b></cfif>
        </a>
    </cfloop>
</cfoutput> 
</div>
<cfoutput>
<cfif StructKeyExists(req, "since")>
    <p>Filter: Only reporting logs since #dateTimeFormat(req.since)# 
        <a href="?action=#req.action#&plugin=#req.plugin#&pluginAction=#req.pluginAction#" class="toolbar-filter">
         (remove filter)
        </a> 
    </p>
</cfif>
<cfif lastLogDate neq "false" or StructKeyExists(req, "since")>    
    <p>Refresh with only new logs created since 
        <a href="?action=#req.action#&plugin=#req.plugin#&pluginAction=#req.pluginAction#&since=#DateTimeFormat(lastlogDate,"yyyy-mm-dd HH:MM:SS")#" class="toolbar-filter">
            #DateTimeFormat(lastLogDate)#
       </a>    
</p>
</cfif>
</cfoutput>