package de.stefanocke.japkit.roo.petclinic.domain;

import javax.validation.constraints.NotNull;

import de.stefanocke.japkit.roo.japkit.ValueObject;

@ValueObject
public class AddressDef {
	/**
	 * the street
	 */
	@NotNull
	String street;
	
	/**
	 * the state
	 */
	String state;
	
	/**
	 * the city
	 */
	@NotNull
	String city;
	
	/**
	 * the zip code
	 */
	@NotNull
	String zip;
	
	
	
}
