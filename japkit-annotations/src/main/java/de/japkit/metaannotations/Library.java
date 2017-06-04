package de.japkit.metaannotations;

/**
 * Marks a class as being a collection of functions to be put onto value stack.
 * @author stefan
 *
 */
public @interface Library {
	/**
	 * Annotations that shall be accessed by their simple names like this: typeElement.Entity
	 * 
	 * @return
	 */
	Class<? extends java.lang.annotation.Annotation>[] annotationImports() default {};
	
	/**
	 * Imported classes to be used in expression language. Those classes must be available on anntoation processor path.
	 * 
	 * @return
	 */
	Class<?>[] elImportedClasses() default {};
	
	/**
	 * As an alternative to langImportedClasses, the FQNs of the classes to be imported can be used here.
	 * 
	 * @return
	 */
	String[] elImportedClassNames() default {};
}
