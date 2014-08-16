package de.stefanocke.japkit.roo.petclinic.web;

import org.springframework.ui.Model;

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
		
		//@Override
		public void foo(String bar){}
		
		//@Override
		protected void addDateTimeFormatPatterns(Model uiModel) {
			// TODO Auto-generated method stub
			genAddDateTimeFormatPatterns(uiModel);
		}

	}

}
