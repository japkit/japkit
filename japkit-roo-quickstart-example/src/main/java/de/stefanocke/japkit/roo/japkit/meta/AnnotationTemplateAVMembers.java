package de.stefanocke.japkit.roo.japkit.meta;

import static de.stefanocke.japkit.metaannotations.classselectors.ClassSelectorKind.EXPR;
import static de.stefanocke.japkit.metaannotations.classselectors.ClassSelectorKind.INNER_CLASS_NAME;
import de.stefanocke.japkit.metaannotations.Matcher;
import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelector;
import de.stefanocke.japkit.metaannotations.classselectors.SrcSingleValueType;


@Template(src = "#{elements.declaredMethods(src.asElement())}")
public @interface AnnotationTemplateAVMembers {
	
	@Method
	SrcSingleValueType[]  $srcElementName$() default {};
	
	
	/**
	 * #{src}
	 * #{src.returnType}
	 * #{src.singleValueType.asElement.simpleName}
	 * #{src.singleValueType.kind == 'DECLARED' && src.singleValueType.asElement.kind == 'ANNOTATION_TYPE'}
	 * */
	@Method(activation = @Matcher(condition="#{src.singleValueType.kind == 'DECLARED' && src.singleValueType.asElement.kind == 'ANNOTATION_TYPE'}"))
	AnnotationTemplateType[] _$srcElementName$() default {}; 
	
	//TODOs: 
	//UnresolvedType per Flag ermöglichen, damit Abhängigkeiten zwischen inner classes "von Hand" aufgelöst werden können.
	//Activation ergänzen: Nur generieren , wenn der Typ in der Trigger Annotation auftaucht.
	@ClassSelector(kind=INNER_CLASS_NAME, expr="#{src.singleValueType.asElement.simpleName}_", enclosing=GenClassEnclosingClass.class)
	@interface AnnotationTemplateType{}
	
	@ClassSelector(kind=EXPR, expr="#{genClass.enclosingElement.asType()}")
	@interface GenClassEnclosingClass{}

	@Method
	String _$srcElementName$Activation() default "";

	@Method
	String _$srcElementName$Src() default "";

	@Method
	String _$srcElementName$Expr() default "";

}