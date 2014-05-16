package de.stefanocke.japkit.roo.petclinic.web;

import de.stefanocke.japkit.roo.japkit.web.TableColumn;
import de.stefanocke.japkit.roo.japkit.web.ViewModel;
import de.stefanocke.japkit.roo.petclinic.domain.Owner;

@ViewModel(formBackingObject = Owner.class)
public class OwnerViewModelDef {
	@TableColumn
	String firstName;


	@TableColumn
	String lastName;
	
}
