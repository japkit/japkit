package de.stefanocke.japkit.roo.petclinic.domain;

import java.util.Date;

import javax.lang.model.element.Modifier;
import javax.persistence.Temporal;
import javax.persistence.TemporalType;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

import org.springframework.format.annotation.DateTimeFormat;

import de.stefanocke.japkit.roo.japkit.JapkitEntity;

@JapkitEntity(// TODO: Das ist etwas hässlich. Ggf. isAbstract AV. o.ä. Oder modifiers per EL "berechnen"
		//modifier = { Modifier.PUBLIC, Modifier.ABSTRACT } 
)
public abstract class AbstractPersonDef {

	/**
     */
	@Size(min = 3, max = 30)
	private String firstName;

	/**
     */
	@NotNull
	@Size(min = 3, max = 30)
	private String lastName;

	/**
     */
	@NotNull
	@Size(min = 1, max = 50)
	private String address;

	/**
     */
	@NotNull
	@Size(max = 30)
	private String city;

	/**
     */
	@NotNull
	private String telephone;

	/**
     */
	@Size(max = 30)
	private String homePage;

	/**
     */
	@Size(min = 6, max = 30)
	private String email;

	/**
     */
	@NotNull
	@Temporal(TemporalType.TIMESTAMP)
	@DateTimeFormat(style = "M-")
	private Date birthDay;
}
