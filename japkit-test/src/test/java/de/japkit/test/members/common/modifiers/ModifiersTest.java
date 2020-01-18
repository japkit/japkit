package de.japkit.test.members.common.modifiers;

import static org.junit.Assert.assertEquals;

import java.lang.reflect.Member;
import java.lang.reflect.Modifier;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

import org.junit.Test;

public class ModifiersTest {

	private static final Map<String, Integer> expectedFieldModifiers = new HashMap<>();

	static {
		expectedFieldModifiers.put("publicField", Modifier.PUBLIC);
		expectedFieldModifiers.put("privateField", Modifier.PRIVATE);
		expectedFieldModifiers.put("publicStaticField", Modifier.PUBLIC | Modifier.STATIC);
		expectedFieldModifiers.put("transientVolatileField", Modifier.TRANSIENT | Modifier.VOLATILE);
		expectedFieldModifiers.put("finalField", Modifier.FINAL);
		expectedFieldModifiers.put("dynamicallyPrivateField", Modifier.PRIVATE);
		expectedFieldModifiers.put("dynamicallyNonPublicStaticField", Modifier.STATIC);
	}

	private static final Map<String, Integer> expectedMethodModifiers = new HashMap<>();

	static {
		expectedMethodModifiers.put("notAbstractMethod", Modifier.PUBLIC);
	}

	private static final Map<String, Integer> expectedClassModifiers = new HashMap<>();

	static {
		expectedClassModifiers.put("NonAbstractInnerClass", Modifier.PUBLIC);
		expectedClassModifiers.put("AbstractInnerClass", Modifier.PUBLIC | Modifier.ABSTRACT);
	}

	@Test
	public void test() {
		ModifiersExampleGen gen = new ModifiersExampleGen();
		assertEquals("initialValue", gen.finalField);
		assertEquals(null, gen.notAbstractMethod());
		Class<? extends ModifiersExampleGen> genClass = gen.getClass();

		assertModifiers(genClass::getDeclaredField, Member::getModifiers, expectedFieldModifiers);
		assertModifiers(genClass::getDeclaredMethod, Member::getModifiers, expectedMethodModifiers);
		assertModifiers(name -> getDeclaredClass(genClass, name), Class::getModifiers, expectedClassModifiers);
	}

	private Class<?> getDeclaredClass(Class<? extends ModifiersExampleGen> declaringClass, String name) {
		return Arrays.stream(declaringClass.getDeclaredClasses()).filter(c -> c.getSimpleName().equals(name)).findFirst().get();
	}

	private <M> void assertModifiers(FunctionWithException<String, M> getMember, Function<M, Integer> getModifiers,
			Map<String, Integer> expectedModifiers) {
		expectedModifiers.entrySet().stream().forEach(e -> {
			try {
				M member = getMember.apply(e.getKey());
				// field.setAccessible(true);
				assertEquals("Wrong modifiers: " + member + ", expected: " + Modifier.toString(e.getValue()) + ".", e.getValue(),
						getModifiers.apply(member));
			} catch (Exception ex) {
				throw new RuntimeException(ex);
			}
		});
	}

	interface FunctionWithException<T, R> {
		R apply(T t) throws Exception;
	}

}
