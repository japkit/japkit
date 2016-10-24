package de.japkit.annotationtemplates;

import static de.japkit.metaannotations.classselectors.ClassSelectorKind.INNER_CLASS_NAME;

import javax.lang.model.element.ElementKind;

import de.japkit.annotations.RuntimeMetadata;
import de.japkit.annotationtemplates.AnnotationTemplatesTemplate.AnnotationName_.AnnotationTemplateAVMembers;
import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.Matcher;
import de.japkit.metaannotations.Method;
import de.japkit.metaannotations.Template;
import de.japkit.metaannotations.TemplateCall;
import de.japkit.metaannotations.classselectors.ClassSelector;
import de.japkit.metaannotations.classselectors.SrcSingleValueType;
import de.japkit.metaannotations.classselectors.SrcType;

@RuntimeMetadata
@Clazz()
public class AnnotationTemplatesTemplate {
	@de.japkit.metaannotations.InnerClass(src = "#{triggerAnnotation.targetAnnotations}",
			nameExpr = "#{src.asElement().simpleName}_",
			kind = ElementKind.ANNOTATION_TYPE,
			templates = @TemplateCall(AnnotationTemplateAVMembers.class))
	@de.japkit.annotations.AnnotationTemplate(targetAnnotation = SrcType.class)
	public @interface AnnotationName_ {
		
		/**
		 * @return expression to determine if the annotation shall be generated. Default is true.
		 */
		String _cond() default "";
		
		/** 
		 * @return the expression language for the condition expression.
		 */
		String _condLang() default "";
		
		/** 
		 * @return as an alternative to the cond expression, a boolean function can be called.
		 */
		Class<?>[] _condFun() default {};
		
		@Template(src = "#{elements.declaredMethods(src.asElement())}")
		public @interface AnnotationTemplateAVMembers {
			
			@Method
			SrcSingleValueType[]  $srcElementName$() default {};
			
			@Matcher(condition="#{src.singleValueType.kind == 'DECLARED' && src.singleValueType.asElement.kind == 'ANNOTATION_TYPE'}")
			class isAnnotationType{};
			
			/**
			 * #{src}
			 * #{src.returnType}
			 * #{src.singleValueType.asElement.simpleName}
			 * #{src.singleValueType.kind == 'DECLARED' && src.singleValueType.asElement.kind == 'ANNOTATION_TYPE'}
			 * */
			@Method(condFun = isAnnotationType.class)
			AnnotationTemplateType[] _$srcElementName$() default {}; 
			
			//TODOs: 
			//UnresolvedType per Flag ermöglichen, damit Abhängigkeiten zwischen inner classes "von Hand" aufgelöst werden können.
			//Activation ergänzen: Nur generieren , wenn der Typ in der Trigger Annotation auftaucht.
			@ClassSelector(kind=INNER_CLASS_NAME, expr="#{src.singleValueType.asElement.simpleName}_", enclosing=GenClassEnclosingClass.class)
			@interface AnnotationTemplateType{}
			
			@ClassSelector(expr="#{genClass.enclosingElement.asType()}")
			@interface GenClassEnclosingClass{}

			/**
			 * @return expression to determine if the annotation value shall be generated. Default is true.
			 */
			String _$srcElementName$Cond() default "";
			
			/** 
			 * @return the expression language for the condition expression.
			 */
			String _$srcElementName$CondLang() default "";
			
			/** 
			 * @return as an alternative to the cond expression, a boolean function can be called.
			 */
			Class<?>[] _$srcElementName$CondFun() default {};

			///??? Was macht das bei einfachen annotation values???
			String _$srcElementName$Src() default "";

			String _$srcElementName$Expr() default "";

		}

	}
}
