package de.japkit.rules

import de.japkit.el.ELSupport
import de.japkit.el.ElVariableError
import de.japkit.metaannotations.ResultVar
import de.japkit.services.ElementsExtensions
import de.japkit.services.ExtensionRegistry
import de.japkit.services.GenerateClassContext
import java.util.List
import java.util.Map
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.TypeElement
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.xbase.lib.Functions.Function1

import static extension de.japkit.rules.RuleUtils.withPrefix
import org.eclipse.xtext.xbase.lib.Functions.Function2

/**Rule that creates a new scope for each src element given by the source rule and executes the given closure within that scope. 
 * Optionally puts EL-Variables into that scope. 
 */
@Data
class ScopeRule<T> implements Function1<(Object)=>T,List<T>>, Function2<(Object)=>void, (Object)=>T,List<T>> {
	
	val protected transient extension RuleUtils = ExtensionRegistry.get(RuleUtils)
	val protected transient extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val protected transient extension ELSupport = ExtensionRegistry.get(ELSupport)
	val protected transient extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)

	String srcVarName
	List<ELVariableRule> varRules
	List<LibraryRule> libraryRules
	LibraryRule selfLibrary 

	AnnotationMirror resultVarAnnotation 
	String resultVarName
	()=>Object srcRule
	
	
	new(
		AnnotationMirror metaAnnotation,
		Element metaElement,
		boolean isLibrary,
		String avPrefix,
		boolean shallCreateSrcRule
	) {

		srcVarName = metaAnnotation?.value("srcVar".withPrefix(avPrefix), String)
		varRules = createELVariableRules(metaAnnotation, metaElement, avPrefix)
		libraryRules = createLibraryRules(metaAnnotation, avPrefix)
		selfLibrary = if(isLibrary) new LibraryRule(metaAnnotation, metaElement as TypeElement)

		resultVarAnnotation = metaElement?.annotationMirror(ResultVar)
		val resultVarAV = resultVarAnnotation?.value("value".withPrefix(avPrefix), String);
		resultVarName = if(resultVarAV.nullOrEmpty) metaElement?.simpleName?.toString else resultVarAV;	
		this.srcRule = if(shallCreateSrcRule) createSrcRule(metaAnnotation, avPrefix)	
	}
	
	override apply((Object)=>T closure) {
		apply(null, closure)
	}
	
	//early closure is applied before el variables and other rules are evaluated
	override apply((Object)=>void earlyClosure, (Object)=>T closure) {
		  
			try {

				val src = srcRule?.apply ?: currentSrc;

				//Iterate only, if the scope has its own src rule
				val iterate = srcRule != null && (src instanceof Iterable<?> || src instanceof Map<?, ?>)

				val result = if (iterate) {
						val iterable = if(src instanceof Iterable<?>) src else (src as Map<?, ?>).entrySet
						iterable.map [ e |
							doInScope(e, earlyClosure, closure)
						].toList

					} else {
						newArrayList(doInScope(src, earlyClosure, closure))
					};
				if (resultVarAnnotation != null && !resultVarName.nullOrEmpty) {
					valueStack.put(resultVarName, if(iterate) result else result.head)
				}

				result

			} catch (Exception e) {
				// To avoid error flooding or misleading errors
				// TODO: Reconsider resultVar. Better use some functional approach + "mapping cache" instead
				if (resultVarAnnotation != null && !resultVarName.nullOrEmpty) {
					valueStack.put(resultVarName, new ElVariableError(resultVarName))
				}
				throw e
			}
		
	}

	private def <T> T doInScope(Object src, (Object)=>void earlyClosure, (Object)=>T closure) {
		scope(src) [
			if (!srcVarName.nullOrEmpty) {
				valueStack.put(srcVarName, src)
			}
			if(earlyClosure != null) {
				earlyClosure.apply(src)
			}
			libraryRules.forEach[apply]
			selfLibrary?.apply
			valueStack.put("currentRule", currentRule)
			varRules?.forEach[it.putELVariable]
			closure.apply(src)
		]
	}

}
