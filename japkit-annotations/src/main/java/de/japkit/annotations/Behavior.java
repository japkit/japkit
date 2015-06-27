package de.japkit.annotations;

/**
 * To annotated behavior classes so that re-generation is triggered when there are some changes in behavior class.
 * 
 * @author stefan
 *
 */
public @interface Behavior {
	/**The class for which code generation shall be triggered when the behavior class changes.*/
	Class<?> forClass();
}
