package de.stefanocke.japkit.roo.quickstart;

import java.util.Date;

import javax.validation.constraints.NotNull;

import de.stefanocke.japkit.roo.japkit.JapkitEntity;
import de.stefanocke.japkit.roo.quickstart.Timer2.AbstractBehavior;

@JapkitEntity(activeRecord = false, customBehavior = true)
public class Timer2Def {

	public static class Behavior extends AbstractBehavior {

		public Behavior(Timer2Internal internal) {
			super(internal);
		}

		@Override
		public String toString() {
			// TODO Auto-generated method stub
			return genToString();
		}

	}

	@NotNull
	String message;

	String message2;

	boolean someBoolean;

	Date someDate;
}
