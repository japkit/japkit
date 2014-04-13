package de.stefanocke.japkit.roo.quickstart.web;

import de.stefanocke.japkit.roo.japkit.web.JapkitWebScaffold;
import de.stefanocke.japkit.roo.quickstart.Timer3;
import de.stefanocke.japkit.roo.quickstart.Timer3Repository;

@JapkitWebScaffold(path = "timers3", modelAttribute = "timer", formBackingObject = Timer3.class, 
		repository = Timer3Repository.class)
public class Timer3ControllerDef {

	
}
