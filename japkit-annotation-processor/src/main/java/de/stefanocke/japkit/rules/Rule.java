package de.stefanocke.japkit.rules;

import javax.lang.model.element.AnnotationMirror;
import javax.lang.model.element.Element;

public interface Rule {
	/**The meta annoation of this rule or null, if the rule has no meta annoatation (f.e. purely template based rule)*/
	AnnotationMirror getMetaAnnotation();
	
	/**
	 * The meta element of the rule. This is the template element of the rule and / or the element, where the meta annotation resides.
	 * Null means, that the the rule inherits the meta element of the parent rule. This is the case if the meta annotation resides as an
	 * annotation value within another meta annotation or if the meta annotation is one amongst others on the meta element and a parent rule
	 * calls different child rules to process each of them.
	 */
	Element getMetaElement();
	
}
