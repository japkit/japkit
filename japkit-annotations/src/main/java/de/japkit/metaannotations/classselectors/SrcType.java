package de.japkit.metaannotations.classselectors;

import de.japkit.functions.SrcClass;
import de.japkit.functions.SrcInterface;

/**
 * @deprecated use {@link de.japkit.functions.SrcType} or {@link SrcClass} or {@link SrcInterface} instead.
 */
@Deprecated
@ClassSelector(kind=ClassSelectorKind.SRC_TYPE)
public @interface SrcType {

}
