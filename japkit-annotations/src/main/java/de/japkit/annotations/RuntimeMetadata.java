package de.japkit.annotations;

import static javax.lang.model.element.ElementKind.CONSTRUCTOR;
import static javax.lang.model.element.ElementKind.METHOD;

import java.lang.annotation.Documented;

import de.japkit.annotations.RuntimeMetadata.Element;
import de.japkit.annotations.RuntimeMetadata.List;
import de.japkit.metaannotations.AV;
import de.japkit.metaannotations.AVMode;
import de.japkit.metaannotations.Annotation;
import de.japkit.metaannotations.AnnotationMode;
import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.Matcher;
import de.japkit.metaannotations.Template;
import de.japkit.metaannotations.Trigger;
import de.japkit.metaannotations.Var;

/**
 * This annotation should be put on every top level template class (annotated
 * with {@link Clazz} or {@link Template}). It generates additional metadata for
 * the template that is required by japkit but not available to annotation
 * processing, if the template class is only available binary but not as source.
 * This is the case if the template class is in another project or if
 * incremental compilation is used in an IDE.
 * <p>
 * The additional provided metadata is:
 * <ul>
 * <li>order of the template elements
 * <li>comments of the template elements (especially code templates contained
 * therein)
 * <li>method parameter names
 * </ul>
 */
@Documented
@Trigger(layer = -1, vars = @Var(name = "srcClass", ifEmpty = true, expr = "#{annotatedClass.asType()}"))
@Clazz(
	commentExpr = "The generated runtime metadata for #{src.simpleName}.",
	nameSuffixToAppend = RuntimeMetadata.CLASS_SUFFIX,
	annotations = {
		@Annotation(
			id = "elementMetadata",
			src = "#{elements.elementAndAllEnclosedElements(src)}",
			targetAnnotation = Element.class,
			values = {
				@AV(name = "id", expr = "#{elements.uniqueNameWithinTopLevelEnclosingTypeElement(src)}"),
				@AV(name = "comment", expr = "#{elements.getDocComment(src)}"),
				@AV(
					condFun = RuntimeMetadata.methodOrConstructor.class,
					name = "paramNames",
					src = "#{src.parameters}",
					expr = "#{simpleName}") }),
		@Annotation(
			targetAnnotation = List.class,
			mode = AnnotationMode.MERGE,
			values = @AV(name = "value", mode = AVMode.JOIN_LIST, annotationMappingId = "elementMetadata")) })

public @interface RuntimeMetadata {
	@Matcher(kind = { METHOD, CONSTRUCTOR })
	class methodOrConstructor {
	}

	public static final String CLASS_SUFFIX = "_RuntimeMetadata";

	boolean shadow() default false;

	Class<?>[] srcClass() default {};

	@interface Element {

		String id();

		String comment() default "";

		String[] paramNames() default {};

	}

	@interface List {
		Element[] value();
	}
}
