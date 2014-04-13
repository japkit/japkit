package de.stefanocke.japkit.roo.quickstart;

import javax.validation.constraints.NotNull;

import de.stefanocke.japkit.roo.japkit.JapkitEntity;

@JapkitEntity(activeRecord = true)
public class Timer2ActiveRecordDef {

	@NotNull
	String message;

}
