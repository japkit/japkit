package de.stefanocke.japkit.roo.petclinic.web;

import javax.validation.constraints.Size;

import de.stefanocke.japkit.roo.japkit.web.ViewModel;
import de.stefanocke.japkit.roo.petclinic.domain.Vet;

@ViewModel(formBackingObject = Vet.class)
public class VetViewModelDef {

	@Size(max = 20, min = 3)
	String lastName;
	
	//boolean nonExistingProperty;
}
