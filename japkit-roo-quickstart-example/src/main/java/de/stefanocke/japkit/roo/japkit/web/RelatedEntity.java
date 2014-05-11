package de.stefanocke.japkit.roo.japkit.web;

import de.stefanocke.japkit.metaannotations.classselectors.ClassSelector;
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelectorKind;

//TODO: Kind VAR -> Name des Klasse = Name der Variable auf dem ValueStack
@ClassSelector(kind = ClassSelectorKind.EXPR, expr = "#{relatedEntity}")
public abstract class RelatedEntity {
}