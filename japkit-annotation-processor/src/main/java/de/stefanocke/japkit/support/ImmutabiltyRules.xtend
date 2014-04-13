package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.CodeBody
import de.stefanocke.japkit.gen.GenDeclaredType
import de.stefanocke.japkit.gen.GenMethod
import de.stefanocke.japkit.gen.GenParameter
import de.stefanocke.japkit.gen.GenTypeElement
import java.util.Collections
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import javax.lang.model.type.ArrayType
import javax.lang.model.type.DeclaredType

@Data
class ImmutabiltyRules {

	extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	extension AnnotationExtensions annotationExtensions = ExtensionRegistry.get(AnnotationExtensions)
	val extension RuleFactory =  ExtensionRegistry.get(RuleFactory)
	val extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)

	Boolean returnUnmodifiableCollections
	Boolean returnDefensiveCopies
	Boolean assignDefensiveCopies
	List<ElementMatcher> returnDefensiveCopiesAlsoFor
	List<ElementMatcher> assignDefensiveCopiesAlsoFor
	
	
	(DeclaredType)=>DeclaredType implTypesForDefensiveCopies

	new(AnnotationMirror annotation, AnnotationMirror metaAnnotation) {
		_returnUnmodifiableCollections = annotation.valueOrMetaValue("returnUnmodifiableCollections", Boolean,
			metaAnnotation)
		_returnDefensiveCopies = annotation.valueOrMetaValue("returnDefensiveCopies", Boolean, metaAnnotation)
		_assignDefensiveCopies = annotation.valueOrMetaValue("assignDefensiveCopies", Boolean, metaAnnotation)
		_returnDefensiveCopiesAlsoFor = annotation.elementMatchers("returnDefensiveCopiesAlsoFor", metaAnnotation)
		_assignDefensiveCopiesAlsoFor = annotation.elementMatchers("assignDefensiveCopiesAlsoFor", metaAnnotation)
		


		val listImpl = annotation.valueOrMetaValue("listImpl", DeclaredType, metaAnnotation)
		val setImpl = annotation.valueOrMetaValue("setImpl", DeclaredType, metaAnnotation)
		val mapImpl = annotation.valueOrMetaValue("mapImpl", DeclaredType, metaAnnotation)

		_implTypesForDefensiveCopies = [ DeclaredType t |
			val impl = switch (t) {
				case t.list: listImpl
				case t.set: setImpl
				case t.map: mapImpl
				default: null
			}
			if(impl !=null){
				new GenDeclaredType(impl.asElement as TypeElement) => [typeArguments = t.typeArguments]	
			} else null
		]
	}
	
	
	
	def CodeBody wrapReturnedValue(GenTypeElement genClass, Property p, CharSequence expr){
		if (returnUnmodifiableCollections && p.type.collectionOrMap) {
			val wrapperName = p.type.simpleName;
			['''«staticTypeRef(Collections)».unmodifiable«wrapperName»(«expr»)''']
		} else if (returnDefensiveCopies) {
			val defensiveCopiesAlsoFor =  returnDefensiveCopiesAlsoFor.exists[matches(p)] //Muss vor dem CodeEmmitter ausgewertet werden, da sonst die TNFE zu spät fliegen!
			defensiveCopyCode(genClass, p, expr, defensiveCopiesAlsoFor)
		} else {
			[expr]
		}
	}
	
	def CodeBody wrapAssignment(GenTypeElement genClass, Property p, CharSequence expr){
		if(assignDefensiveCopies){
			val defensiveCopiesAlsoFor = assignDefensiveCopiesAlsoFor.exists[matches(p)]
			defensiveCopyCode(genClass, p, expr, defensiveCopiesAlsoFor)
		} else {
			[expr]
		}
		
	}
	
	def private CodeBody defensiveCopyCode(GenTypeElement genClass, Property p, CharSequence expr, boolean defensiveCopiesAlsoFor) {
		if (p.type.collectionOrMap) {
			val impl = implTypesForDefensiveCopies.apply(p.type as DeclaredType);
			if (impl == null) {				
				//TODO: Log warning / error here, but don't stop code emitter by throwing exception. 
				return [expr]
			}
			if(!defensiveCopiesAlsoFor){
				//shallow copy of collection / map
				['''new «typeRef(impl)»(«expr»)''']  //TODO: Use EmitterContext.typeReff
			} else {
				//deep copy
				val copyMethodName = '''copy«p.name.toFirstUpper»'''
				if(p.type.collection){
					addCopyCollectionMethod(genClass, p , copyMethodName, impl)
				} else {		
					//TODO	
				}
				['''«copyMethodName»(«expr»)'''] 
			}	
			
		} else if (p.type.temporal || p.type instanceof ArrayType) {
			['''(«typeRef(p.type)») «expr».clone()''']
		} else if(defensiveCopiesAlsoFor){  
			['''(«typeRef(p.type)») «expr».clone()''']
		} else {
			[expr]
		}
	}
	
	def addCopyCollectionMethod(GenTypeElement genClass, Property p, String methodName, DeclaredType collectionImpl) {
		val elementType = (p.type as DeclaredType).typeArguments.get(0)
		val copyMethod = new GenMethod(methodName) => [
			returnType = p.type
			addParameter(new GenParameter("original", p.type))
			body = [
				'''
				«typeRef(p.type)» copy = new «typeRef(collectionImpl)»(original.size());
				for(«typeRef(elementType)» e : original){
					copy.add((«typeRef(elementType)») e.clone());
				}
				return copy;
				'''
			]
		]
		
		if(!genClass.declaredMethods.exists[m | m.isOverrideEquivalent(copyMethod) ]){
			genClass.add(copyMethod)
		}
	}
	

				
				
				
	
	
}
