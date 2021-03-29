<cfscript>
	function hasJavaMethod( obj, name ) {
		loop array=arguments.obj.getClass().getMethods() item="local.m" {
			if( m.getName() == arguments.name ) return true;
		}
		return false;
	}
</cfscript>
<cfoutput>
	<hr>
	<p>This report is based on all the debugging logs currently in memory ( #variables.perf.getRawLogCount()# logs, #variables.perf.getDebugMemUsage()# )  click column headers to sort</p>

	<cfif hasJavaMethod(getPageContext().getConfig().getDebuggerPool(), "purge" )>
		<input type="button" class="bm button submit" name="mainAction" value="Purge Logs"
			onclick='document.location="?action=#arguments.req.action#&plugin=#arguments.req.plugin#&pluginAction=#arguments.req.pluginAction#&doPurge=true"'>
	</cfif>

	#variables.renderUtils.includeLang()#
	#variables.renderUtils.includeJavascript( "perf" )#
</cfoutput>
