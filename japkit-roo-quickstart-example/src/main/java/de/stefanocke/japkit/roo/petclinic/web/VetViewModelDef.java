package de.stefanocke.japkit.roo.petclinic.web;

import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;

import de.stefanocke.japkit.roo.japkit.web.ShowInTable;
import de.stefanocke.japkit.roo.japkit.web.ViewModel;
import de.stefanocke.japkit.roo.petclinic.domain.Vet;

@ViewModel(formBackingObject = Vet.class)
public class VetViewModelDef {
	@ShowInTable
	String firstName;

	//Override and add some annotations
	@Size(max = 10, min = 3)
	@Pattern(regexp="[a-zA-Z]+")
	//
	@ShowInTable
	String lastName;
	
	//boolean nonExistingProperty;
}
