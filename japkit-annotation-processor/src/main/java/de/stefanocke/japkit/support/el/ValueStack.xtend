package de.stefanocke.japkit.support.el

import java.util.HashMap
import java.util.HashSet
import java.util.Map

/**
 * Holds EL-Varaibles.
 * 
 * TODO: Make it a stack of scopes. Allow access to parent scope. Move all "EL root properties" to value stack. 
 */
class ValueStack implements Map<String, Object> {
	
	Map<String, Object> current = newHashMap
	
	ValueStack parent
	
	new(){	
	}
	
	
	public new(Map<String,  ? extends Object> values, ValueStack parent){
		this.current = new HashMap(values)
		this.parent = parent
	}
	
	//deep copy
	new(ValueStack other){
		this.current = new HashMap(other.current)
		if(other.parent != null){
			this.parent = new ValueStack(other.parent)	
		}
	}
	
	def void push(){
		parent = new ValueStack(current, parent)
		current = new HashMap
	}
	
	def void pushAndPutAll(Map<String, ? extends Object> values){
		push()
		putAll(values)
	}
	
	def void pop(){
		if(parent == null){
			throw new IllegalStateException("ValueStack has no parent. pop() is not allowed.")
		}
		current = parent.current
		parent = parent.parent
		
	}
	
	override clear() {
		current.clear
	}
	
	override containsKey(Object key) {
		current.containsKey(key) || (parent != null && parent.containsKey(key)) || (parent != null && key=="parent" )
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
		if("parent" == key) parent else 
		current.get(key) ?: parent?.get(key)
	}
	
	def <T> T get(Object key, Class<T> clazz) {
		clazz.cast(get(key)) 
	}
	
	def getRequired(Object key){
		val v = get(key)
		if(v==null) {
			throw new IllegalStateException('''No value found on value stack for key «key»''')
		}
		v
	}
	
	override isEmpty() {
		current.empty && (parent==null || parent.empty)
	}
	
	override keySet() {
		val keys = new HashSet(current.keySet)
		if(parent!=null) keys.addAll(parent.keySet)
		keys.unmodifiableView
	}
	
	override put(String key, Object value) {
		if("parent" == key) throw new IllegalArgumentException("parent is a reserved key for accessing parent value stack")
		current.put(key, value)
	}
	
	override putAll(Map<? extends String, ?> m) {
		if(m.containsKey("parent")) throw new IllegalArgumentException("parent is a reserved key for accessing parent value stack")
		current.putAll(m)
	}
	
	override remove(Object key) {
		if("parent" == key) throw new IllegalArgumentException("parent is a reserved key for accessing parent value stack")
		current.remove(key)
	}
	
	override size() {
		keySet.size
	}
	
	override values() {
		keySet.map[get].toList.unmodifiableView
	}
	
}