<cfscript>
	param name="arguments.req.maxrows" default="1000";
	local.timers = variables.Perf.getLogs(arguments.req, "timers");
	local.q = timers.q;
	local._total_time = 0;
	local._total_executions = 0;
	setTitle( "Settings" );

	param name="form.bUpdateDebug" default="false";

	if (form.bUpdateDebug){

		var attrColl = form.debugSetting; // struct of settings
		attrColl.action = "updateDebug";
		attrColl.type = "#request.adminType#"
		attrColl.password = "#session["password"&request.adminType]#"
		attrColl.debugTemplate = "";
		attrColl.remoteClients = "";

		admin attributeCollection="#attrColl#";

		admin
			action="updateDebugSetting"
			type="#request.adminType#"
			password="#session["password"&request.adminType]#"
			maxLogs="#form.maxLogs#"
			remoteClients="";

		echo("<b>Debug Settigns updated!</b><br>");
	}

	admin
		action="getDebugSetting"
		type="#request.adminType#"
		password="#session["password"&request.adminType]#"
		returnVariable="local.debugSetting";

	admin
		action="getDebug"
		type="#request.adminType#"
		password="#session["password"&request.adminType]#"
		returnVariable="local.debug";

</cfscript>
<p>
	<i>This is the same as updating the debug settings in the Lucee Admin</i>
</p>

<cfoutput>
	<form method="post" action="#cgi.SCRIPT_NAME#?#cgi.QUERY_STRING#">
		<table class="maintbl checkboxtbl">
		<thead>
			<tr>
				<th>Setting</th>
				<th>Status</th>
			</tr>
		</thead>
		<tbody>
		<cfscript>
			local.r = 0;
			local.d = "debug";
		</cfscript>
		<tr class="#altRow( local.r )#">
			<td style="padding-top:10px;"><b>Debugging Enabled</b></td>
			<td>
				<label>
					Enabled:
					<input type="radio" value="true" name="debugSetting.#d#" <cfif local.debug[ d ]>checked</cfif> >
				</label>
				<label>
					Disabled:
					<input type="radio" value="false" name="debugSetting.#d#" <cfif !local.debug[ d ]>checked</cfif> >
				</label>
			</td>
		</tr>
		<tr>
			<td colspan="2" align="right"><br></td>
		</tr>
		<cfscript>
			structDelete( local.debug, "debug" );
			local.r++;
		</cfscript>
		<cfloop collection=#local.debug# item="local.d">
			<tr class="#altRow( local.r )#">
				<td style="padding-top:10px;">#UCFirst(d)#</td>
				<td>
					<label>
						Enabled:
						<input type="radio" value="true" name="debugSetting.#d#" <cfif local.debug[ d ]>checked</cfif> >
					</label>
					<label>
						Disabled:
						<input type="radio" value="false" name="debugSetting.#d#" <cfif !local.debug[ d ]>checked</cfif> >
					</label>
				</td>
			</tr>
			<cfset local.r++>
		</cfloop>
		<tr class="#altRow( local.r )#">
			<td style="padding-top:10px;">Number of Debug Logs</td>
			<td>
				<input type="text" value="#local.debugSetting.maxlogs#" name="maxlogs" size="6">
			</td>
		</tr>

		</tbody>
		<tfoot>
			<tr>
				<td colspan="2" align="right"><br>
					<input type="hidden" value="true" name="bUpdateDebug">
					<input type="submit" value="Update Debug Settings">
				</td>
			</tr>
		</tfoot>
		</table>
	</form>
</cfoutput>