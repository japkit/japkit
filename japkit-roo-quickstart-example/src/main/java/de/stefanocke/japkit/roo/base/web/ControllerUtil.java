package de.stefanocke.japkit.roo.base.web;

import java.io.UnsupportedEncodingException;

import javax.servlet.http.HttpServletRequest;

import org.joda.time.format.DateTimeFormat;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.web.util.UriUtils;
import org.springframework.web.util.WebUtils;

public class ControllerUtil {

	public static String encodeUrlPathSegment(String pathSegment, HttpServletRequest httpServletRequest) {
	    String enc = httpServletRequest.getCharacterEncoding();
	    if (enc == null) {
	        enc = WebUtils.DEFAULT_CHARACTER_ENCODING;
	    }
	    try {
	        pathSegment = UriUtils.encodePathSegment(pathSegment, enc);
	    } catch (UnsupportedEncodingException uee) {}
	    return pathSegment;
	}
	
	public static String patternForStyle(String style){
		return DateTimeFormat.patternForStyle(style, LocaleContextHolder.getLocale());
	}

}
