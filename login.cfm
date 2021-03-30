<cfscript>
	param name="form.password" default="";
	variables.login_error = "";

	if (len(form.password) gt 0){
		admin action="checkPassword"
			type="#request.adminType#";
		admin action="hashPassword"
			type="#request.adminType#"
			pw="#form.password#"
			returnVariable="hashedPassword";
		try {
			admin action="connect"
				type="#request.adminType#"
				password="#hashedPassword#";
			session["password" & request.adminType] = hashedPassword;
			session.LUCEE_ADMIN_LANG = "EN";
			location url="index.cfm?action=plugin" addtoken="false";

		} catch(e){
			variables.login_error = cfcatch.message;
		}
	}
	variables.plugin.getRenderUtils().includeCSS("style");
</cfscript>
<form action="?action=login" method="POST" class="login">
	<fieldset style="border: 1px solid black; padding: 20px; max-width: 400px;">
		<legend>Login</legend>
		<cfif len(variables.login_error)>
			<cfoutput>
				<div style="color:red;padding-bottom:20px;">#variables.login_error#</div>
			</cfoutput>
		</cfif>
		Login using Lucee Server Password<br>
		<input name="password" type="password" size="15">
		<input type="submit" value="Login">
	</fieldset>
</form>