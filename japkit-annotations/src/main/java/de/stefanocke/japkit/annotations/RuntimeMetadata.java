package de.stefanocke.japkit.annotations;

import static javax.lang.model.element.ElementKind.CONSTRUCTOR;
import static javax.lang.model.element.ElementKind.METHOD;
import de.stefanocke.japkit.annotations.RuntimeMetadata.Element;
import de.stefanocke.japkit.annotations.RuntimeMetadata.List;
import de.stefanocke.japkit.metaannotations.AV;
import de.stefanocke.japkit.metaannotations.AVMode;
import de.stefanocke.japkit.metaannotations.Annotation;
import de.stefanocke.japkit.metaannotations.AnnotationMode;
import de.stefanocke.japkit.metaannotations.Clazz;
import de.stefanocke.japkit.metaannotations.Matcher;
import de.stefanocke.japkit.metaannotations.Var;

@Var(name="srcClass", triggerAV="srcClass", setInShadowAnnotation=true, expr="#{currentAnnotatedClass.asType()}")
@Clazz(nameSuffixToAppend=RuntimeMetadata.CLASS_SUFFIX, annotations={
	@Annotation(id="elementMetadata", targetAnnotation=Element.class, 
			values={
				@AV(name="id", expr="#{elements.uniqueName(src)}"), //TODO: uniqueId
				@AV(name="comment", expr="#{elements.getDocComment(src)}"),
				@AV(activation=@Matcher(kind={METHOD, CONSTRUCTOR}), name="paramNames", expr="#{src.parameters}")
		}),
	@Annotation(targetAnnotation=List.class, mode=AnnotationMode.MERGE, 
		values=@AV(name = "value", expr="#{elements.elementAndAllEnclosedElements(src)}", mode=AVMode.JOIN_LIST, annotationMappingId="elementMetadata"))
})

public @interface RuntimeMetadata {
	public static final String CLASS_SUFFIX = "_RuntimeMetadata";
	
	boolean shadow() default false;
	
	Class<?>[] srcClass() default {};
	
	@interface Element {

		String id();
		String comment() default "";
		String[] paramNames() default {};
		
		
	}
	
	@interface List{
		Element[] value();
	}
}
