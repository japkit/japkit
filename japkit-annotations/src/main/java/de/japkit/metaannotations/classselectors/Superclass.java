package de.japkit.metaannotations.classselectors;

import de.japkit.metaannotations.Function;

/**
 * To use variable "superclass" on valueStack as type.
 * @author stefan
 *
 */
@Function(expr="#{superclass}" )
public @interface Superclass {

}
