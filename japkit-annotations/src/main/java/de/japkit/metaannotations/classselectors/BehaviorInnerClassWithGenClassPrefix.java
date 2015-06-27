package de.japkit.metaannotations.classselectors;

/**
 * Class selector for a custom behavior class. It is an inner class of the
 * annotated class and it has the name #{genClass.simpleName}Behavior. This is
 * for instance useful if there are inner or auxillary classes generated from
 * the annotated class and their custom behavior classes shall be hosted by the
 * annotated class.
 * 
 * @author stefan
 *
 */
@ClassSelector(kind = ClassSelectorKind.INNER_CLASS_NAME,
		expr = "#{genClass.simpleName}Behavior")
public interface BehaviorInnerClassWithGenClassPrefix {
}