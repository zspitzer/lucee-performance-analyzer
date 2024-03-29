<cfscript>
    param name="arguments.req.template" default ="";
	param name="arguments.req.url" default ="";
	param name="arguments.req.log" default ="";
	param name="request.subtitle" default="";
	local.subTitle = request.subtitle; //stash
	local.timer = getTickCount();
	local.related = 0;
	arguments.req.maxrows = (Len(arguments.req.log) eq 0 ? 25 : 100);

	loop array="#path_reports#" item="local.report"{
		if ( report neq arguments.req.pLuginAction ){
			timer label="Related: #report#"	 {
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
	local.reqType = (Len(arguments.req.log) eq 0 ? "Path" : "Log" );
	request.subtitle = ( related gt 0 ) ? ( variables.exactTemplatePath ? "Template" : local.reqType)  & " Analysis" : local.subTitle; //pop
</cfscript>
