package de.japkit.roo.petclinic.domain;

import de.japkit.roo.japkit.domain.JapkitEntity;

@JapkitEntity
public class OwnerDef extends AbstractPersonDef {

	/**
	 * Avoid bidirectional.
     */
	//@OneToMany(cascade = CascadeType.ALL, mappedBy = "owner")
	//Set<Pet> pets = new HashSet<Pet>();
}
