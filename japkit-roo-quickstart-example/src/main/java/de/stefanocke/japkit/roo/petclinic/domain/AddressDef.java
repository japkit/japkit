package de.stefanocke.japkit.roo.petclinic.domain;

import javax.validation.constraints.NotNull;

import de.stefanocke.japkit.roo.japkit.ValueObject;

@ValueObject
public class AddressDef {
	@NotNull
	String street;
	
	String state;
	
	@NotNull
	String city;
	
	@NotNull
	String zip;
	
}
