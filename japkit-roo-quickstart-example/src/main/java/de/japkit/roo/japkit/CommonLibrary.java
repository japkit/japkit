package de.japkit.roo.japkit;

import de.japkit.metaannotations.Function;
import de.japkit.metaannotations.Library;

@Library
public class CommonLibrary {

	@Function(expr="#{src.simpleName.toFirstLower}")
	public class nameFirstLower{}
	
	@Function(expr="#{src.simpleName.toFirstUpper}")
	public class nameFirstUpper{}
}
