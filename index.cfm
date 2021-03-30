<cfscript>
	request.self = ListFirst(cgi.REQUEST_URL,"?") &"?action=Plugin";
	url.action = "Plugin";
	url.plugin = "PerformanceAnalyzer";
	request.version = DeserializeJson(FileRead("box.json")).version;
	request.subtitle = "";
	request.title = "Lucee Performance Analyzer - #request.version#";
	param name="url.pluginAction" default="analysis";
	param name="url.xhr" default="false";
	variables.plugin = new source.cfml.plugins.Action(lang={},app={});

	request.action = ListLast(url.pluginAction,"/\/");
	savecontent variable="body"{
		switch (request.action){
			case "logout":
				sessionInvalidate();
				location url="index.cfm" addtoken="false";
			case "login":
				cfinclude(template="login.cfm");
				break;
			default:
				if (StructKeyExists(variables.plugin, request.action))
					variables.plugin[request.action](lang={}, app={}, req=url);
				if (!url.xhr)
					variables.plugin.getRenderUtils().includeJavascript("jquery-3.6.0.slim.min");
				variables.plugin._display(template=request.action & ".cfm", lang={}, app={}, req=url);
		}
	}
</cfscript>
<cfcontent reset="yes">
<html>
	<head>
		<cfoutput>
			<title>#request.subtitle# <cfif len(request.subtitle)>-</cfif> #request.title#</title>
		</cfoutput>
		<meta name="robots" content="noindex,nofollow">
	</head>
</html>
<body>
<cfoutput>
	<div class="header">
	<h1>Lucee Performance Analyzer (standalone)</h1>
		Version #request.version# / Lucee #server.lucee.version#
		<cfif request.action neq "login">
			<a href="?pluginAction=logout">Logout</a>
		</cfif>
	</div>
	<div class="content">
	#variables.plugin.getRenderUtils().cleanHtml(body)#
</div>
</cfoutput>
</body>
</html>