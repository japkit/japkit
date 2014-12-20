package de.stefanocke.japkit.roo.petclinic.web;

import de.stefanocke.japkit.roo.japkit.web.JapkitWebScaffold;
import de.stefanocke.japkit.roo.petclinic.domain.Vet;
import de.stefanocke.japkit.roo.petclinic.web.VetController.AbstractBehavior;

@JapkitWebScaffold(formBackingObject = Vet.class, customBehavior=true)
public class VetControllerDef {

	public static class Behavior extends AbstractBehavior {

		protected Behavior(VetControllerInternal internal) {
			super(internal);
			// TODO Auto-generated constructor stub
		}

	}

	

}
