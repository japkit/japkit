package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenAnnotationMirror
import de.stefanocke.japkit.gen.GenAnnotationValue
import de.stefanocke.japkit.metaannotations.AVMappingMode
import de.stefanocke.japkit.support.el.ELSupport
import java.util.ArrayList
import java.util.List
import java.util.Map
import javax.annotation.processing.ProcessingEnvironment
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.type.TypeMirror

@Data
class AnnotationValueMappingRule {
	val extension ElementsExtensions jme = ExtensionRegistry.get(ElementsExtensions)
	val extension ProcessingEnvironment procEnv = ExtensionRegistry.get(ProcessingEnvironment)
	val extension ELSupport elSupport = ExtensionRegistry.get(ELSupport)
	val extension RuleUtils =  ExtensionRegistry.get(RuleUtils)

	()=>boolean activationRule
	String name
	String value
	String expr
	String lang
	String annotationMappingId
	AVMappingMode mode

	//for error reporting
	AnnotationMirror mappingRuleAnnotation

	def GenAnnotationValue mapAnnotationValue(GenAnnotationMirror annotation, Element srcElement, TypeMirror avType,
		Map<String, AnnotationMappingRule> mappingsWithId) {

		//existing value (without considering defaults!)
		val existingValue = annotation.getValueWithoutDefault(name)
		
		if(!activationRule.apply){
			return existingValue
		}

		if (existingValue != null) {
			switch (mode) {
				case AVMappingMode.ERROR_IF_EXISTS:
					throw new ProcessingException(
						'''The annotation value «name» was already generated by another rule and the mapping mode is «mode».''',
						srcElement)
				case AVMappingMode.IGNORE:
					return existingValue
				case AVMappingMode.REMOVE:
					return null
				case AVMappingMode.REPLACE: { /**Nothing to do but continue. */
				}
				case AVMappingMode.JOIN_LIST: { /**Nothing to do but here. TODO: After calculating the new value, apply the "join" */
				}
			}
		}

		val v = 
			if (!value.nullOrEmpty) {
				coerceAnnotationValue(value, avType)
			} else if (!annotationMappingId.nullOrEmpty){
				val annotationMapping = mappingsWithId.get(annotationMappingId)
				if(annotationMapping==null){
					throw new IllegalArgumentException('''AnnotationMapping with id «annotationMappingId» not found.''')
				}
				if(expr.nullOrEmpty){
					
						val annotations = newArrayList 
						annotationMapping.mapOrCopyAnnotations(annotations, srcElement, mappingsWithId)
						if(!annotations.empty){
							coerceAnnotationValue(annotations.head, avType)
						} else {
							null 
						}
					
				} else {
					val elements = eval(expr, lang, Iterable) as Iterable<Element>  //TODO: Check if instanceof element
					val annotations = newArrayList 
					elements.forEach[annotationMapping.mapOrCopyAnnotations(annotations, it, mappingsWithId)]
					coerceAnnotationValue(annotations, avType)
				}
				
			} else if (!expr.nullOrEmpty) {
				evaluateExpression(avType, expr)
			} else {

				//messager.printMessage(Kind.ERROR, '''Either 'value' or 'expr' must be set.''', am)
				throw new IllegalArgumentException(
					"Error in annotation value mapping: Either 'value' or 'expr' or 'annotationMappingId'must be set.")
			}

		if(v==null){
			return existingValue;  //No value... Leave existing value unchanged.
		}
		
		if (mode == AVMappingMode.JOIN_LIST && existingValue != null) {
			val joined = new ArrayList(existingValue.value as List<Object>)
			joined.addAll(v as List<Object>)
			new GenAnnotationValue(joined)
		} else {
			new GenAnnotationValue(v)
		}

	}

	def Object evaluateExpression(TypeMirror avType, String expr) {

		val targetClass = if(avType.kind.isPrimitive) avType.toAnnotationValueClass else Object

		val result = eval(expr, lang, targetClass)

		coerceAnnotationValue(result, avType)

	}


	new(AnnotationMirror a) {

		_name = a.value(null, "name", String)
		_value = a.value(null, "value", String)
		_expr = a.value(null, "expr", String)
		_lang = a.value(null, "lang", String)
		_mode = a.value(null, "mode", AVMappingMode)
		_annotationMappingId = a.value(null, "annotationMappingId", String)
		_mappingRuleAnnotation = a
		_activationRule = createActivationRule(a, null)

	}
}
