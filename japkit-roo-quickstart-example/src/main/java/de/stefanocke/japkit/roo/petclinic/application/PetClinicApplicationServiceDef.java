package de.stefanocke.japkit.roo.petclinic.application;

import de.stefanocke.japkit.roo.japkit.application.ApplicationService;
import de.stefanocke.japkit.roo.petclinic.application.RateVetCommand.AbstractBehavior;
import de.stefanocke.japkit.roo.petclinic.domain.Owner;
import de.stefanocke.japkit.roo.petclinic.domain.Pet;
import de.stefanocke.japkit.roo.petclinic.domain.Vet;
import de.stefanocke.japkit.roo.petclinic.domain.Visit;

@ApplicationService(aggregateRoots={Vet.class, Pet.class, Owner.class, Visit.class}, customBehaviorFor=RateVetCommand.class)
public class PetClinicApplicationServiceDef {

	static class RateVetCommandBehavior extends AbstractBehavior {

		protected RateVetCommandBehavior(RateVetCommandInternal internal) {
			super(internal);
		}
		
		//@Override
		protected void setRating(int rating) {
			genSetRating(rating > 5 ? rating : 5);
		}

	}
	
	static class UpdateVetCommandBehavior extends UpdateVetCommand.AbstractBehavior{

		protected UpdateVetCommandBehavior(UpdateVetCommandInternal internal) {
			super(internal);
		}
		
	}
	
	static class Behavior extends PetClinicApplicationService.AbstractBehavior{

		protected Behavior(PetClinicApplicationServiceInternal internal) {
			super(internal);
		}
		
		protected Owner createOwner(CreateOwnerCommand command) {
			
			return genCreateOwner(command);
		}
		
	}

}
