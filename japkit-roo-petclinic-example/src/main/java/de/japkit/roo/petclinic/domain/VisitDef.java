package de.japkit.roo.petclinic.domain;

import java.util.Date;

import javax.persistence.ManyToOne;
import javax.persistence.Temporal;
import javax.persistence.TemporalType;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Past;
import javax.validation.constraints.Size;

import org.springframework.format.annotation.DateTimeFormat;

import de.japkit.annotations.Order;
import de.japkit.roo.japkit.domain.JapkitEntity;

@JapkitEntity
public class VisitDef {

	/**
     */
	@NotNull
	@Past
	@Temporal(TemporalType.TIMESTAMP)
	@DateTimeFormat(style = "M-")
	@Order(0)
	Date visitDate;
	
	/**
     */
	@Size(max = 255)
	@Order(1)
	String description;

	/**
     */
	@NotNull
	@ManyToOne
	@Order(2)
	Pet pet;

	/**
     */
	@ManyToOne
	@Order(3)
	Vet vet;
}
