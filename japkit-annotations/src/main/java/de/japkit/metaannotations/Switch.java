package de.japkit.metaannotations;

public @interface Switch {
	Case[] value() default {};
}
