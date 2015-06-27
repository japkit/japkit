package de.japkit.roo.petclinic.web;

import de.japkit.roo.japkit.web.JapkitWebScaffold;
import de.japkit.roo.petclinic.domain.Vet;
import de.japkit.roo.petclinic.web.VetController.AbstractBehavior;

@JapkitWebScaffold(formBackingObject = Vet.class, customBehavior=true)
public class VetControllerDef {

	public static class Behavior  extends AbstractBehavior{

		protected Behavior(VetControllerInternal internal) {
			super(internal);
			// TODO Auto-generated constructor stub
		}
	

	}


	

}
