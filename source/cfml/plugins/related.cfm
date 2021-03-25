<cfscript>
    param name="arguments.req.template" default ="";
	if ( len( arguments.req.template ) eq 0 )
		exit method="exittemplate";
	local.subTitle = request.subtitle; //stash
	local.timer = getTickCount();
	local.related = 0;
	arguments.req.maxrows = 50;
	
	loop array="#path_reports#" item="local.report"{
		if ( report neq arguments.req.pLuginAction ){
			timer label=report {
				saveContent variable="local.html" {
					cfinclude( template=report & ".cfm" );
				}
				if ( local.q.recordcount gt 0 ){
					echo( "<h3>#request.subtitle#</h3>#local.html#" );
					related++;
				}
			}
		}
	}

	request.subtitle = ( related gt 0 ) ? ( variables.exactTemplatePath? "Template" : "Path" ) & " Report" : local.subTitle; //pop
</cfscript>
<cfoutput>
	<hr>
	<p>This report is based on all the debugging logs currently in memory (#local.debugLogs.data.len()#), click column headers to sort</p>
</cfoutput>
