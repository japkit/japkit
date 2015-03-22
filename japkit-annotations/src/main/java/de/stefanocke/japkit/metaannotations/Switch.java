package de.stefanocke.japkit.metaannotations;

public @interface Switch {
	Case[] value() default {};
}
