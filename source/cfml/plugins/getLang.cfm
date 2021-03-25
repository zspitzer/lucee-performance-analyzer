<cfscript>
	var pluginLanguage = {
		strings: arguments.lang,
		locale: session.LUCEE_ADMIN_LANG
	};
	setting showdebugoutput="false";
	content type="text/javascript" reset="yes";
	echo ('var pluginLanguage = #serializeJson( pluginLanguage )#;');
	abort;
</cfscript>