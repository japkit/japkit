package de.japkit.el

import java.util.HashMap
import java.util.HashSet
import java.util.Map

/**
 * Holds EL-Variables.
 * 
 */
class ValueStack implements Map<String, Object> {
	
	Map<String, Object> current = emptyMap
	
	ValueStack parent
	
	new(){	
	}
	
	
	new(Map<String,  Object> values, ValueStack parent){
		this.current = values
		this.parent = parent
	}
	
	
	
	//deep copy
	new(ValueStack other){
		this.current = new HashMap(other.current)
		if(other.parent !== null){
			this.parent = new ValueStack(other.parent)	
		}
	}
	
	def getParent(){
		parent
	}
	
	def void push(){
		parent = new ValueStack(current, parent)
		current = emptyMap
	}
	
	private def createOnDemand(){
		if(current==emptyMap){
			current = newHashMap()
		}
	}
	
	def void pushAndPutAll(Map<String, ? extends Object> values){
		push()
		putAll(values)
	}
	
	def void pop(){
		if(parent === null){
			throw new IllegalStateException("ValueStack has no parent. pop() is not allowed.")
		}
		current = parent.current
		parent = parent.parent
		
	}
	
	override clear() {
		current.clear
	}
	
	override containsKey(Object key) {
		current.containsKey(key) || (parent !== null && parent.containsKey(key)) || (parent !== null && key=="parent" )
	}
	
	override containsValue(Object value) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override entrySet() {
		val entries = parent?.entrySet?.toMap[key] ?: newHashMap
		entries.putAll(current.entrySet.toMap[key])
		entries.values.toSet.unmodifiableView
	}
	
	override get(Object key) {
		val result = if("parent" == key) parent else 
		current.get(key) ?: parent?.get(key)
		
		//Exceptions are used to indicate failures when evaluating EL variables. Instead returning them as values, they are thrown.
		if(result instanceof Exception) throw result
		
		result 
	}
	
	def <T> T get(Object key, Class<T> clazz) {
		clazz.cast(get(key)) 
	}
	
	def getRequired(Object key){
		val v = get(key)
		if(v === null) {
			throw new IllegalStateException('''No value found on value stack for key «key»''')
		}
		v
	}
	
	override isEmpty() {
		current.empty && (parent === null || parent.empty)
	}
	
	override keySet() {
		val keys = new HashSet(current.keySet)
		if(parent !== null) keys.addAll(parent.keySet)
		keys.unmodifiableView
	}
	
	override put(String key, Object value) {
		if("parent" == key) throw new IllegalArgumentException("parent is a reserved key for accessing parent value stack")
		createOnDemand()
		current.put(key, value)
	}
	
	override putAll(Map<? extends String, ?> m) {
		if(m.containsKey("parent")) throw new IllegalArgumentException("parent is a reserved key for accessing parent value stack")
		createOnDemand()
		current.putAll(m)
	}
	
	override remove(Object key) {
		if("parent" == key) throw new IllegalArgumentException("parent is a reserved key for accessing parent value stack")
		createOnDemand()
		current.remove(key)
	}
	
	override size() {
		keySet.size
	}
	
	override values() {
		keySet.map[get].toList.unmodifiableView
	}
	
}