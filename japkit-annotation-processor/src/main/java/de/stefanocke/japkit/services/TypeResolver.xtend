package de.stefanocke.japkit.services

import de.stefanocke.japkit.el.ELSupport
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelector
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelectorKind
import de.stefanocke.japkit.model.GenArrayType
import de.stefanocke.japkit.model.GenClass
import de.stefanocke.japkit.model.GenUnresolvedType
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import javax.lang.model.type.ArrayType
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.ErrorType
import javax.lang.model.type.TypeMirror
import de.stefanocke.japkit.rules.RuleFactory
import de.stefanocke.japkit.rules.AnnotationExtensions

/**Resolves type references / class selectors from templates and annotations.*/
class TypeResolver {
	val transient extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val transient extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)
	val transient extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	val transient extension GenerateClassContext =  ExtensionRegistry.get(GenerateClassContext)
	val transient extension ELSupport =  ExtensionRegistry.get(ELSupport)
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
		if(selector instanceof ArrayType){
			new GenArrayType(selector.componentType.resolveType)
		} else {
			selector.resolveType_
		}
	}
	
	def private TypeMirror resolveType_(TypeMirror selector) {

		
		try {
			var resolved =  resolveClassSelector(selector)
			
			var type = resolved.type
			
			if (type != null) {
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
			throw tenfe;
		} catch (RuntimeException e) {

			//Wenn in einer annotation ein nicht exisitierender Typ referenziert wird, dann liefert javac dafür leider keinen
			//ErrorType, sondern den String (!) "<error>" als Annotation-Value. Das ist Mist, denn so wissen wir nicht, auf
			//welchen typ wir warten...
			//Daraus folgt, dass manche zyklische Abhängigkeiten evtl. überhaupt nicht aufgelöst werden können.
			//Beispiel: Kind-Entität verweist in ihren Annotationen auf Aggregat-Root. Aggregat-Root enthält liste der Kinder.
			//Ggf kann man hier immer einen Zyklus "vermuten". Aber welche Elemente sind in diesem enthalten?
			//
			//Man kann das umgehen, indem in Trigger-Annotationen immer auf die annotierte Klasse verwiesen wird und nicht auf 
			//die daraus generierte Klasse.
			//
			//Vermutlich ein JDK-Bug. Anstatt eine ErrorType zu liefern, wird hier eine Instanz von com.sun.tools.javac.code.Attribute.Error
			//geliefert. Und das liefert immer "<error>" als value.
			//Sieht aber so aus, als ob das in JDK8 etwas besser wird. Hier gibt es für diesen Fall eine "UnresolvedClass" als AV, die den Error-Type enthält.
			//
			//
			//http://hg.openjdk.java.net/jdk8/tl/langtools/rev/e811fb09a1dc
			throw new TypeElementNotFoundException(e);
		}

	}
	
	/**
	 * If the type element is annotated with @ClassSelector, the selector is resolved.
	 */
	def private ResolvedClassSelector resolveClassSelector(TypeMirror type) {

		val resolvedSelector = new ResolvedClassSelector
		resolvedSelector.type = type

		if (type instanceof DeclaredType && !(type instanceof ErrorType)) {
			val TypeElement te = 
			try {
				//zusätzlicher Aufruf von getTypeElement wegen Bug in UnresolvedAnnotationBinding.getElementValuePairs(): Arrays mit UnresolvedTypeBindings werden nicht resolved.
				getTypeElement(type.asTypeElement.qualifiedName)
			} catch (TypeElementNotFoundException tenfe) {
				null
			}
			

			val classSelectorAnnotation = te?.annotationMirror(ClassSelector)
			
			
			if (classSelectorAnnotation != null) {
				resolvedSelector.kind = classSelectorAnnotation.value("kind", ClassSelectorKind);
				switch (resolvedSelector.kind) {
					case ClassSelectorKind.NONE:
						resolvedSelector.type = null
					case ClassSelectorKind.ANNOTATED_CLASS:
						resolvedSelector.type = currentAnnotatedClass?.asType
					case ClassSelectorKind.GENERATED_CLASS:
						resolvedSelector.type = currentGeneratedClass?.asType
					case ClassSelectorKind.SRC_TYPE:
						resolvedSelector.type = currentSrc.srcType
					case ClassSelectorKind.SRC_SINGLE_VALUE_TYPE:
						resolvedSelector.type = currentSrc.srcType?.singleValueType
					case ClassSelectorKind.INNER_CLASS_NAME:
					{	
						resolveInnerClassSelector(resolvedSelector, classSelectorAnnotation, te)	
					}
					
					case ClassSelectorKind.EXPR : {
						resolvedSelector.type = evalClassSelectorExpr(classSelectorAnnotation, resolvedSelector, [|te.simpleName.toString.toFirstLower], TypeMirror)
					}
					case ClassSelectorKind.FQN : {
						val fqn = evalClassSelectorExpr(classSelectorAnnotation, resolvedSelector, null, String)
						resolvedSelector.type = findTypeElement(fqn)?.asType
						if(resolvedSelector.type == null){
							//Do not throw a TENFE here but allow the type to be resolved later.
							resolvedSelector.type = new GenUnresolvedType(fqn)
						}
					}
					default: {
						resolvedSelector.type = null
						reportRuleError('''Selector «resolvedSelector.kind» not supported''')
					}
						
				}

			
			
				val requiredTriggerAnnotation = classSelectorAnnotation.value("requiredTriggerAnnotation", typeof(TypeMirror[])).toSet
				
				if (!requiredTriggerAnnotation.nullOrEmpty && resolvedSelector.type !=null) {
					resolvedSelector.type = generatedTypeAccordingToTriggerAnnotation(resolvedSelector.type, requiredTriggerAnnotation, true)
				}
			
			}

		}
		
		resolvedSelector
	}
	
	
	private def getEnclosingTypeElement(AnnotationMirror classSelectorAnnotation) {
		val enclosing = classSelectorAnnotation.value("enclosing", TypeMirror)?.resolveType?.asTypeElement
		enclosing
	}
	
	private def resolveInnerClassSelector(ResolvedClassSelector resolvedSelector, AnnotationMirror classSelectorAnnotation, TypeElement te) {
		resolvedSelector.enclosingTypeElement = getEnclosingTypeElement(classSelectorAnnotation)
		if(resolvedSelector.enclosingTypeElement==null){
			reportRuleError('''Could not determine enclosing type element for inner class.''')
			return
		}
		resolvedSelector.innerClassName = evalClassSelectorExpr(classSelectorAnnotation, resolvedSelector, null, String)
		
		//simple name of the type template as fallback
		if(resolvedSelector.innerClassName==null){
			resolvedSelector.innerClassName=te.simpleName.toString
		}
		
		resolvedSelector.typeElement = resolvedSelector.enclosingTypeElement.declaredTypes.findFirst[simpleName.contentEquals(resolvedSelector.innerClassName)]
		resolvedSelector.type = if(resolvedSelector.typeElement != null)
			resolvedSelector.typeElement.asType
			else new GenUnresolvedType('''«resolvedSelector.enclosingTypeElement.qualifiedName».«resolvedSelector.innerClassName»''')
	}
	
	private def <T> T evalClassSelectorExpr(AnnotationMirror classSelectorAnnotation, ResolvedClassSelector resolvedSelector, ()=>String defaultExpr, Class<T> targetType) {
		val exprFromAV = classSelectorAnnotation.value("expr", String);
		val expr = if(exprFromAV.nullOrEmpty) defaultExpr?.apply else exprFromAV
		if(expr.nullOrEmpty) return null
		val lang = classSelectorAnnotation.value("lang", String);
		ExtensionRegistry.get(ELSupport).eval(expr, lang, targetType,
			'''Error when evaluating class selector expression '«expr»'  ''', null			
		)	
		
	}
	
	
	
//	def private getClassSelectorAvName(AnnotationMirror classSelectorAnnotation, TypeElement te) {
//		var avName = classSelectorAnnotation.value("avName", String);
//		if(avName.nullOrEmpty){
//			avName = te.simpleName.toString.toFirstLower
//		}
//		avName
//	}
	
	
	/**Resolves the class selector and creates a "proxy" for the type element so that it is available even if it does not really exist yet.
	 * TODO: Braucht man hier wirklich einen separaten Proxy? Ggf spezieller "UnresolvedType" der bei asElement das TypeElement liefert?
	 * Vllt kann man das dann auch mit der anderen resolve-MEthode vereinheitlichen und generell per Flag steuern, ob eine TENFE geworfen wird
	 * oder auf den Proxy verwiesen wird.
	 */
	def public resolveTypeAndCreateProxy(TypeMirror selector) {
		try {

			var resolved = resolveClassSelector(selector)

			var tm = resolved.type
			var selectorKind = resolved.kind

			if (selectorKind == null || selectorKind == ClassSelectorKind.EXPR) {
				var TypeElement te

				try {
					te = tm.asTypeElement
				} catch (TypeElementNotFoundException tenfe) {
					//That's ok here	
				}

				var GenClass proxy
				if (te != null) {
					proxy = new GenClass(te.simpleName)
					proxy.setEnclosingElement(te.enclosingElement)
				} else {

					//Type Element does not exist... Best guess...
					val fqn = tm.toString
					val segments = fqn.split('\\.')
					val simpleName = segments.last

					val packageName = if (segments.length == 1) {
							currentAnnotatedClass.package.qualifiedName
						} else {
							fqn.substring(0, fqn.length - simpleName.length - 1)
						}

					proxy = new GenClass(simpleName, packageName.toString)
				}
				proxy -> te

			} else if(selectorKind == ClassSelectorKind.INNER_CLASS_NAME){
				
					val proxy = new GenClass(resolved.innerClassName)
					proxy.setEnclosingElement(resolved.enclosingTypeElement )
					proxy -> resolved.typeElement
				
			} else {
				throw new ProcessingException('''Selector «selectorKind» not supported''', currentAnnotatedClass, currentTriggerAnnotation,
							null, null)
			}

		} catch (ProcessingException pe) {
			throw pe
		} catch (RuntimeException e) {
			throw new TypeElementNotFoundException(e);
		}

	}
	
	/**
	 * Validates if the type has (at most) one of the given trigger annotations. If so , and it is not a generated type, 
	 * the according generated type is determined and returned.  
	 */
	def TypeMirror generatedTypeAccordingToTriggerAnnotation(TypeMirror type, Iterable<TypeMirror> triggerAnnotationTypes, boolean mustHaveTrigger
	) {
		var typeCandidate = type
		
		if (typeCandidate instanceof DeclaredType && !(typeCandidate instanceof ErrorType)) {
			
			
			val typeElement = typeCandidate.asTypeElement
			typeCandidate = 
			generatedTypeElementAccordingToTriggerAnnotation(typeElement, triggerAnnotationTypes, mustHaveTrigger)?.asType
		}
		typeCandidate
	}
	
	def TypeElement generatedTypeElementAccordingToTriggerAnnotation(TypeElement typeElement, Iterable<TypeMirror> triggerAnnotationTypes, boolean mustHaveTrigger) {
		if(triggerAnnotationTypes.nullOrEmpty){
			return typeElement
		}
		
		val extension AnnotationExtensions = ExtensionRegistry.get(AnnotationExtensions)
		if(typeElement.annotationMirrors.filter[isTriggerAnnotation].empty){
			//If the type element has no trigger annotations at all we assume it is a "hand-written" class and leave it as it is.
			//TODO: This could be configurable...
			return typeElement
		}
		
		
		val triggerAnnotationTypeFqns = triggerAnnotationTypes.map[qualifiedName].toSet
		val annotations = typeElement.annotationMirrors.filter[triggerAnnotationTypeFqns.contains(annotationType.qualifiedName)] 
		
		if (annotations.empty) {
			if (mustHaveTrigger) {
				reportRuleError(
					'''Related type «typeElement.qualifiedName» must have one of the trigger annotations «triggerAnnotationTypeFqns».''');
				null

			} else {
				typeElement
			}
		}
		
		else if (annotations.size > 1) {
		
			reportRuleError(
				'''Related type «typeElement.qualifiedName» has more than one of the trigger annotations «triggerAnnotationTypeFqns».
				 Thus, the generated type to use is not unique.''');
			null
		}
		else if(!typeElement.generated) {  
		
			//Only apply the transformation if it is not a generated class 
				
			
			val triggerAnnotation = annotations.head

			val rule = ExtensionRegistry.get(RuleFactory).createTriggerAnnotationRule(triggerAnnotation.annotationAsTypeElement)
			val fqn = rule.getGeneratedTypeElementFqn(typeElement)
			
			val generatedTypeElement = findTypeElement(fqn)
			if (generatedTypeElement == null) {
				throw new TypeElementNotFoundException(fqn, '')  
			} else {
				generatedTypeElement				
			}
				
		} else {
			typeElement
		}
	}

}
