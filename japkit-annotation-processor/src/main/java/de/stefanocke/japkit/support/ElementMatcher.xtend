package de.stefanocke.japkit.support

import de.stefanocke.japkit.metaannotations.TypeCategory
import de.stefanocke.japkit.support.el.ELSupport
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.Modifier
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.TypeKind
import javax.lang.model.type.TypeMirror
import javax.lang.model.element.ElementKind
import java.util.Set
import javax.lang.model.element.TypeElement

@Data
class ElementMatcher {
	val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val extension ELSupport elSupport = ExtensionRegistry.get(ELSupport)
	val extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	val extension MessageCollector = ExtensionRegistry.get(MessageCollector)
	val extension TypesExtensions typesExtensions = ExtensionRegistry.get(TypesExtensions)

	String src
	String srcLang
	Modifier[] srcModifiers
	Modifier[] srcModifiersNot
	Set<ElementKind> srcKind
	DeclaredType[] srcAnnotations
	DeclaredType[] srcAnnotationsNot
	DeclaredType[] enclosingAnnotations
	DeclaredType[] enclosingAnnotationsNot
	Set<String> notDeclaredBy //FQNs
	TypeMirror srcType
	TypeCategory[] srcTypeCategory
	TypeCategory[] srcTypeCategoryNot
	DeclaredType[] srcTypeAnnotations
	TypeMirror srcSingleValueType
	TypeCategory[] srcSingleValueTypeCategory
	TypeCategory[] srcSingleValueTypeCategoryNot
	DeclaredType[] srcSingleValueTypeAnnotations
	DeclaredType[] srcTypeArg0Annotations
	DeclaredType[] srcTypeArg1Annotations
	String condition
	String conditionLang
	ConstraintRule[] constraints
	AnnotationMirror am

	def filter(Iterable<?> elements){
		elements.filter[
			if(!(it instanceof Element)){
				throw new IllegalArgumentException('''Matcher can only be applied to elements, but not to «it»''')
			}
			matches(it as Element)
		]
	}

	def boolean matches(Element originalSrcElement) {
		val e = srcElement(originalSrcElement) 
		
		val result = (e!=null)
		&& e.hasAllModifiers(srcModifiers)
		&& e.hasNotModifiers(srcModifiersNot)
		&& e.hasAnyKind(srcKind)
		&& e.hasAllAnnotations(srcAnnotations)
		&& e.hasNotAnnotations(srcAnnotationsNot)
		&& e.enclosingElement.hasAllAnnotations(enclosingAnnotations)
		&& e.enclosingElement.hasNotAnnotations(enclosingAnnotationsNot)
		&& e.isNotDeclaredBy(notDeclaredBy)
		
		&& e.srcType.hasAllAnnotations(srcTypeAnnotations)		
		&& e.srcType.isSubtype(srcType)
		&& (srcTypeCategory.nullOrEmpty || e.srcType.belongsToOneOfCategories(srcTypeCategory))	
		&& !e.srcType.belongsToOneOfCategories(srcTypeCategoryNot)	
			
		&& e.srcSingleValueType.hasAllAnnotations(srcSingleValueTypeAnnotations)
		&& e.srcSingleValueType.isSubtype(srcSingleValueType)
		&& (srcSingleValueTypeCategory.nullOrEmpty || e.srcSingleValueType.belongsToOneOfCategories(srcSingleValueTypeCategory))	
		&& !e.srcSingleValueType.belongsToOneOfCategories(srcSingleValueTypeCategoryNot)	
			
		&& e.srcTypeArgHasAllAnnotations(srcTypeArg0Annotations, 0)
		&& e.srcTypeArgHasAllAnnotations(srcTypeArg1Annotations, 1)
		&& fulfillsCondition(e)
		
		//evaluate all constraints, if the matcher matches
		if(result){
			constraints.forEach[validate(e)] //Prototypisch. sowas sollte besser in den ELResolver.
		}
		
		result
	}
	
	def Element srcElement(Element element) {
			if(src.nullOrEmpty) element else 
				eval(element, src, srcLang, Element, '''Could not evaluate source element expression '«src»' in element matcher. ''', null)
			
		
	}
	
	
	def boolean isNotDeclaredBy(Element element, Set<String> notDeclaredByFqns){
		notDeclaredByFqns.nullOrEmpty || !notDeclaredByFqns.contains((element.enclosingElement as TypeElement).qualifiedName.toString)
	}
	
	def boolean hasAnyKind(Element element, ElementKind[] kinds){
		kinds.nullOrEmpty || kinds.contains(element.kind) 
	}
	
	
	def boolean hasAllModifiers(Element e, Modifier[] modifiers){
		modifiers.nullOrEmpty || modifiers.forall[e.modifiers.contains(it)]
	}
	
	def boolean hasNotModifiers(Element e, Modifier[] modifiers){
		modifiers.nullOrEmpty || modifiers.forall[!e.modifiers.contains(it)]
	}
	
	def isSubtype(TypeMirror t1, TypeMirror type) {
		type.isJavaLangObject ||  //shortcut to avoid unnecessary type lookups
		typesExtensions.isSubtype(t1, type) //TODO: Für generierte Typen funzt das nicht... Mit generierten Typen hingegen  (Stichwort: asTypeElement) führt es zu (ggf. zirkulären) dependencies
	}
	
	def boolean belongsToOneOfCategories(TypeMirror type, TypeCategory[] categories){
		categories.exists[type.belongsToCategory(it)]	
	}
	
	def Boolean belongsToCategory(TypeMirror type, TypeCategory category){
		handleTypeElementNotFound(false, '''Could not determine type category of type «type»''')[
			switch(category){
				case TypeCategory.PRIMITIVE: type.primitive || type.boxed
				case TypeCategory.STRING: type.string
				case TypeCategory.TEMPORAL: type.temporal
				case TypeCategory.MATH: type.math
				case TypeCategory.ARRAY: type.kind == TypeKind.ARRAY
				case TypeCategory.COLLECTION: type.collection
				case TypeCategory.MAP: type.map
				case TypeCategory.LIST: type.list
				case TypeCategory.SET: type.set
				case TypeCategory.ENUM: type.enum	
			}	
		]
	}
	
	
	
	def boolean fulfillsCondition(Element element) {
			condition.nullOrEmpty || {
				eval(element, condition, conditionLang, Boolean, '''Could not evaluate condition '«condition»' in element matcher. ''', false)
			}
		
	}

	def hasAllAnnotations(TypeMirror type, DeclaredType[] annotations) {
		annotations.nullOrEmpty ||		//avoid to get type element as far as possible	
		type.typeElementHasAllAnnotations(annotations)
	}
	
	def srcTypeArgHasAllAnnotations(Element e, DeclaredType[] annotations, int argIndex) {
		annotations.nullOrEmpty ||		//avoid to get type element as far as possible	
		e.srcType.getTypeArg(argIndex).typeElementHasAllAnnotations(annotations)	 
	}
	
	def srcSingleValueType(Element e){
		singleValueType(e.srcType)
	}
	
	
	
	
	def dispatch typeElementHasAllAnnotations(DeclaredType type, DeclaredType[] annotations) {
		handleTypeElementNotFound(true, '''Matcher cannot determine annotations of type «type»''')[
			type!=null && type.asTypeElement.hasAllAnnotations(annotations)	
		]		
	}
	
	def dispatch typeElementHasAllAnnotations(TypeMirror type, DeclaredType[] annotations) {
		annotations.nullOrEmpty
	}
	
	def hasAllAnnotations(Element e, DeclaredType[] annotations) {
		annotations.forall[e.hasAnnotation(it)]
	}
	
	def hasNotAnnotations(Element e, DeclaredType[] annotations) {
		annotations.forall[!e.hasAnnotation(it)]
	}
	
	def hasAnnotation(Element e, DeclaredType annotationType) {
		e.annotationMirrors.exists[am|am.hasFqn(annotationType.qualifiedName)]
	}
	
	
	new(AnnotationMirror am) {
		_src =  am.value("src", String)
		_srcLang =  am.value("srcLang", String)
		_srcModifiers = am.value("srcModifiers", typeof(Modifier[]))
		_srcModifiersNot = am.value("srcModifiersNot", typeof(Modifier[]))
		_srcKind = am.value("srcKind", typeof(ElementKind[]))?.toSet
		_srcAnnotations = am.value("srcAnnotations", typeof(DeclaredType[]))
		_srcAnnotationsNot = am.value("srcAnnotationsNot", typeof(DeclaredType[]))
		_enclosingAnnotations = am.value("enclosingAnnotations", typeof(DeclaredType[]))
		_enclosingAnnotationsNot = am.value("enclosingAnnotationsNot", typeof(DeclaredType[]))
		_notDeclaredBy = am.value("notDeclaredBy", typeof(DeclaredType[]))?.map[asTypeElement.qualifiedName.toString].toSet
		_srcType = am.value("srcType", TypeMirror)
		_srcTypeCategory = am.value("srcTypeCategory", typeof(TypeCategory[]))	
		_srcTypeCategoryNot = am.value("srcTypeCategoryNot", typeof(TypeCategory[]))	
		_srcTypeAnnotations = am.value("srcTypeAnnotations", typeof(DeclaredType[]))	
		_srcSingleValueType = am.value("srcSingleValueType", TypeMirror)
		_srcSingleValueTypeCategory = am.value("srcSingleValueTypeCategory", typeof(TypeCategory[]))	
		_srcSingleValueTypeCategoryNot = am.value("srcSingleValueTypeCategoryNot", typeof(TypeCategory[]))	
		_srcSingleValueTypeAnnotations = am.value("srcSingleValueTypeAnnotations", typeof(DeclaredType[]))
		_srcTypeArg0Annotations = am.value("srcTypeArg0Annotations", typeof(DeclaredType[]))	
		_srcTypeArg1Annotations = am.value("srcTypeArg1Annotations", typeof(DeclaredType[]))	
		_condition =  am.value("condition", String)
		_conditionLang =  am.value("conditionLang", String)
		_constraints = am.value("constraints", typeof(AnnotationMirror[])).map[new ConstraintRule(it)]	
		_am = am
		
	}
	
}
