package de.stefanocke.japkit.rules

import de.stefanocke.japkit.model.GenArrayType
import de.stefanocke.japkit.services.ElementsExtensions
import de.stefanocke.japkit.services.ExtensionRegistry
import de.stefanocke.japkit.services.GenerateClassContext
import de.stefanocke.japkit.services.MessageCollector
import de.stefanocke.japkit.services.TypeElementNotFoundException
import de.stefanocke.japkit.services.TypesExtensions
import de.stefanocke.japkit.services.TypesRegistry
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import javax.lang.model.type.ArrayType
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.ErrorType
import javax.lang.model.type.TypeMirror
import de.stefanocke.japkit.model.GenDeclaredType

/**Resolves type references / class selectors from templates and annotations.*/
class TypeResolver {
	val transient extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val transient extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)
	val transient extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	val transient extension GenerateClassContext =  ExtensionRegistry.get(GenerateClassContext)
	val transient extension RuleFactory =  ExtensionRegistry.get(RuleFactory)
	val transient extension MessageCollector = ExtensionRegistry.get(MessageCollector)
	
	def TypeMirror resolveType(
		AnnotationMirror metaAnnotation,
		String typeAvName,
		String typeArgsAvName
	) {
		createTypeIfNecessary(
			resolveType( metaAnnotation, typeAvName),
			resolveTypes(metaAnnotation, typeArgsAvName)
		)
	}
	
	def private TypeMirror createTypeIfNecessary(TypeMirror type, List<? extends TypeMirror> typeArgs) {
		if (type == null || typeArgs.nullOrEmpty || !(type instanceof DeclaredType)) {
			type
		} else {
			getDeclaredType(type.asElement, typeArgs)
		}
	}

	def TypeMirror resolveType(AnnotationMirror metaAnnotation, String typeAvName) { 

		val selector = metaAnnotation.value(typeAvName, TypeMirror)
		selector.resolveType

	}

	def List<? extends TypeMirror> resolveTypes(AnnotationMirror metaAnnotation, String typeArgsAvName)  {

		val selectors =  metaAnnotation.value(typeArgsAvName, typeof(TypeMirror[]))
		selectors.map(s|s.resolveType)

	}
	
	def TypeMirror resolveType(TypeMirror selector) {
		resolveType(selector, true)
	}

	def TypeMirror resolveType(TypeMirror selector, boolean required) {
		if(selector instanceof ArrayType){
			new GenArrayType(selector.componentType.resolveType(required))
		} else {
			selector.resolveType_(required)
		}
	}
	
	def private TypeMirror resolveType_(TypeMirror selector, boolean required) {

		
		try {			
			var type = resolveTypeFunctionIfNecessary(selector)
			
			//Always try to resolve error type if the type is required
			type = if(type instanceof ErrorType && required) type.asTypeElement.asType else type
			
			//TODO: Wird das hier wirklich noch benötigt oder ist das redundant zu anderen Mechanismen (tenfe)?
			if (type != null && required) {
				currentAnnotatedClass.registerTypeDependencyForAnnotatedClass(type)
			}
			
			//If the selector has type arguments, map them as well
			if(type == null || !(type instanceof DeclaredType) || !(selector instanceof DeclaredType)){
				type
			} else {
				val selDecl =  selector as DeclaredType 
				if(selDecl.typeArguments.nullOrEmpty){
					type
				} else {
					getDeclaredType(type.asElement, selDecl.typeArguments.map[
						resolveType()
					])				
				}	
			}
		} catch (TypeElementNotFoundException tenfe) {
			throw tenfe 
		} catch (Exception e) {
			reportRuleError(e)
			throw e;
		}

	}
	
	/**
	 * Checks it the type refers to a function. If so, the function is called and the resulting type mirror is returned.
	 */
	def private TypeMirror resolveTypeFunctionIfNecessary(TypeMirror type) {

			if (type instanceof DeclaredType && !(type instanceof ErrorType)) {
				//zusätzlicher Aufruf von getTypeElement wegen Bug in UnresolvedAnnotationBinding.getElementValuePairs(): Arrays mit UnresolvedTypeBindings werden nicht resolved.
				//TODO: Ist das schon in ElementsExtensions geregelt?
				var TypeElement te = type.asTypeElement
				if(!(type instanceof GenDeclaredType)){
					te =  getTypeElement(te.qualifiedName)		
					if(te==null){
						throw new TypeElementNotFoundException(te.qualifiedName.toString)
					}		
				}
		
				//if it is a function, call it and return the resulting type
				val function = createFunctionRule(te);
				
				if(function!=null){
					if(function instanceof AbstractFunctionRule<?>){
						val result = function.apply
						if(result == null || result instanceof TypeMirror){
							return result as TypeMirror
						} else {
							reportRuleError('''«te.qualifiedName» cannot be used as type since it's result is not a TypeMirror but «result».''')
						}
					} else {
						reportRuleError('''«te.qualifiedName» cannot be used as type since it is not a function.''')
					}
				}
			}
		
		
		
		type
	}

}
