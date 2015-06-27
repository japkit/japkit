package de.japkit.roo.petclinic.domain;

import java.util.HashSet;
import java.util.Set;

import javax.persistence.CascadeType;
import javax.persistence.OneToMany;

import de.japkit.roo.japkit.domain.JapkitEntity;

@JapkitEntity
public class OwnerDef extends AbstractPersonDef {

	/**
     */
	@OneToMany(cascade = CascadeType.ALL, mappedBy = "owner")
	Set<Pet> pets = new HashSet<Pet>();
}
