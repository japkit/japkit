package de.japkit.annotations;

import de.japkit.annotations.RuntimeMetadata.Element;
import de.japkit.annotations.RuntimeMetadata.List;
import de.japkit.metaannotations.AV;
import de.japkit.metaannotations.AVMode;
import de.japkit.metaannotations.Annotation;
import de.japkit.metaannotations.AnnotationMode;
import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.Trigger;
import de.japkit.metaannotations.Var;

@Trigger(layer=-1, vars=@Var(name="srcClass", ifEmpty=true, expr="#{annotatedClass.asType()}"))
@Clazz(nameSuffixToAppend=RuntimeMetadata.CLASS_SUFFIX, annotations={
	@Annotation(id="elementMetadata", targetAnnotation=Element.class, 
			values={
				@AV(name="id", expr="#{elements.uniqueNameWithinTopLevelEnclosingTypeElement(src)}"), 
				@AV(name="comment", expr="#{elements.getDocComment(src)}"),
				@AV(cond="#{src.kind.name()=='METHOD' || src.kind.name()=='CONSTRUCTOR'}", name="paramNames", expr="#{src.parameters}")
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
