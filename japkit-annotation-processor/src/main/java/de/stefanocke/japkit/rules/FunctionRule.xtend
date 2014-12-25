package de.stefanocke.japkit.rules

import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import org.eclipse.xtend.lib.annotations.Data

@Data
class FunctionRule extends AbstractNoArgFunctionRule<Object> {
	
	String expr
	String lang
	
	new(AnnotationMirror metaAnnotation, Element metaElement) {
		super(metaAnnotation, metaElement, null)
	
		val exprFromAv = metaAnnotation.value("expr", String);
		
		expr = if(!exprFromAv.nullOrEmpty) exprFromAv else JavadocUtil.getCode(metaElement?.getDocCommentUsingRuntimeMetadata).get("expr")
		
		lang = metaAnnotation.value("lang", String);
		
	}
	
	override evalInternal(){ 
		eval(expr, lang, type)
	}

}