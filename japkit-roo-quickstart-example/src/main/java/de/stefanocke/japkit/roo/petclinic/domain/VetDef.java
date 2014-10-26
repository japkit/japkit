package de.stefanocke.japkit.roo.petclinic.domain;

import java.util.Calendar;

import javax.persistence.Enumerated;
import javax.persistence.Temporal;
import javax.persistence.TemporalType;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Past;

import org.springframework.format.annotation.DateTimeFormat;

import de.stefanocke.japkit.annotations.Order;
import de.stefanocke.japkit.roo.japkit.domain.JapkitEntity;

@JapkitEntity(createCommandProperties={VetProperties.Specialty_.class /*, VetProperties.FirstName_.class, VetProperties.LastName_.class*/})
public class VetDef extends AbstractPersonDef {	
	
	/**
     */
	@NotNull
	@Past
	@Temporal(TemporalType.TIMESTAMP)
	@DateTimeFormat(style = "M-")
	@Order(0)
	private Calendar employedSince;

	/**
     */
	@Enumerated
	@Order(1)
	private Specialty specialty;
	
	
}
