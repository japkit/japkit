package de.stefanocke.japkit.roo.petclinic.application;

import de.stefanocke.japkit.roo.japkit.application.ApplicationService;
import de.stefanocke.japkit.roo.petclinic.domain.Owner;
import de.stefanocke.japkit.roo.petclinic.domain.Pet;
import de.stefanocke.japkit.roo.petclinic.domain.Vet;
import de.stefanocke.japkit.roo.petclinic.domain.Visit;

@ApplicationService(aggregateRoots={Vet.class, Pet.class, Owner.class, Visit.class})
public class PetClinicApplicationServiceDef {

}
