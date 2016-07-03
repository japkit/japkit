package de.japkit.roo.japkit;

import de.japkit.metaannotations.Function;
import de.japkit.metaannotations.Library;

/**
 * TODO: Check whether to move to annotation processor.
 * @author stefan
 *
 */
@Library
public class CommonLibrary {

	@Function(expr="#{src.simpleName.toFirstLower}")
	public class nameFirstLower{}
	
	@Function(expr="#{src.simpleName.toFirstUpper}")
	public class nameFirstUpper{}
	
	@Function(expr="#{src.asType()}")
	public class type{}
	
	/**If src is a Map entry, this function retrieves its key.*/
	@Function(expr="#{src.key}")
	public class SrcKey{}
	
	/**If src is a Map entry, this function retrieves its value.*/
	@Function(expr="#{src.value}")
	public class SrcValue{}
	
}
