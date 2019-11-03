package de.japkit.services

import de.japkit.annotations.Order
import de.japkit.annotations.ParamNames
import de.japkit.annotations.RuntimeMetadata
import de.japkit.metaannotations.SingleValue
import de.japkit.model.AnnotationAndParent
import de.japkit.model.AnnotationWithDefaultAnnotation
import de.japkit.model.AnnotationWrapper
import de.japkit.model.GenAnnotationMirror
import de.japkit.model.GenAnnotationValue
import de.japkit.model.GenElement
import de.japkit.model.GenName
import de.japkit.model.GenTypeElement
import de.japkit.model.ParameterWrapper
import de.japkit.model.Path
import de.japkit.model.Property
import de.japkit.util.MoreCollectionExtensions
import java.io.Writer
import java.lang.annotation.Annotation
import java.lang.reflect.Array
import java.lang.reflect.Method
import java.util.Collection
import java.util.Collections
import java.util.HashMap
import java.util.IdentityHashMap
import java.util.List
import java.util.Map
import java.util.regex.Pattern
import java.util.regex.PatternSyntaxException
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.AnnotationValue
import javax.lang.model.element.Element
import javax.lang.model.element.ElementKind
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.Modifier
import javax.lang.model.element.PackageElement
import javax.lang.model.element.QualifiedNameable
import javax.lang.model.element.TypeElement
import javax.lang.model.element.VariableElement
import javax.lang.model.type.ArrayType
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.PrimitiveType
import javax.lang.model.type.TypeKind
import javax.lang.model.type.TypeMirror
import javax.lang.model.util.Elements

import static javax.lang.model.util.ElementFilter.*

class ElementsExtensions {
	val transient extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)
	val transient extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	val MessageCollector mc = ExtensionRegistry.get(MessageCollector)
	val Elements elementUtils = ExtensionRegistry.get(Elements)
	
	val TypeElementFromCompilerCache typeElementCache = ExtensionRegistry.get(TypeElementFromCompilerCache)

	def hasType(Element e, TypeMirror type) {
		e.asType == type;
	}

	//TODO: Naming.
	def dispatch srcType(VariableElement e) {
		e.asType
	}

	def dispatch srcType(ExecutableElement e) {

		//Für Methoden schauen wir uns den return-type an...
		e.returnType
	}

	def dispatch srcType(Element e) {
		e.asType
	}
	
	def dispatch srcType(TypeMirror t) {
		t
	}
	
	def dispatch srcType(Object o) {
		mc.reportRuleError('''Cannot determine type for source «o», since it is neither a type nor an element.''')
		null as TypeMirror
	}

	def declaredFields(TypeElement type) {
		fieldsIn(type.enclosedElements).sortBy[ordinalNumber]
	}

	def declaredMethods(TypeElement type) {
		methodsIn(type.enclosedElements).sortBy[ordinalNumber]
	}

	def declaredConstructors(TypeElement type) {
		constructorsIn(type.enclosedElements).sortBy[ordinalNumber]
	}

	def declaredTypes(TypeElement type) {
		typesIn(type.enclosedElements).sortBy[ordinalNumber]
	}
	
	/**
	 * If there is any element with an Order annotation, sort by order annotations. Otherwise use "natural" order.
	 */
	def enclosedElementsOrdered(TypeElement type) {
		val elements = type.enclosedElements

		if (elements.exists[annotationMirror(ORDER_ANNOTATION_NAME) !== null]) {
			elements.sortBy[ordinalNumber]
		} else {
			val orderFromRuntimeMetadata = getOrderFromRuntimeMetadata(type);

			if (orderFromRuntimeMetadata !== null) {
				elements.sortBy(orderFromRuntimeMetadata)
			} else
				elements
		}
	}

	public val ORDER_ANNOTATION_NAME = Order.name
	
	public val PARAM_NAMES_ANNOTATION_NAME = ParamNames.name

	def Integer getOrdinalNumber(Element e) {
		val am = e.annotationMirror(ORDER_ANNOTATION_NAME)
		if (am === null) {
			Integer.MAX_VALUE //elements without order go to the end
		} else {
			am.value("value", Integer) ?: Integer.MAX_VALUE 
		}
	}

	/**Warning: Does not work for Gen-Elements! */
	def allFields(TypeElement type) {
		fieldsIn(type.allMembers)
	}

	/**Warning: Does not work for Gen-Elements! */
	def allMethods(TypeElement type) {
		if (type instanceof GenTypeElement) {
			type.allMethods
		} else {
			methodsIn(type.allMembers)
		}
	}

	def notDeclaredBy(Element e, CharSequence name) {
		notDeclaredBy(e, elementUtils.getTypeElement(name))
	}

	def notDeclaredBy(Element e, TypeElement type) {
		e.enclosingElement != type
	}

	/**
	 * Finds all methods up to (but except from) a given superclass.
	 * For overridden methods, only the most specific one is returned.
	 * <p>
	 * TODO: Check, if private methods of superclass are included and fix it.
	 */
	def allMethods(TypeElement type, String stopSuperclass) {

		type.collectInTypeAndSuperclasses(stopSuperclass, [m1, m2|m1.overrides(m2)]) [
			declaredMethods.filter [ m |
				m.enclosingElement == type || m.public || m.protected || (m.defaultAccess && samePackage(m, type))
			].toList
		]
	}

	/**
	 * Unfortunately, Eclipse does not always provide parameter names during incremental build, since types
	 * that are not root elements of current round are provided as binary type bindings. We fix the parameter names here,
	 * if the method has a ParamNames annotation 
	 * We also remember the ExecutableElement, since for constructor parameters this is null in Eclipse (at least up to Neon).
	 */
	def List<? extends VariableElement> parametersWithSrcNames(ExecutableElement e) {
		val am = e.annotationMirror(ParamNames)
		val params = e.parameters
		if (am !== null) {
			val namesAv = am.value("value", typeof(String[]))
			val names = if (namesAv.size == 1) {

					//Alternative representation: All names as one comma separated string.
					namesAv.get(0).split(",").map[trim]
				} else
					namesAv.toList

			if (params.size != names.size) {
				mc.reportRuleError("Then number of parameter names must match the number of parameters: "+e)
				
				//TODO?
				//mc.reportError("Then number of parameter names must match the number of parameters", e, am, "value")
				params
			} else {
				wrapParams(e, names)
			}
		} else {
			val names = getParamNamesFromRuntimeMetadata(e)
			if(!names.nullOrEmpty){
				wrapParams(e, names)
			} else {
				params
			}
			
		}
	}
	
	private def List<ParameterWrapper> wrapParams(ExecutableElement e, List<String> names) {
		val params = e.parameters;
		
		(0 ..< params.size).map[i|new ParameterWrapper(e, i, params.get(i), new GenName(names.get(i)))].toList
	}

	/**We cannot use the ElementUtils.override, since it does not work for our GenElements... */
	def boolean overrides(ExecutableElement m1, ExecutableElement m2) {

		isVisibleFromSubclass(m2, m1) && m1.isSubSignature(m2)

	}

	def boolean isVisibleFromSubclass(Element e, Element subclassOrMemberOfIt) {
		e.public || e.protected || (e.defaultAccess && samePackage(subclassOrMemberOfIt, e))
	}

	def boolean isSubSignature(ExecutableElement m1, ExecutableElement m2) {
		val result = m1.simpleName.contentEquals(m2.simpleName) && m1.parameters.size == m2.parameters.size && (0 ..<
			m1.parameters.length).forall [ i |
			val TypeMirror t1 = m1.parameters.get(i).asType
			val TypeMirror t2 = m2.parameters.get(i).asType
			t1.isSameType(t2) || t1.isSameType(t2?.erasure)
		]

		result
	}

	def boolean isOverrideEquivalent(ExecutableElement m1, ExecutableElement m2) {
		m1.isSubSignature(m2) || m2.isSubSignature(m1)
	}

	def typeElements(Iterable<? extends Element> elements) {
		elements.filter[it instanceof TypeElement].map[it as TypeElement]
	}

	def <T> T findFirstInTypeAndSuperclasses(TypeElement typeElement, String stopSuperclass, (TypeElement)=>T query) {
		var v = query.apply(typeElement)
		if (v === null) {
			val sup = typeElement.superclass
			if (sup.kind != TypeKind.NONE && stopSuperclass != sup.asTypeElement.qualifiedName.toString) {
				v = sup.asTypeElement.findFirstInTypeAndSuperclasses(stopSuperclass, query)
			}
		}
		v
	}

	def <T> List<T> collectInTypeAndSuperclasses(TypeElement typeElement, String stopSuperclass,
		(T, T)=>boolean isDuplicate, (TypeElement)=>List<T> query) {
		val list = newArrayList()
		list.addAll(query.apply(typeElement))
		val sup = typeElement.superclass
		if (sup.kind != TypeKind.NONE && sup.asTypeElement.qualifiedName.toString != stopSuperclass) {
			val supList = sup.asTypeElement.collectInTypeAndSuperclasses(stopSuperclass, isDuplicate, query)
			val supListWithoutDuplicates = supList.filter[e|list.forall[!isDuplicate.apply(it, e)]]
			list.addAll(supListWithoutDuplicates)
		}
		list
	}

	/**
	 * Gets a certain annotation of an element. Inheritance is not considered.
	 * 
	 * TODO: Java 8?
	 * 
	 * @param type the annotated element
	 * @param annotationFqn the qualified name of the annotation class
	 */
	def AnnotationMirror annotationMirror(Element annotatedElement, CharSequence annotationFqn) {
		val am = annotatedElement.annotationMirrors.findFirst[hasFqn(annotationFqn)]
		if(am === null) null else new AnnotationAndParent(am, null, null, annotatedElement)
	}

	/**
	 * Gets a certain annotation of an element. Inheritance is not considered
	 * 
	 * TODO: Java 8?
	 * 
	 * @param type the annotated element
	 * @param annotationClass the annotation class
	 */
	def AnnotationMirror annotationMirror(Element annotatedElement, Class<? extends Annotation> annotationClass) {
		annotatedElement.annotationMirror(annotationClass.canonicalName)
	}

	/**
	 * Gets a certain annotation of an element. Supports multiple occurences by using the inner List class convention. 
	 * 
	 * TODO: Java 8?
	 */
	def List<AnnotationMirror> annotationMirrors(Element annotatedElement, Class<? extends Annotation> annotationClass) {
		annotationMirrors(annotatedElement, annotationClass.canonicalName)
	}

	/**
	 * Gets a certain annotation of an element. Supports multiple occurences by using the inner List class convention. 
	 * 
	 * TODO: Java 8?
	 */
	def List<AnnotationMirror> annotationMirrors(Element annotatedElement, CharSequence annotationFqn) {
		val listAnnotationType = findTypeElement(annotationFqn.toString).declaredTypes.findFirst[
			simpleName.contentEquals("List")]
		if (listAnnotationType !== null) {
			val listAnnotation = annotatedElement.annotationMirror(listAnnotationType.qualifiedName)
			if (listAnnotation !== null) {
				return listAnnotation.value("value", typeof(AnnotationMirror[]))
			}

		}
		val singleAnnotation = annotatedElement.annotationMirror(annotationFqn)
		return if(singleAnnotation === null) emptyList else Collections.singletonList(singleAnnotation)
	}

	def boolean hasMetaAnnotation(AnnotationMirror am, CharSequence metaAnnotationFqn) {	
		am.metaAnnotations.exists[hasFqn(metaAnnotationFqn)]			
	}

	def metaAnnotations(AnnotationMirror annotationMirror) {
		annotationMirror.annotationAsTypeElement.annotationMirrors		
	}

	//TODO: Java 8
	def AnnotationMirror metaAnnotation(AnnotationMirror annotationMirror, CharSequence metaAnnotationFqn) {
		annotationMirror.annotationAsTypeElement.annotationMirror(metaAnnotationFqn)			
	}

	//Annotation.List support 
	//TODO: Java 8
	def List<AnnotationMirror> metaAnnotations(AnnotationMirror annotationMirror, CharSequence metaAnnotationFqn) {
		annotationMirror.annotationAsTypeElement.annotationMirrors(metaAnnotationFqn)
	}

	def AnnotationMirror metaAnnotation(AnnotationMirror annotationMirror, Class<? extends Annotation> annotationClass) {
		metaAnnotation(annotationMirror, annotationClass.name)
	}

	//Annotation.List support 
	//TODO: Java 8
	def List<AnnotationMirror> metaAnnotations(AnnotationMirror annotationMirror,
		Class<? extends Annotation> annotationClass) {
		metaAnnotations(annotationMirror, annotationClass.name)
	}

	def String fqn(AnnotationMirror annotationMirror) {
		annotationMirror.annotationType.qualifiedName
	}

	def TypeElement annotationAsTypeElement(AnnotationMirror annotationMirror) {
		annotationMirror.annotationType.asTypeElement
	}

	def boolean hasFqn(AnnotationMirror annotationMirror, CharSequence annotationFqn) {
		annotationMirror.fqn.equals(annotationFqn.toString)
	}

	def boolean hasFqn(QualifiedNameable element, CharSequence fqn) {
		element.qualifiedName.contentEquals(fqn)
	}

	def boolean hasSameName(Element e1, Element e2) {
		e1.simpleName.contentEquals(e2.simpleName)

	}

	def clearCaches() {
		annotationValuesCache.clear
		annotationValueMethodsCache.clear
		runtimeMetadataByFqn.clear
		commentsFromRuntimeMetadata.clear
		orderFromRuntimeMetadata.clear
		paramNamesFromRuntimeMetadata.clear
	}

	//FQN of AnnotationTypeElement to (name of annotation value to mehtod)
	val annotationValueMethodsCache = new HashMap<String, Map<String, ExecutableElement>>
	
	def ExecutableElement getAVMethod(AnnotationMirror annotationMirror, String name){
		val annotationTypeElement = annotationMirror.annotationType.asElement as TypeElement
		val annotationTypeElementFqn = (annotationTypeElement).qualifiedName.toString;
		
		annotationValueMethodsCache.get(annotationTypeElementFqn)?.get(name) ?: {
		
			val map = newHashMap
			
			annotationTypeElement.enclosedElements.filter[kind==ElementKind.METHOD]
				.map[it as ExecutableElement].forEach[e | map.put(e.simpleName.toString, e)]
			
			annotationValueMethodsCache.put(annotationTypeElementFqn, map)
			
			map.get(name)
		
		}
		
	}


	val annotationValuesCache = new IdentityHashMap<AnnotationMirror, Map<String, AnnotationValue>>

	def private AnnotationValue value(AnnotationMirror annotationMirror, CharSequence name) {
		loadAnnotationValues(annotationMirror).get(name.toString)
	}

	def private dispatch Map<String, AnnotationValue> loadAnnotationValues(AnnotationWrapper wrapper) {
		loadAnnotationValues(wrapper.annotation)
	}

	//Gets the annotation vlaues from cache and loads them if not yet in cache.
	def private dispatch Map<String, AnnotationValue> loadAnnotationValues(AnnotationMirror annotationMirror) {
		var valuesMap = annotationValuesCache.get(annotationMirror)

		if (valuesMap === null) {
			valuesMap = loadAnnotationValuesCacheMiss(annotationMirror)
		}
		valuesMap
	}
	
	def private Map<String, AnnotationValue>loadAnnotationValuesCacheMiss(AnnotationMirror annotationMirror) {
		val map = newHashMap
		annotationMirror.elementValuesWithDefaults.forEach[k, v|
			val v2 = if((v.value instanceof List<?>) && k.annotationMirror(SingleValue) !== null){
				val list = (v.value as List<AnnotationValue>)
//Does not work, since currentAnnotatedClass is not always available.
//				if(list.size>1){
//					ExtensionRegistry.get(MessageCollector).reportError("At most one value is allowed here.", null, annotationMirror, k.simpleName)
//				}
				list.head
			} else {
				v
			}
			map.put(k.simpleName.toString, v2)
		]
		annotationValuesCache.put(annotationMirror, map)
		map
	}

	def getValueWithErrorHandling(AnnotationValue av){
		
		if(av?.class.canonicalName.equals("com.sun.tools.javac.code.Attribute.UnresolvedClass")){
			//Javac >= 8
			val errorType = try { 
				(av.class.getField("classType").get(av) as TypeMirror)
			} catch (Exception e){
				//We cannot determine the error type. Maybe it is Java 7 or less (where UnresolvedClass did not exist yet) or the implementation has changed...
				//Throw a generic TENFE.
				throw new TypeElementNotFoundException(e);
			}
			
			return errorType
		}
		
		val v = av?.value
		
		//TODO: This is far from being reliable. Replace by AST parsing.
		//Already now we have errors, since <error> is not only used for missing types, but also for other kinds of erroneous AVs.
		if (v == "<error>") {
			throw new TypeElementNotFoundException(TypeElementNotFoundException.UNKNOWN_TYPE, "Error in annotation value: "+av+". Could not determine the missing type.");
		}
		
		if(v instanceof DeclaredType && (v as DeclaredType).isDeclared && v.class.canonicalName.startsWith("org.eclipse.jdt")){
			try{
				//In Eclipse: zusätzlicher Aufruf von getTypeElement wegen Bug in UnresolvedAnnotationBinding.getElementValuePairs(): 
				//Arrays mit UnresolvedTypeBindings werden nicht resolved.	
				//https://bugs.eclipse.org/bugs/show_bug.cgi?id=498022	
				if(v.class.eclipseGetBindingMethod  !== null && v.class.eclipseGetBindingMethod.invoke(v).class.canonicalName.contains("Unresolved")){
					val te =  (v as DeclaredType).asTypeElement			
					val char dollar = '$'  //UnresolvedTypeBindings for inner classes have $ in their FQNs.
					val teFqn = te.qualifiedName.toString.replace(dollar ,'.')
					val teResolved = getTypeElement(teFqn)
					return teResolved.asType		
				}			
			
			} catch (Exception e){
				//Ignore reflection exceptions. 
				//TODO: Logging
			}
		}
		
		v
	}
	
	static Map<Class<?>, Method> bindingMethod = newHashMap;
	
	def Method eclipseGetBindingMethod(Class<?> clazz) {
		bindingMethod.get(clazz) ?: { 
			val m = searchEclipseBindingMethod(clazz); 
			bindingMethod.put(clazz, m);
			m
		}
		
	}
	
	protected def Method searchEclipseBindingMethod(Class<?> clazz) {
		try{
			val m = clazz.getDeclaredMethod("binding")
			m.accessible = true
			m
		} catch (Exception e){
			return clazz.superclass?.eclipseGetBindingMethod
		}
	}
	
	def annotationValueNames(AnnotationMirror annotationMirror){
		annotationMirror.annotationAsTypeElement.declaredMethods.map[simpleName].toSet
	}


	/**
	 * Gets an annotation value and casts it to a given type. 
	 */
	def <T> T value(AnnotationMirror annotationMirror, CharSequence name, Class<T> avType) {
		try {
			val av = annotationMirror.value(name)
	
			val value = av?.valueWithErrorHandling
			
			if (isNullOrEmptyAV(value)) {
				return null
			}	
			av.mapAs(av.valueWithErrorHandling, annotationMirror, name, null, avType)		
		} catch (TypeElementNotFoundException tenfe) {
			throw tenfe
		} catch (AnnotationException ae) {
			//We already have context. No need to wrap again.
			throw ae
		} catch (Exception e) {
			//Rethrow as AnnotationException here top provide some context.
			throw new AnnotationException('''Error when getting annotation value «name»: «e.message»''', annotationMirror, name.toString, e);
		}
	}
	
	def isNullOrEmptyAV(Object value) {
		value === null || value.isEmptyAV
	}
	
	def dispatch boolean isEmptyAV(String s) {
		s.empty
	}
	
//	def dispatch boolean isEmptyAV(Iterable<?> i) {
//		i.empty
//	}
	
	def dispatch boolean isEmptyAV(Object o) {
		//TODO: Mehr support für "FAKE null values"? Oder doch besser mittels leerer arrays und @SingleValue ?
		false  
	}

	def isVoidValue(Object value, Class<?> clazz) {
		if (!clazz.isInstance(value)) {
			return false //Will be validated again when casting to target type.
		}
		switch (clazz) {
			case String: (value as String).nullOrEmpty
			default: false
		}
	}

	private def <T> T mapAs(AnnotationValue av, Object value, AnnotationMirror annotationMirror,
		CharSequence avName, Integer index, Class<T> avType) {
		
		if(value === null) {return null;}

		//Arrays can be converted to single values to support optionality. The array may contain zero or one element then.
		if (!avType.array && value instanceof Iterable<?>) {	
			return av.mapAs(singleAV(value as Iterable<AnnotationValue>), annotationMirror, avName, 0, avType)
		}
		

		if (avType == TypeElement) {
			val tm = av.cast(value, TypeMirror)
			tm?.asTypeElement as T
		} else if (avType == Pattern) {
			val patternString = av.cast(value, String)
			if (patternString.nullOrEmpty) {
				return null
			}
			try {
				val pattern = Pattern.compile(patternString)
				avType.cast(pattern) //"as T" does not work here. XTend bug?
			} catch (PatternSyntaxException pse) {
				throw new AnnotationException('''Invalid regular expression: «pse.message»''', annotationMirror, avName.toString)
			}
			
		} else if (avType.enum) {
			val ve = av.cast(value, VariableElement)
						
			Enum.valueOf(avType as Class<?> as Class<? extends Enum>, ve.simpleName.toString) as T

		} else if (avType.array) {
			val arr = Array.newInstance(avType.getComponentType(), (value as List<AnnotationValue>).size)
			
			(value as List<AnnotationValue>).forEach[avInList , i|
				Array.set(arr, i, avInList.mapAs(avInList.valueWithErrorHandling, annotationMirror, avName, i, avType.getComponentType()))
			]
			arr as T
		} else if(avType==AnnotationMirror){
			val avAsAnnotation = av.cast(value, AnnotationMirror)			
			createAnnotationAndParent(annotationMirror, avAsAnnotation, avName, index) as T			
		} else {

			av.cast(value, avType)
		}
	}
	
	
	
	private def dispatch AnnotationMirror createAnnotationAndParent(AnnotationAndParent annotationMirror, AnnotationMirror avAsAnnotation, CharSequence avName, Integer index) {
		new AnnotationAndParent(avAsAnnotation, new Path.Segment(avName.toString, index), annotationMirror, null)
	}
	
	private def dispatch AnnotationMirror createAnnotationAndParent(AnnotationWithDefaultAnnotation annotationMirror, AnnotationMirror avAsAnnotation, CharSequence avName, Integer index) {
		createAnnotationAndParent(annotationMirror.annotation, avAsAnnotation, avName, index)
	}
	
	private def dispatch AnnotationMirror createAnnotationAndParent(AnnotationMirror annotationMirror, AnnotationMirror avAsAnnotation, CharSequence avName, Integer index) {
		avAsAnnotation
	}

	def private singleAV(Iterable<AnnotationValue> values) {		
		(MoreCollectionExtensions.singleValue(values))?.valueWithErrorHandling
	}
	

	private def <T> T cast(AnnotationValue av, Object value, Class<T> avType) {

		var Class<?> targetType = avType
		if (avType.primitive) {
			targetType = avType.boxedType
		}
		targetType.cast(value) as T	
	}		

	def getPrefixedAvName(AnnotationMirror metaAnnotation, CharSequence name) {
		if (metaAnnotation === null) {
			return name
		}
		val prefix = metaAnnotation.value("_prefix", String)
		val prefixedAvName = if(prefix.nullOrEmpty) name else prefix + name.toString.toFirstUpper
		prefixedAvName
	}


	def annotationsByName(Element e, String packageForShortNames) {
		[ String fqnOrShortname |
			val am = if (fqnOrShortname.contains('.') || packageForShortNames.nullOrEmpty) {
					e.annotationMirror(fqnOrShortname)
				} else {
					e.annotationMirror('''«packageForShortNames».«fqnOrShortname»''')
				}
			am?.annotationValuesByNameUnwrapped
		]
	}

	def annotationValuesByNameUnwrappedAsMap(AnnotationMirror am) {
		loadAnnotationValues(am).mapValues[unwrapAnnotationValue]
	}
	
	def annotationValuesByNameUnwrapped(AnnotationMirror am) {
		[CharSequence avName|loadAnnotationValues(am).get(avName.toString)?.unwrapAnnotationValue]
	}
	
	def private dispatch Object unwrapAnnotationValue(AnnotationValue av) {
		av?.valueWithErrorHandling.unwrapAnnotationValue
	}

	def private dispatch Object unwrapAnnotationValue(List<? extends AnnotationValue> values) {
		values.map[
			it.valueWithErrorHandling
		]
	}

	def private dispatch Object unwrapAnnotationValue(Object value) {
		value
	}
	
	def private dispatch Object unwrapAnnotationValue(Void value) {
		null
	}

	//Maps from annotation value type mirror to the expected class of the value
	def dispatch Class<?> toAnnotationValueClass(PrimitiveType type) {
		switch (type.kind) {
			case TypeKind.BOOLEAN: Boolean
			case TypeKind.BYTE: Byte
			case TypeKind.CHAR: Character
			case TypeKind.DOUBLE: Double
			case TypeKind.FLOAT: Float
			case TypeKind.INT: Integer
			case TypeKind.LONG: Long
			case TypeKind.SHORT: Short
			default: throw new IllegalArgumentException("Unsupported primitive type kind " + type.kind)
		}
	}

	def dispatch Class<?> toAnnotationValueClass(ArrayType type) {
		List
	}

	def dispatch Class<?> toAnnotationValueClass(DeclaredType type) {
		val e = type.asTypeElement

		switch (e) {
			case e.hasFqn("java.lang.String"): String
			case e.hasFqn("java.lang.Class"): TypeMirror
			case e.kind == ElementKind.ANNOTATION_TYPE: AnnotationMirror
			case e.kind == ElementKind.ENUM: VariableElement
		}
	}

	def dispatch toAnnotationValue(PrimitiveType type, String s) {

		switch (type.kind) {
			case TypeKind.BOOLEAN: Boolean.valueOf(s)
			case TypeKind.BYTE: Byte.valueOf(s)
			case TypeKind.CHAR: Character.valueOf(s.charAt(0))
			case TypeKind.DOUBLE: Double.valueOf(s)
			case TypeKind.FLOAT: Float.valueOf(s)
			case TypeKind.INT: Integer.valueOf(s)
			case TypeKind.LONG: Long.valueOf(s)
			case TypeKind.SHORT: Short.valueOf(s)
			default: throw unsupportedAVType(type, s)
		}

	}
	
	def coerceAnnotationValue(Object value, TypeMirror avType) {
		if (avType.kind === TypeKind.ARRAY) {

			val compType = (avType as ArrayType).componentType

			if (value instanceof Iterable<?>) {
				value.map [
					new GenAnnotationValue(coerceSingleValue(it, compType))
				].toList

			} else if(value === null){
				emptyList
			} else {
				newArrayList(new GenAnnotationValue(coerceSingleValue(value, compType)))
			}

		} else {
			coerceSingleValue(value, avType)
		}
	}
	
	//For example, in annotation templates, array are used to make single-valued AVs optional.
	//So, we tolerate Iterables when setting single valued AVs
	def dispatch Object coerceSingleValue(Iterable<?> value, TypeMirror avType) {
		if(value.size>1) {
			throw new IllegalArgumentException(''''«value»' is not a valid value or element value for type «avType», since it contains multiple elements''');
		}
		coerceSingleValue(value.head, avType) 
	}

	def dispatch Object coerceSingleValue(Object value, TypeMirror avType) {
		val v = toAnnotationValue(avType, value)
		
		if (!avType.toAnnotationValueClass.isInstance(v)) {
			throw new IllegalArgumentException(''''«v»' of type «v?.class» is not a valid value or element value for type «avType»''');
		}
		v
	}
	
	def dispatch Object coerceSingleValue(Void value, TypeMirror avType) {
		//This is no valid annotation value but it just says not to set the AV
		return null;
	}

	def dispatch toAnnotationValue(DeclaredType avType, Object o) {
		val e = avType.asTypeElement

		if(e.hasFqn("java.lang.String")){
			return o.toString
		}
		
		if(!(o instanceof CharSequence)){
			return o
		}
		
		val s = o.toString
		
		switch (e) {
			case e.hasFqn("java.lang.String"):
				s?.toString
			case e.hasFqn("java.lang.Class"): {

				//FQN to type mirror
				val typeMirror = getTypeElement(s)?.asType
				if (typeMirror === null) {
					throw new IllegalArgumentException('''Class «s» could not be found.''');
				}
				typeMirror
			}
			case e.kind == ElementKind.ANNOTATION_TYPE: {
				throw unsupportedAVType(avType, s)
			}
			case e.kind == ElementKind.ENUM: {
				val enumConst = avType.asTypeElement.declaredFields.findFirst[simpleName.contentEquals(s)]
				if (enumConst === null) {
					throw new IllegalArgumentException('''«s» is not a valid enum constant for enum type «avType»''');
				}
				enumConst
			}
			default:
				throw unsupportedAVType(avType, s)
		}

	}
	
	def dispatch toAnnotationValue(PrimitiveType type, Object o) {
		o
	}

	def dispatch toAnnotationValue(TypeMirror type, Object o) {
		throw unsupportedAVType(type, o)
	}

	def static unsupportedAVType(TypeMirror type, Object o) {
		new IllegalArgumentException('''An annotation value of type «type» cannot be created from value "«o»" of type «o?.class»''')
	}

	def isAbstract(Element e) {
		e.modifiers.contains(Modifier.ABSTRACT)
	}

	def isAbstractOrInInterface(Element e) {
		e.modifiers.contains(Modifier.ABSTRACT) || e.enclosingElement.kind == ElementKind.INTERFACE
	}

	def isStatic(Element e) {
		e.modifiers.contains(Modifier.STATIC)
	}

	def isPublic(Element e) {
		e.modifiers.contains(Modifier.PUBLIC)
	}

	def isProtected(Element e) {
		e.modifiers.contains(Modifier.PROTECTED)
	}

	def isPrivate(Element e) {
		e.modifiers.contains(Modifier.PRIVATE)
	}

	public static val VISIBILITY_MODIFIERS = #{Modifier.PRIVATE, Modifier.PUBLIC, Modifier.PROTECTED}

	def getVisibility(Element e) {
		e.modifiers.filter[VISIBILITY_MODIFIERS.contains(it)].head
	}

	def isDefaultAccess(Element e) {
		!e.private && !e.protected && !e.private
	}

	def dispatch PackageElement getPackage(Element e) {
		e.enclosingElement.getPackage
	}

	def dispatch PackageElement getPackage(PackageElement e) {
		e
	}

	def dispatch PackageElement getPackage(Void e) {
		null
	}

	def boolean samePackage(Element e1, Element e2) {
		e1.getPackage?.qualifiedName?.toString == e2.getPackage?.qualifiedName?.toString
	}

	def private dispatch String docComment(GenElement e, boolean useRuntimeMetadata) {
		e.comment?.toString?.trim
	}
	
	def private dispatch String docComment(Property p, boolean useRuntimeMetadata) {
		p.fieldOrGetter?.docComment(useRuntimeMetadata)  //TODO: If getter, extract @return comment here?
	}

	def private dispatch String docComment(Element e, boolean useRuntimeMetadata) {
		val result = elementUtils.getDocComment(e)?.trim
		if(result.nullOrEmpty && useRuntimeMetadata) getCommentFromRuntimeMetadata(e) else result
	}
		
	def getDocComment(Element e) {
		docComment(e, false)
	}
	
	def getDocCommentUsingRuntimeMetadata(Element e) {
		docComment(e, true)
	}
	
	

	Map<String, String> commentsFromRuntimeMetadata = newHashMap()
	Map<String, List<String>> paramNamesFromRuntimeMetadata = newHashMap()
	Map<String, Integer> orderFromRuntimeMetadata = newHashMap()
	
	//FQNs RuntimeMetadata. Used to detect if it has been re-generated and thus must be reloaded
	Map<String, TypeElement> runtimeMetadataByFqn = new HashMap
	
	def String getCommentFromRuntimeMetadata(Element element) {
		loadRuntimeMetadata(element)
		commentsFromRuntimeMetadata.get(uniqueNameWithinTopLevelEnclosingTypeElement(element))
	}

	
	def List<String> getParamNamesFromRuntimeMetadata(Element element) {
		loadRuntimeMetadata(element)
		paramNamesFromRuntimeMetadata.get(uniqueNameWithinTopLevelEnclosingTypeElement(element))
	}
	
	//Order within TopLevelEnclosingTypeElement
	def (Element)=> Integer getOrderFromRuntimeMetadata(Element someParent) {
		if(!loadRuntimeMetadata(someParent)) return null;
		[element | orderFromRuntimeMetadata.get(uniqueNameWithinTopLevelEnclosingTypeElement(element)) ?: 0]
	}
	
	
	def boolean loadRuntimeMetadata(Element element) {
		val topLevelEnclosingTypeElement = element.getTopLevelEnclosingTypeElement
		val typeElementFqn = topLevelEnclosingTypeElement.qualifiedName.toString
		if (topLevelEnclosingTypeElement.annotationMirror(RuntimeMetadata) === null) {
			//shortcut: If there is no according trigger annoatation there won't be runtime metadata at all
			//TODO: Exception, since we know at this point that we NEED comments or param names?
			return false
		}
		
		val runtimemetadataFqn = typeElementFqn + "_RuntimeMetadata"
		var runtimeMetadataTypeElement = findTypeElement(runtimemetadataFqn) //TODO: Constant
		if (runtimeMetadataTypeElement !== null) {
			if(runtimeMetadataTypeElement != runtimeMetadataByFqn.get(runtimemetadataFqn)){
				loadCommentsAndParamNames(runtimeMetadataTypeElement)
				runtimeMetadataByFqn.put(runtimemetadataFqn, runtimeMetadataTypeElement)	
			}
			registerTypeDependencyForCurrentAnnotatedClass(runtimeMetadataTypeElement.asType)
			return true;
		} else {
			// TODO: Exception immer werfen ist zu hart hier. Ggf nur dann werfen, wenn erkennbar ist, dass es sich um ein "BinaryTypeBinding" handelt.
			//throw new TypeElementNotFoundException(runtimemetadataFqn, "Access to parameter names or comments required.")
			return false;
		}		
			
	}
	
	def loadCommentsAndParamNames(TypeElement runtimeMetadataTypeElement) {
		runtimeMetadataTypeElement.annotationMirror(RuntimeMetadata.List)?.value("value", typeof(AnnotationMirror[]))?.
			forEach [am , index |
				val uniqueName = am.value("id", String)
				val comment = am.value("comment", String)
				val paramNames = am.value("paramNames", typeof(String[]))

				commentsFromRuntimeMetadata.put(uniqueName, comment)
				paramNamesFromRuntimeMetadata.put(uniqueName, paramNames)
				orderFromRuntimeMetadata.put(uniqueName, index)
			]
	}
	
	/////////////////////////////////

	def dispatch TypeElement getTopLevelEnclosingTypeElement(TypeElement e){
		if(e.enclosingElement?.kind == ElementKind.PACKAGE) e else e.enclosingElement?.topLevelEnclosingTypeElement
	}
	
	def dispatch TypeElement getTopLevelEnclosingTypeElement(Element e){
		e.enclosingElement?.topLevelEnclosingTypeElement
	}

	//TODO: No delegation but custom impl for GenElements
	def getAllAnnotationMirrors(Element e) {
		elementUtils.getAllAnnotationMirrors(e)
	}

	def getAllMembers(TypeElement type) {
		elementUtils.getAllMembers(type)
	}

	def getBinaryName(TypeElement type) {
		elementUtils.getBinaryName(type)
	}

	def getConstantExpression(Object value) {
		elementUtils.getConstantExpression(value)
	}

	
	
	def dispatch Map<? extends ExecutableElement, ? extends AnnotationValue> getElementValuesWithDefaults(
		AnnotationWithDefaultAnnotation a) {
		val result = new HashMap(getElementValuesWithDefaults(a.annotation))
		result.putAll(a.elementValues)
		result
	}

	def dispatch Map<? extends ExecutableElement, ? extends AnnotationValue> getElementValuesWithDefaults(
		GenAnnotationMirror am) {
		val result = am.annotationType.asTypeElement.declaredMethods.filter[defaultValue !== null].toInvertedMap[
			defaultValue]
		result.putAll(am.elementValues)
		result
	}

	def dispatch Map<? extends ExecutableElement, ? extends AnnotationValue> getElementValuesWithDefaults(
		AnnotationWrapper annotationWrapper
	){
		annotationWrapper.annotation.elementValuesWithDefaults
	}
	
	def dispatch Map<? extends ExecutableElement, ? extends AnnotationValue> getElementValuesWithDefaults(
		AnnotationMirror a) {
		elementUtils.getElementValuesWithDefaults(a)
	}

	def getName(CharSequence cs) {
		elementUtils.getName(cs)
	}

	def getPackageElement(CharSequence name) {
		elementUtils.getPackageElement(name)
	}

	def getPackageOf(Element type) {
		elementUtils.getPackageOf(type)
	}

	//Note: Callers currently rely on not throwning tenfe here
	def getTypeElement(CharSequence name) {
		typeElementCache.getTypeElement(name?.toString)
	}

	def hides(Element hider, Element hidden) {
		elementUtils.hides(hider, hidden)
	}

	def isDeprecated(Element e) {
		elementUtils.isDeprecated(e)
	}

	def overrides(ExecutableElement overrider, ExecutableElement overridden, TypeElement type) {
		if (type !== null) {
			throw new UnsupportedOperationException("Method overrides with type parameter currently not supported")
		}
		return overrides(overrider, overridden)
	}

	def printElements(Writer w, Element... elements) {
		elementUtils.printElements(w, elements)
	}
	
	
	
	//to get unique names for methods and constructors, the type parameters are appended
	def dispatch uniqueSimpleName(ExecutableElement e){
		'''«e.simpleName»(«FOR p : e.parameters SEPARATOR ','»«p.asType.qualifiedName»«ENDFOR»)'''
	}
	
	def dispatch uniqueSimpleName(Element e){
		e.simpleName
	}
	
	def dispatch String uniqueName(QualifiedNameable e){
		e.qualifiedName.toString
	}
	
	def dispatch String uniqueName(Element e){
		'''«e.enclosingElement.uniqueName».«e.uniqueSimpleName»'''
	}
	
	def String uniqueNameWithin(Element e, QualifiedNameable enclosing) {
		if(e==enclosing)
			''
		else if (e.enclosingElement == enclosing)
			e.uniqueSimpleName.toString
		else {
			if (e?.enclosingElement === null) {
				throw new IllegalArgumentException('''«e» is not enclosed by element «enclosing»''')
			}
			'''«e.enclosingElement.uniqueNameWithin(enclosing)».«e.uniqueSimpleName.toString»'''

		}
	}
	
	
	def uniqueNameWithinTopLevelEnclosingTypeElement(Element element) {
		element.uniqueNameWithin(element.topLevelEnclosingTypeElement)
	}
	
	def Iterable<? extends Element> elementAndAllEnclosedElements(Element e){
		elementAndAllEnclosedElements(e, false)
	}
	
	//quick and dirty. Should probably be an iterator instead.
	def Iterable<? extends Element> elementAndAllEnclosedElements(Element e, boolean withMethodParams){
		val List<Element> list = newArrayList()
		list.add(e)
		if(withMethodParams && e instanceof ExecutableElement) {
			list.addAll((e as ExecutableElement).parametersWithSrcNames)
		}
		list.addAll(e.enclosedElements.map[elementAndAllEnclosedElements(withMethodParams)].flatten)
		list
	}
	
	
	//defines when a value of a variable is considered to be empty.
	def dispatch boolean isEmptyVar(String string) {
		string.empty
	}
	
	def dispatch boolean isEmptyVar(CharSequence cs) {
		cs.length == 0
	}
	
	def dispatch boolean isEmptyVar(Collection<?> c) {
		c.empty
	}
	
	def dispatch boolean isEmptyVar(Map<?, ?> m) {
		m.empty
	}
	
	def dispatch boolean isEmptyVar(Iterable<?> i) {
		i.empty
	}
	
	def dispatch boolean isEmptyVar(Object object) {
		if(object.class.array){
			Array.getLength(object) == 0
		} else {
			false
		}
	}

	

}
