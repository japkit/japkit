package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenArrayType
import de.stefanocke.japkit.gen.GenClass
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelector
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelectorKind
import de.stefanocke.japkit.support.el.ELSupport
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import javax.lang.model.type.ArrayType
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.ErrorType
import javax.lang.model.type.TypeMirror
import javax.lang.model.element.Element

/**Resolves type references / class selectors from templates and annotations.*/
class TypeResolver {
	extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)
	extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	extension GenerateClassContext =  ExtensionRegistry.get(GenerateClassContext)
	extension ELSupport =  ExtensionRegistry.get(ELSupport)
	MessageCollector messageCollector = ExtensionRegistry.get(MessageCollector)
	
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

		val selector = currentTriggerAnnotation.valueOrMetaValue(typeAvName, TypeMirror, metaAnnotation)
		selector.resolveType

	}

	def List<? extends TypeMirror> resolveTypes(AnnotationMirror metaAnnotation, String typeArgsAvName)  {

		val selectors = currentTriggerAnnotation.valueOrMetaValue(typeArgsAvName, typeof(TypeMirror[]), metaAnnotation)
		selectors.map(s|s.resolveType)

	}

	def TypeMirror resolveType(TypeMirror selector) {
		if(selector instanceof ArrayType){
			new GenArrayType(selector.componentType.resolveType)
		} else {
			selector.resolveType_
		}
	}
	
	def TypeMirror resolveType_(TypeMirror selector) {

		
		try {
			var resolved =  resolveClassSelector(selector, true)
			
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
	def private ResolvedClassSelector resolveClassSelector(TypeMirror type, boolean throwTypeElementNotFound) {

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
						resolvedSelector.type = currentAnnotatedClass?.asType
					case ClassSelectorKind.GENERATED_CLASS:
						resolvedSelector.type = currentGeneratedClass?.asType
					case ClassSelectorKind.SRC_TYPE:
						resolvedSelector.type = currentSrc.srcType
					case ClassSelectorKind.SRC_SINGLE_VALUE_TYPE:
						resolvedSelector.type = currentSrc.srcType?.singleValueType
					case ClassSelectorKind.TYPE_MIRROR: {
						resolvedSelector.type = currentTriggerAnnotation.value(classSelectorAnnotation.getClassSelectorAvName(te),
							TypeMirror)
						if(resolvedSelector.type == null){
							resolvedSelector.type = evalClassSelectorExpr(classSelectorAnnotation, resolvedSelector, TypeMirror)
						}	
					}
					case ClassSelectorKind.INNER_CLASS_NAME:
					{	
						resolveInnerClassSelector(resolvedSelector, classSelectorAnnotation, te, throwTypeElementNotFound)	
					}
					
					case ClassSelectorKind.EXPR : {
						resolvedSelector.type = evalClassSelectorExpr(classSelectorAnnotation, resolvedSelector, TypeMirror)
					}
					default: {
						resolvedSelector.type = null
						messageCollector.reportError('''Selector «resolvedSelector.kind» not supported''',
							currentAnnotatedClass, currentTriggerAnnotation, null)
					}
						
				}

			}

		}

		resolvedSelector
	}
	
	
	private def getEnclosingTypeElement(AnnotationMirror classSelectorAnnotation) {
		val enclosing = classSelectorAnnotation.value("enclosing", TypeMirror)?.resolveType?.asTypeElement
		enclosing
	}
	
	private def resolveInnerClassSelector(ResolvedClassSelector resolvedSelector, AnnotationMirror classSelectorAnnotation, TypeElement te, boolean throwTypeElementNotFound) {
		resolvedSelector.enclosingTypeElement = getEnclosingTypeElement(classSelectorAnnotation)
		if(resolvedSelector.enclosingTypeElement==null){
			messageCollector.reportError('''Could not determine enclosing type element for inner class.''',
							currentAnnotatedClass, currentTriggerAnnotation, null)
			return
		}
		resolvedSelector.innerClassName = evalClassSelectorExpr(classSelectorAnnotation, resolvedSelector, String)
		
		//simple name of the type template as fallback
		if(resolvedSelector.innerClassName==null){
			resolvedSelector.innerClassName=te.simpleName.toString
		}
		
		resolvedSelector.typeElement = findInnerClass(resolvedSelector.enclosingTypeElement , resolvedSelector.innerClassName, throwTypeElementNotFound)
		resolvedSelector.type = resolvedSelector.typeElement?.asType
	}
	
	private def <T> T evalClassSelectorExpr(AnnotationMirror classSelectorAnnotation, ResolvedClassSelector resolvedSelector, Class<T> targetType) {
		val expr = classSelectorAnnotation.value("expr", String);
		if(expr.nullOrEmpty) return null
		val lang = classSelectorAnnotation.value("lang", String);
		ExtensionRegistry.get(ELSupport).eval(expr, lang, targetType,
			'''Error when evaluating class selector expression '«expr»'  ''', null			
		)
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
	def relatedTypeElementWithProxy(AnnotationMirror metaAnnotation, CharSequence annotationValueName) {

		val selector = currentTriggerAnnotation.valueOrMetaValue(annotationValueName, TypeMirror, metaAnnotation)
		relatedTypeElementWithProxy(selector)

	}

	def private relatedTypeElementWithProxy(TypeMirror selector) {
		try {

			var resolved = resolveClassSelector(selector, false)

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

	def findInnerClass(TypeElement enclosingClass, String innerClassName, boolean mustExist) {
		
		val e = enclosingClass.declaredTypes.findFirst[simpleName.contentEquals(innerClassName)]

		if (mustExist && e == null) {
			throw new TypeElementNotFoundException('''«enclosingClass».«innerClassName»''');
		}
		e
	}
}
