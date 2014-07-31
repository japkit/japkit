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

	String srcExpr
	String srcLang
	String name
	Modifier[] modifiers
	Modifier[] modifiersNot
	Set<ElementKind> kind
	DeclaredType[] annotations
	DeclaredType[] annotationsNot
	DeclaredType[] enclosingAnnotations
	DeclaredType[] enclosingAnnotationsNot
	Set<String> notDeclaredBy //FQNs
	TypeMirror type
	TypeCategory[] typeCategory
	TypeCategory[] typeCategoryNot
	DeclaredType[] typeAnnotations
	TypeMirror singleValueType
	TypeCategory[] singleValueTypeCategory
	TypeCategory[] singleValueTypeCategoryNot
	DeclaredType[] singleValueTypeAnnotations
	DeclaredType[] typeArg0Annotations
	DeclaredType[] typeArg1Annotations
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
		
		scope(e)[
			val result = (e!=null)
			&& (name.nullOrEmpty || name.contentEquals(e.simpleName))
			&& e.hasAllModifiers(modifiers)
			&& e.hasNotModifiers(modifiersNot)
			&& e.hasAnyKind(kind)
			&& e.hasAllAnnotations(annotations)
			&& e.hasNotAnnotations(annotationsNot)
			&& e.enclosingElement.hasAllAnnotations(enclosingAnnotations)
			&& e.enclosingElement.hasNotAnnotations(enclosingAnnotationsNot)
			&& e.isNotDeclaredBy(notDeclaredBy)
			
			&& e.srcType.hasAllAnnotations(typeAnnotations)		
			&& e.srcType.isSubtype(type)
			&& (typeCategory.nullOrEmpty || e.srcType.belongsToOneOfCategories(typeCategory))	
			&& !e.srcType.belongsToOneOfCategories(typeCategoryNot)	
				
			&& e.srcSingleValueType.hasAllAnnotations(singleValueTypeAnnotations)
			&& e.srcSingleValueType.isSubtype(singleValueType)
			&& (singleValueTypeCategory.nullOrEmpty || e.srcSingleValueType.belongsToOneOfCategories(singleValueTypeCategory))	
			&& !e.srcSingleValueType.belongsToOneOfCategories(singleValueTypeCategoryNot)	
				
			&& e.srcTypeArgHasAllAnnotations(typeArg0Annotations, 0)
			&& e.srcTypeArgHasAllAnnotations(typeArg1Annotations, 1)
			&& fulfillsCondition(e)
			
			//evaluate all constraints, if the matcher matches
			if(result){
				constraints.forEach[validate] 
			}
			
			result
		
		]
	}
	
	def Element srcElement(Element element) {
			if(srcExpr.nullOrEmpty) element else 
				eval(srcExpr, srcLang, Element, '''Could not evaluate source element expression '«srcExpr»' in element matcher. ''', null)
			
		
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
			condition.nullOrEmpty || 
				eval(condition, conditionLang, Boolean, '''Could not evaluate condition '«condition»' in element matcher. ''', false)		
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
		_srcExpr =  am.value("src", String)
		_srcLang =  am.value("srcLang", String)
		_name = am.value("name", String)
		_modifiers = am.value("modifiers", typeof(Modifier[]))
		_modifiersNot = am.value("modifiersNot", typeof(Modifier[]))
		_kind = am.value("kind", typeof(ElementKind[]))?.toSet
		_annotations = am.value("annotations", typeof(DeclaredType[]))
		_annotationsNot = am.value("annotationsNot", typeof(DeclaredType[]))
		_enclosingAnnotations = am.value("enclosingAnnotations", typeof(DeclaredType[]))
		_enclosingAnnotationsNot = am.value("enclosingAnnotationsNot", typeof(DeclaredType[]))
		_notDeclaredBy = am.value("notDeclaredBy", typeof(DeclaredType[]))?.map[asTypeElement.qualifiedName.toString].toSet
		_type = am.value("type", TypeMirror)
		_typeCategory = am.value("typeCategory", typeof(TypeCategory[]))	
		_typeCategoryNot = am.value("typeCategoryNot", typeof(TypeCategory[]))	
		_typeAnnotations = am.value("typeAnnotations", typeof(DeclaredType[]))	
		_singleValueType = am.value("singleValueType", TypeMirror)
		_singleValueTypeCategory = am.value("singleValueTypeCategory", typeof(TypeCategory[]))	
		_singleValueTypeCategoryNot = am.value("singleValueTypeCategoryNot", typeof(TypeCategory[]))	
		_singleValueTypeAnnotations = am.value("singleValueTypeAnnotations", typeof(DeclaredType[]))
		_typeArg0Annotations = am.value("typeArg0Annotations", typeof(DeclaredType[]))	
		_typeArg1Annotations = am.value("typeArg1Annotations", typeof(DeclaredType[]))	
		_condition =  am.value("condition", String)
		_conditionLang =  am.value("conditionLang", String)
		_constraints = am.value("constraints", typeof(AnnotationMirror[])).map[new ConstraintRule(it)]	
		_am = am
		
	}
	
}
