package de.stefanocke.japkit.roo.petclinic.domain;

import java.util.Date;

import javax.persistence.ManyToOne;
import javax.persistence.Temporal;
import javax.persistence.TemporalType;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Past;
import javax.validation.constraints.Size;

import org.springframework.format.annotation.DateTimeFormat;

import de.stefanocke.japkit.roo.japkit.domain.JapkitEntity;

@JapkitEntity
public class VisitDef {

	/**
     */
	@Size(max = 255)
	private String description;

	/**
     */
	@NotNull
	@Past
	@Temporal(TemporalType.TIMESTAMP)
	@DateTimeFormat(style = "M-")
	private Date visitDate;

	/**
     */
	@NotNull
	@ManyToOne
	private Pet pet;

	/**
     */
	@ManyToOne
	private Vet vet;
}
