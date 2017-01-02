package de.japkit.functions;

import java.util.Collection;
import java.util.Map;

import de.japkit.metaannotations.Function;

/**
 * The single value type of the current source element. If the source element is
 * {@link Collection} typed, this is the type the elements in the collection. If
 * it is of type {@link Map}, it is the value type of the Map.
 * In other cases, it is the same as {@link SrcType}.
 * 
 * @author stefan
 */
@Function(expr = "#{src.singleValueType}")
public @interface SrcSingleValueType {

}
