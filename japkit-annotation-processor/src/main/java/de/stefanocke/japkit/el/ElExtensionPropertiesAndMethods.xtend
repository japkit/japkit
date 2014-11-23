package de.stefanocke.japkit.el

import java.util.Map
import org.eclipse.xtend.lib.annotations.Accessors

import static extension de.stefanocke.japkit.util.MoreCollectionExtensions.*

class ElExtensionPropertiesAndMethods {

	// baseClass -> ( propertyName -> ((rootProperties, base)=>resultValue) ) 
	@Accessors
	val Map<Class<?>, Map<String, (Map<String, Object>, Object)=>Object>> propertyNameToGetterClosureByClass = newHashMap
	
	//baseClass ->  ((rootProperties, base, propertyName)=>resultValue)  
	@Accessors
	val Map<Class<?>, (Map<String, Object>, Object, String)=>Object> getPropertyClosureByClass = newHashMap
	
	// baseClass -> ( methodName -> ((rootProperties, base, params)=>resultValue) ) 
	@Accessors
	val Map<Class<?>, Map<String, (Map<String, Object>, Object, Class<?>[], Object[])=>Object>> methodNameToClosureByClass = newHashMap
	
	def <T> void  registerProperty(Class<T> baseClass, String propertyName, (Map<String, Object>, T)=>Object getterClosure){
		propertyNameToGetterClosureByClass.getOrCreateMap(baseClass).put(propertyName, getterClosure as (Map<String, Object>, Object)=>Object)
	}
	
	def <T> void  registerGetProperty(Class<T> baseClass, (Map<String, Object>, T, String)=>Object getPropertyClosure){
		getPropertyClosureByClass.put(baseClass, getPropertyClosure as (Map<String, Object>, Object, String)=>Object)
	}
	
	def <T>  void registerMethod(Class<T> baseClass, String methodName, (Map<String, Object>, T, Class<?>[], Object[])=>Object closure){
		methodNameToClosureByClass.getOrCreateMap(baseClass).put(methodName, closure as (Map<String, Object>, Object, Class<?>[], Object[])=>Object)
	}
	
	def findMethodClosure(Object base, String methodName){
		findClosure(methodNameToClosureByClass, base, methodName)
	}
	
	def findPropertyClosure(Object base, String propertyName){
		findClosure(propertyNameToGetterClosureByClass, base, propertyName)
	}
	
	def findGetPropertyClosure(Object base){
		base?.class?.findForClassOrSuperclass(getPropertyClosureByClass)
	}
	
	def private <V> V findClosure(Map<Class<?>, Map<String, V>> map, Object base, String name) {
		base?.class?.findForClassOrSuperclass(map, name)
	}

	def private <V> V findForClassOrSuperclass(Class<?> clazz, Map<Class<?>, Map<String, V>> map, String name){
		map.get(clazz)?.get(name) ?: {
			clazz.superclass?.findForClassOrSuperclass(map, name) ?: 
			clazz.interfaces.map[findForClassOrSuperclass(map, name)].findFirst[it != null]		
		}
	}
	
	def private <V> V findForClassOrSuperclass(Class<?> clazz, Map<Class<?>, V> map){
		map.get(clazz) ?: {
			clazz.superclass?.findForClassOrSuperclass(map) ?: 
			clazz.interfaces.map[findForClassOrSuperclass(map)].findFirst[it != null]		
		}
	}
}