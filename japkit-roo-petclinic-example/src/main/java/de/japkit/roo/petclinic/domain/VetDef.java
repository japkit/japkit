package de.japkit.roo.petclinic.domain;

import java.util.Calendar;

import javax.persistence.Enumerated;
import javax.persistence.Temporal;
import javax.persistence.TemporalType;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Past;

import org.springframework.format.annotation.DateTimeFormat;

import de.japkit.annotations.Order;
import de.japkit.roo.japkit.domain.JapkitEntity;
import de.japkit.roo.petclinic.domain.Vet.AbstractBehavior;

@JapkitEntity(customBehavior=true/*createCommandProperties={VetProperties.Specialty_.class , VetProperties.FirstName_.class, VetProperties.LastName_.class}*/)
public class VetDef extends AbstractPersonDef {	
	
	public static class Behavior extends AbstractBehavior {

		protected Behavior(VetInternal internal) {
			super(internal);
		}
		
		public void rateVet(int rating){
			
		}

	}

	/**
     */
	@NotNull
	@Past
	@Temporal(TemporalType.TIMESTAMP)
	@DateTimeFormat(style = "M-")
	@Order(0)
	Calendar employedSince;

	/**
     */
	@Enumerated
	@Order(1)
	Specialty specialty;
	
	
}
