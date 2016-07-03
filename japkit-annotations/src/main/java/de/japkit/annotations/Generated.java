package de.japkit.annotations;

/**
 * This annotation is used to mark generated classes (or other elements).
 * <p>
 * {@link javax.annotation.Generated} is not sufficient for this purpose, since it has source retention. Thus, it is not available
 * during Eclipse incremental builds, where source level annotations are only available for root type elements of the current 
 * annotation processing round.
 * 
 * @author stefan
 *
 */
public @interface Generated {
	/**Identifies the source the code has been generated from. For generated classes, this is the FQN of the annotated class.*/
	String src();
}
