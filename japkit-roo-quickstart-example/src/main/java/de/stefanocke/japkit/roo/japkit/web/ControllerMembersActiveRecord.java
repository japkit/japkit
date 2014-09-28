package de.stefanocke.japkit.roo.japkit.web;

import java.util.List;

import de.stefanocke.japkit.annotations.ParamNames;
import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.roo.base.web.CrudOperations;

@Template
public abstract class ControllerMembersActiveRecord implements CrudOperations<FormBackingObject> {

	@Method(bodyCode = "return this;")
	protected abstract CrudOperations<FormBackingObject> crudOperations();

	/*
	 * (non-Javadoc)
	 * 
	 * @see
	 * de.stefanocke.japkit.roo.japkit.domain.CrudOperations#remove(java.lang.Long)
	 */
	@Override
	@Method(bodyCode = "#{fbo.code} fbo = #{fbo.name}.find#{fboName}(id);\n" + "fbo.remove();\n")
	@ParamNames("id")
	public abstract void remove(Long id);

	/*
	 * (non-Javadoc)
	 * 
	 * @see
	 * de.stefanocke.japkit.roo.japkit.domain.CrudOperations#merge(de.stefanocke.japkit
	 * .roo.japkit.FormBackingObject)
	 */
	@Override
	@Method(bodyCode = "return fbo.merge();")
	@ParamNames("fbo")
	public abstract FormBackingObject merge(FormBackingObject fbo);

	/*
	 * (non-Javadoc)
	 * 
	 * @see
	 * de.stefanocke.japkit.roo.japkit.domain.CrudOperations#persist(de.stefanocke.
	 * japkit.roo.japkit.FormBackingObject)
	 */
	@Override
	@Method(bodyCode = "fbo.persist();")
	@ParamNames("fbo")
	public abstract void persist(FormBackingObject fbo);

	/*
	 * (non-Javadoc)
	 * 
	 * @see de.stefanocke.japkit.roo.japkit.domain.CrudOperations#find(java.lang.Long)
	 */
	@Override
	@Method(bodyCode = "return #{fbo.name}.find#{fboName}(id);")
	@ParamNames("id")
	public abstract FormBackingObject find(Long id);

	/*
	 * (non-Javadoc)
	 * 
	 * @see de.stefanocke.japkit.roo.japkit.domain.CrudOperations#count()
	 */
	@Override
	@Method(bodyCode = "return #{fbo.name}.count#{fboName}s();")
	public abstract long count();

	/*
	 * (non-Javadoc)
	 * 
	 * @see
	 * de.stefanocke.japkit.roo.japkit.domain.CrudOperations#findAll(java.lang.String,
	 * java.lang.String)
	 */
	@Override
	@Method(bodyCode = "return #{fbo.name}.findAll#{fboName}s(sortFieldName, sortOrder);")
	@ParamNames({ "sortFieldName", "sortOrder" })
	public abstract List<FormBackingObject> findAll(String sortFieldName, String sortOrder);

	/*
	 * (non-Javadoc)
	 * 
	 * @see
	 * de.stefanocke.japkit.roo.japkit.domain.CrudOperations#findEntries(java.lang.
	 * Integer, java.lang.Integer, java.lang.String, java.lang.String)
	 */
	@Override
	@Method(bodyCode = "return #{fbo.name}.find#{fboName}Entries(firstResult, maxResults, sortFieldName, sortOrder);")
	@ParamNames({ "firstResult", "maxResults", "sortFieldName", "sortOrder" })
	public abstract List<FormBackingObject> findEntries(Integer firstResult, Integer maxResults, String sortFieldName, String sortOrder);

}
