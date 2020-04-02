<cfscript>
    local.reports = ["Scopes","Queries"];
</cfscript>
<div class="btn-group" role="group">
<cfoutput>
    <cfloop array=#local.reports# item="report">
        <a href="?action=#req.action#&plugin=#req.plugin#&pluginAction=#report#" style="padding-right:20px;">
            <cfif req.pLuginAction eq report><b></cfif>#ucase(report)#
            <cfif req.pLuginAction eq report></b></cfif>
        </a>
    </cfloop>
</cfoutput>
</div>