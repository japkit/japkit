package de.japkit.roo.petclinic.domain;

import java.util.Date;

import javax.persistence.Temporal;
import javax.persistence.TemporalType;
import javax.validation.Valid;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

import org.springframework.format.annotation.DateTimeFormat;

import de.japkit.annotations.Order;
import de.japkit.roo.japkit.domain.JapkitEntity;

@JapkitEntity(// TODO: Das ist etwas hässlich. Ggf. isAbstract AV. o.ä. Oder
				// modifiers per EL "berechnen"
// modifier = { Modifier.PUBLIC, Modifier.ABSTRACT }
)
public abstract class AbstractPersonDef {

	/**
     */
	@Order(0)
	@Size(min = 3, max = 30)
	String firstName;

	/**
     */
	@Order(1)
	@NotNull
	@Size(min = 3, max = 30)
	String lastName;

	/**
     */
	@Order(2)
	@NotNull
	@Valid
	//@Size(min = 1, max = 50)
	Address address;

	/**
     */
	@Order(4)
	@NotNull
	String telephone;

	/**
     */
	@Order(5)
	@Size(max = 30)
	String homePage;

	/**
     */
	@Order(6)
	@Size(min = 6, max = 30)
	String email;

	/**
     */
	@Order(7)
	@NotNull
	@Temporal(TemporalType.TIMESTAMP)
	@DateTimeFormat(style = "M-")
	Date birthDay;
}
