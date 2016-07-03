package de.japkit.services;

import java.util.HashMap;
import java.util.Map;

import org.eclipse.xtext.xbase.lib.Functions.Function0;

/**
 * Holds all central stateful extensions in a thread local. So, we can get the
 * everywhere without having to pass around them as constructor arguments.
 */
public final class ExtensionRegistry {

	private ExtensionRegistry() {
	}

	private static final ThreadLocal<Map<Class<?>, Object>> extensions = new ThreadLocal<Map<Class<?>, Object>>() {
		@Override
		protected Map<Class<?>, Object> initialValue() {
			return new HashMap<>();
		}
	};

	public static <T> T get(Class<T> clazz) {
		return get(clazz, null);
	}

	@SuppressWarnings("unchecked")
	public static <T> T get(final Class<T> clazz, Function0<T> factory) {
		T t = (T) extensions.get().get(clazz);
		if (t == null) {
			t = createInstance(clazz, factory, t);
			register(clazz, t);
			//get(ProcessingEnvironment.class).getMessager().printMessage(Kind.NOTE,  "ExtensionRegistry created "+clazz);
		}
		return t;
	}

	private static <T> T createInstance(Class<T> clazz, Function0<T> factory, T t) {
		if (factory == null) {
			try {
				t = clazz.newInstance();
			} catch (InstantiationException | IllegalAccessException e) {
				throw new IllegalStateException("Extension " + clazz
						+ " not available. Extensions: " + extensions.get()
						+ " Thread: " + Thread.currentThread(), e);
			}
		} else {
			t = factory.apply();
		}
		return t;
	}

	public static void register(Class<?> clazz, Object extension) {
		extensions.get().put(clazz, extension);
	}

	public static void cleanup() {
		extensions.remove();
	}

}