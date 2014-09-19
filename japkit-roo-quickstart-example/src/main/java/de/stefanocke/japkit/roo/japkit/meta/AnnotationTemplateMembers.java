package de.stefanocke.japkit.roo.japkit.meta;

import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelector;
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelectorKind;
import de.stefanocke.japkit.roo.japkit.meta.AnnotationTemplateMembers.SrcType;

@Template
@AnnotationTemplate(targetAnnotations = SrcType.class)
public class AnnotationTemplateMembers {
	
	@ClassSelector(kind=ClassSelectorKind.EXPR, expr="#{src}")
	public @interface SrcType{}
}
