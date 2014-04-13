package de.stefanocke.japkit.roo.quickstart;

import javax.validation.constraints.NotNull;

import de.stefanocke.japkit.roo.japkit.JapkitEntity;

@JapkitEntity(activeRecord = false, customBehavior = false)
public class Timer3Def {

	

	@NotNull
	String foo;

	String bar;
}
