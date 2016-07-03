package de.japkit.roo.petclinic.domain;

import javax.validation.constraints.NotNull;

import de.japkit.annotations.Order;
import de.japkit.roo.japkit.domain.ValueObject;

@ValueObject
public class AddressDef {
	/**
	 * the street
	 */
	@NotNull
	@Order(0)
	String street;
	
	/**
	 * the city
	 */
	@Order(1)
	@NotNull
	String city;
	
	/**
	 * the zip code
	 */
	@Order(2)
	@NotNull
	String zip;
	
	/**
	 * the state
	 */
	@Order(3)
	String state;
	
	//@Order(4)
	//Date someDate;
	
	
}
