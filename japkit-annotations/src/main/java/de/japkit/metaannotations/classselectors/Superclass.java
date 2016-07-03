package de.japkit.metaannotations.classselectors;

/**
 * To use variable "superclass" on valueStack as type.
 * @author stefan
 *
 */
@ClassSelector(kind=ClassSelectorKind.EXPR, expr="#{superclass}" )
public @interface Superclass {

}
