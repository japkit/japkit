package de.stefanocke.japkit.support

import javax.lang.model.element.AnnotationMirror

/**
 * This exception is thrown if the type element for a given type mirror could not be found.
 * 
 * This is not unusal, since generated classes may depend on other generated classes.
 * 
 * @author stefan
 *
 */
@Data
public class TypeElementNotFoundException extends RuntimeException {
	/**
	 * 
	 */
	val serialVersionUID = 1L;
	
	//The typeMirror for which the type element could not be determined. Might sometimes be the shortname, since neither eclipse nor javac peovide FQN for error types
	String fqn;
	
	//Used if the name of the unresolved type is not available. For javac, this is the case if a not (yet) existing type is used as annotation value. In this case javac does 
	//not return an ErrorType (with the short name of the missing type), but instead, it just returns the string "<error>" as annotation value :(
	public static val String UNKNOWN_TYPE = "<unknown>"
	
	new(Throwable cause){
		super('''«cause.message» «cause» «cause.stackTrace.join("\n")» ''', cause)
		_fqn=UNKNOWN_TYPE
	}
	
	new(String fqn){
		super(fqn)
		_fqn=fqn
	}
	
	new(String fqn, String message){
		super(message)
		_fqn=fqn
	}
	
	new(AnnotationMirror mirror, CharSequence av) {
		super('''Error in annotation value «av» of annotation «mirror»''')
		_fqn=UNKNOWN_TYPE
	}
	
	new(){
		_fqn=UNKNOWN_TYPE
	}
	
}