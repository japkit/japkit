package de.japkit.roo.petclinic.domain;

import javax.persistence.Enumerated;
import javax.persistence.ManyToOne;
import javax.validation.constraints.Min;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

import de.japkit.annotations.Order;
import de.japkit.roo.japkit.domain.JapkitEntity;

@JapkitEntity()
public class PetDef {

	/**
     */
	@NotNull
	@Size(min = 1)
	@Order(0)
	String name;

	/**
     */
	@NotNull
	@Enumerated
	@Order(1)
	PetType type;
	
	/**
     */
	@NotNull
	@Min(0L)
	@Order(2)
	Float weight;

	/**
     */
	@Order(3)
	boolean sendReminders;
	
	/**
     */
	@ManyToOne
	@Order(4)
	Owner owner;

	
	
}
