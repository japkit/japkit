package de.stefanocke.japkit.roo.japkit;

import java.util.List;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.TypedQuery;

import org.springframework.beans.factory.annotation.Configurable;
import org.springframework.transaction.annotation.Transactional;

import de.stefanocke.japkit.annotations.RuntimeMetadata;
import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.metaannotations.classselectors.GeneratedClass;

@RuntimeMetadata
@Template(vars = @Var(expr = "#{currentGenClass.simpleName}", name = "entityName", type = String.class))
@Configurable
public abstract class ActiveRecordMembers {
	
	/**@japkit.initCode <code>null</code>*/
	@PersistenceContext
	transient EntityManager entityManager;

	@Method(imports = { EntityManager.class, IllegalStateException.class },
			bodyCode = "EntityManager em = new #{entityName}().entityManager;\n"
					+ "if (em == null) throw new IllegalStateException(\"Entity manager has not been injected\");\n" + "return em;\n")
	static final EntityManager entityManager() {
		return null;
	}

	@Method(bodyCode = "if (this.entityManager == null) this.entityManager = entityManager();")
	private void initEntityManager() {
	}

	@Method(bodyCode = "return entityManager().createQuery(\"SELECT COUNT(o) FROM #{entityName} o\", Long.class).getSingleResult();")
	public static long count$entityName$s() {
		return 0;
	}

	@Method(bodyCode = "if (id == null) return null;\n"
			+ "return entityManager().find(#{entityName}.class, id);")
	public static GeneratedClass find$entityName$(Long id) {
		return null;
	}

	@Method(bodyCode = "return find#{entityName}Entries(null, null, null, null);")
	public static List<GeneratedClass> findAll$entityName$s() {
		return null;
	}

	@Method(bodyCode = "return find#{entityName}Entries(null, null, sortFieldName, sortOrder);")
	public static List<GeneratedClass> findAll$entityName$s(String sortFieldName, String sortOrder) {
		return null;
	}

	@Method(bodyCode = "return find#{entityName}Entries(firstResult, maxResults, null, null);")
	public static List<GeneratedClass> find$entityName$Entries(Integer firstResult, Integer maxResults) {
		return null;
	}

	@Method(imports = TypedQuery.class,
			bodyCode = "String jpaQuery = \"SELECT o FROM #{entityName} o\";\n" + "addOrderBy(jpaQuery, sortFieldName, sortOrder);\n"
					+ "TypedQuery<#{entityName}> query =  entityManager().createQuery(jpaQuery, #{entityName}.class);\n"
					+ "if(firstResult!=null && maxResults!=null){query.setFirstResult(firstResult).setMaxResults(maxResults);}\n"
					+ "return query.getResultList();")
	public static List<GeneratedClass> find$entityName$Entries(Integer firstResult, Integer maxResults, String sortFieldName, String sortOrder) {
		return null;
	}

	// NOTE: This should be better moved to a separate class instead of
	// being generated. However, we keep quite close to Roo code gen here.
	// Same is true for other methods here. Mostly, fixed parts can easily
	// be factored out.
	@Method(bodyCode = "if (sortFieldName != null /**TODO: Check field name*/) {\n"
			+ "\tString jpaQueryWithOrderBy = jpaQuery + \" ORDER BY \" + sortFieldName;\n"
			+ "\tif (\"ASC\".equalsIgnoreCase(sortOrder) || \"DESC\".equalsIgnoreCase(sortOrder)) {\n"
			+ "\t\tjpaQueryWithOrderBy = jpaQueryWithOrderBy + \" \" + sortOrder;\n" + "\t}\n" + "\treturn jpaQueryWithOrderBy;\n" + "}\n"
			+ "return jpaQuery;")
	private static String addOrderBy(String jpaQuery, String sortFieldName, String sortOrder) {
		return null;
	}

	@Method(bodyCode = "initEntityManager();\n" + "this.entityManager.persist(this);")
	@Transactional
	public abstract void persist();

	@Method(bodyCode = "initEntityManager();\n" + " if (this.entityManager.contains(this)) {\n" + "\tthis.entityManager.remove(this);\n"
			+ "} else {\n" + "\t#{entityName} attached = #{entityName}.find#{entityName}(this.id);\n"
			+ "\tthis.entityManager.remove(attached);\n" + "}")
	@Transactional
	public abstract void remove();

	@Method(bodyCode = "initEntityManager();\n" + "this.entityManager.flush();")
	@Transactional
	public abstract void flush();

	@Method(bodyCode = "initEntityManager();\n" + "this.entityManager.clear();")
	@Transactional
	public abstract void clear();

	@Method(bodyCode = "initEntityManager();\n" + "#{entityName} merged = this.entityManager.merge(this);\n"
			+ "this.entityManager.flush();\n" + "return merged;")
	@Transactional
	public abstract GeneratedClass merge();
}
