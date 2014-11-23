package de.stefanocke.japkit.util

import java.util.List
import java.util.Map
import java.util.Set
import java.util.SortedSet
import java.util.TreeSet

class MoreCollectionExtensions {
	def static <K, V> V getOrCreate(Map<K, ? super V> map, K key, (K)=>V factory) {
		map.get(key) as V ?: {
			val v = factory.apply(key)
			map.put(key, v)
			v
		}
	}
	
	
	def static <K, V> Set<V> getOrCreateSet(Map<K, Set<V>> map, K key) {
		getOrCreate(map, key, [newHashSet()])
	}
	
	def static <K1, K2, V> Map<K2, V> getOrCreateMap(Map<K1,  Map<K2, V>> map, K1 key) {
		getOrCreate(map, key, [newHashMap()])
	}
	
	def static <K, V> SortedSet<V> getOrCreateSortedSet(Map<K, SortedSet<V>> map, K key) {
		getOrCreate(map, key, [new TreeSet()])
	}
	
	def static <K, V> List<V> getOrCreateList(Map<K, List<V>> map, K key) {
		getOrCreate(map, key, [newArrayList()])
	}
	
	def static <T, FT> Iterable<FT> filterInstanceOf(Iterable<T> unfiltered, Class<FT> type) {
		unfiltered.filter(e | type.isInstance(e)).map(e | type.cast(e))
	} 
	
	def static <T> T singleValue(Iterable<? extends T> values) {
		if (values.size > 1) {
			throw new IllegalArgumentException('''At most one value is expected here, but not: «values»''');
		} else {
			values.head 
		}
	}
}
