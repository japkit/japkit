package de.japkit.roo.base.web;

import org.joda.time.format.DateTimeFormat;
import org.springframework.context.i18n.LocaleContextHolder;

public class ControllerUtil {

	public static String patternForStyle(String style) {
		return DateTimeFormat.patternForStyle(style, LocaleContextHolder.getLocale());
	}

}
