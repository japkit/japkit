package de.stefanocke.japkit.roo.petclinic.domain;

import javax.persistence.Enumerated;
import javax.persistence.ManyToOne;
import javax.validation.constraints.Min;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

import de.stefanocke.japkit.roo.japkit.domain.JapkitEntity;

@JapkitEntity()
public class PetDef {

	/**
     */
	private boolean sendReminders;

	/**
     */
	@NotNull
	@Size(min = 1)
	private String name;

	/**
     */
	@NotNull
	@Min(0L)
	private Float weight;

	/**
     */
	@ManyToOne
	private Owner owner;

	/**
     */
	@NotNull
	@Enumerated
	private PetType type;
}
