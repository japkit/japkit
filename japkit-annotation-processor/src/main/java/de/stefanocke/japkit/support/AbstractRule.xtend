package de.stefanocke.japkit.support

import de.stefanocke.japkit.support.Rule
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element

@Data
class AbstractRule implements Rule {
	AnnotationMirror metaAnnotation
	Element metaElement
	
}