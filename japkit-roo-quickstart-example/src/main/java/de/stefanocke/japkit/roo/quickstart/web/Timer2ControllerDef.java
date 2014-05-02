package de.stefanocke.japkit.roo.quickstart.web;

import de.stefanocke.japkit.roo.japkit.web.JapkitWebScaffold;
import de.stefanocke.japkit.roo.quickstart.Timer2;
import de.stefanocke.japkit.roo.quickstart.web.Timer2Controller.AbstractBehavior;

@JapkitWebScaffold(formBackingObject = Timer2.class, customBehavior = true, path = "timers2")
public class Timer2ControllerDef {

	public static class Behavior extends AbstractBehavior {

		protected Behavior(Timer2ControllerInternal internal) {
			super(internal);
		}

	}

}
