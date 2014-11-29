package de.stefanocke.japkit.metaannotations.classselectors;

/**
 * The default class selector for the custom behavior class. It is an inner
 * class of the annotated class. Its name is "Behavior". If the generated class
 * is an aux class, the name is #{genClass.simpleName}Behavior
 * 
 * @author stefan
 *
 */
@ClassSelector(kind = ClassSelectorKind.INNER_CLASS_NAME,
		expr = "#{genClass.auxClass ? genClass.simpleName : ''}Behavior")
public interface BehaviorInnerClass {
}