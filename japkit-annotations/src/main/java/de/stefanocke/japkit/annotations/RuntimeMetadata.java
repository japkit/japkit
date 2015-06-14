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
import de.stefanocke.japkit.metaannotations.Trigger;
import de.stefanocke.japkit.metaannotations.Var;

@Trigger(layer=-1, vars=@Var(name="srcClass", ifEmpty=true, expr="#{annotatedClass.asType()}"))
@Clazz(nameSuffixToAppend=RuntimeMetadata.CLASS_SUFFIX, annotations={
	@Annotation(id="elementMetadata", targetAnnotation=Element.class, 
			values={
				@AV(name="id", expr="#{elements.uniqueNameWithinTopLevelEnclosingTypeElement(src)}"), 
				@AV(name="comment", expr="#{elements.getDocComment(src)}"),
				@AV(condFun=RuntimeMetadata.methodOrConstructor.class, name="paramNames", expr="#{src.parameters}")
		}),
	@Annotation(targetAnnotation=List.class, mode=AnnotationMode.MERGE, 
		values=@AV(name = "value", expr="#{elements.elementAndAllEnclosedElements(src)}", mode=AVMode.JOIN_LIST, annotationMappingId="elementMetadata"))
})

public @interface RuntimeMetadata {
	@Matcher(kind={METHOD, CONSTRUCTOR})
	class methodOrConstructor{}
	
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
