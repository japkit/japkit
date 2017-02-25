package de.japkit.rules

import de.japkit.el.ELSupport
import de.japkit.model.GenArrayType
import de.japkit.model.GenDeclaredType
import de.japkit.services.ElementsExtensions
import de.japkit.services.ExtensionRegistry
import de.japkit.services.GenerateClassContext
import de.japkit.services.MessageCollector
import de.japkit.services.TypeElementNotFoundException
import de.japkit.services.TypesExtensions
import de.japkit.services.TypesRegistry
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import javax.lang.model.type.ArrayType
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.ErrorType
import javax.lang.model.type.TypeMirror
import javax.lang.model.type.TypeVariable
import javax.lang.model.element.TypeParameterElement

/**Resolves type references / class selectors from templates and annotations.*/
class TypeResolver {
	val transient extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val transient extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)
	val transient extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	val transient extension GenerateClassContext =  ExtensionRegistry.get(GenerateClassContext)
	val transient extension RuleFactory =  ExtensionRegistry.get(RuleFactory)
	val transient extension MessageCollector = ExtensionRegistry.get(MessageCollector)
	val transient extension ELSupport = ExtensionRegistry.get(ELSupport)
	
	def TypeMirror resolveTypeFromAnnotationValues(
		AnnotationMirror metaAnnotation,
		String typeAvName,
		String typeArgsAvName
	) {
		createTypeIfNecessary(
			resolveTypeFromAnnotationValues( metaAnnotation, typeAvName),
			resolveTypesFromAnnotationValues(metaAnnotation, typeArgsAvName)
		)
	}
	
	def private TypeMirror createTypeIfNecessary(TypeMirror type, List<? extends TypeMirror> typeArgs) {
		if (type === null || typeArgs.nullOrEmpty || !(type instanceof DeclaredType)) {
			type
		} else {
			getDeclaredType(type.asElement, typeArgs)
		}
	}

	def TypeMirror resolveTypeFromAnnotationValues(AnnotationMirror metaAnnotation, String typeAvName) { 

		val selector = metaAnnotation.value(typeAvName, TypeMirror)
		selector.resolveType

	}

	def List<? extends TypeMirror> resolveTypesFromAnnotationValues(AnnotationMirror metaAnnotation, String typeArgsAvName)  {

		val selectors =  metaAnnotation.value(typeArgsAvName, typeof(TypeMirror[]))
		selectors.map(s|s.resolveType)

	}
	
	def TypeMirror resolveType(TypeMirror selector) {
		resolveType(selector, true)
	}

	def dispatch TypeMirror resolveType(ArrayType selector, boolean required) {
		new GenArrayType(selector.componentType.resolveType(required))
	}
	
	def dispatch TypeMirror resolveType(DeclaredType typeOrTypeFunction, boolean required) {
		val typeFunctionResult = resolveTypeFunctionIfNecessary(typeOrTypeFunction)
		
		if(typeFunctionResult instanceof DeclaredType)  typeFunctionResult.resolveType_(required) else typeFunctionResult?.resolveType(required)
	}
	
	//TypeVars can be used to pass parameters to type functions. Resolve them from value stack if possible.	
	def dispatch TypeMirror resolveType(TypeVariable typeVariable, boolean required) {

		val param = typeVariable.asElement as TypeParameterElement
		valueStack.get(
			'''«(param.enclosingElement as TypeElement).qualifiedName».«param.simpleName»'''.toString) as TypeMirror ?:
			typeVariable

	}
	
	def dispatch TypeMirror resolveType(TypeMirror selector, boolean required) {
		selector
	}
	
	
	def private TypeMirror resolveType_(DeclaredType typeFunctionResult, boolean required) {

		
		try {			
			var type = typeFunctionResult
			
			//Always try to resolve error type if the type is required
			type = if(type instanceof ErrorType && required) type.asTypeElement.asType as DeclaredType else type
			
			//TODO: Wird das hier wirklich noch benötigt oder ist das redundant zu anderen Mechanismen (tenfe)?
			if (type !== null && required) {
				currentAnnotatedClass.registerTypeDependencyForAnnotatedClass(type)
			}
			
			
			if(type === null) {
				type
			} else {
				//If there are type arguments, map them as well. 
				val typeArgs = typeFunctionResult.typeArguments
				
				if(typeArgs.nullOrEmpty){
					type
				} else {
					
					getDeclaredType(type.asElement as TypeElement, typeArgs.map[typeArg |
						
						typeArg.resolveType(required)
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
	def private TypeMirror resolveTypeFunctionIfNecessary(DeclaredType type) {

		if (!(type instanceof ErrorType)) {
			// zusätzlicher Aufruf von getTypeElement wegen Bug in UnresolvedAnnotationBinding.getElementValuePairs(): Arrays mit UnresolvedTypeBindings werden nicht resolved.
			// TODO: Ist das schon in ElementsExtensions geregelt?
			var TypeElement te = type.asTypeElement
			if (!(type instanceof GenDeclaredType)) {
				te = getTypeElement(te.qualifiedName)
				if (te === null) {
					throw new TypeElementNotFoundException(te.qualifiedName.toString)
				}
			}
			val teFinal = te

			// if it is a function, call it and return the resulting type
			val function = createFunctionRule(te);

			if (function !== null) {
				return scope[
					//if the type function has type arguments, resolve them and put them on the value stack. They can be retrieved by the simpleName of the type parameter. 
					if (!type.typeArguments.nullOrEmpty) {
						teFinal.typeParameters?.forEach [ param, index |
							if (index < type.typeArguments.length) {
								val resolvedArg = type.typeArguments.get(index)?.resolveType(true)
								valueStack.put(param.simpleName.toString, resolvedArg);
								//put it also under unique name
								valueStack.put('''«teFinal.qualifiedName».«param.simpleName»''' , resolvedArg);
							}
						]
					}

					val result = function.apply
					if (result === null ||
						result instanceof TypeMirror) {
						result as TypeMirror
					} else {
						reportRuleError('''«teFinal.qualifiedName» cannot be used as type since it's result is not a TypeMirror but «result».''')
						null
					}

				]

			}
		}

		type
	}

}
