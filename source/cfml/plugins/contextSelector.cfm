<!--- show a select list of all the web contexts --->
<cfswitch expression="#request.admintype#">
	<cfcase value="web">
		<!--- not applicable --->
	</cfcase>
	<cfdefaultcase>
		<cfif request.admintype neq "Server">
			<div class="warning">
				 <b>Warning:</b> request.admintype is "#request.admintype#", should be either web or server??
			</div>
		</cfif>
		<!--- assume admintype=server --->
		<cfparam name="req.nextAction" default="overview">
		<cfparam name="session.logViewer.webID" default="serverContext" />
		<cfset var webContexts = logGateway.getWebContexts() />
		<cfoutput><form action="#action('setContext', '&nextAction=#req.nextAction#')#" method="post"></cfoutput>
			<cfoutput>#i18n('chooseLogLocation')#</cfoutput>
			<select name="webID">
				<cfoutput><option value="serverContext">#i18n('serverContext')#</option></cfoutput>
				<optgroup label="Web contexts">
					<cfoutput query="webContexts">
						<option value="#webContexts.id#"<cfif session.logViewer.webID eq webContexts.id> selected</cfif>>
							<cfif len(webContexts.path) gt 68>
								#rereplace(webContexts.path, "^(.{25}).+(.{40})$", "\1...\2")#
							<cfelse>
								#webContexts.path#
							</cfif>
							- #webContexts.url#</option>
					</cfoutput>
				</optgroup>
			</select>
			<cfoutput>
				<input type="submit" value="#i18n('Go')#" class="button" />
			</cfoutput>
		</form>
		<cfif not len(session.logViewer.webID)>
			<cfexit method="exittemplate" />
		<cfelse>
			<cfif session.logViewer.webID eq "serverContext">
				<cfset request.subtitle = i18n('ServerContext')>
			<cfelse>
				<cfset request.subtitle = "#logGateway.getWebRootPathByWebID(session.logViewer.webID)# (<em>#i18n('webContext')#</em>)">
			</cfif>
		</cfif>
	</cfdefaultcase>
</cfswitch>