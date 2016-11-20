package de.japkit.annotationtemplates;

import static de.japkit.metaannotations.classselectors.ClassSelectorKind.INNER_CLASS_NAME;

import javax.lang.model.element.ElementKind;

import de.japkit.annotations.AnnotationTemplate;
import de.japkit.annotations.RuntimeMetadata;
import de.japkit.annotationtemplates.AnnotationTemplatesTemplate.AnnotationName_.AnnotationTemplateAVMembers;
import de.japkit.metaannotations.AV;
import de.japkit.metaannotations.Annotation;
import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.Matcher;
import de.japkit.metaannotations.Method;
import de.japkit.metaannotations.Template;
import de.japkit.metaannotations.TemplateCall;
import de.japkit.metaannotations.classselectors.ClassSelector;
import de.japkit.metaannotations.classselectors.ClassSelectorKind;
import de.japkit.metaannotations.classselectors.SrcSingleValueType;

@RuntimeMetadata
@Clazz()
public class AnnotationTemplatesTemplate {
	@de.japkit.metaannotations.InnerClass(src = "#{triggerAnnotation.targetAnnotations}",
			nameExpr = "#{src.asElement().simpleName}_",
			kind = ElementKind.ANNOTATION_TYPE,
			templates = @TemplateCall(AnnotationTemplateAVMembers.class),
			annotations = @Annotation(targetAnnotation=AnnotationTemplate.class, values = @AV(name = "targetAnnotation", expr="#{src}")))
	//Does not work, since japkit annotations are not copied:
	//@de.japkit.annotations.AnnotationTemplate(targetAnnotation = SrcType.class)
	public @interface AnnotationName_ {
		

		/**
		 * An expression to determine the source object for generating this annotation(s).
		 * The source element is available as "src" in expressions and is used in
		 * matchers and other rules. If the src expression is not set, the src
		 * element of the element hosting the annotation is used.
		 * @return
		 */
		String _src() default "";

		/**
		 * 
		 * @return the language of the src expression. Defaults to Java EL.
		 */
		String _srcLang() default "";
				
		/**
		 * As an alternative to the src expression, a function can be called to determine the source object.
		 * 
		 * @return
		 */
		Class<?>[] _srcFun() default {};

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
			
			@Method(condFun = isAnnotationType.class)
			AnnotationTemplateType[] $srcElementName$_() default {}; 
			
			@ClassSelector(kind=INNER_CLASS_NAME, expr="#{src.singleValueType.asElement.simpleName}_", enclosing=GenClassEnclosingClass.class)
			@interface AnnotationTemplateType{}
			
			@ClassSelector(expr="#{genClass.enclosingElement.asType()}")
			@interface GenClassEnclosingClass{}

			/**
			 * @return expression to determine if the annotation value shall be generated. Default is true.
			 */
			String $srcElementName$_cond() default "";
			
			/** 
			 * @return the expression language for the condition expression.
			 */
			String $srcElementName$_condLang() default "";
			
			/** 
			 * @return as an alternative to the cond expression, a boolean function can be called.
			 */
			Class<?>[] $srcElementName$_condFun() default {};

			///??? Was macht das bei einfachen annotation values???
			String $srcElementName$_src() default "";

			String $srcElementName$_expr() default "";

		}

	}
}
