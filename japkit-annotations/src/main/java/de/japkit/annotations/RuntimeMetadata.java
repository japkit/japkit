package de.japkit.annotations;

import static javax.lang.model.element.ElementKind.CONSTRUCTOR;
import static javax.lang.model.element.ElementKind.METHOD;

import de.japkit.annotations.RuntimeMetadata.Element;
import de.japkit.annotations.RuntimeMetadata.List;
import de.japkit.metaannotations.AV;
import de.japkit.metaannotations.AVMode;
import de.japkit.metaannotations.Annotation;
import de.japkit.metaannotations.AnnotationMode;
import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.Matcher;
import de.japkit.metaannotations.Trigger;
import de.japkit.metaannotations.Var;

@Trigger(layer=-1, vars=@Var(name="srcClass", ifEmpty=true, expr="#{annotatedClass.asType()}"))
@Clazz(nameSuffixToAppend=RuntimeMetadata.CLASS_SUFFIX, annotations={
	@Annotation(id="elementMetadata", src="#{elements.elementAndAllEnclosedElements(src)}", targetAnnotation=Element.class, 
			values={
				@AV(name="id", expr="#{elements.uniqueNameWithinTopLevelEnclosingTypeElement(src)}"), 
				@AV(name="comment", expr="#{elements.getDocComment(src)}"),
				@AV(condFun=RuntimeMetadata.methodOrConstructor.class, name="paramNames", src="#{src.parameters}", expr="#{simpleName}")
		}),
	@Annotation(targetAnnotation=List.class, mode=AnnotationMode.MERGE, 
		values=@AV(name = "value", mode=AVMode.JOIN_LIST, annotationMappingId="elementMetadata"))
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
