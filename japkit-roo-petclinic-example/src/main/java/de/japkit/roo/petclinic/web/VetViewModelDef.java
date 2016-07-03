package de.japkit.roo.petclinic.web;

import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;

import de.japkit.roo.japkit.web.TableColumn;
import de.japkit.roo.japkit.web.ViewModel;
import de.japkit.roo.petclinic.domain.Vet;

@ViewModel(formBackingObject = Vet.class)
public class VetViewModelDef {
	@TableColumn
	String firstName;

	//Override and add some annotations
	@Size(max = 10, min = 3)
	@Pattern(regexp="[a-zA-Z]+")
	//
	@TableColumn
	String lastName;

}
