package de.stefanocke.japkit.roo.petclinic.domain;

import java.util.Calendar;

import javax.persistence.Enumerated;
import javax.persistence.Temporal;
import javax.persistence.TemporalType;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Past;

import org.springframework.format.annotation.DateTimeFormat;

import de.stefanocke.japkit.roo.japkit.JapkitEntity;

@JapkitEntity
public abstract class VetDef extends AbstractPersonDef {

	/**
     */
	@NotNull
	@Past
	@Temporal(TemporalType.TIMESTAMP)
	@DateTimeFormat(style = "M-")
	private Calendar employedSince;

	/**
     */
	@Enumerated
	private Specialty specialty;
}
