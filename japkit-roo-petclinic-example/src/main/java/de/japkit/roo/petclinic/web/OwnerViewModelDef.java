package de.japkit.roo.petclinic.web;

import de.japkit.roo.japkit.web.TableColumn;
import de.japkit.roo.japkit.web.ViewModel;
import de.japkit.roo.petclinic.domain.Owner;

@ViewModel(formBackingObject = Owner.class)
public class OwnerViewModelDef {
	@TableColumn
	String firstName;


	@TableColumn
	String lastName;
	
}
