package de.stefanocke.japkit.roo.petclinic.domain;
import java.util.HashSet;
import java.util.Set;

import javax.persistence.CascadeType;
import javax.persistence.OneToMany;

import de.stefanocke.japkit.roo.japkit.JapkitEntity;

@JapkitEntity
public class OwnerDef extends AbstractPerson {

    /**
     */
    @OneToMany(cascade = CascadeType.ALL, mappedBy = "owner")
    private Set<Pet> pets = new HashSet<Pet>();
}
