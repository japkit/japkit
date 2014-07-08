package de.stefanocke.japkit.gen

import de.stefanocke.japkit.annotations.Order
import de.stefanocke.japkit.metaannotations.GenerateClass
import de.stefanocke.japkit.support.ElementsExtensions
import de.stefanocke.japkit.support.ExtensionRegistry
import de.stefanocke.japkit.support.TypeElementNotFoundException
import java.util.ArrayList
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.AnnotationValue
import javax.lang.model.element.Element
import javax.lang.model.element.ElementKind
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.Modifier
import javax.lang.model.element.TypeElement
import javax.lang.model.element.VariableElement
import javax.lang.model.type.TypeMirror

class GenExtensions {
	val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	
	def createOverride(ExecutableElement m, CodeBody b) {
		//TODO: Check, if method can be overridden?
		copyFrom(m) => [
			if (m.enclosingElement.kind == ElementKind.INTERFACE) {
				addModifier(Modifier.PUBLIC)			
			}
			body = b			
		]

	}

	def copyFrom(ExecutableElement m) {
		copyFrom(m, false)
	}
////copy all but enclosing type
//	def copyFrom(ExecutableElement m, boolean copyAnnotations, (GenMethod)=>void modifications) {
//		val method = copyFrom(m, copyAnnotations)
//		modifications.apply(method);
//		method
//	}
	
	def copyFrom(ExecutableElement m, boolean copyAnnotations){
		copyFrom(m, copyAnnotations, [TypeMirror t | t]) as GenMethod
	}
	
	
	
	
	
	//copy all but enclosing type
	def dispatch copyFrom(ExecutableElement m, boolean copyAnnotations, (TypeMirror)=>TypeMirror typeTransformer) {

		//TODO: Optionally copy Annotations?
		val result = if(m.kind == ElementKind.METHOD){ 
			new GenMethod(m.simpleName) 
			
		} else if(m.kind== ElementKind.CONSTRUCTOR) {
			new GenConstructor
		} else {
			throw new IllegalArgumentException('''Copying «m» not supported.''');
		}
		
		result => [
			if (copyAnnotations) {
				annotationMirrors = m.copyAnnotations
			}
			if(m.kind == ElementKind.METHOD){
				returnType = typeTransformer.apply(m.returnType)
			
			}
			setThrownTypes(m.thrownTypes.map[typeTransformer.apply(it)])
			setTypeParameters(m.typeParameters.map[tp|getOrCreateTypeParameter(tp)])
			setVarArgs(m.varArgs)
			setParameters(copyParametersFrom(m, copyAnnotations, typeTransformer))
			modifiers = m.modifiers
		]
	}
	
	def copyParametersFrom(ExecutableElement m, boolean copyAnnotations){
		copyParametersFrom(m, copyAnnotations, [TypeMirror t | t]) 
	}
	
	def copyParametersFrom(ExecutableElement method, boolean copyAnnotations, (TypeMirror)=>TypeMirror typeTransformer) {
		method.parametersWithSrcNames.map [ p |
			copyParamFrom(p, copyAnnotations, typeTransformer)
		]
	}
	
	def copyParamFrom(VariableElement p, boolean copyAnnotations, (TypeMirror)=>TypeMirror typeTransformer) {
		new GenParameter(p.simpleName, typeTransformer.apply(p.asType)) => [
			if (copyAnnotations) {
				annotationMirrors = p.copyAnnotations
			}]
	}
	
	//Copy a field 
	def dispatch copyFrom(VariableElement ve, boolean copyAnnotations, (TypeMirror)=>TypeMirror typeTransformer) {
		new GenField(ve.simpleName, typeTransformer.apply(ve.asType)) => [
			modifiers = ve.modifiers
			if (copyAnnotations) {
				annotationMirrors = ve.copyAnnotations
			}]
	}
	
	def asMemberOf(ExecutableElement m, TypeElement type) {
		copyFrom(m) => [
			enclosingElement = m.enclosingElement
			resolveContainedTypeVariables(type as GenTypeElement)
		]
	}
	
	def asInterfaceMethod(ExecutableElement m) {
		copyFrom(m) => [
			modifiers = emptySet //TODO: Make configurable whether to use "public abstract"
			body = null
		]
	}
	
	def asAbstractMethod(ExecutableElement m) {
		copyFrom(m) => [
			addModifier(Modifier.ABSTRACT)
			body = null
		]
	}
	
	//do never copy japkit meta-annotations
	val japkitAnnotationPackages = #{GenerateClass.package.name, Order.package.name}
	
	def boolean isJapkitAnnotation(AnnotationMirror am){
		japkitAnnotationPackages.contains(am.annotationAsTypeElement.package.qualifiedName.toString)
	}
	
	val isNoJapkitAnnotationFilter = [AnnotationMirror am | 
		!(am.isJapkitAnnotation)
	]	
	
	//Copies all annotations but Japkit metaannotations.
	def copyAnnotations(Element src){
		src.copyAnnotations(isNoJapkitAnnotationFilter)
	}
	
	def static copyAnnotations(Element src, (AnnotationMirror)=>boolean filter){
		new ArrayList(src.annotationMirrors.filter(filter).map[copy].toList)
	}
	
	def static GenAnnotationMirror copy(AnnotationMirror am){
		new GenAnnotationMirror(am.annotationType) => [ 
			am.elementValues.entrySet.forEach[avEntry | setValue(avEntry.key.simpleName.toString, avEntry.value.copy)]
		]
	}
	
	def static GenAnnotationValue copy(AnnotationValue av){
		new GenAnnotationValue(av.value.copyAvValue)
	}
	
	def static dispatch copyAvValue(List<? extends AnnotationValue> values){
		new ArrayList(values.map[copy])
	}
	
	def static dispatch copyAvValue(AnnotationMirror v){
		v.copy
	}
	
	def static dispatch copyAvValue(Object v){
		
		//In Eclipse, annotation values with errors are returned as "<error>". F.e. constant values that use not-(yet)-existing types. 
		//TODO: Same in javac?
		//TODO: TENFE is a bit misleading here...
		if(v == "<error>" ){
			throw new TypeElementNotFoundException();
		}
		return v
	}
}