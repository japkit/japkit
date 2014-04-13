package de.stefanocke.japkit.roo.japkit.web;

import org.springframework.beans.factory.annotation.Autowired;

import de.stefanocke.japkit.metaannotations.Field;
import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.roo.base.web.CrudOperations;
import de.stefanocke.japkit.roo.base.web.RepositoryAdapter;

@Template
public abstract class ControllerMembersJpaRepository {
	
	@Field()
    @Autowired
    private Repository repository;
	
	@Method(imports=RepositoryAdapter.class,			
			bodyExpr="return new RepositoryAdapter<#{ec.typeRef(fbo)}>(repository);")
	protected abstract CrudOperations<FormBackingObject> crudOperations();

	
}
