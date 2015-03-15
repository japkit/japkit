package de.stefanocke.japkit.rules

import de.stefanocke.japkit.services.TypeElementNotFoundException
import java.lang.reflect.Array
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.type.ArrayType
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.TypeMirror
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.xbase.lib.Functions.Function0
import org.eclipse.xtext.xbase.lib.Functions.Function1
import javax.lang.model.type.PrimitiveType
import javax.lang.model.type.TypeKind
import java.util.List
import javax.lang.model.element.ExecutableElement

////TODO: The name is not correct any,ore, since params are supported. Clients must use mustBeCalledWithParams to determine whether params are required or not.
@Data
abstract class AbstractFunctionRule<T> extends AbstractRule implements Function1<Object, T>,  Function0<T>{
	
	Class<T> type
	
	List<Pair<Class<?>, String>> params;
	
	new(AnnotationMirror metaAnnotation, Element metaElement, Class<T> type){
		super(metaAnnotation, metaElement)
		params = createParams(metaElement)
		val typeAV = metaAnnotation.value("type", TypeMirror)
		this.type = type ?: typeAV.loadClass as Class<T>
	}
	
	def List<Pair<Class<?>, String>> createParams(Element element){
		if(element instanceof ExecutableElement){
			element.parametersWithSrcNames.map[p | p.asType.loadClass -> p.simpleName.toString]
		} else null
	}
	
	def boolean mustBeCalledWithParams(){
		params != null
	}
		
	def eval(Object src){
		if(params!=null){
			throw new IllegalStateException("A function with params must be called using the evalWithParams method")
		}
		inRule[
			try{
				scope(src) [
					evalInternal()
				]
			
			} catch (TypeElementNotFoundException tenfe) {
				throw tenfe
			} catch (Exception e) {
				reportRuleError(e)				
				throw e
			}
			
		]
	}
	
	def evalWithParams(Object[] args){
		
		inRule[
			try{
				if(params==null){
					throw new IllegalStateException("A function without params cannot be called using the evalWithParams method")
				}
				if(args.length != params.length){
					//TODO: Varargs support
					throw new IllegalArgumentException('''The function requires «params.length» parameters but only «args.length» are passed in.''')	
				}
				
				scope [
					(0..<args.length).forEach[
						//TODO: Type checking of params
						valueStack.put(params.get(it).value, args.get(it))
					]
					evalInternal()
				]
			
			} catch (TypeElementNotFoundException tenfe) {
				throw tenfe
			} catch (Exception e) {
				reportRuleError(e)				
				throw e
			}
			
		]
		
		
	}
	
	def protected abstract T evalInternal()
	
	override T apply(Object src) {
		eval(src)
	}
	
	override T apply() {
		eval(currentSrc)
	}
	
	def private dispatch Class<?> loadClass(DeclaredType type){
		Class.forName(type?.asTypeElement?.qualifiedName?.toString ?: "java.lang.Object") 
	}
	
	def private dispatch Class<?> loadClass(ArrayType type){
		Array.newInstance(type.componentType.loadClass, 0).class
	}
	
	private static val primitiveTypes = 
		#{TypeKind.BOOLEAN -> boolean, TypeKind.INT -> int, TypeKind.LONG -> long, TypeKind.SHORT -> short, 
			TypeKind.CHAR -> char, TypeKind.FLOAT -> float, TypeKind.DOUBLE -> double
		}
	
	def private dispatch Class<?> loadClass(PrimitiveType type){
		primitiveTypes.get(type)
	}
	
	def private dispatch Class<?> loadClass(TypeMirror type){
		throw new IllegalArgumentException("Cannot load class for type "+type)
	}
	
}