package de.stefanocke.japkit.gen

import de.stefanocke.japkit.activeannotations.FieldsFromInterface
import java.util.List
import javax.lang.model.element.AnnotationValue
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.Modifier
import javax.lang.model.element.Name
import javax.lang.model.element.VariableElement
import javax.lang.model.type.TypeMirror
import javax.lang.model.type.TypeVariable

@FieldsFromInterface
abstract class GenExecutableElement extends GenParameterizable implements ExecutableElement {
	
	CodeBody body
	AnnotationValue defaultValue
	List<VariableElement> parameters = newArrayList
	TypeMirror returnType = GenNoType.INSTANCE
	List<TypeMirror> thrownTypes = newArrayList
	boolean varArgs
	
	def CodeBody getBody(){
		this.body
	}
	
	def setBody(CodeBody body){			
		this.body = body
		if(body!=null){
			removeModifier(Modifier.ABSTRACT)	
		
		}	
	}
	
	override addModifier(Modifier m){
		if(body != null && m == Modifier.ABSTRACT){
			//Methods with a body are not abstract
			return
		}
		super.addModifier(m)
	}
	
	def addParameter(VariableElement ve){
		val p = ve as GenParameter
		parameters.add(p)
		p.setEnclosingElement(this) 
	}
	
	
	override TypeMirror resolveTypeVariable(TypeVariable tv){
		//we search a type parameter with the same name. If found, we leave the type variable as it is.
		//otherwise we return null, to allow resolving by the declaring type
		if(typeParameters.exists[simpleName.contentEquals(tv.asElement.simpleName)]){
			tv
		} else {
			null
		}
	}
	
	override void resolveContainedTypeVariables(GenParameterizable parameterizable){		
		//processingEnv.getMessager().printMessage(Kind.WARNING, '''Resolve contained type vatiables of «simpleName» «this» ''')
 		returnType = parameterizable.resolveTypeVariables(returnType);  
 		parameters.forEach[p | (p as GenVariableElement).resolveContainedTypeVariables(parameterizable)]
 	}
 	
 	//The following constructors shall be generated, but xtend has some bug and claims there are no super-constructors...
	new(String simpleName){
		super(simpleName)
	}
	
	new(Name  simpleName){
		super(simpleName)
	}
 	
}