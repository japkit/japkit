package de.japkit.metaannotations;

import java.lang.annotation.Documented;

@Documented
public @interface Case {

	String cond() default "";

	String condLang() default "";

	Class<?>[] condFun() default {};

	String value() default "";

	String valueLang() default "";

	Class<?>[] valueFun() default {};
}
