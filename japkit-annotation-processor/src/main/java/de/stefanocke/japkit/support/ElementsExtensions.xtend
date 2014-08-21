package de.stefanocke.japkit.support

import com.google.common.cache.CacheBuilder
import de.stefanocke.japkit.annotations.Order
import de.stefanocke.japkit.annotations.RuntimeMetadata
import de.stefanocke.japkit.gen.GenAnnotationMirror
import de.stefanocke.japkit.gen.GenAnnotationValue
import de.stefanocke.japkit.gen.GenElement
import de.stefanocke.japkit.gen.GenName
import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.metaannotations.Clazz
import de.stefanocke.japkit.metaannotations.ParamNames
import de.stefanocke.japkit.metaannotations.RequiredTriggerAnnotation
import de.stefanocke.japkit.util.MoreCollectionExtensions
import java.io.Writer
import java.lang.annotation.Annotation
import java.lang.reflect.Array
import java.util.Collections
import java.util.HashMap
import java.util.HashSet
import java.util.List
import java.util.Map
import java.util.Set
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
import javax.lang.model.type.ErrorType
import javax.lang.model.type.PrimitiveType
import javax.lang.model.type.TypeKind
import javax.lang.model.type.TypeMirror
import javax.lang.model.util.Elements

import static javax.lang.model.util.ElementFilter.*

class ElementsExtensions {
	extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)
	extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	MessageCollector mc = ExtensionRegistry.get(MessageCollector)
	Elements elementUtils = ExtensionRegistry.get(Elements)

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
		mc.reportError('''Cannot determine type for source «o», since it is neither a type nor an element.''', null,null,null)
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

	public val ORDER_ANNOTATION_NAME = Order.name
	
	public val PARAM_NAMES_ANNOTATION_NAME = ParamNames.name

	def Integer getOrdinalNumber(Element e) {
		val am = e.annotationMirror(ORDER_ANNOTATION_NAME)
		if (am == null) {
			Integer.MAX_VALUE //elements without order go to the end
		} else {
			am.requiredValue(e, "value", Integer)
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
	 */
	def List<? extends VariableElement> parametersWithSrcNames(ExecutableElement e) {
		val am = e.annotationMirror(ParamNames)
		val params = e.parameters
		if (am != null) {
			val namesAv = am.value("value", typeof(String[]))
			val names = if (namesAv.size == 1) {

					//Alternative representation: All names as one comma separated string.
					namesAv.get(0).split(",").map[trim]
				} else
					namesAv.toList

			if (params.size != names.size) {
				mc.reportError("Then number of parameter names must match the number of parameters", e, am, "value")
				params
			} else {
				wrapParams(params, names)
			}
		} else {
			val names = getParamNamesFromRuntimeMetadata(e)
			if(!names.nullOrEmpty){
				wrapParams(params, names)
			} else {
				params
			}
			
		}
	}
	
	private def List<ParameterWrapper> wrapParams(List<? extends VariableElement> params, List<String> names) {
		(0 ..< params.size).map[i|new ParameterWrapper(params.get(i), new GenName(names.get(i)))].toList
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
			val t1 = m1.parameters.get(i).asType
			val t2 = m2.parameters.get(i).asType
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
		if (v == null) {
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
		annotatedElement.annotationMirrors.findFirst[hasFqn(annotationFqn)]
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
		if (listAnnotationType != null) {
			val listAnnotation = annotatedElement.annotationMirror(listAnnotationType.qualifiedName)
			if (listAnnotation != null) {
				return listAnnotation.value("value", typeof(AnnotationMirror[]))
			}

		}
		val singleAnnotation = annotatedElement.annotationMirror(annotationFqn)
		return if(singleAnnotation == null) emptyList else Collections.singletonList(singleAnnotation)
	}

	def annotationsWithMetaAnnotation(Element annotatedElement, CharSequence metaAnnotationFqn) {
		annotatedElement.annotationMirrors.filter[hasMetaAnnotation(metaAnnotationFqn)]
	}

	def boolean hasMetaAnnotation(AnnotationMirror am, CharSequence metaAnnotationFqn) {
		am.metaAnnotations.exists[hasFqn(metaAnnotationFqn)]
	}

	def annotationsWithMetaAnnotation(Element annotatedElement, Class<? extends Annotation> annotationClass) {
		annotationsWithMetaAnnotation(annotatedElement, annotationClass.name)
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
		annotationValuesCache.invalidateAll
	}

	//Ist das legal? GGf. auf eine Runde beschränken...
	static val annotationValuesCache = CacheBuilder.newBuilder.maximumSize(1000).weakKeys.<AnnotationMirror, Map<String, AnnotationValue>>build
	

	def AnnotationValue value(AnnotationMirror annotationMirror, CharSequence name) {
		loadAnnotationValues(annotationMirror).get(name.toString)
	}

	//Gets the annotation vlaues from cache and loads them if not yet in cache.
	def loadAnnotationValues(AnnotationMirror annotationMirror) {
		var valuesMap = annotationValuesCache.getIfPresent(annotationMirror)

		if (valuesMap == null) {
			val map = newHashMap
			annotationMirror.elementValuesWithDefaults.forEach[k, v|map.put(k.simpleName.toString, v)]
			annotationValuesCache.put(annotationMirror, map)
			valuesMap = map
		}
		valuesMap
	}

	def handleErrorAnnotationValues(AnnotationValue v, AnnotationMirror annotationMirror, CharSequence name) {

		//In Eclipse, annotation values with errors are returned as "<error>". F.e. constant values that use not-(yet)-existing types. 
		//TODO: Same in javac?
		//TODO: TENFE is a bit misleading here...
		if (v?.value == "<error>") {
			throw new TypeElementNotFoundException(annotationMirror, name);
		}
	}

	//	def valueAsTypeElement(AnnotationMirror annotationMirror, Element annotatedElement, CharSequence name) {
	//		annotationMirror.value(annotatedElement, name, TypeElement)
	//	}
	/**
 * Gets an annotation value and casts it to a given type. The annotates element must be provided for error reporting.
 */
	def <T> T value(AnnotationMirror annotationMirror, Element annotatedElement, CharSequence name, Class<T> avType,
		boolean isRequired) {
		val av = annotationMirror.value(name)

		val value = av?.value
		
		if (isNullOrEmptyAV(value)) {
			if (isRequired) {
				throw new ProcessingException('''Required Annotation value «name» is missing.''', annotatedElement,
					annotationMirror, name, av);
			} else {
				return null
			}
		}

		av.mapAs(av.value, annotationMirror, annotatedElement, name, avType)
	}
	
	def isNullOrEmptyAV(Object value) {
		value == null || value.isEmptyAV
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
		Element annotatedElement, CharSequence name, Class<T> avType) {
		handleErrorAnnotationValues(av, annotationMirror, name)
		
		if(value==null) {return null;}

		//Arrays can be converted to single values to support optionality. The array may contain zero or one element then.
		if (!avType.array && value instanceof Iterable<?>) {	
			return av.mapAs(singleAV(value as Iterable<AnnotationValue>), annotationMirror, annotatedElement, name, avType)
		}
		

		if (avType == TypeElement) {
			val tm = av.cast(value, annotationMirror, annotatedElement, name, TypeMirror)
			tm?.asTypeElement as T
		} else if (avType == Pattern) {
			try {
				val patternString = av.cast(value, annotationMirror, annotatedElement, name, String)
				if (patternString.nullOrEmpty) {
					return null
				}
				val pattern = Pattern.compile(patternString)
				avType.cast(pattern) //"as T" does not work here. XTend bug?
			} catch (PatternSyntaxException pse) {
				throw new ProcessingException('''Exception when compiling regular expression: «pse.message»''',
					annotatedElement, annotationMirror, name, av)
			}
		} else if (avType.enum) {
			val ve = av.cast(value, annotationMirror, annotatedElement, name, VariableElement)

			//xtend issue or java issue?
			val clazz = avType as Class<?>
			val enumClazz = clazz as  Class<? extends Enum>
			Enum.valueOf(enumClazz, ve.simpleName.toString) as T

		} else if (avType.array) {
			val arr = Array.newInstance(avType.componentType, 0)
			(value as Iterable<AnnotationValue>).map[
				it.mapAs(it.value, annotationMirror, annotatedElement, name, avType.componentType)].toList.toArray(
				arr as Object[]) as T
		} else {

			av.cast(value, annotationMirror, annotatedElement, name, avType)
		}
	}
	
	
	
	//TODO: Cache?
	private def annotationValueDeclaration(AnnotationMirror annotationMirror, CharSequence name) {
		annotationMirror.annotationAsTypeElement.declaredMethods.findFirst[simpleName.contentEquals(name)]
	}

	def singleAV(Iterable<AnnotationValue> values) {		
		(MoreCollectionExtensions.singleValue(values))?.value
	}
	

	private def <T> T cast(AnnotationValue av, Object value, AnnotationMirror annotationMirror, Element annotatedElement,
		CharSequence name, Class<T> avType) {

		var Class<?> targetType = avType
		if (avType.primitive) {
			targetType = avType.boxedType
		}
		try {
			targetType.cast(value) as T
		} catch (RuntimeException re) {
			throw new ProcessingException(
				'''Exception when casting annotation value '«name»' (value : '«value»'): «re.message»''',
				annotatedElement, annotationMirror, name, av);
		}
	}

	def <T> valueOrMetaValue(AnnotationMirror annotationMirror, Element annotatedElement, CharSequence name,
		Class<T> avType, boolean isRequired, AnnotationMirror metaAnnotation) {

		//At first, look at the annotation itself for the value. Prepend the disambiguation prefix from the meta annotation, if provided.
		val prefixedAvName = getPrefixedAvName(metaAnnotation, name)

		var value = value(annotationMirror, annotatedElement, prefixedAvName, avType, false);
		
		//TODO: Das wirkt nicht überall. z.B. nicht in annotationValuesByNameUnwrapped
		if(value!=null){
			value = transformTypeToGeneratedType(value, annotationMirror, name) as T	
		}

		//If the annotation does not provide the value, take it from the meta annotation
		if (value == null && metaAnnotation != null) {
			value = value(metaAnnotation, annotationMirror.annotationType.asElement, name, avType,
				isRequired || avType.primitive)
		}
		value
	}

		

	def getPrefixedAvName(AnnotationMirror metaAnnotation, CharSequence name) {
		if (metaAnnotation == null) {
			return name
		}
		val prefix = metaAnnotation.value("_prefix", String)
		val prefixedAvName = if(prefix.nullOrEmpty) name else prefix + name.toString.toFirstUpper
		prefixedAvName
	}

	def <T> value(AnnotationMirror annotationMirror, Element annotatedElement, CharSequence name, Class<T> avType) {
		annotationMirror.value(annotatedElement, name, avType, false)
	}

	def <T> value(AnnotationMirror annotationMirror, CharSequence name, Class<T> avType) {
		annotationMirror.value(null, name, avType, false)
	}

	def <T> valueOrMetaValue(AnnotationMirror annotationMirror, Element annotatedElement, CharSequence name,
		Class<T> avType, AnnotationMirror metaAnnotation) {
		annotationMirror.valueOrMetaValue(annotatedElement, name, avType, false, metaAnnotation)
	}

	def <T> valueOrMetaValue(AnnotationMirror annotationMirror, CharSequence name, Class<T> avType,
		AnnotationMirror metaAnnotation) {
		annotationMirror.valueOrMetaValue(null, name, avType, false, metaAnnotation)
	}

	def <T> requiredValue(AnnotationMirror annotationMirror, Element annotatedElement, CharSequence name,
		Class<T> avType) {
		annotationMirror.value(annotatedElement, name, avType, true)
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

	def annotationValuesByNameUnwrapped(AnnotationMirror am) {
		[CharSequence avName|loadAnnotationValues(am).get(avName.toString)?.unwrapAnnotationValue]
	}
	
	def dispatch Object unwrapAnnotationValue(AnnotationValue av) {
		av?.value.unwrapAnnotationValue
	}

	def dispatch Object unwrapAnnotationValue(List<? extends AnnotationValue> values) {
		values.map[it.value]
	}

	def dispatch Object unwrapAnnotationValue(Object value) {
		value
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
		if (avType instanceof ArrayType) {

			val compType = avType.componentType

			if (value instanceof Iterable<?>) {
				value.map [
					new GenAnnotationValue(coerceSingleValue(it, compType))
				].toList

			} else if(value==null){
				emptyList
			} else {
				newArrayList(new GenAnnotationValue(coerceSingleValue(value, compType)))
			}

		} else {
			coerceSingleValue(value, avType)
		}
	}

	def coerceSingleValue(Object value, TypeMirror avType) {
		if(value==null){
			//This is no valid annotation value but it just says not to set the AV
			return null;
		}
		val v = toAnnotationValue(avType, value)
		
		if (!avType.toAnnotationValueClass.isInstance(v)) {
			throw new IllegalArgumentException(
				''''«v»' of type «v?.class» is not a valid value or element value for type «avType»''');
		}
		v
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
				if (typeMirror == null) {
					throw new IllegalArgumentException('''Class «s» could not be found.''');
				}
				typeMirror
			}
			case e.kind == ElementKind.ANNOTATION_TYPE: {
				throw unsupportedAVType(avType, s)
			}
			case e.kind == ElementKind.ENUM: {
				val enumConst = avType.asTypeElement.declaredFields.findFirst[simpleName.contentEquals(s)]
				if (enumConst == null) {
					throw new IllegalArgumentException('''«s» is not a valid enum constant for enum type «avType»''');
				}
				enumConst
			}
			default:
				throw unsupportedAVType(avType, s)
		}

	}

	def dispatch toAnnotationValue(TypeMirror type, Object o) {
		throw unsupportedAVType(type, o)
	}

	def static unsupportedAVType(TypeMirror type, Object o) {
		new IllegalArgumentException(
			'''An annotation value of type «type» cannot be created from value "«o»" of type «o?.class»''')
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
	
	
	////////////////////////////////
	//TODO: Move to separate class
	//Unique element name -> comment
	Map<String, String> commentsFromRuntimeMetadata = newHashMap()
	Map<String, List<String>> paramNamesFromRuntimeMetadata = newHashMap()
	
	//FQNs of types for which RuntimeMetadata has been loaded or  does not exist
	Set<String> typeElementsForWhichRuntimeMetadataHasBeenLoaded = new HashSet
	
	def String getCommentFromRuntimeMetadata(Element element) {
		loadRuntimeMetadata(element)
		commentsFromRuntimeMetadata.get(uniqueNameWithinTopLevelEnclosingTypeElement(element))
	}

	
	def List<String> getParamNamesFromRuntimeMetadata(Element element) {
		loadRuntimeMetadata(element)
		paramNamesFromRuntimeMetadata.get(uniqueNameWithinTopLevelEnclosingTypeElement(element))
	}
	
	
	def loadRuntimeMetadata(Element element) {
		val topLevelEnclosingTypeElement = element.getTopLevelEnclosingTypeElement
		val typeElementFqn = topLevelEnclosingTypeElement.qualifiedName.toString
		if (!typeElementsForWhichRuntimeMetadataHasBeenLoaded.contains(typeElementFqn)) {
			if (topLevelEnclosingTypeElement.annotationMirror(RuntimeMetadata) != null) {
				val runtimeMetadataTypeElement = findTypeElement(typeElementFqn + "_RuntimeMetadata") //TODO: Constant
				if (runtimeMetadataTypeElement != null) {
					runtimeMetadataTypeElement.annotationMirror(RuntimeMetadata.List)?.value("value",
						typeof(AnnotationMirror[]))?.forEach [
						val uniqueName = value("id", String)
						val comment = value("comment", String)
						val paramNames = value("paramNames", typeof(String[]))
						
						commentsFromRuntimeMetadata.put(uniqueName, comment)
						paramNamesFromRuntimeMetadata.put(uniqueName, paramNames)
					]
				}

			}
			typeElementsForWhichRuntimeMetadataHasBeenLoaded.add(typeElementFqn)
		}
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
		val result = am.annotationType.asTypeElement.declaredMethods.filter[defaultValue != null].toInvertedMap[
			defaultValue]
		result.putAll(am.elementValues)
		result
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
		elementUtils.getTypeElement(name)
	}

	def hides(Element hider, Element hidden) {
		elementUtils.hides(hider, hidden)
	}

	def isDeprecated(Element e) {
		elementUtils.isDeprecated(e)
	}

	def overrides(ExecutableElement overrider, ExecutableElement overridden, TypeElement type) {
		if (type != null) {
			throw new UnsupportedOperationException("Method overrides with type parameter currently not supported")
		}
		return overrides(overrider, overridden)
	}

	def printElements(Writer w, Element... elements) {
		elementUtils.printElements(w, elements)
	}
	
	
	//TODO: Das ist ziemlich high level für ElementsExtensions. Ggf. als "Plugin" bereitstellen.
		//Transform annotated types to their generated counterparts, if the annotation value decl. has an according metanannotation
	
	private def dispatch transformTypeToGeneratedType(TypeMirror value, AnnotationMirror annotationMirror, CharSequence name) {		
			val triggerAnnotationTypes = getAVTriggerAnnotationTypes(annotationMirror, name)			
			generatedTypeAccordingToTriggerAnnotation(value, triggerAnnotationTypes, false)			
	}
	
	private def dispatch transformTypeToGeneratedType(TypeElement value, AnnotationMirror annotationMirror, CharSequence name) {		
			val triggerAnnotationTypes = getAVTriggerAnnotationTypes(annotationMirror, name)			
			generatedTypeElementAccordingToTriggerAnnotation(value, triggerAnnotationTypes, false)			
	}
	
	private def dispatch transformTypeToGeneratedType(Iterable<?> value, AnnotationMirror annotationMirror, CharSequence name) {		
		if(!value.nullOrEmpty && (value.head instanceof TypeMirror)){
			val triggerAnnotationTypes = getAVTriggerAnnotationTypes(annotationMirror, name)
			value.map[generatedTypeAccordingToTriggerAnnotation(it as TypeMirror, triggerAnnotationTypes, false)]
		} else if(!value.nullOrEmpty && value.head instanceof TypeElement){
			val triggerAnnotationTypes = getAVTriggerAnnotationTypes(annotationMirror, name)
			value.map[generatedTypeElementAccordingToTriggerAnnotation(it as TypeElement, triggerAnnotationTypes, false)]
		} else {
			value
		}
	}
	
	private def dispatch transformTypeToGeneratedType(Object value, AnnotationMirror annotationMirror, CharSequence name) {
		value
	}
	
	
	private def getAVTriggerAnnotationTypes(AnnotationMirror annotationMirror, CharSequence name) {
		val am = annotationValueDeclaration(annotationMirror, name).annotationMirror(RequiredTriggerAnnotation)
		am?.value("value", typeof(TypeMirror[]))
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
		val triggerAnnotationTypeFqns = triggerAnnotationTypes.map[qualifiedName].toSet
		val annotations = typeElement.annotationMirrors.filter[triggerAnnotationTypeFqns.contains(annotationType.qualifiedName)] 
		
		if (annotations.empty) {
			if (mustHaveTrigger) {
				mc.reportError(
					'''Related type «typeElement.qualifiedName» must have one of the trigger annotations «triggerAnnotationTypeFqns».''',
					null, null, null);
				null

			} else {
				typeElement
			}
		}
		
		else if (annotations.size > 1) {
		
			mc.reportError(
				'''Related type «typeElement.qualifiedName» has more than one of the trigger annotations «triggerAnnotationTypeFqns».
				 Thus, the generated type to use is not unique.''',
				null, null, null);
			null
		}
		else if(!typeElement.generated && 
			//Workaround dafür, dass @Generated Source-Retention hat und somit typeElement.generated im inkrementellen Build falsche Ergebnisse liefert.
			!ExtensionRegistry.get(AnnotationExtensions).isShadowAnnotation(annotations.head)
			
		) {  
		
			//Only apply the transformation if it is not a generated class 
				
			//TODO: Zumindest Teile davon können in die Type Registry
			val triggerAnnotation = annotations.head
			val nameRule = new ClassNameRule(triggerAnnotation.metaAnnotation(Clazz))
			val fqn = nameRule.generateQualifiedName(typeElement)
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
	
	def String uniqueNameWithin(Element e, TypeElement enclosing) {
		if(e==enclosing)
			''
		else if (e.enclosingElement == enclosing)
			e.uniqueSimpleName.toString
		else {
			if (e?.enclosingElement == null) {
				throw new IllegalArgumentException('''«e» is not enclosed by element «enclosing»''')
			}
			'''«e.enclosingElement.uniqueNameWithin(enclosing)».«e.uniqueSimpleName.toString»'''

		}
	}
	
	
	def uniqueNameWithinTopLevelEnclosingTypeElement(Element element) {
		element.uniqueNameWithin(element.topLevelEnclosingTypeElement)
	}
	
	//quick and dirty. Should probably be an iterator instead.
	def Iterable<? extends Element> elementAndAllEnclosedElements(Element e){
		val List<Element> list = newArrayList()
		list.add(e)
		list.addAll(e.enclosedElements.map[elementAndAllEnclosedElements].flatten)
		list
	}

}
