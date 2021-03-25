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
component hint="various rendering related files"{

	public void function init( required struct lang, required string href, required any action ) {
		variables.AssetHrefPath = ListFirst( arguments.href, "?" );
		variables.AssetHrefParams = ListLast( arguments.href, "?" );;
		variables.lang = arguments.lang;
		variables.action = arguments.action;
	}

	public string function getCSRF(){
		return CSRFGenerateToken("log-analyzer");
	}

	private boolean function checkCSRF( required string token ){
		if ( !CSRFVerifyToken( arguments.token, "log-analyzer" ) )
			throw message="access denied";
		else
			return true;
	}

	public void function renderServerTimingHeaders( required array timings ){
		var serverTimingHeaders = [];
		for ( var timing in arguments.timings ){
			arrayAppend( serverTimingHeaders, '#timing.metric#;dur=#timing.data#;desc="#timing.name#"' );
		}

		if (serverTimingHeaders.len() gt 0 and not getPageContext().getHttpServletResponse().isCommitted() ) // avoid cfflush error
            header name="Server-Timing" value="#ArrayToList( serverTimingHeaders, ", " )#";
	}

	public void function includeCSS( required string template ) {
		htmlhead text='<link rel="stylesheet" href="#variables.AssetHrefPath#?asset=#arguments.template#.css&#variables.AssetHrefParams#">#chr(10)#';
	}

	public void function includeJavascript( required string template ) {
		htmlbody text='<script src="#variables.AssetHrefPath#?asset=#arguments.template#.js&#variables.AssetHrefParams#"></script>#chr(10)#';
	}

	public void function includeLang() {
		htmlbody text='<script src="#variables.action( 'getLang' )#"></script>#Chr( 10 )#';
	}

	public void function warnMissingLang( required struct missingLang ) {
		if ( structCount( warnMissingLang ) eq 0 )
			return;
		var missing = [];
		for (var k in arguments.missingLang)
			missing.append( "console.warn('missing language string: [#JSStringFormat( k )#] from cfml');" );

		writeOutput( "<script>#ArrayToList( missing, Chr( 10 ) )#</script>" );
	}

	public void function returnAsset( required string asset ) {
		if (arguments.asset contains "..")
			throw "invalid asset request #EncodeForHtml( arguments.asset )#";
		local.fileType = ListLast( arguments.asset, "." );

		switch (local.fileType){
			case "js":
				local.file = getDirectoryFromPath( getCurrentTemplatePath() ) & "js/#arguments.asset#";
				local.mime = "text/javascript";
				break;
			case "css":
				local.file = getDirectoryFromPath( getCurrentTemplatePath() ) & "css/#arguments.asset#";
				local.mime = "text/css";
				break;
			default:
				throw();
		}
		if ( !FileExists( local.file ) ){
			header statuscode="404";
			writeOutput( "file not found #EncodeForHtml( local.file )#" );
			abort;
		}
		local.fileInfo = FileInfo(local.file);

		if ( StructKeyExists( GetHttpRequestData().headers, "If-Modified-Since" ) ){
			local.if_modified_since = ParseDateTime( GetHttpRequestData().headers['If-Modified-Since'] );
			if ( DateDiff( "s", local.fileInfo.dateLastModified, local.if_modified_since ) GTE 0 ){
				header statuscode="304" statustext="Not Modified";
				abort;
			}
		}
		header name="cache-control" value="max-age=50000";
		header name="Last-Modified" value="#GetHttpTimeString(local.fileInfo.dateLastModified)#";
		content type="#local.mime#" reset="yes" file="#local.file#";
	}

	/**
	 * creates a text string indicating the timespan between NOW and given datetime
	 */
	public function getTextTimeSpan( required date date ) output=false {
		var diffSecs = DateDiff( 's', arguments.date, now() );
		if ( diffSecs < 60 ) {
			return Replace( variables.lang.xSecondsAgo, '%1', diffSecs );
		} else if ( diffSecs < 3600 ) {
			return Replace( variables.lang.xMinutesAgo, '%1', int (diffSecs / 60 ) );
		} else if ( diffSecs < 86400 ) {
			return Replace( variables.lang.xHoursAgo, '%1', int( diffSecs / 3600 ) );
		} else {
			return Replace( variables.lang.xDaysAgo, '%1', int( diffSecs / 86400 ) );
		}
	}

	public function cleanHtml( required string content ){
		return ReReplace( arguments.content, "[\r\n]\s*([\r\n]|\Z)", Chr(10), "ALL" )
	}

}
