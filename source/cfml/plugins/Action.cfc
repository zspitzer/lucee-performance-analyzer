/*
 *
 * Copyright (c) 2016, Paul Klinkenberg, Utrecht, The Netherlands.
 * Originally written by Gert Franz, Switzerland.
 * All rights reserved.
 *
 * Date: 2016-02-11 13:45:05
 * Revision: 2.3.1.
 * Project info: http://www.lucee.nl/post.cfm/railo-admin-log-analyzer
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 */
component extends="lucee.admin.plugin.Plugin" {

	public void function init( required struct lang, required struct app ) {
		variables.renderUtils = new RenderUtils( arguments.lang, action( "asset" ), this.action );
		variables._lang = arguments.lang;
		setting showdebugoutput = "true";
	}

	RenderUtils public function getRenderUtils(){
		return variables.renderUtils;
	}

	public void function _display( required string template, required struct lang, required struct app, required struct req ) {
		param name="url.xhr" default="false";
		request._missing_lang = {};
		var cfquery = ""; // var scoping
		request.title = "Perf Analyzer";
		if ( not url.xhr)
			variables.renderUtils.includeCSS( "style" );
		this.perf = new Perf();
		cfinclude( template="toolbar.cfm" );

		cfinclude( template=arguments.template );

		cfinclude( template="footer.cfm" );
		//variables.renderUtils.warnMissingLang(request._missing_lang);
	}

	public void function asset(struct lang, struct app, struct req) output=false {
		param name="arguments.req.asset";
		// dunno why, sometimes this doesn't exist and throws an error
		if (not structKeyExists(variables, "renderUtils") )
			variables.renderUtils = new RenderUtils( arguments.lang, action( "asset" ), this.action );
		variables.renderUtils.returnAsset( arguments.req.asset );
	}

	public void function getLang( struct lang, struct app, struct req ) output=false {
		url.xhr = true;
	}
}
