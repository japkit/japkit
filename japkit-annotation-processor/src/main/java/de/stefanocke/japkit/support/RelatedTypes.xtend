package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenClass
import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.metaannotations.GenerateClass
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelector
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelectorKind
import de.stefanocke.japkit.support.el.ELSupport
import java.util.List
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.TypeElement
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.ErrorType
import javax.lang.model.type.TypeMirror

class RelatedTypes {
	extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)
	extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	extension AnnotationExtensions = ExtensionRegistry.get(AnnotationExtensions)
	MessageCollector messageCollector = ExtensionRegistry.get(MessageCollector)
	
	//Closure to resolve all type selectors in a given type
	def relatedTypesTransformation(TypeElement annotatedClass, GenTypeElement generatedClass, AnnotationMirror triggerAnnotation, Element ruleSrcElement) {
		[ TypeMirror t |
			//TODO: Das Konzept bzgl meta-annotations ist bei relatedType noch nicht ganz durchdacht.
			//Meist bezieht sich der selector auf die Trigger annotation. Nur bei "BehaviorInnerClass" ist das bisher anders. 
			//Da bezieht er sich auf GenClass.
			//Vorläufig setzten wir hier null als metaannotation, damit es überhaupt funzt.
			t.relatedType(annotatedClass, generatedClass, triggerAnnotation, null, null, ruleSrcElement)
		]
	}
	
	def resolveType(
		AnnotationMirror anno,
		TypeElement annotatedClass,
		GenTypeElement generatedClass,
		AnnotationMirror methodAnnotation,
		String typeAvName,
		String typeArgsAvName,
		Element ruleSrcElement
	) {
		createTypeIfNecessary(
			relatedType(annotatedClass, generatedClass, anno, typeAvName, methodAnnotation, ruleSrcElement),
			relatedTypes(annotatedClass, generatedClass, anno, typeArgsAvName, methodAnnotation, ruleSrcElement)
		)
	}

	def private createTypeIfNecessary(TypeMirror type, List<TypeMirror> typeArgs) {
		if (type == null || typeArgs.nullOrEmpty || !(type instanceof DeclaredType)) {
			type
		} else {
			getDeclaredType(type.asElement, typeArgs)
		}
	}

	def relatedType(TypeElement annotatedClass, GenTypeElement generatedClass, AnnotationMirror am, CharSequence annotationValueName,
		AnnotationMirror metaAnnotation,  Element ruleSourceElement) {

		//TODO: Reconsider which metaannotation to use here.
		val genClass = am.metaAnnotation(GenerateClass)
		val selector = am.valueOrMetaValue(annotationValueName, TypeMirror, metaAnnotation)
		relatedType(selector, annotatedClass, generatedClass, am, genClass, annotationValueName, ruleSourceElement)

	}

	def relatedTypes(TypeElement annotatedClass, GenTypeElement generatedClass, AnnotationMirror am, CharSequence annotationValueName,
		AnnotationMirror metaAnnotation, Element ruleSourceElement) {

		//TODO: Reconsider which metaannotation to use here.
		val genClass = am.metaAnnotation(GenerateClass)
		val selectors = am.valueOrMetaValue(annotationValueName, typeof(TypeMirror[]), metaAnnotation)
		selectors.map(s|relatedType(s, annotatedClass, generatedClass, am, genClass, annotationValueName, ruleSourceElement))

	}
	

	def TypeMirror relatedType(TypeMirror selector, TypeElement annotatedClass, GenTypeElement generatedClass, AnnotationMirror am, AnnotationMirror metaAnnotation,
		CharSequence annotationValueName, Element ruleSourceElement) {

		
		try {
			var resolved =  resolveClassSelector(selector, annotatedClass, generatedClass, am, metaAnnotation, annotationValueName, ruleSourceElement, true)
			
			var type = resolved.type
			
			if (type != null) {
				annotatedClass.registerTypeDependencyForAnnotatedClass(type)
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
						relatedType(annotatedClass, generatedClass, am, metaAnnotation, annotationValueName, ruleSourceElement)
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
			//Man kann das evtl umgehen, in dem in relatedTypes immer auf die annotierte Klasse verwiesen wird und nicht auf 
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
	def private resolveClassSelector(TypeMirror type, TypeElement annotatedClass, GenTypeElement generatedClass, AnnotationMirror am,
		AnnotationMirror metaAnnotation, CharSequence annotationValueName, Element ruleSourceElement, boolean throwTypeElementNotFound) {

		val resolvedSelector = new ResolvedClassSelector
		resolvedSelector.type = type

		if (type instanceof DeclaredType && !(type instanceof ErrorType)) {
			var TypeElement te = null
			try {
				//zusätzlicher Aufruf von getTypeElement wegen Bug in UnresolvedAnnotationBinding.getElementValuePairs(): Arrays mit UnresolvedTypeBindings werden nicht resolved.
				te = getTypeElement(type.asTypeElement.qualifiedName)
			} catch (TypeElementNotFoundException tenfe) {
				//No selector.
			}
			

			val classSelectorAnnotation = te?.annotationMirror(ClassSelector)
			
			
			if (classSelectorAnnotation != null) {
				resolvedSelector.kind = classSelectorAnnotation.value("kind", ClassSelectorKind);
				switch (resolvedSelector.kind) {
					case ClassSelectorKind.NONE:
						resolvedSelector.type = null
					case ClassSelectorKind.ANNOTATED_CLASS:
						resolvedSelector.type = annotatedClass?.asType
					case ClassSelectorKind.GENERATED_CLASS:
						resolvedSelector.type = generatedClass?.asType
					case ClassSelectorKind.SRC_ELEMENT_TYPE:
						resolvedSelector.type = ruleSourceElement.asType
					case ClassSelectorKind.SRC_ELEMENT_SINGLE_VALUE_TYPE:
						resolvedSelector.type = ruleSourceElement.asType.singleValueType
					case ClassSelectorKind.TYPE_MIRROR: {
						resolvedSelector.type = am.valueOrMetaValue(classSelectorAnnotation.getClassSelectorAvName(te),
							TypeMirror, metaAnnotation)
					}
					case ClassSelectorKind.INNER_CLASS_NAME: {
						resolvedSelector.innerClassName = am.valueOrMetaValue(annotatedClass,
							classSelectorAnnotation.getClassSelectorAvName(te), String, true, metaAnnotation)

						resolvedSelector.typeElement = findInnerClass(annotatedClass, resolvedSelector.innerClassName,
							throwTypeElementNotFound)
						resolvedSelector.type = resolvedSelector.typeElement?.asType	

					}
					case ClassSelectorKind.EXPR : {
						val expr = classSelectorAnnotation.value("expr", String);
						val lang = classSelectorAnnotation.value("lang", String);
						resolvedSelector.type = ExtensionRegistry.get(ELSupport).eval(annotatedClass, expr, lang, TypeMirror,
							'''Error when evaluating class selector expression '«expr»'  ''', null			
						)
					}
					default: {
						resolvedSelector.type = null
						messageCollector.reportError('''Selector «resolvedSelector.kind» not supported''',
							annotatedClass, am, annotationValueName)
					}
						
				}

			}

		}

		resolvedSelector
	}
	
	
	
	def private getClassSelectorAvName(AnnotationMirror classSelectorAnnotation, TypeElement te) {
		var avName = classSelectorAnnotation.value("avName", String);
		if(avName.nullOrEmpty){
			avName = te.simpleName.toString.toFirstLower
		}
		avName
	}
	
	

	/**
	 * If some generated code refers to a type element that is expected to be created by the user, this method can be used.
	 * It will provide the type element, if it exists. It will always provide an GenClass (TODO: What about interfaces?), that acts as a "proxy" for this type element.
	 * This proxy can be used by the code generator to state requirements for the type element, for example, which superclasses to extend. 
	 * 
	 */
	def relatedTypeElementWithProxy(TypeElement annotatedClass, AnnotationMirror am, CharSequence annotationValueName,
		AnnotationMirror metaAnnotation) {

		val genClass = am.metaAnnotation(GenerateClass)
		val selector = am.valueOrMetaValue(annotationValueName, TypeMirror, metaAnnotation)
		relatedTypeElementWithProxy(selector, annotatedClass, am, genClass, annotationValueName)

	}

	def private relatedTypeElementWithProxy(TypeMirror selector, TypeElement annotatedClass, AnnotationMirror am,
		AnnotationMirror metaAnnotation, CharSequence annotationValueName) {
		try {

			var resolved = resolveClassSelector(selector, annotatedClass, null, am, metaAnnotation, annotationValueName, annotatedClass, false)

			var tm = resolved.type
			var selectorKind = resolved.kind

			if (selectorKind == null || selectorKind == ClassSelectorKind.TYPE_MIRROR) {
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
							annotatedClass.package.qualifiedName
						} else {
							fqn.substring(0, fqn.length - simpleName.length - 1)
						}

					proxy = new GenClass(simpleName, packageName.toString)
				}
				proxy -> te

			} else if(selectorKind == ClassSelectorKind.INNER_CLASS_NAME){
				
					val proxy = new GenClass(resolved.innerClassName)
					proxy.setEnclosingElement(annotatedClass)
					proxy -> resolved.typeElement
				
			} else {
				throw new ProcessingException('''Selector «selectorKind» not supported''', annotatedClass, am,
							annotationValueName, null)
			}

		} catch (ProcessingException pe) {
			throw pe
		} catch (RuntimeException e) {
			throw new TypeElementNotFoundException(e);
		}

	}

	def findInnerClass(TypeElement annotatedClass, String innerClassName, boolean mustExist) {
		val fqn = '''«annotatedClass.qualifiedName».«innerClassName»'''
		val e = getTypeElement(fqn)

		if (mustExist && (e == null || !(e instanceof TypeElement))) {
			throw new TypeElementNotFoundException(fqn);
		}
		e
	}
}
