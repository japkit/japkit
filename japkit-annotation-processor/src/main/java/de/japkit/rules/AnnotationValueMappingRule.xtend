package de.japkit.rules

import de.japkit.metaannotations.AVMode
import de.japkit.model.GenAnnotationMirror
import de.japkit.model.GenAnnotationValue
import de.japkit.services.ProcessingException
import java.util.ArrayList
import java.util.List
import java.util.Map
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.type.TypeMirror
import org.eclipse.xtend.lib.annotations.Data

import static extension de.japkit.rules.RuleUtils.withPrefix
import de.japkit.services.RuleException

@Data
class AnnotationValueMappingRule extends AbstractRule {

	()=>boolean activationRule
	String name
	Object value
	String expr
	String exprAvName
	String lang
	()=>AnnotationMappingRule lazyAnnotationMapping
	AVMode mode


	def GenAnnotationValue mapAnnotationValue(GenAnnotationMirror annotation, TypeMirror avType) {
		inRule[
			//existing value (without considering defaults!)
			val existingValue = annotation?.getValueWithoutDefault(name)
			
			if(!activationRule.apply){
				return existingValue
			}
	
			if (existingValue != null) {
				switch (mode) {
					case AVMode.ERROR_IF_EXISTS:
						throw new RuleException(
							'''The annotation value «name» was already generated by another rule and the mapping mode is «mode».''')
					case AVMode.IGNORE:
						return existingValue
					case AVMode.REMOVE:
						return null
					case AVMode.REPLACE: { /**Nothing to do but continue. */
					}
					case AVMode.JOIN_LIST: { /**Nothing to do but here. TODO: After calculating the new value, apply the "join" */
					}
					case AVMode.MERGE:{
						
					}
				}
			}
	
			val v = if (value != null) {
					coerceAnnotationValue(value, avType)
				} else if (lazyAnnotationMapping != null) {
					
					val annotationMapping = lazyAnnotationMapping.apply

					val annotations = newArrayList
					annotationMapping.mapOrCopyAnnotations(annotations)
					if (!annotations.empty) {
						coerceAnnotationValue(annotations, avType)
					} else {
						null
					}

				} else if (!expr.nullOrEmpty) {
					evaluateExpression(avType, expr)
				} else {
					// messager.printMessage(Kind.ERROR, '''Either 'value' or 'expr' must be set.''', am)
					// throw new IllegalArgumentException(
					// "Error in annotation value mapping: Either 'value' or 'expr' or 'annotationMappingId'must be set.")
				}
	
			if(v==null){
				return existingValue;  //No value... Leave existing value unchanged.
			}
			
			if (mode == AVMode.JOIN_LIST && existingValue != null) {
				val joined = new ArrayList(existingValue.valueWithErrorHandling as List<Object>)
				joined.addAll(v as List<Object>)
				new GenAnnotationValue(joined)
			} else {
				new GenAnnotationValue(v)
			}
		
		]

	}

	def private Object evaluateExpression(TypeMirror avType, String expr) {

		val targetClass = if(avType.kind.isPrimitive) avType.toAnnotationValueClass else Object

		handleException(null, exprAvName)[ 
			val result = eval(expr, lang, targetClass)
			coerceAnnotationValue(result, avType)
		]

	}


	new(AnnotationMirror a,  Map<String, AnnotationMappingRule> mappingsWithId) {
		super(a, null)
		name = a.value(null, "name", String)
		value = a.value(null, "value", String)
		exprAvName="expr"
		expr = a.value(null, exprAvName, String)
		lang = a.value(null, "lang", String)
		mode = a.value(null, "mode", AVMode)
		val annotationMappingId = a.value(null, "annotationMappingId", String)
		lazyAnnotationMapping = if(annotationMappingId.nullOrEmpty) null else [| 
			val amr = mappingsWithId.get(annotationMappingId)
			if(amr==null){
				throw new IllegalArgumentException("Annotation Mapping with id "+annotationMappingId+" not found");
			}
			amr
		]
		if(#[expr!=null,value!=null,lazyAnnotationMapping!=null].filter[it].size > 1){
			throwRuleCreationException('''At most one of the annotation values 'value', '«exprAvName»', 'annotationMappingId' may be set.''')
		}
		activationRule = createActivationRule(a, null)

	}
	
	new(AnnotationMirror a,  Element templateElement, String avName) {
		super(a, templateElement)
		name = avName
		value = a.value(avName, Object)
		
		val avPrefix = avName+'_'
		exprAvName="expr".withPrefix(avPrefix)
		expr = a.value(exprAvName, String)
		lang = a.value("lang".withPrefix(avPrefix), String)
		mode = AVMode.JOIN_LIST
		
		
		val annotationMappingAnnotation =  a.value(avPrefix, AnnotationMirror)
		
		lazyAnnotationMapping = if (annotationMappingAnnotation == null) null else {
			val amr = new AnnotationMappingRule(annotationMappingAnnotation, templateElement);
			[| amr]
		}
		
		if(#[expr!=null,value!=null,lazyAnnotationMapping!=null].filter[it].size > 1){
			throwRuleCreationException('''At most one of the annotation values '«avName»', '«exprAvName»', '«avPrefix»' may be set.''')
		}
		
		activationRule = createActivationRule(a, avPrefix)

	}
}
