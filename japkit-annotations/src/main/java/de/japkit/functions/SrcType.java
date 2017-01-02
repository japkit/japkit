package de.japkit.functions;

import de.japkit.metaannotations.classselectors.ClassSelector;
import de.japkit.metaannotations.classselectors.ClassSelectorKind;

/**
 * The type of the current source element.
 * This is an annotation to allow it in a wide range of places, for example when generating annotations.
 * If you need the source type in "extends" or "implements" clause, use {@link SrcClass} or {@link SrcInterface} instead. 
 * 
 * @author stefan
 */
@ClassSelector(kind=ClassSelectorKind.SRC_TYPE)
public @interface SrcType {

}
